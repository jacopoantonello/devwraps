#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""Wrapper for Ximea cameras

"""

# devwraps - some device wrappers for Python
# Copyright 2018 J. Antonello <jacopo.antonello@dpag.ox.ac.uk>
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

    cdef int xiTypeInteger = 0
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

cdef extern from "m3ErrorCodes.h":
    cdef int MM40_OK                         =  0
    cdef int MM40_INVALID_HANDLE             =  1
    cdef int MM40_READREG                    =  2
    cdef int MM40_WRITEREG                   =  3
    cdef int MM40_FREE_RESOURCES             =  4
    cdef int MM40_FREE_CHANNEL               =  5
    cdef int MM40_FREE_BANDWIDTH             =  6
    cdef int MM40_READBLK                    =  7
    cdef int MM40_WRITEBLK                   =  8
    cdef int MM40_NO_IMAGE                   =  9
    cdef int MM40_TIMEOUT                    = 10
    cdef int MM40_INVALID_ARG                = 11
    cdef int MM40_NOT_SUPPORTED              = 12
    cdef int MM40_ISOCH_ATTACH_BUFFERS       = 13
    cdef int MM40_GET_OVERLAPPED_RESULT      = 14
    cdef int MM40_MEMORY_ALLOCATION          = 15
    cdef int MM40_DLLCONTEXTISNULL           = 16
    cdef int MM40_DLLCONTEXTISNONZERO        = 17
    cdef int MM40_DLLCONTEXTEXIST            = 18
    cdef int MM40_TOOMANYDEVICES             = 19
    cdef int MM40_ERRORCAMCONTEXT            = 20
    cdef int MM40_UNKNOWN_HARDWARE           = 21
    cdef int MM40_INVALID_TM_FILE            = 22
    cdef int MM40_INVALID_TM_TAG             = 23
    cdef int MM40_INCOMPLETE_TM              = 24
    cdef int MM40_BUS_RESET_FAILED           = 25
    cdef int MM40_NOT_IMPLEMENTED            = 26
    cdef int MM40_SHADING_TOOBRIGHT          = 27
    cdef int MM40_SHADING_TOODARK            = 28
    cdef int MM40_TOO_LOW_GAIN               = 29
    cdef int MM40_INVALID_BPL                = 30
    cdef int MM40_BPL_REALLOC                = 31
    cdef int MM40_INVALID_PIXEL_LIST         = 32
    cdef int MM40_INVALID_FFS                = 33
    cdef int MM40_INVALID_PROFILE            = 34
    cdef int MM40_INVALID_CALIBRATION        = 35
    cdef int MM40_INVALID_BUFFER             = 36
    cdef int MM40_INVALID_DATA               = 38
    cdef int MM40_TGBUSY                     = 39
    cdef int MM40_IO_WRONG                   = 40
    cdef int MM40_ACQUISITION_ALREADY_UP     = 41
    cdef int MM40_OLD_DRIVER_VERSION         = 42
    cdef int MM40_GET_LAST_ERROR             = 43
    cdef int MM40_CANT_PROCESS               = 44
    cdef int MM40_ACQUISITION_STOPED         = 45
    cdef int MM40_ACQUISITION_STOPED_WERR    = 46
    cdef int MM40_INVALID_INPUT_ICC_PROFILE  = 47
    cdef int MM40_INVALID_OUTPUT_ICC_PROFILE = 48
    cdef int MM40_DEVICE_NOT_READY           = 49
    cdef int MM40_SHADING_TOOCONTRAST        = 50
    cdef int MM40_ALREADY_INITIALIZED        = 51
    cdef int MM40_NOT_ENOUGH_PRIVILEGES      = 52
    cdef int MM40_NOT_COMPATIBLE_DRIVER      = 53
    cdef int MM40_TM_INVALID_RESOURCE        = 54
    cdef int MM40_DEVICE_HAS_BEEN_RESETED    = 55
    cdef int MM40_NO_DEVICES_FOUND           = 56
    cdef int MM40_RESOURCE_OR_FUNCTION_LOCKED= 57
    cdef int MM40_BUFFER_SIZE_TOO_SMALL      = 58
    cdef int MM40_COULDNT_INIT_PROCESSOR     = 59
    cdef int MM40_NOT_INITIALIZED            = 60
    cdef int MM40_RESOURCE_NOT_FOUND         = 61
