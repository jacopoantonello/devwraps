#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""Wrapper for Thorlabs cameras

"""

# This file is part of devwraps.
#
# devwraps is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# devwraps is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with devwraps.  If not, see <http://www.gnu.org/licenses/>.


from libc.stddef cimport wchar_t

cdef extern from "Python.h":
    wchar_t* PyUnicode_AsWideCharString(object, Py_ssize_t *)

# cdef extern from "wchar.h":
#     int wprintf(const wchar_t *, ...)

cdef extern from "uc480.h":

    # ctypedef int USBCAMEXP
    # ctypedef unsigned long USBCAMEXPUL
    # ctypedef unsigned long DWORD
    # ctypedef unsigned short WORD
    # ctypedef DWORD HCAM
    # ctypedef int BOOL
    # ctypedef HANDLE HWND
    # ctypedef PVOID HANDLE
    # ctypedef void *PVOID
    # cdef IS_GET_STATUS = 0x8000

    cdef int IS_SUCCESS = 0
    cdef int IS_INVALID_PARAMETER = 125

    ctypedef struct UC480_CAMERA_INFO:
        unsigned long dwCameraID
        unsigned long dwDeviceID
        unsigned long dwSensorID
        unsigned long dwInUse
        char SerNo[16]
        char Model[16]
        unsigned long dwStatus
        unsigned long dwReserved[2]
        char FullModelName[32]
        unsigned long dwReserved2[5]

    ctypedef struct UC480_CAMERA_LIST:
        unsigned long dwCount
        UC480_CAMERA_INFO uci[1]

    ctypedef struct BOARDINFO:
        char SerNo[12]
        char ID[20]
        char Version[10]
        char Date[12]
        unsigned char Select
        unsigned char Type
        char Reserved[8]

    ctypedef struct SENSORINFO:
        unsigned short SensorID
        char strSensorName[32]
        char nColorMode
        unsigned long nMaxWidth
        unsigned long nMaxHeight
        int bMasterGain
        int bRGain
        int bGGain
        int bBGain
        int bGlobShutter
        unsigned short wPixelSize
        char nUpperLeftBayerPixel
        char Reserved[13]

    cdef int IS_EXPOSURE_CAP_EXPOSURE = 0x00000001
    cdef int IS_EXPOSURE_CAP_FINE_INCREMENT = 0x00000002
    cdef int IS_EXPOSURE_CAP_LONG_EXPOSURE = 0x00000004
    cdef int IS_EXPOSURE_CAP_DUAL_EXPOSURE = 0x00000008

    cdef int IS_EXPOSURE_CMD_GET_CAPS = 1
    cdef int IS_EXPOSURE_CMD_GET_EXPOSURE_DEFAULT = 2
    cdef int IS_EXPOSURE_CMD_GET_EXPOSURE_RANGE_MIN = 3
    cdef int IS_EXPOSURE_CMD_GET_EXPOSURE_RANGE_MAX = 4
    cdef int IS_EXPOSURE_CMD_GET_EXPOSURE_RANGE_INC = 5
    cdef int IS_EXPOSURE_CMD_GET_EXPOSURE_RANGE = 6
    cdef int IS_EXPOSURE_CMD_GET_EXPOSURE = 7
    cdef int IS_EXPOSURE_CMD_GET_FINE_INCREMENT_RANGE_MIN = 8
    cdef int IS_EXPOSURE_CMD_GET_FINE_INCREMENT_RANGE_MAX = 9
    cdef int IS_EXPOSURE_CMD_GET_FINE_INCREMENT_RANGE_INC = 10
    cdef int IS_EXPOSURE_CMD_GET_FINE_INCREMENT_RANGE = 11
    cdef int IS_EXPOSURE_CMD_SET_EXPOSURE = 12
    cdef int IS_EXPOSURE_CMD_GET_LONG_EXPOSURE_RANGE_MIN = 13
    cdef int IS_EXPOSURE_CMD_GET_LONG_EXPOSURE_RANGE_MAX = 14
    cdef int IS_EXPOSURE_CMD_GET_LONG_EXPOSURE_RANGE_INC = 15
    cdef int IS_EXPOSURE_CMD_GET_LONG_EXPOSURE_RANGE = 16
    cdef int IS_EXPOSURE_CMD_GET_LONG_EXPOSURE_ENABLE = 17
    cdef int IS_EXPOSURE_CMD_SET_LONG_EXPOSURE_ENABLE = 18
    cdef int IS_EXPOSURE_CMD_GET_DUAL_EXPOSURE_RATIO_DEFAULT = 19
    cdef int IS_EXPOSURE_CMD_GET_DUAL_EXPOSURE_RATIO_RANGE = 20
    cdef int IS_EXPOSURE_CMD_GET_DUAL_EXPOSURE_RATIO = 21
    cdef int IS_EXPOSURE_CMD_SET_DUAL_EXPOSURE_RATIO = 22
    cdef int IS_AOI_IMAGE_SET_AOI = 0x0001

    cdef int IS_CM_SENSOR_RAW8 = 11
    cdef int IS_CM_SENSOR_RAW10 = 33
    cdef int IS_CM_SENSOR_RAW12 = 27
    cdef int IS_CM_SENSOR_RAW16 = 29
    cdef int IS_CM_MONO8 = 6
    cdef int IS_CM_MONO10 = 34
    cdef int IS_CM_MONO12 = 26
    cdef int IS_CM_MONO16 = 28

    cdef int IS_COLORMODE_INVALID = 0
    cdef int IS_COLORMODE_MONOCHROME = 1
    cdef int IS_COLORMODE_BAYER = 2
    cdef int IS_COLORMODE_CBYCRY = 4
    cdef int IS_COLORMODE_JPEG = 8

    cdef int IS_PARAMETERSET_CMD_LOAD_EEPROM = 1
    cdef int IS_PARAMETERSET_CMD_LOAD_FILE = 2
    cdef int IS_PARAMETERSET_CMD_SAVE_EEPROM = 3
    cdef int IS_PARAMETERSET_CMD_SAVE_FILE = 4
    cdef int IS_PARAMETERSET_CMD_GET_NUMBER_SUPPORTED = 5
    cdef int IS_PARAMETERSET_CMD_GET_HW_PARAMETERSET_AVAILABLE = 6
    cdef int IS_PARAMETERSET_CMD_ERASE_HW_PARAMETERSET = 7

    cdef int IS_SET_EVENT_FRAME = 2

    cdef int is_GetNumberOfCameras(int* pnNumCams)

    cdef int is_GetCameraList(UC480_CAMERA_LIST *pucl)

    cdef unsigned long is_CameraStatus(
        unsigned long hCam, int nInfo, unsigned long ulValue)

    cdef int is_GetCameraInfo(unsigned long hCam, BOARDINFO *pInfo)

    cdef int is_InitCamera(unsigned long *phCam, void *hWnd)

    cdef int is_ExitCamera(unsigned long hCam)

    cdef int is_GetSensorInfo(unsigned long hCam, SENSORINFO *pInfo)

    cdef int is_ImageFormat(
        unsigned long hCam, unsigned int nCommand, void *pParam,
        unsigned int nSizeOfParam)

    cdef int is_AllocImageMem(
        unsigned long hCam, int width, int height, int bitspixel,
        char **ppcImgMem, int* pid)

    cdef int is_SetAllocatedImageMem(
        unsigned long hCam, int width, int height, int bitspixel,
        char *pcImgMem, int *pid)

    cdef int is_ParameterSet(
        unsigned long hCam, unsigned int nCommand, void *pParam,
        unsigned int cbSizeOfParam)

    cdef int is_SetImageMem(unsigned long hCam, char *pcMem, int id)

    cdef int is_FreezeVideo(unsigned long hCam, int Wait)

    cdef int is_CopyImageMem(
        unsigned long hCam, char *pcSource, int nID, char *pcDest)

    cdef int is_Exposure(
        unsigned long hCam, unsigned int nCommand, void* pParam,
        unsigned int cbSizeOfParam)

    cdef int is_FreeImageMem(unsigned long hCam, char *pcMem, int id)

    cdef int is_ResetToDefault(unsigned long hCam)

    cdef int is_EnableAutoExit(unsigned long hCam, int nMode)

    cdef int is_GetImageMemPitch(unsigned long hCam, int *pPitch)

    cdef int is_Exposure(
        unsigned long hCam, unsigned int nCommand, void* pParam,
        unsigned int cbSizeOfParam)

    cdef int is_ResetToDefault(unsigned long hCam)

    ctypedef struct IS_RECT:
        int s32X
        int s32Y
        int s32Width
        int s32Height

    cdef int is_AOI(
            unsigned long hCam, unsigned long nCommand, void* pParam,
            unsigned long nSizeOfParam)

    cdef int is_SetColorMode(unsigned long hCam, int Mode)

    cdef int is_AddToSequence(unsigned long hCam, char* pcImgMem, int nID)

    cdef void *CreateEvent(
        void *lpEventAttributes, int bManualReset, int bInitialState,
        char* lpName)

    cdef int CloseHandle(void *hObject);

    cdef int is_InitEvent(unsigned long hCam, void *hEv, int which)

    cdef int is_EnableEvent(unsigned long hCam, int which)
    cdef int is_DisableEvent(unsigned long hCam, int which)
    cdef int is_ExitEvent(unsigned long hCam, int which)

    cdef int IS_GET_LIVE = 0x8000
    cdef int IS_WAIT = 0x0001
    cdef int IS_DONT_WAIT = 0x0000
    cdef int IS_FORCE_VIDEO_STOP = 0x4000
    cdef int IS_FORCE_VIDEO_START = 0x4000
    cdef int IS_USE_NEXT_MEM = 0x8000

    cdef unsigned long WAIT_TIMEOUT = 0x00000102
    cdef unsigned long WAIT_OBJECT_0 = 0x00000000

    cdef unsigned long WaitForSingleObject(
        void *hHandle, unsigned long dwMilliseconds)

    cdef int is_GetImageMem(unsigned long hCam, void **pMem)

    cdef int IS_IGNORE_PARAMETER = -1

    cdef int is_UnlockSeqBuf(unsigned long hCam, int nNum, char* pcMem)

    cdef int is_LockSeqBuf(unsigned long hCam, int nNum, char* pcMem)

    cdef int IS_SET_ENABLE_AUTO_GAIN = 0x8800
    cdef int IS_GET_ENABLE_AUTO_GAIN = 0x8801
    cdef int IS_SET_ENABLE_AUTO_SHUTTER = 0x8802
    cdef int IS_GET_ENABLE_AUTO_SHUTTER = 0x8803
    cdef int IS_SET_ENABLE_AUTO_WHITEBALANCE = 0x8804
    cdef int IS_GET_ENABLE_AUTO_WHITEBALANCE = 0x8805
    cdef int IS_SET_ENABLE_AUTO_FRAMERATE = 0x8806
    cdef int IS_GET_ENABLE_AUTO_FRAMERATE = 0x8807
    cdef int IS_SET_ENABLE_AUTO_SENSOR_GAIN = 0x8808
    cdef int IS_GET_ENABLE_AUTO_SENSOR_GAIN = 0x8809
    cdef int IS_SET_ENABLE_AUTO_SENSOR_SHUTTER = 0x8810
    cdef int IS_GET_ENABLE_AUTO_SENSOR_SHUTTER = 0x8811
    cdef int IS_SET_ENABLE_AUTO_SENSOR_GAIN_SHUTTER = 0x8812
    cdef int IS_GET_ENABLE_AUTO_SENSOR_GAIN_SHUTTER = 0x8813
    cdef int IS_SET_ENABLE_AUTO_SENSOR_FRAMERATE = 0x8814
    cdef int IS_GET_ENABLE_AUTO_SENSOR_FRAMERATE = 0x8815
    cdef int IS_SET_ENABLE_AUTO_SENSOR_WHITEBALANCE = 0x8816
    cdef int IS_GET_ENABLE_AUTO_SENSOR_WHITEBALANCE = 0x8817
    cdef int IS_SET_AUTO_REFERENCE = 0x8000
    cdef int IS_GET_AUTO_REFERENCE = 0x8001
    cdef int IS_SET_AUTO_GAIN_MAX = 0x8002
    cdef int IS_GET_AUTO_GAIN_MAX = 0x8003
    cdef int IS_SET_AUTO_SHUTTER_MAX = 0x8004
    cdef int IS_GET_AUTO_SHUTTER_MAX = 0x8005
    cdef int IS_SET_AUTO_SPEED = 0x8006
    cdef int IS_GET_AUTO_SPEED = 0x8007
    cdef int IS_SET_AUTO_WB_OFFSET = 0x8008
    cdef int IS_GET_AUTO_WB_OFFSET = 0x8009
    cdef int IS_SET_AUTO_WB_GAIN_RANGE = 0x800A
    cdef int IS_GET_AUTO_WB_GAIN_RANGE = 0x800B
    cdef int IS_SET_AUTO_WB_SPEED = 0x800C
    cdef int IS_GET_AUTO_WB_SPEED = 0x800D
    cdef int IS_SET_AUTO_WB_ONCE = 0x800E
    cdef int IS_GET_AUTO_WB_ONCE = 0x800F
    cdef int IS_SET_AUTO_BRIGHTNESS_ONCE = 0x8010
    cdef int IS_GET_AUTO_BRIGHTNESS_ONCE = 0x8011
    cdef int IS_SET_AUTO_HYSTERESIS = 0x8012
    cdef int IS_GET_AUTO_HYSTERESIS = 0x8013
    cdef int IS_GET_AUTO_HYSTERESIS_RANGE = 0x8014
    cdef int IS_SET_AUTO_WB_HYSTERESIS = 0x8015
    cdef int IS_GET_AUTO_WB_HYSTERESIS = 0x8016
    cdef int IS_GET_AUTO_WB_HYSTERESIS_RANGE = 0x8017
    cdef int IS_SET_AUTO_SKIPFRAMES = 0x8018
    cdef int IS_GET_AUTO_SKIPFRAMES = 0x8019
    cdef int IS_GET_AUTO_SKIPFRAMES_RANGE = 0x801A
    cdef int IS_SET_AUTO_WB_SKIPFRAMES = 0x801B
    cdef int IS_GET_AUTO_WB_SKIPFRAMES = 0x801C
    cdef int IS_GET_AUTO_WB_SKIPFRAMES_RANGE = 0x801D
    cdef int IS_SET_SENS_AUTO_SHUTTER_PHOTOM = 0x801E
    cdef int IS_SET_SENS_AUTO_GAIN_PHOTOM = 0x801F
    cdef int IS_GET_SENS_AUTO_SHUTTER_PHOTOM = 0x8020
    cdef int IS_GET_SENS_AUTO_GAIN_PHOTOM = 0x8021
    cdef int IS_GET_SENS_AUTO_SHUTTER_PHOTOM_DEF = 0x8022
    cdef int IS_GET_SENS_AUTO_GAIN_PHOTOM_DEF = 0x8023
    cdef int IS_SET_SENS_AUTO_CONTRAST_CORRECTION = 0x8024
    cdef int IS_GET_SENS_AUTO_CONTRAST_CORRECTION = 0x8025
    cdef int IS_GET_SENS_AUTO_CONTRAST_CORRECTION_RANGE = 0x8026
    cdef int IS_GET_SENS_AUTO_CONTRAST_CORRECTION_INC = 0x8027
    cdef int IS_GET_SENS_AUTO_CONTRAST_CORRECTION_DEF = 0x8028
    cdef int IS_SET_SENS_AUTO_CONTRAST_FDT_AOI_ENABLE = 0x8029
    cdef int IS_GET_SENS_AUTO_CONTRAST_FDT_AOI_ENABLE = 0x8030
    cdef int IS_SET_SENS_AUTO_BACKLIGHT_COMP = 0x8031
    cdef int IS_GET_SENS_AUTO_BACKLIGHT_COMP = 0x8032
    cdef int IS_GET_SENS_AUTO_BACKLIGHT_COMP_RANGE = 0x8033
    cdef int IS_GET_SENS_AUTO_BACKLIGHT_COMP_INC = 0x8034
    cdef int IS_GET_SENS_AUTO_BACKLIGHT_COMP_DEF = 0x8035
    cdef int IS_SET_ANTI_FLICKER_MODE = 0x8036
    cdef int IS_GET_ANTI_FLICKER_MODE = 0x8037
    cdef int IS_GET_ANTI_FLICKER_MODE_DEF = 0x8038
    cdef int IS_GET_AUTO_REFERENCE_DEF = 0x8039
    cdef int IS_GET_AUTO_WB_OFFSET_DEF = 0x803A
    cdef int IS_GET_AUTO_WB_OFFSET_MIN = 0x803B
    cdef int IS_GET_AUTO_WB_OFFSET_MAX = 0x803C

    cdef int is_SetAutoParameter(
        unsigned long hCam, int param, double* pval1, double* pval2)

    cdef double IS_GET_FRAMERATE = 0x8000

    cdef double IS_GET_DEFAULT_FRAMERATE = 0x8001

    cdef int is_SetFrameRate(unsigned long hCam, double FPS, double* newFPS)

    cdef int is_GetFrameTimeRange(
        unsigned long hCam, double* min, double* max, double* intervall)

    cdef int is_GetFramesPerSecond(unsigned long hCam, double* dblFPS)

    cdef int is_CaptureVideo(unsigned long hCam, int Wait)

    cdef int is_StopLiveVideo(unsigned long hCam, int Wait)

    cdef int is_CaptureStatus(
        unsigned long hCam, unsigned int nCommand,
        void* pParam, unsigned int cbSizeOfParam)

    ctypedef struct UC480_CAPTURE_STATUS_INFO:
        unsigned long dwCapStatusCnt_Total
        unsigned char reserved[60]
        unsigned long adwCapStatusCnt_Detail[256]

    cdef int IS_CAPTURE_STATUS_INFO_CMD_RESET = 1
    cdef int IS_CAPTURE_STATUS_INFO_CMD_GET = 2

    cdef int IS_CAP_STATUS_API_NO_DEST_MEM = 0xa2
    cdef int IS_CAP_STATUS_API_CONVERSION_FAILED = 0xa3
    cdef int IS_CAP_STATUS_API_IMAGE_LOCKED = 0xa5
    cdef int IS_CAP_STATUS_DRV_OUT_OF_BUFFERS = 0xb2
    cdef int IS_CAP_STATUS_DRV_DEVICE_NOT_READY = 0xb4
    cdef int IS_CAP_STATUS_USB_TRANSFER_FAILED = 0xc7
    cdef int IS_CAP_STATUS_DEV_MISSED_IMAGES = 0xe5
    cdef int IS_CAP_STATUS_DEV_TIMEOUT = 0xd6
    cdef int IS_CAP_STATUS_DEV_FRAME_CAPTURE_FAILED = 0xd9
    cdef int IS_CAP_STATUS_ETH_BUFFER_OVERRUN = 0xe4
    cdef int IS_CAP_STATUS_ETH_MISSED_IMAGES = 0xe5

    cdef unsigned long IS_USE_DEVICE_ID = 0x8000
