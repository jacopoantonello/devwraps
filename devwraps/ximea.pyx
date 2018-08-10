#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#cython: embedsignature=True

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


import sys
import numpy as np
cimport numpy as np

from os import path

from libc.string cimport memset, memcpy
from libc.stdint cimport uintptr_t
from libc.stddef cimport wchar_t
from libc.stdlib cimport free, malloc
from cpython cimport PyObject, Py_INCREF

from .ximead cimport (
    MM40_OK, MM40_INVALID_HANDLE, MM40_READREG, MM40_WRITEREG,
    MM40_FREE_RESOURCES, MM40_FREE_CHANNEL, MM40_FREE_BANDWIDTH,
    MM40_READBLK, MM40_WRITEBLK, MM40_NO_IMAGE, MM40_TIMEOUT,
    MM40_INVALID_ARG, MM40_NOT_SUPPORTED, MM40_ISOCH_ATTACH_BUFFERS,
    MM40_GET_OVERLAPPED_RESULT, MM40_MEMORY_ALLOCATION, MM40_DLLCONTEXTISNULL,
    MM40_DLLCONTEXTISNONZERO, MM40_DLLCONTEXTEXIST, MM40_TOOMANYDEVICES,
    MM40_ERRORCAMCONTEXT, MM40_UNKNOWN_HARDWARE, MM40_INVALID_TM_FILE,
    MM40_INVALID_TM_TAG, MM40_INCOMPLETE_TM, MM40_BUS_RESET_FAILED,
    MM40_NOT_IMPLEMENTED, MM40_SHADING_TOOBRIGHT, MM40_SHADING_TOODARK,
    MM40_TOO_LOW_GAIN, MM40_INVALID_BPL, MM40_BPL_REALLOC,
    MM40_INVALID_PIXEL_LIST, MM40_INVALID_FFS, MM40_INVALID_PROFILE,
    MM40_INVALID_CALIBRATION, MM40_INVALID_BUFFER, MM40_INVALID_DATA,
    MM40_TGBUSY, MM40_IO_WRONG, MM40_ACQUISITION_ALREADY_UP,
    MM40_OLD_DRIVER_VERSION, MM40_GET_LAST_ERROR, MM40_CANT_PROCESS,
    MM40_ACQUISITION_STOPED, MM40_ACQUISITION_STOPED_WERR,
    MM40_INVALID_INPUT_ICC_PROFILE, MM40_INVALID_OUTPUT_ICC_PROFILE,
    MM40_DEVICE_NOT_READY, MM40_SHADING_TOOCONTRAST, MM40_ALREADY_INITIALIZED,
    MM40_NOT_ENOUGH_PRIVILEGES, MM40_NOT_COMPATIBLE_DRIVER,
    MM40_TM_INVALID_RESOURCE, MM40_DEVICE_HAS_BEEN_RESETED,
    MM40_NO_DEVICES_FOUND, MM40_RESOURCE_OR_FUNCTION_LOCKED,
    MM40_BUFFER_SIZE_TOO_SMALL, MM40_COULDNT_INIT_PROCESSOR,
    MM40_NOT_INITIALIZED, MM40_RESOURCE_NOT_FOUND,
    )


np.import_array()

cdef extern from "numpy/ndarraytypes.h":
    int NPY_ARRAY_CARRAY_RO

DEF DEBUG = 1

ctypedef int XIR
ctypedef unsigned long DWORD
ctypedef DWORD * PDWORD

cdef check(ret):
    if ret is not None:
        raise Exception(error_string(ret))


cdef str error_string(XIR e):
    if e == MM40_OK:
        return None
    elif e == MM40_INVALID_HANDLE:
        return 'Invalid handle'
    elif e == MM40_READREG:
        return 'Register read error'
    elif e == MM40_WRITEREG:
        return 'Register write error'
    elif e == MM40_FREE_RESOURCES:
        return 'Freeing resources error'
    elif e == MM40_FREE_CHANNEL:
        return 'Freeing channel error'
    elif e == MM40_FREE_BANDWIDTH:
        return 'Freeing bandwith error'
    elif e == MM40_READBLK:
        return 'Read block error'
    elif e == MM40_WRITEBLK:
        return 'Write block error'
    elif e == MM40_NO_IMAGE:
        return 'No image'
    elif e == MM40_TIMEOUT:
        return 'Timeout'
    elif e == MM40_INVALID_ARG:
        return 'Invalid arguments supplied'
    elif e == MM40_NOT_SUPPORTED:
        return 'Not supported'
    elif e == MM40_ISOCH_ATTACH_BUFFERS:
        return 'Attach buffers error'
    elif e == MM40_GET_OVERLAPPED_RESULT:
        return 'Overlapped result'
    elif e == MM40_MEMORY_ALLOCATION:
        return 'Memory allocation error'
    elif e == MM40_DLLCONTEXTISNULL:
        return 'DLL context is NULL'
    elif e == MM40_DLLCONTEXTISNONZERO:
        return 'DLL context is non zero'
    elif e == MM40_DLLCONTEXTEXIST:
        return 'DLL context exists'
    elif e == MM40_TOOMANYDEVICES:
        return 'Too many devices connected'
    elif e == MM40_ERRORCAMCONTEXT:
        return 'Camera context error'
    elif e == MM40_UNKNOWN_HARDWARE:
        return 'Unknown hardware'
    elif e == MM40_INVALID_TM_FILE:
        return 'Invalid TM file'
    elif e == MM40_INVALID_TM_TAG:
        return 'Invalid TM tag'
    elif e == MM40_INCOMPLETE_TM:
        return 'Incomplete TM'
    elif e == MM40_BUS_RESET_FAILED:
        return 'Bus reset error'
    elif e == MM40_NOT_IMPLEMENTED:
        return 'Not implemented'
    elif e == MM40_SHADING_TOOBRIGHT:
        return 'Shading is too bright'
    elif e == MM40_SHADING_TOODARK:
        return 'Shading is too dark'
    elif e == MM40_TOO_LOW_GAIN:
        return 'Gain is too low'
    elif e == MM40_INVALID_BPL:
        return 'Invalid sensor defect correction list'
    elif e == MM40_BPL_REALLOC:
        return 'Error while sensor defect correction list reallocation'
    elif e == MM40_INVALID_PIXEL_LIST:
        return 'Invalid pixel list'
    elif e == MM40_INVALID_FFS:
        return 'Invalid Flash File System'
    elif e == MM40_INVALID_PROFILE:
        return 'Invalid profile'
    elif e == MM40_INVALID_CALIBRATION:
        return 'Invalid calibration'
    elif e == MM40_INVALID_BUFFER:
        return 'Invalid buffer'
    elif e == MM40_INVALID_DATA:
        return 'Invalid data'
    elif e == MM40_TGBUSY:
        return 'Timing generator is busy'
    elif e == MM40_IO_WRONG:
        return 'Wrong operation open/write/read/close'
    elif e == MM40_ACQUISITION_ALREADY_UP:
        return 'Acquisition already started'
    elif e == MM40_OLD_DRIVER_VERSION:
        return 'Old version of device driver installed to the system.'
    elif e == MM40_GET_LAST_ERROR:
        return 'To get error code please call GetLastError function.'
    elif e == MM40_CANT_PROCESS:
        return 'Data cannot be processed'
    elif e == MM40_ACQUISITION_STOPED:
        return 'Acquisition is stopped. It needs to be started.'
    elif e == MM40_ACQUISITION_STOPED_WERR:
        return 'Acquisition has been stopped with an error.'
    elif e == MM40_INVALID_INPUT_ICC_PROFILE:
        return 'Input ICC profile missing or corrupted'
    elif e == MM40_INVALID_OUTPUT_ICC_PROFILE:
        return 'Output ICC profile missing or corrupted'
    elif e == MM40_DEVICE_NOT_READY:
        return 'Device not ready to operate'
    elif e == MM40_SHADING_TOOCONTRAST:
        return 'Shading is too contrast'
    elif e == MM40_ALREADY_INITIALIZED:
        return 'Module already initialized'
    elif e == MM40_NOT_ENOUGH_PRIVILEGES:
        return 'Application does not have enough privileges (one or more app)'
    elif e == MM40_NOT_COMPATIBLE_DRIVER:
        return 'Installed driver is not compatible with current software'
    elif e == MM40_TM_INVALID_RESOURCE:
        return 'TM file was not loaded successfully from resources'
    elif e == MM40_DEVICE_HAS_BEEN_RESETED:
        return 'Device has been reset, abnormal initial state'
    elif e == MM40_NO_DEVICES_FOUND:
        return 'No Devices Found'
    elif e == MM40_RESOURCE_OR_FUNCTION_LOCKE:
        return 'Resource (device) or function locked by mutex'
    elif e == MM40_BUFFER_SIZE_TOO_SMALL:
        return 'Buffer provided by user is too small'
    elif e == MM40_COULDNT_INIT_PROCESSOR:
        return 'Couldnt initialize processor.'
    elif e == MM40_NOT_INITIALIZED:
        return 'The object being referred to has not been started.'
    elif e == MM40_RESOURCE_NOT_FOUND:
        return 'Resource not found.'


cdef class BufWrap:
    cdef uintptr_t data
    cdef np.npy_intp shape[2]
    cdef np.npy_intp strides[2]
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
        self.data = <uintptr_t>data
        self.shape[0] = size0
        self.shape[1] = size1
        self.strides[0] = size1
        self.strides[1] = 1
        self.memid = memid

        if DEBUG:
            print('BufWrap SET data {:x} memid {:d}'.format(data, memid))

    def __array__(self):
        ndarray = np.PyArray_New(
            np.ndarray, 2, self.shape, np.NPY_UINT8, self.strides,
            <void*>self.data, 0, NPY_ARRAY_CARRAY_RO, 0)
        return ndarray

    def __dealloc__(self):
        if DEBUG:
            print('BufWrap FREE data {:x} memid {:d}'.format(
                self.data, self.memid))
        free(<void*>self.data)

    def get_data(self):
        return self.data

    def get_memid(self):
        return self.memid


cdef class Ximea:

    cdef list bufwraps

    def __cinit__(self):
        pass

    def get_number_of_cameras(self):
        pass

    def get_devices(self):
        cdef DWORD num
        
        check(xiGetNumberDevices(&num))
        print(num)
