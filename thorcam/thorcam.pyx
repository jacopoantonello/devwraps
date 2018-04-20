#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#cython: embedsignature=True

"""

author: J. Antonello <jacopo.antonello@dpag.ox.ac.uk>
date: Mon Feb 26 07:32:24 GMT 2018

"""

import sys
import numpy as np
cimport numpy as np

from os import path

from libc.string cimport memset, memcpy
from libc.stdint cimport uintptr_t
from libc.stddef cimport wchar_t
from libc.stdlib cimport free, malloc
from cpython cimport PyObject, Py_INCREF

from cthorcam cimport (
    IS_SUCCESS, is_GetNumberOfCameras, is_InitCamera, is_ExitCamera,
    is_GetCameraInfo, BOARDINFO, is_GetSensorInfo, SENSORINFO,
    is_EnableAutoExit, is_SetAllocatedImageMem, is_SetImageMem,
    is_FreeImageMem, is_FreezeVideo, is_CopyImageMem, is_GetImageMemPitch,
    is_Exposure, IS_EXPOSURE_CMD_GET_CAPS, IS_EXPOSURE_CMD_GET_EXPOSURE,
    IS_EXPOSURE_CMD_SET_EXPOSURE, IS_EXPOSURE_CMD_GET_EXPOSURE_RANGE,
    IS_EXPOSURE_CMD_GET_FINE_INCREMENT_RANGE, IS_EXPOSURE_CAP_EXPOSURE,
    IS_EXPOSURE_CAP_FINE_INCREMENT, IS_EXPOSURE_CAP_LONG_EXPOSURE,
    IS_EXPOSURE_CAP_DUAL_EXPOSURE, IS_PARAMETERSET_CMD_SAVE_FILE,
    IS_PARAMETERSET_CMD_LOAD_FILE, is_ParameterSet, is_ResetToDefault,
    IS_RECT, is_AOI, IS_AOI_IMAGE_SET_AOI, IS_CM_MONO8, is_SetColorMode,
    PyUnicode_AsWideCharString, IS_COLORMODE_MONOCHROME, is_AddToSequence,
    is_EnableEvent, IS_SET_EVENT_FRAME, is_InitEvent, CreateEvent,
    CloseHandle, IS_DONT_WAIT, WaitForSingleObject, WAIT_TIMEOUT,
    WAIT_OBJECT_0, is_GetImageMem, is_UnlockSeqBuf, is_LockSeqBuf,
    IS_IGNORE_PARAMETER, is_DisableEvent, is_ExitEvent,
    is_SetAutoParameter, IS_GET_ENABLE_AUTO_GAIN, IS_SET_ENABLE_AUTO_GAIN,
    is_SetFrameRate, IS_GET_FRAMERATE, is_GetFrameTimeRange,
    is_GetFramesPerSecond, is_CaptureVideo, IS_GET_LIVE, IS_WAIT,
    is_StopLiveVideo, IS_CAPTURE_STATUS_INFO_CMD_RESET,
    IS_CAPTURE_STATUS_INFO_CMD_GET, IS_CAP_STATUS_API_NO_DEST_MEM,
    IS_CAP_STATUS_API_CONVERSION_FAILED, IS_CAP_STATUS_API_IMAGE_LOCKED,
    IS_CAP_STATUS_DRV_OUT_OF_BUFFERS, IS_CAP_STATUS_DRV_DEVICE_NOT_READY,
    IS_CAP_STATUS_USB_TRANSFER_FAILED, IS_CAP_STATUS_DEV_MISSED_IMAGES,
    IS_CAP_STATUS_DEV_TIMEOUT, IS_CAP_STATUS_DEV_FRAME_CAPTURE_FAILED,
    IS_CAP_STATUS_ETH_BUFFER_OVERRUN, IS_CAP_STATUS_ETH_MISSED_IMAGES,
    UC480_CAPTURE_STATUS_INFO, is_CaptureStatus, UC480_CAMERA_LIST,
    is_GetCameraList, UC480_CAMERA_INFO, IS_USE_DEVICE_ID )


np.import_array()

DEF DEBUG = 0

# https://gist.github.com/GaelVaroquaux/1249305
# https://github.com/BackupGGCode/pyueye/

cdef class BufWrap:
    cdef void* data
    cdef np.npy_intp shape[2]
    cdef int memid

    cdef set_data(self, int size0, int size1, char* data, int memid):
        """ Set the data of the array

        This cannot be done in the constructor as it must receive C-level
        arguments.

        Parameters:
        -----------
        size: int
            Length of the array.
        data: void*
            Pointer to the data

        """
        self.data = data
        self.shape[0] = size0
        self.shape[1] = size1
        self.memid = memid

        if DEBUG:
            print('BufWrap SET data {:x} memid {:d}'.format(
                <unsigned long>data, memid))

    def __array__(self):
        ndarray = np.PyArray_SimpleNewFromData(
            2, self.shape, np.NPY_UINT8, self.data)
        return ndarray

    def __dealloc__(self):
        if DEBUG:
            print('BufWrap FREE data {:x} memid {:d}'.format(
                <unsigned long>self.data, self.memid))
        free(<void*>self.data)

    def get_data(self):
        return <uintptr_t>self.data

    def get_memid(self):
        return self.memid


cdef class ThorCam:

    cdef unsigned long phCam
    cdef SENSORINFO info
    cdef char *imgMem
    cdef int imgId
    cdef int pitch
    cdef int exp_cap
    cdef int exp_cap_fine
    cdef int exp_cap_long
    cdef int exp_dual_long
    cdef void *hEvent
    cdef char *lastSeqBuf
    cdef int liveMode
    cdef list bufwraps

    def __cinit__(self):
        self.phCam = 0
        self.imgMem = NULL
        self.imgId = -1
        self.pitch = 0

        self.hEvent = NULL
        self.lastSeqBuf = NULL
        self.liveMode = 0
        self.bufwraps = []

    def get_number_of_cameras(self):
        cdef int ret
        cdef int num

        ret = is_GetNumberOfCameras(&num)
        if ret != IS_SUCCESS:
            raise Exception('Failure in is_GetNumberOfCameras')
        else:
            return num

    def get_devices(self):
        cdef int ret
        cdef int num
        cdef UC480_CAMERA_LIST *clist
        cdef list retlist = []
        cdef list tmplist

        ret = is_GetNumberOfCameras(&num)
        if ret != IS_SUCCESS:
            raise Exception('Failure in is_GetNumberOfCameras camera_list')

        if num <= 0:
            return []
        else:
            clist = <UC480_CAMERA_LIST *>malloc(
                sizeof(unsigned long) + num*sizeof(UC480_CAMERA_INFO))
            if clist == NULL:
                raise MemoryError('get_devices')

            clist.dwCount = num
            ret = is_GetCameraList(clist)
            if ret != IS_SUCCESS:
                free(clist)
                raise Exception('Failure in is_GetCameraList')

            for i in range(clist.dwCount):
                tmplist = []
                tmplist.append(clist.uci[i].dwCameraID)
                tmplist.append(clist.uci[i].dwDeviceID)
                tmplist.append(clist.uci[i].dwSensorID)
                tmplist.append(clist.uci[i].dwInUse)
                tmplist.append(clist.uci[i].SerNo.decode('utf-8'))
                tmplist.append(clist.uci[i].Model.decode('utf-8'))

                # print(
                #     clist.uci[i].dwCameraID, clist.uci[i].dwDeviceID,
                #     clist.uci[i].dwSensorID, clist.uci[i].dwInUse,
                #     clist.uci[i].SerNo, clist.uci[i].Model)

                retlist.append(tmplist)

            free(clist)
            return retlist

    def open(self, str serial=None):
        cdef int ret
        cdef char *cp
        cdef unsigned int expcap
        cdef UC480_CAMERA_LIST *clist
        cdef int num

        if self.phCam != 0 and serial is not None:
            # camera already opened but a name specified
            raise Exception('Camera already opened')
        elif self.phCam != 0:
            # open has been called twice, keep quiet
            return

        if serial is None:
            self.phCam = 0
            ret = is_InitCamera(&self.phCam, NULL)
            if ret != IS_SUCCESS:
                raise Exception(
                    'Failed to open first camera {}'.format(str(ret)))
        else:
            ret = is_GetNumberOfCameras(&num)
            if ret != IS_SUCCESS:
                raise Exception(
                    'Failure in is_GetNumberOfCameras camera_list')

            if num <= 0:
                raise Exception('No camera found')
            else:
                clist = <UC480_CAMERA_LIST *>malloc(
                    sizeof(unsigned long) + num*sizeof(UC480_CAMERA_INFO))
                if clist == NULL:
                    raise MemoryError('open')

                clist.dwCount = num
                ret = is_GetCameraList(clist)
                if ret != IS_SUCCESS:
                    free(clist)
                    raise Exception('Failure in is_GetCameraList open')

                devid = 0
                for i in range(clist.dwCount):
                    if clist.uci[i].SerNo.decode('utf-8') == serial:
                        devid = clist.uci[i].dwDeviceID
                        break

                free(clist)

                if devid:
                    self.phCam = devid | IS_USE_DEVICE_ID 

                    ret = is_InitCamera(&self.phCam, NULL)
                    if ret != IS_SUCCESS:
                        raise Exception(
                            'Failed to open camera {} {}'.format(
                                serial, str(ret)))
                else:
                    raise Exception('Camera {} not found'.format(serial))

            assert(self.phCam)

        ret = is_GetSensorInfo(self.phCam, &self.info)
        if ret != IS_SUCCESS:
            raise Exception('Failed to load sensor info')
        if self.info.nColorMode != IS_COLORMODE_MONOCHROME:
            raise NotImplementedError('Unsupported color mode')

        ret = is_Exposure(
            self.phCam, IS_EXPOSURE_CMD_GET_CAPS, &expcap,
            sizeof(expcap))
        if ret != IS_SUCCESS:
            raise Exception('Failed to query exposure')

        self.exp_cap = expcap & IS_EXPOSURE_CAP_EXPOSURE
        self.exp_cap_fine = expcap & IS_EXPOSURE_CAP_FINE_INCREMENT
        self.exp_cap_long = expcap & IS_EXPOSURE_CAP_LONG_EXPOSURE
        self.exp_dual_long = expcap & IS_EXPOSURE_CAP_DUAL_EXPOSURE

        ret = is_EnableAutoExit(self.phCam, 1)
        if ret != IS_SUCCESS:
            raise Exception('Failed to enable auto exit')

        self.hEvent = CreateEvent(<void *>NULL, 0, 0, <char *>NULL)
        ret = is_InitEvent(self.phCam, self.hEvent, IS_SET_EVENT_FRAME)
        if ret != IS_SUCCESS:
            raise Exception('Failed InitEvent')
        ret = is_EnableEvent(self.phCam, IS_SET_EVENT_FRAME)
        if ret != IS_SUCCESS:
            raise Exception('Failed InitEvent')

        self._init_bufs()
            
    cdef void _init_bufs(self, x=None, y=None, w=None, h=None, nbufs=10):
        cdef IS_RECT rectAOI
        cdef char *cp
        cdef int cx
        cdef int cy
        cdef int cw
        cdef int ch
        cdef int memid

        if nbufs < 2:
            nbufs = 2

        cx = 0
        cy = 0
        cw = self.info.nMaxWidth
        ch = self.info.nMaxHeight

        rectAOI.s32X = cx
        rectAOI.s32Y = cy
        rectAOI.s32Width = cw
        rectAOI.s32Height = ch
        ret = is_AOI(
                self.phCam, IS_AOI_IMAGE_SET_AOI, <void*>&rectAOI,
                sizeof(rectAOI))
        if ret != IS_SUCCESS:
            raise Exception('Failed IS_AOI_IMAGE_SET_AOI')

        ret = is_SetColorMode(self.phCam, IS_CM_MONO8)
        if ret != IS_SUCCESS:
            raise Exception('Failed is_SetColorMode')

        for i in range(len(self.bufwraps)):
            ret = is_FreeImageMem(
                self.phCam, self.bufwraps[i].get_data(),
                self.bufwraps[i].get_memid())
            if ret != IS_SUCCESS:
                raise Exception('Error in is_FreeImageMem')

        self.bufwraps.clear()

        for i in range(nbufs):
            cp = <char*>malloc(sizeof(unsigned char)*cw*ch)
            if not cp:
                raise MemoryError('cannot allocate buffer')

            ret = is_SetAllocatedImageMem(
                self.phCam, self.info.nMaxWidth, self.info.nMaxHeight, 8,
                cp, &memid)
            if ret != IS_SUCCESS:
                raise Exception('Failed allocating memory')

            bw = BufWrap()
            bw.set_data(ch, cw, cp, memid)
            self.bufwraps.append(bw)

            ret = is_AddToSequence(self.phCam, cp, memid)
            if ret != IS_SUCCESS:
                raise Exception('Failed is_AddToSequence')

        ret = is_GetImageMemPitch(self.phCam, &self.pitch)
        if ret != IS_SUCCESS:
            raise Exception('Failed GetImageMemPitch')
        if self.pitch != self.info.nMaxWidth:
            raise NotImplementedError
        
    def shape(self):
        if self.phCam:
            return (self.info.nMaxHeight, self.info.nMaxWidth)
        else:
            return None

    def get_framerate(self):
        "Get framerate in FPS."
        cdef int ret
        cdef double d

        if self.phCam:
            ret = is_SetFrameRate(
                self.phCam, IS_GET_FRAMERATE, &d)
            if ret != IS_SUCCESS:
                raise Exception('Failed is_SetFrameRate')
            return d
        else:
            return None

    def get_framespersecond(self):
        "Get effective frames per second."
        cdef int ret
        cdef double d

        if self.phCam:
            ret = is_GetFramesPerSecond(self.phCam, &d)
            if ret != IS_SUCCESS:
                raise Exception('Failed is_GetFramesPerSecond')
            return d
        else:
            return None

    def set_framerate(self, fps):
        "Set framerate in FPS."
        cdef int ret
        cdef double db1
        cdef double db2

        if self.phCam:
            db1 = float(fps)
            ret = is_SetFrameRate(
                self.phCam, db1, &db2)
            if ret != IS_SUCCESS:
                raise Exception('Failed is_SetFrameRate')
            return db2
        else:
            return None

    def get_framerate_range(self):
        """TODO

        FPS_max = 1/min, FPS_min = 1/max, FPS = 1/(min + n*interval)

        Returns
        -------
        -   `(min, max, interval)`

        """
        cdef int ret
        cdef double dmin
        cdef double dmax
        cdef double dint

        if self.phCam:
            ret = is_GetFrameTimeRange(self.phCam, &dmin, &dmax, &dint)
            if ret != IS_SUCCESS:
                raise Exception('Failed is_GetFrameTimeRange')
            return (1.0/dmax, 1.0/dmin, 1.0/dmax)
        else:
            return None

    def get_frametime_range(self):
        """TODO

        FPS_max = 1/min, FPS_min = 1/max, FPS = 1/(min + n*interval)

        Returns
        -------
        -   `(min, max, interval)`

        """
        cdef int ret
        cdef double dmin
        cdef double dmax
        cdef double dint

        if self.phCam:
            ret = is_GetFrameTimeRange(self.phCam, &dmin, &dmax, &dint)
            if ret != IS_SUCCESS:
                raise Exception('Failed is_GetFrameTimeRange')
            return (dmin, dmax, dint)
        else:
            return None

    def get_capture_status(self):
        cdef int ret
        cdef UC480_CAPTURE_STATUS_INFO csi

        if self.phCam:
            ret = is_CaptureStatus(
                self.phCam, IS_CAPTURE_STATUS_INFO_CMD_GET, &csi, sizeof(csi))
            if ret != IS_SUCCESS:
                raise Exception('Failed is_CaptureStatus')

        d = dict()
        d['NO_DEST_MEM'] = csi.adwCapStatusCnt_Detail[
            IS_CAP_STATUS_API_NO_DEST_MEM]
        d['CONVERSION_FAILED'] = csi.adwCapStatusCnt_Detail[
            IS_CAP_STATUS_API_CONVERSION_FAILED]
        d['IMAGE_LOCKED'] = csi.adwCapStatusCnt_Detail[
            IS_CAP_STATUS_API_IMAGE_LOCKED]
        d['OUT_OF_BUFFERS'] = csi.adwCapStatusCnt_Detail[
            IS_CAP_STATUS_DRV_OUT_OF_BUFFERS]
        d['DEVICE_NOT_READY'] = csi.adwCapStatusCnt_Detail[
            IS_CAP_STATUS_DRV_DEVICE_NOT_READY]
        d['USB_TRANSFER_FAILED'] = csi.adwCapStatusCnt_Detail[
            IS_CAP_STATUS_USB_TRANSFER_FAILED]
        d['DEV_MISSED_IMAGES'] = csi.adwCapStatusCnt_Detail[
            IS_CAP_STATUS_DEV_MISSED_IMAGES]
        d['DEV_TIMEOUT'] = csi.adwCapStatusCnt_Detail[
            IS_CAP_STATUS_DEV_TIMEOUT]
        d['CAPTURE_FAILED'] = csi.adwCapStatusCnt_Detail[
            IS_CAP_STATUS_DEV_FRAME_CAPTURE_FAILED]
        d['BUFFER_OVERRUN'] = csi.adwCapStatusCnt_Detail[
            IS_CAP_STATUS_ETH_BUFFER_OVERRUN]
        d['MISSED_IMAGES'] = csi.adwCapStatusCnt_Detail[
            IS_CAP_STATUS_ETH_MISSED_IMAGES]

        return csi.dwCapStatusCnt_Total, d

    def get_exposure(self):
        "Get exposure in ms."
        cdef int ret
        cdef double d

        if self.phCam:
            ret = is_Exposure(
                self.phCam, IS_EXPOSURE_CMD_GET_EXPOSURE, &d, sizeof(d))
            if ret != IS_SUCCESS:
                raise Exception(
                    'Failed IS_EXPOSURE_CMD_GET_EXPOSURE {}'.format(str(ret)))
            return d
        else:
            return 0.

    def set_exposure(self, double exp):
        "Set exposure in ms."
        cdef int ret
        cdef double d

        if self.phCam:
            d = exp
            ret = is_Exposure(
                self.phCam, IS_EXPOSURE_CMD_SET_EXPOSURE, &d, sizeof(d))
            if ret != IS_SUCCESS:
                raise Exception(
                    'Failed IS_EXPOSURE_CMD_SET_EXPOSURE {}'.format(str(ret)))

            ret = is_Exposure(
                self.phCam, IS_EXPOSURE_CMD_GET_EXPOSURE, &d, sizeof(d))
            if ret != IS_SUCCESS:
                raise Exception(
                    'Failed IS_EXPOSURE_CMD_GET_EXPOSURE {}'.format(str(ret)))
            return d
        else:
            return 0.

    def get_exposure_range(self):
        """Get exposure range.

        Returns
        -------
        -   `(min, max, step)`: exposure range

        """
        cdef int ret
        cdef double drange[3]

        if self.phCam:
            ret = is_Exposure(
                self.phCam,
                IS_EXPOSURE_CMD_GET_EXPOSURE_RANGE,
                &drange, sizeof(drange))
            if ret != IS_SUCCESS:
                raise Exception(
                    'Failed CMD_GET_EXPOSURE_RANGE {}'.format(str(ret)))

            return (drange[0], drange[1], drange[2])
        else:
            return None

    def get_exposure_fine_inc_range(self):
        "Get exposure fine increment in ms."

        cdef int ret
        cdef double drange[3]

        if self.phCam:
            ret = is_Exposure(
                self.phCam,
                IS_EXPOSURE_CMD_GET_FINE_INCREMENT_RANGE,
                &drange, sizeof(drange))
            if ret != IS_SUCCESS:
                raise Exception(
                    'Failed GET_FINE_INCREMENT_RANGE {}'.format(str(ret)))

            return (drange[0], drange[1], drange[2])
        else:
            return None

    def start_video(self, int wait=IS_WAIT):
        cdef int ret

        if self.phCam:
            if wait != IS_GET_LIVE:
                ret = is_CaptureStatus(
                    self.phCam, IS_CAPTURE_STATUS_INFO_CMD_RESET, NULL, 0)
                if ret != IS_SUCCESS:
                    raise Exception('Failed is_CaptureStatus in start_video')

            ret = is_CaptureVideo(self.phCam, wait)
            if wait == IS_GET_LIVE:
                return ret
            elif ret != IS_SUCCESS:
                raise Exception('Failed is_CaptureVideo')
            else:
                self.liveMode = 1

    def stop_video(self, int wait=IS_WAIT):
        cdef int ret

        if self.phCam:
            ret = is_StopLiveVideo(self.phCam, wait)
            if ret != IS_SUCCESS:
                raise Exception('Failed is_StopLiveVideo')
            self.liveMode = 0

    def grab_image(self, int wait=1000):
        """Acquire a single image.

        Parameters
        ----------
        - `wait`: timeout in milliseconds
        
        Returns
        -------
        - `img`: `numpy` image
        
        """

        cdef int ret
        cdef unsigned long ret2
        cdef char *pMem
        cdef np.ndarray ndarray
        cdef uintptr_t uptr1
        cdef uintptr_t uptr2

        if self.phCam == 0:
            return None

        if wait < 0:
            wait = -wait

        assert(self.hEvent)

        if self.lastSeqBuf:
            ret = is_UnlockSeqBuf(
                self.phCam, IS_IGNORE_PARAMETER, self.lastSeqBuf)
            if ret != IS_SUCCESS:
                raise Exception('Failed is_UnlockSeqBuf {}'.format(str(ret)))
            self.lastSeqBuf = NULL

        ret = is_CaptureVideo(self.phCam, IS_GET_LIVE)
        if self.liveMode and not ret:
            ret = is_CaptureVideo(self.phCam, IS_WAIT)
            if ret != IS_SUCCESS:
                raise Exception('Failed is_CaptureVideo in grab_image')

        if not self.liveMode:
            ret = is_CaptureStatus(
                self.phCam, IS_CAPTURE_STATUS_INFO_CMD_RESET, NULL, 0)
            if ret != IS_SUCCESS:
                raise Exception('Failed is_CaptureStatus in grab_image')

            ret = is_FreezeVideo(self.phCam, IS_DONT_WAIT)
            if ret != IS_SUCCESS:
                raise Exception('Failed FreezeVideo {}'.format(str(ret)))

        ret2 = WaitForSingleObject(self.hEvent, wait)
        if ret2 == WAIT_TIMEOUT:
            raise Exception('WAIT_TIMEOUT')
        elif ret2 == WAIT_OBJECT_0:
            if DEBUG:
                print('WAIT_OBJECT_0')

        ret = is_GetImageMem(self.phCam, <void **>(&pMem))
        if ret != IS_SUCCESS:
            raise Exception('Failed is_GetImageMem {}'.format(str(ret)))

        ret = is_LockSeqBuf(
            self.phCam, IS_IGNORE_PARAMETER, pMem)
        if ret != IS_SUCCESS:
            raise Exception('Failed is_LockSeqBuf {}'.format(str(ret)))
        self.lastSeqBuf = pMem

        aw = None
        uptr1 = <uintptr_t>pMem
        for i in range(len(self.bufwraps)):
            uptr2 = self.bufwraps[i].get_data()
            if uptr1 == uptr2:
                aw = self.bufwraps[i]
        if aw is None:
            raise Exception('Unknown pMem')

        ndarray = np.array(aw, copy=False)
        ndarray.base = <PyObject*>aw
        Py_INCREF(aw)
        
        return ndarray

    def get_auto_gain(self):
        cdef int ret
        cdef double db1

        if self.phCam:
            ret = is_SetAutoParameter(
                self.phCam, IS_GET_ENABLE_AUTO_GAIN, &db1, NULL)
            if ret != IS_SUCCESS:
                raise Exception('is_SetAutoParameter')
            return db1 == 1
        else:
            return False

    def set_auto_gain(self, set1):
        cdef int ret
        cdef double db1 = 0.0

        if self.phCam:
            if set1:
                db1 = 1.0
            ret = is_SetAutoParameter(
                self.phCam, IS_SET_ENABLE_AUTO_GAIN, &db1, NULL)
            if ret != IS_SUCCESS:
                raise Exception('is_SetAutoParameter')

    def close(self):
        cdef int ret
        cdef uintptr_t ptr

        if self.phCam:
            for i in range(len(self.bufwraps)):
                ptr = self.bufwraps[i].get_data()
                ret = is_FreeImageMem(
                    self.phCam, <char *>ptr, self.bufwraps[i].get_memid())
                if ret != IS_SUCCESS:
                    raise Exception('Error in is_FreeImageMem')

            self.bufwraps.clear()
            self.lastSeqBuf = NULL

            ret = is_DisableEvent(self.phCam, IS_SET_EVENT_FRAME)
            if ret != IS_SUCCESS:
                raise Exception('Error in is_DisableEvent')
            ret = is_ExitEvent(self.phCam, IS_SET_EVENT_FRAME)
            if ret != IS_SUCCESS:
                raise Exception('Error in is_ExitEvent')
            CloseHandle(self.hEvent)
            self.hEvent = NULL

            ret = is_ExitCamera(self.phCam)
            if ret != IS_SUCCESS:
                raise Exception('Failed to close camera')

            self.phCam = 0

    def get_serial_number(self):
        cdef BOARDINFO info

        if self.phCam:
            ret = is_GetCameraInfo(self.phCam, &info)
            if ret != IS_SUCCESS:
                raise Exception('Failed to load camera info')

            return info.SerNo.decode('utf-8')
        else:
            return None

    def get_camera_info(self):
        """Get camera info.

        Returns
        ----------
        - `(serial, cid, version, date)`: camera info
        
        """

        cdef BOARDINFO info

        if self.phCam:
            ret = is_GetCameraInfo(self.phCam, &info)
            if ret != IS_SUCCESS:
                raise Exception('Failed to load camera info')

            serial = info.SerNo.decode('utf-8')
            cid = info.ID.decode('utf-8')
            version = info.Version.decode('utf-8')
            date = info.Date.decode('utf-8')

            return (serial, cid, version, date)

        else:
            return None

    def get_sensor_info(self):
        """Get sensor info.

        Returns
        ----------
        - `tuple` containing sensorid, name, color_mode, max_width, max_height,
          master_gain, r_gain, g_gain, b_gain, glob_shutter, pixel_size.
        
        """

        if self.phCam:
            cid = self.info.SensorID
            name = self.info.strSensorName.decode('utf-8')
            color_mode = self.info.nColorMode
            max_width = self.info.nMaxWidth
            max_height = self.info.nMaxHeight
            master_gain = self.info.bMasterGain
            r_gain = self.info.bRGain
            g_gain = self.info.bGGain
            b_gain = self.info.bBGain
            glob_shutter = self.info.bGlobShutter
            pixel_size = self.info.wPixelSize

            return (
                cid, name, color_mode, max_width, max_height, master_gain,
                r_gain, g_gain, b_gain, glob_shutter, pixel_size)
        else:
            return None

    def get_pixel_size(self):
        "Get pixel size (width, height) in um."

        if self.phCam:
            return (self.info.wPixelSize/100, self.info.wPixelSize/100)
        else:
            return None

    def get_image_dtype(self):
        return 'uint8'

    def get_image_max(self):
        return 0xff

    def reset(self):
        if self.phCam:
            ret = is_ResetToDefault(self.phCam)
            if ret != IS_SUCCESS:
                raise Exception('Failed to reset')

    def save(self, str name='dump.ini'):
        "Save camera parameters into an ini file."
        cdef Py_ssize_t length
        cdef wchar_t *fname = PyUnicode_AsWideCharString(name, &length)

        if self.phCam:
            ret = is_ParameterSet(
                self.phCam, IS_PARAMETERSET_CMD_SAVE_FILE, <void *>fname, 0)
            if ret != IS_SUCCESS:
                raise Exception('Failed to save parameters')
        else:
            raise Exception('Camera not opened')

    def load(self, str name='dump.ini'):
        "Load camera parameters from an ini file."
        cdef Py_ssize_t length
        cdef wchar_t *fname = PyUnicode_AsWideCharString(name, &length)

        if self.phCam:
            if not path.isfile(name):
                raise Exception('File not found')

            ret = is_ParameterSet(
                self.phCam, IS_PARAMETERSET_CMD_LOAD_FILE, <void *>fname, 0)
            if ret != IS_SUCCESS:
                raise Exception('Failed to load parameters')
        else:
            raise Exception('Camera not opened')
