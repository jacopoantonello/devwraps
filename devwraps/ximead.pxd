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

    cdef int xiGetNumberDevices(unsigned long *pNumberDevices)

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
