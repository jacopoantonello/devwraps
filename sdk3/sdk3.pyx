#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#cython: embedsignature=True

# sdk3 - 
# Copyright 2018 J. Antonello <jacopo@antonello.org>

import sys
import numpy as np
cimport numpy as np

from os import path
from libc.stdint cimport uintptr_t
from libc.stdlib cimport free, malloc
from cpython cimport PyObject, Py_INCREF
from csdk3 cimport (
    AT_IsImplemented, AT_IsReadable, AT_IsWritable,
    AT_GetBool, AT_SetBool,
    AT_GetFloat, AT_SetFloat, AT_GetFloatMin, AT_GetFloatMax,
    AT_GetInt, AT_SetInt,
    AT_GetString, AT_SetString,
    AT_GetEnumStringByIndex, AT_GetEnumCount, AT_GetEnumIndex, AT_SetEnumIndex,
    AT_IsEnumIndexAvailable, AT_QueueBuffer, AT_Command, AT_WaitBuffer,
    AT_Open, AT_Close, AT_InitialiseLibrary, AT_FinaliseLibrary, AT_Flush,
    AT_SUCCESS, AT_HANDLE_SYSTEM, AT_HANDLE_UNINITIALISED, AT_INFINITE,
    AT_ERR_NOTINITIALISED, AT_ERR_NOTIMPLEMENTED, AT_ERR_READONLY,
    AT_ERR_NOTREADABLE, AT_ERR_NOTWRITABLE, AT_ERR_OUTOFRANGE,
    AT_ERR_INDEXNOTAVAILABLE, AT_ERR_INDEXNOTIMPLEMENTED,
    AT_ERR_EXCEEDEDMAXSTRINGLENGTH, AT_ERR_CONNECTION, AT_ERR_NODATA,
    AT_ERR_INVALIDHANDLE, AT_ERR_TIMEDOUT, AT_ERR_BUFFERFULL,
    AT_ERR_INVALIDSIZE, AT_ERR_INVALIDALIGNMENT, AT_ERR_COMM,
    AT_ERR_STRINGNOTAVAILABLE, AT_ERR_STRINGNOTIMPLEMENTED,
    AT_ERR_NULL_FEATURE, AT_ERR_NULL_HANDLE, AT_ERR_NULL_IMPLEMENTED_VAR,
    AT_ERR_NULL_READABLE_VAR, AT_ERR_NULL_READONLY_VAR,
    AT_ERR_NULL_WRITABLE_VAR, AT_ERR_NULL_MINVALUE, AT_ERR_NULL_MAXVALUE,
    AT_ERR_NULL_VALUE, AT_ERR_NULL_STRING, AT_ERR_NULL_COUNT_VAR,
    AT_ERR_NULL_ISAVAILABLE_VAR, AT_ERR_NULL_MAXSTRINGLENGTH,
    AT_ERR_NULL_EVCALLBACK, AT_ERR_NULL_QUEUE_PTR, AT_ERR_NULL_WAIT_PTR,
    AT_ERR_NULL_PTRSIZE, AT_ERR_NOMEMORY, AT_ERR_DEVICEINUSE,
    AT_ERR_DEVICENOTFOUND, AT_ERR_HARDWARE_OVERFLOW,
    )


np.import_array()

cdef extern from "numpy/ndarraytypes.h":
    int NPY_ARRAY_CARRAY

DEF STRLEN = 256
DEF DEBUG = 1


ctypedef int ath
ctypedef int atbool
ctypedef long long at64
ctypedef unsigned char atu8
ctypedef Py_UNICODE atwc


cdef check_return(ret):
    if ret != AT_SUCCESS:
        raise Exception(error_string(ret))


cdef str error_string(int e):
    if e == AT_ERR_NOTINITIALISED:
        return 'AT_ERR_NOTINITIALISED'
    elif e == AT_ERR_NOTIMPLEMENTED:
        return 'AT_ERR_NOTIMPLEMENTED'
    elif e == AT_ERR_READONLY:
        return 'AT_ERR_READONLY '
    elif e == AT_ERR_NOTREADABLE:
        return 'AT_ERR_NOTREADABLE'
    elif e == AT_ERR_NOTWRITABLE:
        return 'AT_ERR_NOTWRITABLE'
    elif e == AT_ERR_OUTOFRANGE:
        return 'AT_ERR_OUTOFRANGE'
    elif e == AT_ERR_INDEXNOTAVAILABLE:
        return 'AT_ERR_INDEXNOTAVAILABLE'
    elif e == AT_ERR_INDEXNOTIMPLEMENTED:
        return 'AT_ERR_INDEXNOTIMPLEMENTED'
    elif e == AT_ERR_EXCEEDEDMAXSTRINGLENGTH:
        return 'AT_ERR_EXCEEDEDMAXSTRINGLENGTH'
    elif e == AT_ERR_CONNECTION:
        return 'AT_ERR_CONNECTION'
    elif e == AT_ERR_NODATA:
        return 'AT_ERR_NODATA'
    elif e == AT_ERR_INVALIDHANDLE:
        return 'AT_ERR_INVALIDHANDLE'
    elif e == AT_ERR_TIMEDOUT:
        return 'AT_ERR_TIMEDOUT'
    elif e == AT_ERR_BUFFERFULL:
        return 'AT_ERR_BUFFERFULL'
    elif e == AT_ERR_INVALIDSIZE:
        return 'AT_ERR_INVALIDSIZE'
    elif e == AT_ERR_INVALIDALIGNMENT:
        return 'AT_ERR_INVALIDALIGNMENT'
    elif e == AT_ERR_COMM:
        return 'AT_ERR_COMM'
    elif e == AT_ERR_STRINGNOTAVAILABLE:
        return 'AT_ERR_STRINGNOTAVAILABLE'
    elif e == AT_ERR_STRINGNOTIMPLEMENTED:
        return 'AT_ERR_STRINGNOTIMPLEMENTED'
    elif e == AT_ERR_NULL_FEATURE:
        return 'AT_ERR_NULL_FEATURE'
    elif e == AT_ERR_NULL_HANDLE:
        return 'AT_ERR_NULL_HANDLE'
    elif e == AT_ERR_NULL_IMPLEMENTED_VAR:
        return 'AT_ERR_NULL_IMPLEMENTED_VAR'
    elif e == AT_ERR_NULL_READABLE_VAR:
        return 'AT_ERR_NULL_READABLE_VAR'
    elif e == AT_ERR_NULL_READONLY_VAR:
        return 'AT_ERR_NULL_READONLY_VAR'
    elif e == AT_ERR_NULL_WRITABLE_VAR:
        return 'AT_ERR_NULL_WRITABLE_VAR'
    elif e == AT_ERR_NULL_MINVALUE:
        return 'AT_ERR_NULL_MINVALUE'
    elif e == AT_ERR_NULL_MAXVALUE:
        return 'AT_ERR_NULL_MAXVALUE'
    elif e == AT_ERR_NULL_VALUE:
        return 'AT_ERR_NULL_VALUE'
    elif e == AT_ERR_NULL_STRING:
        return 'AT_ERR_NULL_STRING'
    elif e == AT_ERR_NULL_COUNT_VAR:
        return 'AT_ERR_NULL_COUNT_VAR'
    elif e == AT_ERR_NULL_ISAVAILABLE_VAR:
        return 'AT_ERR_NULL_ISAVAILABLE_VAR'
    elif e == AT_ERR_NULL_MAXSTRINGLENGTH:
        return 'AT_ERR_NULL_MAXSTRINGLENGTH'
    elif e == AT_ERR_NULL_EVCALLBACK:
        return 'AT_ERR_NULL_EVCALLBACK'
    elif e == AT_ERR_NULL_QUEUE_PTR:
        return 'AT_ERR_NULL_QUEUE_PTR'
    elif e == AT_ERR_NULL_WAIT_PTR:
        return 'AT_ERR_NULL_WAIT_PTR'
    elif e == AT_ERR_NULL_PTRSIZE:
        return 'AT_ERR_NULL_PTRSIZE'
    elif e == AT_ERR_NOMEMORY:
        return 'AT_ERR_NOMEMORY'
    elif e == AT_ERR_DEVICEINUSE:
        return 'AT_ERR_DEVICEINUSE'
    elif e == AT_ERR_DEVICENOTFOUND:
        return 'AT_ERR_DEVICENOTFOUND'
    elif e == AT_ERR_HARDWARE_OVERFLOW:
        return 'AT_ERR_HARDWARE_OVERFLOW'
    else:
        return 'Unkown error'


cdef class BufWrap:
    cdef np.npy_intp shape[2]
    cdef np.npy_intp strides[2]
    cdef int imsize
    cdef int dtype
    cdef uintptr_t ptr
    cdef uintptr_t data

    cdef init(
            self, int imsize, int width, int height, int stride, int dtype):
        cdef uintptr_t pmask = 0x7
        cdef uintptr_t notpmask = ~0x7

        self.imsize = imsize
        self.shape[0] = height
        self.shape[1] = width
        self.strides[0] = stride
        self.strides[1] = 0
        self.dtype = dtype

        self.ptr = <uintptr_t>malloc(imsize + 7)
        if not self.ptr:
            raise MemoryError('cannot allocate buffer')
        # https://stackoverflow.com/questions/227897
        self.data = ((self.ptr + 7) & notpmask)
        assert((self.data & pmask) == 0)

        if DEBUG:
            print('BufWrap INIT ptr 0x{:x} data 0x{:x} imsize {:d}'.format(
                self.ptr, self.data, self.imsize))

    def __array__(self):
        # #define PyArray_SimpleNewFromData(nd, dims, typenum, data) \
        # PyArray_New(&PyArray_Type, nd, dims, typenum, NULL, \
        # data, 0, NPY_ARRAY_CARRAY, NULL)
        ndarray = np.PyArray_New(
            np.ndarray, 2, self.shape, self.dtype, self.strides,
            <void*>self.data, 0, NPY_ARRAY_CARRAY, 0)
        return ndarray

    def __dealloc__(self):
        if DEBUG:
            print('BufWrap FREE ptr 0x{:x} data 0x{:x} imsize {:d}'.format(
                self.ptr, self.data, self.imsize))
        free(<void*>self.ptr)

    def get_data(self):
        return self.data

    def get_imsize(self):
        return self.imsize


cdef class SDK3:

    cdef int index
    cdef ath handle
    cdef int lastSeqBuf
    cdef int liveMode
    cdef list bufwraps

    cdef check_write(self, Py_UNICODE *setting):
        cdef atbool impl
        cdef atbool check

        check_return(AT_IsImplemented(self.handle, setting, &impl))
        if not impl:
            raise Exception(setting + ' not implemented')
        check_return(AT_IsWritable(self.handle, setting, &check))
        if not check:
            raise Exception('Cannot write ' + setting)

    cdef check_implemented(self, Py_UNICODE *setting):
        cdef atbool impl

        check_return(AT_IsImplemented(self.handle, setting, &impl))
        return impl

    cdef check_read(self, Py_UNICODE *setting):
        cdef atbool impl
        cdef atbool check

        check_return(AT_IsImplemented(self.handle, setting, &impl))
        if not impl:
            raise Exception(setting + ' not implemented')
        check_return(AT_IsReadable(self.handle, setting, &check))
        if not check:
            raise Exception('Cannot read ' + setting)

    cdef int check_opened(self):
        return self.handle != AT_HANDLE_UNINITIALISED

    def __cinit__(self):
        self.index = 0
        self.handle = AT_HANDLE_UNINITIALISED
        check_return(AT_InitialiseLibrary())
        self.liveMode = 0
        self.bufwraps = []
        self.lastSeqBuf = -1

    def __dealloc__(self):
        if self.check_opened():
            check_return(AT_Close(self.handle))
            self.handle = AT_HANDLE_UNINITIALISED

        check_return(AT_FinaliseLibrary())

    def get_number_of_cameras(self):
        cdef at64 num

        check_return(AT_GetInt(AT_HANDLE_SYSTEM, 'DeviceCount', &num))

        return num

    def open(self, what=None):
        cdef int ret1
        cdef int ret2
        cdef at64 num
        cdef int index
        cdef int i
        cdef ath hand
        cdef atwc sn[STRLEN]

        if self.handle != AT_HANDLE_UNINITIALISED and what is not None:
            # camera already opened bur index or serial specified
            raise Exception('Camera already opened')
        elif self.handle != AT_HANDLE_UNINITIALISED:
            # default camera already opened, be quiet
            return

        if what is None:
            what = 0

        if type(what) is int:
            index = what
            check_return(AT_GetInt(AT_HANDLE_SYSTEM, 'DeviceCount', &num))
            if index >= num:
                raise Exception('Camera {:d} not found'.format(index))
            else:
                check_return(AT_Open(index, &self.handle))
        elif type(what) is str:
            check_return(AT_GetInt(AT_HANDLE_SYSTEM, 'DeviceCount', &num))
            self.handle = AT_HANDLE_UNINITIALISED
            for i in range(num):
                ret1 = AT_Open(i, &hand)
                if ret1 == AT_SUCCESS:
                    ret2 = AT_GetString(hand, 'SerialNumber', sn, STRLEN)
                    if ret2 == AT_SUCCESS:
                        if sn == what:
                            self.handle = hand
                            break
                        else:
                            check_return(AT_Close(hand))
                    else:
                        ret2 = AT_Close(hand)
                        raise Exception('Cannot read serial number')
                # else:
                #     print('Cannot open', i)
            if self.handle == AT_HANDLE_UNINITIALISED:
                raise Exception('Camera {} not found'.format(what))
        else:
            raise ValueError('Use an int or a str with the serial number')

        assert(self.handle != AT_HANDLE_UNINITIALISED)
        self._init_bufs()

    def get_devices(self, what=None):
        cdef list retlist = []
        cdef int ret1
        cdef int ret2
        cdef at64 num
        cdef int i
        cdef ath hand2
        cdef atwc sn[STRLEN]

        if self.check_opened():
            raise NotImplementedError()
        else:
            check_return(AT_GetInt(AT_HANDLE_SYSTEM, 'DeviceCount', &num))
            hand2 = AT_HANDLE_UNINITIALISED
            for i in range(num):
                ret1 = AT_Open(i, &hand2)
                if ret1 == AT_SUCCESS:
                    ret2 = AT_GetString(hand2, 'SerialNumber', sn, STRLEN)
                    if ret2 == AT_SUCCESS:
                        retlist.append(sn)
                    else:
                        ret2 = AT_Close(hand2)
                        raise Exception('Cannot read serial number')
                    ret2 = AT_Close(hand2)
            return retlist

    cdef void _init_bufs(self, nbufs=10, encoding=None):
        cdef at64 imsize
        cdef at64 stride
        cdef at64 width
        cdef at64 height
        cdef int dtype
        cdef atwc *set_imsize = 'ImageSizeBytes'
        cdef atwc *set_width = 'AOIWidth'
        cdef atwc *set_height = 'AOIHeight'
        cdef atwc *set_stride = 'AOIStride'
        cdef atwc *set_enc = 'PixelEncoding'
        cdef int tmp
        cdef uintptr_t dataptr
        cdef int count
        cdef at64 encoding_handled
        cdef int i
        cdef atwc name[STRLEN]

        if not self.check_opened():
            return

        if nbufs < 2:
            nbufs = 2

        pix_enc_ranges = self.get_pixel_encoding_range(True)
        if encoding is None:
            if 'Mono12' in pix_enc_ranges:
                encoding = 'Mono12'
                dtype = np.NPY_UINT16
            elif 'Mono16' in pix_enc_ranges:
                encoding = 'Mono16'
                dtype = np.NPY_UINT16
            elif 'Mono8' in pix_enc_ranges:
                encoding = 'Mono8'
                dtype = np.NPY_UINT8
            elif 'Mono32' in pix_enc_ranges:
                encoding = 'Mono32'
                dtype = np.NPY_UINT32
            else:
                self.close()
                raise NotImplementedError(
                    'encoding must be Mono8, Mono12, or Mono16')
        else:
            if encoding not in ('Mono8', 'Mono12', 'Mono16'):
                self.close()
                raise NotImplementedError(
                    'encoding must be Mono8, Mono12, or Mono16')
            elif encoding not in pix_enc_ranges:
                self.close()
                raise NotImplementedError(
                    'encoding ' + encoding + ' not supported')
        self.check_write(set_enc)
        check_return(AT_GetEnumCount(self.handle, set_enc, &count))
        encoding_handled = 0
        for i in range(count):
            check_return(AT_GetEnumStringByIndex(
                self.handle, set_enc, i, name, STRLEN))
            if name == encoding:
                check_return(AT_SetEnumIndex(self.handle, set_enc, i))
                encoding_handled = 1
                break
        if encoding_handled != 1:
            self.close()
            raise ValueError('failed to set pixel encoding')

        self.check_read(set_imsize)
        check_return(AT_GetInt(self.handle, set_imsize, &imsize))
        self.check_read(set_width)
        check_return(AT_GetInt(self.handle, set_width, &width))
        self.check_read(set_height)
        check_return(AT_GetInt(self.handle, set_height, &height))
        self.check_read(set_stride)
        check_return(AT_GetInt(self.handle, set_stride, &stride))

        check_return(AT_Flush(self.handle))
        self.bufwraps.clear()

        for i in range(nbufs):
            bw = BufWrap()
            bw.init(imsize, width, height, stride, dtype)
            dataptr = bw.get_data()
            check_return(AT_QueueBuffer(self.handle, <atu8*>dataptr, imsize))
            self.bufwraps.append(bw)

    def close(self):
        if self.check_opened():
            check_return(AT_Flush(self.handle))
            self.bufwraps.clear()
            self.lastSeqBuf = -1
            check_return(AT_Close(self.handle))
            self.handle = AT_HANDLE_UNINITIALISED

    def start_video(self, int wait=AT_INFINITE):
        if self.check_opened():
            check_return(AT_Command(self.handle, 'AcquisitionStart'))
            self.liveMode = 1

    def stop_video(self, int wait=AT_INFINITE):
        if self.check_opened():
            check_return(AT_Command(self.handle, 'AcquisitionStop'))
            self.liveMode = 0

    def grab_image(self, int wait=AT_INFINITE):
        """Acquire a single image.

        Parameters
        ----------
        - `wait`: timeout in milliseconds

        Returns
        -------
        - `img`: `numpy` image

        """

        cdef int bufSize
        cdef uintptr_t buf
        cdef uintptr_t tmpBuf
        cdef np.ndarray ndarray
        cdef atwc *set_cycle_mode = 'CycleMode'
        cdef atwc name[STRLEN]
        cdef int i
        cdef uintptr_t dataptr

        if not self.check_opened():
            return None

        if self.lastSeqBuf >= 0:
            dataptr = self.bufwraps[self.lastSeqBuf].get_data()
            check_return(AT_QueueBuffer(
                self.handle, <atu8*>dataptr,
                self.bufwraps[self.lastSeqBuf].get_imsize()))
            self.lastSeqBuf = -1

        self.check_read(set_cycle_mode)
        check_return(AT_GetEnumIndex(self.handle, set_cycle_mode, &i))
        check_return(
            AT_GetEnumStringByIndex(
                self.handle, set_cycle_mode, i, name, STRLEN))
        if self.liveMode and name != 'Continuous':
            check_return(AT_SetEnumIndex(self.handle, set_cycle_mode, i))

        if not self.liveMode:
            check_return(AT_Command(self.handle, 'AcquisitionStart'))

        check_return(AT_WaitBuffer(self.handle, <atu8**>&buf, &bufSize, wait))

        if not self.liveMode:
            check_return(AT_Command(self.handle, 'AcquisitionStop'))

        aw = None
        for i in range(len(self.bufwraps)):
            tmpBuf = self.bufwraps[i].get_data()
            if buf == tmpBuf:
                aw = self.bufwraps[i]
        if aw is None:
            raise Exception('Unknown buffer')

        self.lastSeqBuf = i

        ndarray = np.array(aw, copy=False)
        ndarray.base = <PyObject*>aw
        Py_INCREF(aw)

        return ndarray

    def get_serial_number(self):
        cdef atwc sn[STRLEN]

        if self.check_opened():
            check_return(AT_GetString(self.handle, 'SerialNumber', sn, STRLEN))
            return sn
        else:
            return None

    def set_exposure(self, double exp):
        "Set exposure in ms."
        cdef double d
        cdef double mul = 1e-3
        cdef atwc *setting = 'ExposureTime'

        if self.check_opened():
            d = exp*mul

            self.check_read(setting)
            self.check_write(setting)
            check_return(AT_SetFloat(self.handle, setting, d))
            check_return(AT_GetFloat(self.handle, setting, &d))

            return d/mul
        else:
            return 0.

    def get_exposure(self):
        "Get exposure in ms."
        cdef double d
        cdef double mul = 1e-3
        cdef atwc *setting = 'ExposureTime'

        if self.check_opened():
            self.check_read(setting)
            check_return(AT_GetFloat(self.handle, setting, &d))

            return d/mul
        else:
            return 0.

    def get_exposure_range(self):
        "Get exposure in ms."
        cdef double d1
        cdef double d2
        cdef double mul = 1e-3
        cdef atwc *setting = 'ExposureTime'

        if self.check_opened():
            self.check_read(setting)
            check_return(AT_GetFloatMin(self.handle, setting, &d1))
            self.check_read(setting)
            check_return(AT_GetFloatMax(self.handle, setting, &d2))

            return (d1/mul, d2/mul, None)
        else:
            return None

    def set_cooling(self, int b):
        cdef atbool d
        cdef atwc *setting = 'SensorCooling'

        if self.check_opened():
            d = b

            self.check_write(setting)
            check_return(AT_SetBool(self.handle, setting, d))

    def get_cooling(self):
        cdef atbool d
        cdef atwc *setting = 'SensorCooling'

        if self.check_opened():
            self.check_read(setting)
            check_return(AT_GetBool(self.handle, setting, &d))
            return d
        else:
            return False

    def get_temperature_control_range(self, available=False):
        cdef atwc *setting = 'TemperatureControl'
        cdef int i
        cdef int count
        cdef list ret = []
        cdef atwc name[STRLEN]
        cdef atbool impl

        if self.check_opened():
            self.check_read(setting)
            check_return(AT_GetEnumCount(self.handle, setting, &count))
            for i in range(count):
                check_return(AT_GetEnumStringByIndex(
                    self.handle, setting, i, name, STRLEN))
                if available:
                    check_return(AT_IsEnumIndexAvailable(
                        self.handle, setting, i, &impl))
                    if impl:
                        ret.append(str(name))
                else:
                    ret.append(str(name))
            return ret
        else:
            return ret

    def get_temperature_status(self):
        cdef atwc *setting = 'TemperatureStatus'
        cdef atwc name[STRLEN]
        cdef int i

        if self.check_opened():
            self.check_read(setting)
            check_return(AT_GetEnumIndex(self.handle, setting, &i))
            check_return(
                AT_GetEnumStringByIndex(self.handle, setting, i, name, STRLEN))
            return name
        else:
            return None

    def get_pixel_size(self):
        "Get pixel size (width, height) in um."
        cdef double d1
        cdef double d2
        cdef atwc *setting1 = 'PixelWidth'
        cdef atwc *setting2 = 'PixelWidth'

        if self.check_opened():
            self.check_read(setting1)
            check_return(AT_GetFloat(self.handle, setting1, &d1))
            check_return(AT_GetFloat(self.handle, setting2, &d2))

            return (d1, d2)
        else:
            return None

    def get_camera_model(self):
        cdef atwc *setting1 = 'CameraModel'
        cdef atwc sn[STRLEN]

        if self.check_opened():
            self.check_read(setting1)
            check_return(AT_GetString(self.handle, setting1, sn, STRLEN))
            return sn
        else:
            return None

    def get_accumulate_count(self):
        cdef atwc *setting1 = 'AccumulateCount'
        cdef at64 i

        if self.check_opened():
            self.check_read(setting1)
            check_return(AT_GetInt(self.handle, setting1, &i))
            return i
        else:
            return 0

    def set_accumulate_count(self, int i):
        cdef atwc *setting1 = 'AccumulateCount'
        cdef int i1 = i

        if self.check_opened():
            self.check_write(setting1)
            check_return(AT_SetInt(self.handle, setting1, i1))

    def get_bitdepth_range(self, available=False):
        cdef atwc *setting = 'BitDepth'
        cdef int i
        cdef int count
        cdef list ret = []
        cdef atwc name[STRLEN]
        cdef atbool impl

        if self.check_opened():
            self.check_read(setting)
            check_return(AT_GetEnumCount(self.handle, setting, &count))
            for i in range(count):
                check_return(AT_GetEnumStringByIndex(
                    self.handle, setting, i, name, STRLEN))
                if available:
                    check_return(AT_IsEnumIndexAvailable(
                        self.handle, setting, i, &impl))
                    if impl:
                        ret.append(str(name))
                else:
                    ret.append(str(name))
            return ret
        else:
            return ret

    def get_bytesperpixel(self):
        cdef double d
        cdef atwc *setting = 'BytesPerPixel'

        if self.check_opened():
            self.check_read(setting)
            check_return(AT_GetFloat(self.handle, setting, &d))

            return d
        else:
            return 0.

    def get_camera_name(self):
        cdef atwc *setting1 = 'CameraName'
        cdef atwc sn[STRLEN]

        if self.check_opened():
            self.check_read(setting1)
            check_return(AT_GetString(self.handle, setting1, sn, STRLEN))
            return sn
        else:
            return None

    def get_cycle_mode_range(self):
        cdef atwc *setting = 'CycleMode'
        cdef int i
        cdef int count
        cdef list ret = []
        cdef atwc name[STRLEN]

        if self.check_opened():
            self.check_read(setting)
            check_return(AT_GetEnumCount(self.handle, setting, &count))
            for i in range(count):
                check_return(AT_GetEnumStringByIndex(
                    self.handle, setting, i, name, STRLEN))
                ret.append(str(name))
            return ret
        else:
            return ret

    def get_cycle_mode(self):
        cdef atwc *setting = 'CycleMode'
        cdef atwc name[STRLEN]
        cdef int i

        if self.check_opened():
            self.check_read(setting)
            check_return(AT_GetEnumIndex(self.handle, setting, &i))
            check_return(
                AT_GetEnumStringByIndex(self.handle, setting, i, name, STRLEN))
            return name
        else:
            return None

    def set_cycle_mode(self, str1):
        cdef atwc *setting = 'CycleMode'
        cdef list ret = []
        cdef int i
        cdef int count
        cdef atwc name[STRLEN]

        if self.check_opened():
            self.check_read(setting)
            self.check_write(setting)
            check_return(AT_GetEnumCount(self.handle, setting, &count))
            for i in range(count):
                check_return(AT_GetEnumStringByIndex(
                    self.handle, setting, i, name, STRLEN))
                if name == str1:
                    check_return(AT_SetEnumIndex(self.handle, setting, i))
                    return
            raise ValueError('Illegal parameter')

    def get_firmware_version(self):
        cdef atwc *setting1 = 'FirmwareVersion'
        cdef atwc sn[STRLEN]

        if self.check_opened():
            self.check_read(setting1)
            check_return(AT_GetString(self.handle, setting1, sn, STRLEN))
            return sn
        else:
            return None

    def get_frame_count(self):
        cdef atwc *setting1 = 'FrameCount'
        cdef at64 i

        if self.check_opened():
            self.check_read(setting1)
            check_return(AT_GetInt(self.handle, setting1, &i))
            return i
        else:
            return 0

    def set_frame_count(self, int i):
        cdef atwc *setting1 = 'FrameCount'
        cdef atwc *setting2 = 'AccumulateCount'
        cdef at64 i1 = i
        cdef at64 i2

        if self.check_opened():
            if self.check_implemented(setting2):
                self.check_read(setting2)
                check_return(AT_GetInt(self.handle, setting2, &i2))
                if i1 % i2 != 0:
                    raise ValueError('FrameCount % AccumulateCount != 0')
            self.check_write(setting1)
            check_return(AT_SetInt(self.handle, setting1, i1))

    def set_framerate(self, double fps):
        cdef double d
        cdef atwc *setting = 'FrameRate'

        if self.check_opened():
            d = fps

            self.check_read(setting)
            self.check_write(setting)
            check_return(AT_SetFloat(self.handle, setting, d))
            check_return(AT_GetFloat(self.handle, setting, &d))

            return d
        else:
            return 0.

    def get_framerate(self):
        cdef double d
        cdef atwc *setting = 'FrameRate'

        if self.check_opened():
            self.check_read(setting)
            check_return(AT_GetFloat(self.handle, setting, &d))

            return d
        else:
            return 0.

    def get_framerate_range(self):
        cdef double d1
        cdef double d2
        cdef atwc *setting = 'FrameRate'

        if self.check_opened():
            self.check_read(setting)
            check_return(AT_GetFloatMin(self.handle, setting, &d1))
            self.check_read(setting)
            check_return(AT_GetFloatMax(self.handle, setting, &d2))

            return (d1, d2, None)
        else:
            return None

    def get_image_size_bytes(self):
        cdef atwc *setting1 = 'ImageSizeBytes'
        cdef at64 i

        if self.check_opened():
            self.check_read(setting1)
            check_return(AT_GetInt(self.handle, setting1, &i))
            return i
        else:
            return 0

    def set_metadata(self, int b):
        cdef atbool d
        cdef atwc *setting = 'MetadataEnable'

        if self.check_opened():
            d = b

            self.check_write(setting)
            check_return(AT_SetBool(self.handle, setting, d))

    def get_metadata(self):
        cdef atbool d
        cdef atwc *setting = 'MetadataEnable'

        if self.check_opened():
            self.check_read(setting)
            check_return(AT_GetBool(self.handle, setting, &d))
            return d
        else:
            return False

    def set_metadata_frame(self, int b):
        cdef atbool d
        cdef atwc *setting = 'MetadataFrame'

        if self.check_opened():
            d = b

            self.check_write(setting)
            check_return(AT_SetBool(self.handle, setting, d))

    def get_metadata_frame(self):
        cdef atbool d
        cdef atwc *setting = 'MetadataFrame'

        if self.check_opened():
            self.check_read(setting)
            check_return(AT_GetBool(self.handle, setting, &d))
            return d
        else:
            return False

    def set_metadata_timestamp(self, int b):
        cdef atbool d
        cdef atwc *setting = 'MetadataTimestamp'

        if self.check_opened():
            d = b

            self.check_write(setting)
            check_return(AT_SetBool(self.handle, setting, d))

    def get_metadata_timestamp(self):
        cdef atbool d
        cdef atwc *setting = 'MetadataTimestamp'

        if self.check_opened():
            self.check_read(setting)
            check_return(AT_GetBool(self.handle, setting, &d))
            return d
        else:
            return False

    def get_pixel_encoding_range(self, available=False):
        cdef atwc *setting = 'PixelEncoding'
        cdef int i
        cdef int count
        cdef list ret = []
        cdef atwc name[STRLEN]
        cdef atbool impl

        if self.check_opened():
            self.check_read(setting)
            check_return(AT_GetEnumCount(self.handle, setting, &count))
            for i in range(count):
                check_return(AT_GetEnumStringByIndex(
                    self.handle, setting, i, name, STRLEN))
                if available:
                    check_return(AT_IsEnumIndexAvailable(
                        self.handle, setting, i, &impl))
                    if impl:
                        ret.append(str(name))
                else:
                    ret.append(str(name))
            return ret
        else:
            return ret

    def get_pixel_encoding(self):
        cdef atwc *setting = 'PixelEncoding'
        cdef atwc name[STRLEN]
        cdef int i

        if self.check_opened():
            self.check_read(setting)
            check_return(AT_GetEnumIndex(self.handle, setting, &i))
            check_return(
                AT_GetEnumStringByIndex(self.handle, setting, i, name, STRLEN))
            return name
        else:
            return None

    def set_pixel_encoding(self, str1):
        cdef atwc *setting = 'PixelEncoding'
        cdef list ret = []
        cdef int i
        cdef int count
        cdef atwc name[STRLEN]

        if self.check_opened():
            self.check_read(setting)
            self.check_write(setting)
            check_return(AT_GetEnumCount(self.handle, setting, &count))
            for i in range(count):
                check_return(AT_GetEnumStringByIndex(
                    self.handle, setting, i, name, STRLEN))
                if name == str1:
                    check_return(AT_SetEnumIndex(self.handle, setting, i))
                    self._init_bufs(nbufs=len(self.bufwraps), encoding=name)
                    return
            raise ValueError('Illegal parameter')

    def get_pixel_readout_range(self, available=False):
        cdef atwc *setting = 'PixelReadoutRate'
        cdef int i
        cdef int count
        cdef list ret = []
        cdef atwc name[STRLEN]
        cdef atbool impl

        if self.check_opened():
            self.check_read(setting)
            check_return(AT_GetEnumCount(self.handle, setting, &count))
            for i in range(count):
                check_return(AT_GetEnumStringByIndex(
                    self.handle, setting, i, name, STRLEN))
                if available:
                    check_return(AT_IsEnumIndexAvailable(
                        self.handle, setting, i, &impl))
                    if impl:
                        ret.append(str(name))
                else:
                    ret.append(str(name))
            return ret
        else:
            return ret

    def get_pixel_readout(self):
        cdef atwc *setting = 'PixelReadoutRate'
        cdef atwc name[STRLEN]
        cdef int i

        if self.check_opened():
            self.check_read(setting)
            check_return(AT_GetEnumIndex(self.handle, setting, &i))
            check_return(
                AT_GetEnumStringByIndex(self.handle, setting, i, name, STRLEN))
            return name
        else:
            return None

    def set_pixel_readout(self, str1):
        cdef atwc *setting = 'PixelReadoutRate'
        cdef list ret = []
        cdef int i
        cdef int count
        cdef atwc name[STRLEN]

        if self.check_opened():
            self.check_read(setting)
            self.check_write(setting)
            check_return(AT_GetEnumCount(self.handle, setting, &count))
            for i in range(count):
                check_return(AT_GetEnumStringByIndex(
                    self.handle, setting, i, name, STRLEN))
                if name == str1:
                    check_return(AT_SetEnumIndex(self.handle, setting, i))
                    return
            raise ValueError('Illegal parameter')

    def get_readout_time(self):
        cdef double d
        cdef atwc *setting = 'ReadoutTime'

        if self.check_opened():
            self.check_read(setting)
            check_return(AT_GetFloat(self.handle, setting, &d))

            return d
        else:
            return 0.

    def get_sensor_width(self):
        cdef atwc *setting1 = 'SensorWidth'
        cdef at64 i

        if self.check_opened():
            self.check_read(setting1)
            check_return(AT_GetInt(self.handle, setting1, &i))
            return i
        else:
            return 0

    def get_sensor_height(self):
        cdef atwc *setting1 = 'SensorWidth'
        cdef at64 i

        if self.check_opened():
            self.check_read(setting1)
            check_return(AT_GetInt(self.handle, setting1, &i))
            return i
        else:
            return 0

    def shape(self):
        cdef atwc *setting1 = 'SensorHeight'
        cdef at64 i1
        cdef atwc *setting2 = 'SensorWidth'
        cdef at64 i2

        if self.check_opened():
            self.check_read(setting1)
            check_return(AT_GetInt(self.handle, setting1, &i1))
            self.check_read(setting2)
            check_return(AT_GetInt(self.handle, setting1, &i2))
            return (i1, i2)
        else:
            return None

    def get_sensor_temperature(self):
        cdef double d
        cdef atwc *setting = 'SensorTemperature'

        if self.check_opened():
            self.check_read(setting)
            check_return(AT_GetFloat(self.handle, setting, &d))

            return d
        else:
            return 0.

    def get_software_version(self):
        cdef atwc *setting1 = 'SoftwareVersion'
        cdef atwc sn[STRLEN]

        if self.check_opened():
            self.check_read(setting1)
            check_return(AT_GetString(self.handle, setting1, sn, STRLEN))
            return sn
        else:
            return None

    def get_trigger_mode_range(self, available=False):
        cdef atwc *setting = 'TriggerMode'
        cdef int i
        cdef int count
        cdef list ret = []
        cdef atwc name[STRLEN]
        cdef atbool impl

        if self.check_opened():
            self.check_read(setting)
            check_return(AT_GetEnumCount(self.handle, setting, &count))
            for i in range(count):
                check_return(AT_GetEnumStringByIndex(
                    self.handle, setting, i, name, STRLEN))
                if available:
                    check_return(AT_IsEnumIndexAvailable(
                        self.handle, setting, i, &impl))
                    if impl:
                        ret.append(str(name))
                else:
                    ret.append(str(name))
            return ret
        else:
            return ret

    def get_trigger_mode(self):
        cdef atwc *setting = 'TriggerMode'
        cdef atwc name[STRLEN]
        cdef int i

        if self.check_opened():
            self.check_read(setting)
            check_return(AT_GetEnumIndex(self.handle, setting, &i))
            check_return(
                AT_GetEnumStringByIndex(self.handle, setting, i, name, STRLEN))
            return name
        else:
            return None

    def set_trigger_mode(self, str1):
        cdef atwc *setting = 'TriggerMode'
        cdef list ret = []
        cdef int i
        cdef int count
        cdef atwc name[STRLEN]

        if self.check_opened():
            self.check_read(setting)
            self.check_write(setting)
            check_return(AT_GetEnumCount(self.handle, setting, &count))
            for i in range(count):
                check_return(AT_GetEnumStringByIndex(
                    self.handle, setting, i, name, STRLEN))
                if name == str1:
                    check_return(AT_SetEnumIndex(self.handle, setting, i))
                    return
            raise ValueError('Illegal parameter')

    def get_image_dtype(self):
        cdef atwc *setting = 'PixelEncoding'
        cdef atwc name[STRLEN]
        cdef int i

        if self.check_opened():
            self.check_read(setting)
            check_return(AT_GetEnumIndex(self.handle, setting, &i))
            check_return(
                AT_GetEnumStringByIndex(self.handle, setting, i, name, STRLEN))
            if name == 'Mono8':
                return np.uint8
            elif name in ('Mono12', 'Mono12Packed',  'Mono16'):
                return np.uint16
            elif name in ('Mono32'):
                return np.uint32
            else:
                return NotImplementedError(name)

        else:
            return None

    def get_image_max(self):
        cdef atwc *setting = 'PixelEncoding'
        cdef atwc name[STRLEN]
        cdef int i

        if self.check_opened():
            self.check_read(setting)
            check_return(AT_GetEnumIndex(self.handle, setting, &i))
            check_return(
                AT_GetEnumStringByIndex(self.handle, setting, i, name, STRLEN))
            if name == 'Mono8':
                return 0xff
            if name in ('Mono12', 'Mono12Packed'):
                return 2**12 - 1
            elif name in 'Mono16':
                return 0xffff
            elif name in 'Mono32':
                return 0xffffff
            else:
                return NotImplementedError(name)

        else:
            return None
