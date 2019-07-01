#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""Wrapper for Ximea cameras

"""

# devwraps - some device wrappers for Python
# Copyright 2018-2019 J. Antonello <jacopo@antonello.org>
#
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

cdef extern from "xiApi.h":

    # ctypedef int XIR
    # ctypedef unsigned long DWORD
    # ctypedef DWORD * PDWORD

    cdef int XI_OPEN_BY_SN = 1

    cdef int peFloat = 1
    cdef int eString = 2
    cdef int peEnum = 3
    cdef int peBoolean = 4
    cdef int peCommand = 5

    cdef int xiGetNumberDevices(unsigned long *pNumberDevices)
    cdef int xiGetDeviceInfoString(
        unsigned long DevId, const char* prm, char* value,
        unsigned long value_size)
    cdef int xiOpenDeviceBy(int sel, const char* prm, void **hDevice)
    cdef int xiOpenDevice(unsigned long DevId, void **hDevice)
    cdef int xiCloseDevice(void *hDevice)
    cdef int xiSetParamInt(void *hDevice, const char* prm, const int val)
    cdef int xiSetParamFloat(void *hDevice, const char* prm, const float val)
    cdef int xiSetParamString(
        void *hDevice, const char* prm, void* val, unsigned long size)
    cdef int xiGetParamInt(void *hDevice, const char* prm, int* val)
    cdef int xiGetParamFloat(void *hDevice, const char* prm, float* val)
    cdef int xiGetParamString(
        void *hDevice, const char* prm, void* val, unsigned int size)
    cdef int xiGetParam(void *hDevice, const char* prm, void* value,
        unsigned long* size, int *type1)
    cdef int xiSetParam(void *hDevice, const char* prm, void* value,
        unsigned long size, int type1)
    cdef int xiGetImage(
        void *hDevice, unsigned long TimeOut, XI_IMG *img)
    cdef int xiStartAcquisition(void *hDevice)
    cdef int xiStopAcquisition(void *hDevice)

    cdef int xiTypeInteger =0
    cdef int xiTypeFloat = 1
    cdef int xiTypeString = 2
    cdef int xiTypeEnum = 3
    cdef int xiTypeBoolean = 4
    cdef int xiTypeCommand = 5

    cdef int XI_MONO8 = 0 # 8 bits per pixel
    cdef int XI_MONO16 = 1 # 16 bits per pixel
    cdef int XI_RGB24 = 2 # RGB data format
    cdef int XI_RGB32 = 3 # RGBA data format
    cdef int XI_RGB_PLANAR = 4 # RGB planar data format
    cdef int XI_RAW8 = 5 # 8 bits per pixel raw data from sensor
    cdef int XI_RAW16 = 6 # 16 bits per pixel raw data from sensor
    cdef int XI_FRM_TRANSPORT_DATA = 7 # Data from transport layer
    cdef int XI_RGB48 = 8 # RGB data format
    cdef int XI_RGB64 = 9 # RGBA data format
    cdef int XI_RGB16_PLANAR = 10 # RGB16 planar data format
    cdef int XI_RAW8X2 = 11 # 8 bits per pixel raw data from sensor
    cdef int XI_RAW8X4 = 12 # 8 bits per pixel raw data from sensor
    cdef int XI_RAW16X2 = 13 # 16 bits per pixel raw data from sensor
    cdef int XI_RAW16X4 = 14 # 16 bits per pixel raw data from sensor

    cdef int XI_BINNING = 0
    cdef int XI_SKIPPING = 1

    cdef int XI_BP_UNSAFE = 0
    cdef int XI_BP_SAFE = 1

    ctypedef struct XI_IMG_DESC:
        unsigned long Area0Left
        unsigned long Area1Left
        unsigned long Area2Left
        unsigned long Area3Left
        unsigned long Area4Left
        unsigned long Area5Left
        unsigned long ActiveAreaWidth
        unsigned long Area5Right
        unsigned long Area4Right
        unsigned long Area3Right
        unsigned long Area2Right
        unsigned long Area1Right
        unsigned long Area0Right
        unsigned long Area0Top
        unsigned long Area1Top
        unsigned long Area2Top
        unsigned long Area3Top
        unsigned long Area4Top
        unsigned long Area5Top
        unsigned long ActiveAreaHeight
        unsigned long Area5Bottom
        unsigned long Area4Bottom
        unsigned long Area3Bottom
        unsigned long Area2Bottom
        unsigned long Area1Bottom
        unsigned long Area0Bottom
        unsigned long format
        unsigned long flags

    ctypedef struct XI_IMG:
        unsigned long size  # Size of current structure
        void *bp # Pointer to data
        unsigned long bp_size  # Filled buffer size
        int frm # Format of image data get from xiGetImage.
        unsigned long width   # width of incoming image.
        unsigned long height  # height of incoming image.
        unsigned long nframe  # Frame number
        unsigned long tsSec  # Seconds part of timestamp
        unsigned long tsUSec  # Micro-seconds part of timestamp
        unsigned long GPI_level  # Levels of digital inputs/outputs
        unsigned long black_level  # Black level of image (ONLY for MONO/RAW)
        unsigned long padding_x
        unsigned long AbsoluteOffsetX
        unsigned long AbsoluteOffsetY
        unsigned long transport_frm  # format of pixels on transport layer
        XI_IMG_DESC img_desc
        unsigned long DownsamplingX
        unsigned long DownsamplingY
        unsigned long flags  # description of XI_IMG.
        unsigned long exposure_time_us
        float gain_db  # Gain used for this image in deci-bells
        unsigned long acq_nframe # Frame number reset by acquisition start
        unsigned long image_user_data
        unsigned long exposure_sub_times_us[5]

    cdef int XI_OK                         =  0
    cdef int XI_INVALID_HANDLE             =  1
    cdef int XI_READREG                    =  2
    cdef int XI_WRITEREG                   =  3
    cdef int XI_FREE_RESOURCES             =  4
    cdef int XI_FREE_CHANNEL               =  5
    cdef int XI_FREE_BANDWIDTH             =  6
    cdef int XI_READBLK                    =  7
    cdef int XI_WRITEBLK                   =  8
    cdef int XI_NO_IMAGE                   =  9
    cdef int XI_TIMEOUT                    = 10
    cdef int XI_INVALID_ARG                = 11
    cdef int XI_NOT_SUPPORTED              = 12
    cdef int XI_ISOCH_ATTACH_BUFFERS       = 13
    cdef int XI_GET_OVERLAPPED_RESULT      = 14
    cdef int XI_MEMORY_ALLOCATION          = 15
    cdef int XI_DLLCONTEXTISNULL           = 16
    cdef int XI_DLLCONTEXTISNONZERO        = 17
    cdef int XI_DLLCONTEXTEXIST            = 18
    cdef int XI_TOOMANYDEVICES             = 19
    cdef int XI_ERRORCAMCONTEXT            = 20
    cdef int XI_UNKNOWN_HARDWARE           = 21
    cdef int XI_INVALID_TM_FILE            = 22
    cdef int XI_INVALID_TM_TAG             = 23
    cdef int XI_INCOMPLETE_TM              = 24
    cdef int XI_BUS_RESET_FAILED           = 25
    cdef int XI_NOT_IMPLEMENTED            = 26
    cdef int XI_SHADING_TOOBRIGHT          = 27
    cdef int XI_SHADING_TOODARK            = 28
    cdef int XI_TOO_LOW_GAIN               = 29
    cdef int XI_INVALID_BPL                = 30
    cdef int XI_BPL_REALLOC                = 31
    cdef int XI_INVALID_PIXEL_LIST         = 32
    cdef int XI_INVALID_FFS                = 33
    cdef int XI_INVALID_PROFILE            = 34
    cdef int XI_INVALID_CALIBRATION        = 35
    cdef int XI_INVALID_BUFFER             = 36
    cdef int XI_INVALID_DATA               = 38
    cdef int XI_TGBUSY                     = 39
    cdef int XI_IO_WRONG                   = 40
    cdef int XI_ACQUISITION_ALREADY_UP     = 41
    cdef int XI_OLD_DRIVER_VERSION         = 42
    cdef int XI_GET_LAST_ERROR             = 43
    cdef int XI_CANT_PROCESS               = 44
    cdef int XI_ACQUISITION_STOPED         = 45
    cdef int XI_ACQUISITION_STOPED_WERR    = 46
    cdef int XI_INVALID_INPUT_ICC_PROFILE  = 47
    cdef int XI_INVALID_OUTPUT_ICC_PROFILE = 48
    cdef int XI_DEVICE_NOT_READY           = 49
    cdef int XI_SHADING_TOOCONTRAST        = 50
    cdef int XI_ALREADY_INITIALIZED        = 51
    cdef int XI_NOT_ENOUGH_PRIVILEGES      = 52
    cdef int XI_NOT_COMPATIBLE_DRIVER      = 53
    cdef int XI_TM_INVALID_RESOURCE        = 54
    cdef int XI_DEVICE_HAS_BEEN_RESETED    = 55
    cdef int XI_NO_DEVICES_FOUND           = 56
    cdef int XI_RESOURCE_OR_FUNCTION_LOCKED= 57
    cdef int XI_BUFFER_SIZE_TOO_SMALL      = 58
    cdef int XI_COULDNT_INIT_PROCESSOR     = 59
    cdef int XI_NOT_INITIALIZED            = 60
    cdef int XI_RESOURCE_NOT_FOUND         = 61
    cdef int XI_UNKNOWN_PARAM                  =100
    cdef int XI_WRONG_PARAM_VALUE              =101
    cdef int XI_WRONG_PARAM_TYPE               =103
    cdef int XI_WRONG_PARAM_SIZE               =104
    cdef int XI_BUFFER_TOO_SMALL               =105
    cdef int XI_NOT_SUPPORTED_PARAM            =106
    cdef int XI_NOT_SUPPORTED_PARAM_INFO       =107
    cdef int XI_NOT_SUPPORTED_DATA_FORMAT      =108
    cdef int XI_READ_ONLY_PARAM                =109
    cdef int XI_BANDWIDTH_NOT_SUPPORTED        =111
    cdef int XI_INVALID_FFS_FILE_NAME          =112
    cdef int XI_FFS_FILE_NOT_FOUND             =113
    cdef int XI_PARAM_NOT_SETTABLE             =114
    cdef int XI_SAFE_POLICY_NOT_SUPPORTED      =115
    cdef int XI_GPUDIRECT_NOT_AVAILABLE        =116
    cdef int XI_PROC_OTHER_ERROR               =201
    cdef int XI_PROC_PROCESSING_ERROR          =202
    cdef int XI_PROC_INPUT_FORMAT_UNSUPPORTED  =203
    cdef int XI_PROC_OUTPUT_FORMAT_UNSUPPORTED =204
    cdef int XI_OUT_OF_RANGE                   =205
