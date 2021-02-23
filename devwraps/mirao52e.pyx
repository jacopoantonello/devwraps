#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#cython: embedsignature=True, language_level=3

"""Wrapper for MIRAO 52-E

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


import numpy as np
import os

cimport cython
cimport numpy as np

from os import path
from glob import glob
from libc.string cimport memset, memcpy
from libc.stdlib cimport malloc, free


np.import_array()

DEF MAX_DLL_VERSION = 32

cdef extern from "mirao52e.h":
    cdef int MRO_TRUE "MRO_TRUE"
    cdef int MRO_FALSE "MRO_FALSE"
    cdef int MRO_NB_COMMAND_VALUES "MRO_NB_COMMAND_VALUES"
    ctypedef double *MroCommand
    ctypedef char MroBoolean
    ctypedef double MroTemperature
    ctypedef double MroIntensity

    cdef int MRO_OK                          "MRO_OK"
    cdef int MRO_UNKNOWN_ERROR               "MRO_UNKNOWN_ERROR"
    cdef int MRO_DEVICE_NOT_OPENED_ERROR     "MRO_DEVICE_NOT_OPENED_ERROR"
    cdef int MRO_DEFECTIVE_DEVICE_ERROR      "MRO_DEFECTIVE_DEVICE_ERROR"
    cdef int MRO_DEVICE_ALREADY_OPENED_ERROR "MRO_DEVICE_ALREADY_OPENED_ERROR"
    cdef int MRO_DEVICE_IO_ERROR             "MRO_DEVICE_IO_ERROR"
    cdef int MRO_DEVICE_LOCKED_ERROR         "MRO_DEVICE_LOCKED_ERROR"
    cdef int MRO_DEVICE_DISCONNECTED_ERROR   "MRO_DEVICE_DISCONNECTED_ERROR"
    cdef int MRO_DEVICE_DRIVER_ERROR         "MRO_DEVICE_DRIVER_ERROR"
    cdef int MRO_FILE_EXISTS_ERROR           "MRO_FILE_EXISTS_ERROR"
    cdef int MRO_FILE_FORMAT_ERROR           "MRO_FILE_FORMAT_ERROR"
    cdef int MRO_FILE_IO_ERROR               "MRO_FILE_IO_ERROR"
    cdef int MRO_INVALID_COMMAND_ERROR       "MRO_INVALID_COMMAND_ERROR"
    cdef int MRO_NULL_POINTER_ERROR          "MRO_NULL_POINTER_ERROR"
    cdef int MRO_OUT_OF_BOUNDS_ERROR         "MRO_OUT_OF_BOUNDS_ERROR"
    cdef int MRO_OPERATION_ONGOING_ERROR     "MRO_OPERATION_ONGOING_ERROR"
    cdef int MRO_SYSTEM_ERROR                "MRO_SYSTEM_ERROR"
    cdef int MRO_UNAVAILABLE_DATA_ERROR      "MRO_UNAVAILABLE_DATA_ERROR"
    cdef int MRO_UNDEFINED_VALUE_ERROR       "MRO_UNDEFINED_VALUE_ERROR"
    cdef int MRO_OUT_OF_SPECIFICATIONS_ERROR "MRO_OUT_OF_SPECIFICATIONS_ERROR"
    cdef int MRO_FILE_FORMAT_VERSION_ERROR   "MRO_FILE_FORMAT_VERSION_ERROR"
    cdef int MRO_USB_INVALID_HANDLE          "MRO_USB_INVALID_HANDLE"
    cdef int MRO_USB_DEVICE_NOT_FOUND        "MRO_USB_DEVICE_NOT_FOUND"
    cdef int MRO_USB_DEVICE_NOT_OPENED       "MRO_USB_DEVICE_NOT_OPENED"
    cdef int MRO_USB_IO_ERROR                "MRO_USB_IO_ERROR"
    cdef int MRO_USB_INSUFFICIENT_RESOURCES  "MRO_USB_INSUFFICIENT_RESOURCES"
    cdef int MRO_USB_INVALID_BAUD_RATE       "MRO_USB_INVALID_BAUD_RATE"
    cdef int MRO_USB_NOT_SUPPORTED           "MRO_USB_NOT_SUPPORTED"
    cdef int MRO_FILE_IO_EACCES              "MRO_FILE_IO_EACCES"
    cdef int MRO_FILE_IO_EAGAIN              "MRO_FILE_IO_EAGAIN"
    cdef int MRO_FILE_IO_EBADF               "MRO_FILE_IO_EBADF"
    cdef int MRO_FILE_IO_EINVAL              "MRO_FILE_IO_EINVAL"
    cdef int MRO_FILE_IO_EMFILE              "MRO_FILE_IO_EMFILE"
    cdef int MRO_FILE_IO_ENOENT              "MRO_FILE_IO_ENOENT"
    cdef int MRO_FILE_IO_ENOMEM              "MRO_FILE_IO_ENOMEM"
    cdef int MRO_FILE_IO_ENOSPC              "MRO_FILE_IO_ENOSPC"

    cdef MroBoolean mro_getVersion(char* version, int* status)
    cdef MroBoolean mro_open(int* status)
    cdef MroBoolean mro_close(int* status)
    cdef MroBoolean mro_applyCommand(MroCommand command, MroBoolean trig, int* status)
    cdef MroBoolean mro_applySmoothCommand(MroCommand command, MroBoolean trig, int* status)

    cdef MroBoolean mro_getLastAppliedCommand(MroCommand command, int* status)

    cdef MroBoolean mro_setStockCommand(MroCommand command, int index, int* status)
    cdef MroBoolean mro_applyStockCommand(int index, MroBoolean trig, int* status)
    cdef MroBoolean mro_applySmoothStockCommand(int index, MroBoolean trig, int* status)
    cdef MroBoolean mro_resetCommandStock(int* status)
    cdef MroBoolean mro_getCommandStockSize(int* size, int* status)
    cdef MroBoolean mro_getCommandStockMaxSize(int* size, int* status)

    cdef MroBoolean mro_isMonitoringEnabled(MroBoolean* enabled, int* status)
    cdef MroBoolean mro_setMonitoringEnabled(MroBoolean enabled, int* status)

    cdef MroBoolean mro_getMirrorTemperature(MroTemperature* val, int* status)
    cdef MroBoolean mro_getPowerSupplyTemperature(MroTemperature* val, int* status)
    cdef MroBoolean mro_getMirrorLockTemperature(MroTemperature* val, int* status)
    cdef MroBoolean mro_getPowerSupplyLockTemperature(MroTemperature* val, int* status)

    cdef MroBoolean mro_getNegativeCoilsIntensity(MroIntensity* val, int* status)
    cdef MroBoolean mro_getPositiveCoilsIntensity(MroIntensity* val, int* status)
    cdef MroBoolean mro_getNegativeCoilsLockIntensity(MroIntensity* val, int* status)
    cdef MroBoolean mro_getPositiveCoilsLockIntensity(MroIntensity* val, int* status)

    cdef MroBoolean mro_isLocked(MroBoolean* val, int* status)
    cdef MroBoolean mro_isConnected(MroBoolean* val, int* status)

    # cdef MroBoolean mro_registerCallback(void (*callback)(MiraoInfo*), int* status)
    # cdef MroBoolean mro_unregisterCallback(int* status)

cdef char* getMiraoErrorMessage(int status):
    if status == MRO_OK:
        return "MRO_OK"
    elif status == MRO_UNKNOWN_ERROR:
        return "MRO_UNKNOWN_ERROR"
    elif status == MRO_DEVICE_NOT_OPENED_ERROR:
        return "MRO_DEVICE_NOT_OPENED_ERROR"
    elif status == MRO_DEFECTIVE_DEVICE_ERROR:
        return "MRO_DEFECTIVE_DEVICE_ERROR"
    elif status == MRO_DEVICE_ALREADY_OPENED_ERROR:
        return "MRO_DEVICE_ALREADY_OPENED_ERROR"
    elif status == MRO_DEVICE_IO_ERROR:
        return "MRO_DEVICE_IO_ERROR"
    elif status == MRO_DEVICE_LOCKED_ERROR:
        return "MRO_DEVICE_LOCKED_ERROR"
    elif status == MRO_DEVICE_DISCONNECTED_ERROR:
        return "MRO_DEVICE_DISCONNECTED_ERROR"
    elif status == MRO_DEVICE_DRIVER_ERROR:
        return "MRO_DEVICE_DRIVER_ERROR"
    elif status == MRO_FILE_EXISTS_ERROR:
        return "MRO_FILE_EXISTS_ERROR"
    elif status == MRO_FILE_FORMAT_ERROR:
        return "MRO_FILE_FORMAT_ERROR"
    elif status == MRO_FILE_IO_ERROR:
        return "MRO_FILE_IO_ERROR"
    elif status == MRO_INVALID_COMMAND_ERROR:
        return "MRO_INVALID_COMMAND_ERROR"
    elif status == MRO_NULL_POINTER_ERROR:
        return "MRO_NULL_POINTER_ERROR"
    elif status == MRO_OUT_OF_BOUNDS_ERROR:
        return "MRO_OUT_OF_BOUNDS_ERROR"
    elif status == MRO_OPERATION_ONGOING_ERROR:
        return "MRO_OPERATION_ONGOING_ERROR"
    elif status == MRO_SYSTEM_ERROR:
        return "MRO_SYSTEM_ERROR"
    elif status == MRO_UNAVAILABLE_DATA_ERROR:
        return "MRO_UNAVAILABLE_DATA_ERROR"
    elif status == MRO_UNDEFINED_VALUE_ERROR:
        return "MRO_UNDEFINED_VALUE_ERROR"
    elif status == MRO_OUT_OF_SPECIFICATIONS_ERROR:
        return "MRO_OUT_OF_SPECIFICATIONS_ERROR"
    elif status == MRO_FILE_FORMAT_VERSION_ERROR:
        return "MRO_FILE_FORMAT_VERSION_ERROR"
    elif status == MRO_USB_INVALID_HANDLE:
        return "MRO_USB_INVALID_HANDLE"
    elif status == MRO_USB_DEVICE_NOT_FOUND:
        return "MRO_USB_DEVICE_NOT_FOUND"
    elif status == MRO_USB_DEVICE_NOT_OPENED:
        return "MRO_USB_DEVICE_NOT_OPENED"
    elif status == MRO_USB_IO_ERROR:
        return "MRO_USB_IO_ERROR"
    elif status == MRO_USB_INSUFFICIENT_RESOURCES:
        return "MRO_USB_INSUFFICIENT_RESOURCES"
    elif status == MRO_USB_INVALID_BAUD_RATE:
        return "MRO_USB_INVALID_BAUD_RATE"
    elif status == MRO_USB_NOT_SUPPORTED:
        return "MRO_USB_NOT_SUPPORTED"
    elif status == MRO_FILE_IO_EACCES:
        return "MRO_FILE_IO_EACCES"
    elif status == MRO_FILE_IO_EAGAIN:
        return "MRO_FILE_IO_EAGAIN"
    elif status == MRO_FILE_IO_EBADF:
        return "MRO_FILE_IO_EBADF"
    elif status == MRO_FILE_IO_EINVAL:
        return "MRO_FILE_IO_EINVAL"
    elif status == MRO_FILE_IO_EMFILE:
        return "MRO_FILE_IO_EMFILE"
    elif status == MRO_FILE_IO_ENOENT:
        return "MRO_FILE_IO_ENOENT"
    elif status == MRO_FILE_IO_ENOMEM:
        return "MRO_FILE_IO_ENOMEM"
    elif status == MRO_FILE_IO_ENOSPC:
        return "MRO_FILE_IO_ENOSPC"
    else:
        return "???"


cdef class Mirao52e:
    cdef char dllVersion[MAX_DLL_VERSION]
    cdef int opened
    cdef object transform
    cdef str defaultName
    cdef double *doubles
    cdef int stock_size

    def __cinit__(self):
        memset(self.dllVersion, 0, MAX_DLL_VERSION)
        self.opened = 0
        self.stock_size = 0
        self.transform = None
        self.defaultName = 'Mirao52-e'
        self.doubles = <double*>malloc(MRO_NB_COMMAND_VALUES*sizeof(double))
        if not self.doubles:
            raise Exception('error in malloc()')
        for i in range(MRO_NB_COMMAND_VALUES):
            self.doubles[i] = 0.0

    def __dealloc__(self):
        free(self.doubles)
        self.doubles = NULL

    def open(self, dev=None):
        cdef int status = 0
        cdef MroBoolean ret = 0

        if mro_getVersion(self.dllVersion, &status) == MRO_FALSE:
            raise Exception(f'Error in mro_getVersion(): {getMiraoErrorMessage(status)}')

        if self.opened and dev is not None:
            # already opened but a name or id was specified
            raise Exception('dm already opened')
        elif self.opened:
            # open has been called twice, keep quiet
            return

        if dev is None:
            dev = 0

        if type(dev) == int:
            devs = self.get_devices()
            if dev >= len(devs):
                raise Exception('dm not found')
            else:
                dev = devs[dev]

        if dev is not None:
            if type(dev) != str:
                raise Exception('dm not found')
            else:
                self.defaultName = dev

        try:
            ret = mro_open(&status)
        except Exception:
            pass

        if ret == MRO_FALSE:
            if status == MRO_USB_DEVICE_NOT_FOUND:
                raise Exception('dm not found')
        else:
            self.opened = 1

    def get_devices(self):
        cdef int status = 0
        cdef MroBoolean ret = 0

        if self.opened:
            return [self.defaultName]
        else:
            if mro_getVersion(self.dllVersion, &status) == MRO_FALSE:
                raise Exception(f'Error in mro_getVersion(): {getMiraoErrorMessage(status)}')

            try:
                ret = mro_open(&status)
            except Exception:
                pass

            if ret == MRO_FALSE:
                if status == MRO_USB_DEVICE_NOT_FOUND:
                    return []
                else:
                    raise Exception(f'Error in mro_open(): {getMiraoErrorMessage(status)}')
            else:
                if mro_close(&status) == MRO_FALSE:
                    raise Exception(f'Error in mro_close(): {getMiraoErrorMessage(status)}')
                return ['Mirao52e']

    def close(self):
        cdef int status = 0

        if self.opened:
            for i in range(MRO_NB_COMMAND_VALUES):
                self.doubles[i] = 0.0
            if mro_close(&status) == MRO_FALSE:
                raise Exception(f'Error in mro_close(): {getMiraoErrorMessage(status)}')

        self.opened = 0

    def size(self):
        "Number of actuators."
        if self.opened:
            return MRO_NB_COMMAND_VALUES
        else:
            raise Exception('dm not opened')

    @cython.boundscheck(False)
    @cython.wraparound(False)
    def write(self, np.ndarray[double, ndim=1] array not None, int trig=0, int smooth=0):
        cdef double val
        cdef int status = 0

        """Write actuators.

        Write DM actuators. The input array should be in the range [-1, 1]. If
        the `transform` object is not `None`, the array is transformed before
        writing the DM.

        Parameters
        ----------
        - `array`: `numpy` actuator values in the range [-1, 1]
        - `trig`: `bool` if true, a hardware trig will follow the command application
        - `smooth`: `bool` minimise vibrations but taking a little more time

        """

        if self.transform is not None:
            array = self.transform(array)

        if not self.opened:
            raise Exception('DM not opened')
        elif not isinstance(array, np.ndarray):
            raise Exception('array must be numpy.ndarray')
        elif array.ndim != 1:
            raise Exception('array must be a vector')
        elif array.size != MRO_NB_COMMAND_VALUES:
            raise Exception(f'array.size must be {MRO_NB_COMMAND_VALUES}')
        elif array.dtype != np.float64:
            raise Exception('array.dtype must be np.float64')

        for i in range(MRO_NB_COMMAND_VALUES):
            val = array[i]

            if val > 1.0:
                val = 1.0
            elif val < -1.0:
                val = -1.0

            self.doubles[i] = val

        if smooth:
            if mro_applySmoothCommand(self.doubles, MRO_TRUE, &status) == MRO_FALSE:
                raise Exception(
                    f'Error in mro_applySmoothCommand(): {getMiraoErrorMessage(status)}')
        else:
            if mro_applyCommand(self.doubles, MRO_TRUE, &status) == MRO_FALSE:
                raise Exception(f'Error in mro_applyCommand(): {getMiraoErrorMessage(status)}')

    def preset(self, name, mag=0.7):
        if name == 'centre':
            inds = np.array([22, 30, 23, 31])
        elif name == 'cross':
            inds = np.array([
                2, 7, 14, 22, 30, 38, 45, 50,
                3, 8, 15, 23, 31, 39, 46, 51,
                19, 20, 21, 22, 23, 24, 25, 26,
                27, 28, 29, 30, 31, 32, 33, 34])
        elif name == 'x':
            inds = np.array([
                5, 13, 22, 31, 40, 48,
                10, 16, 23, 30, 37, 43])
        elif name == 'rim':
            inds = np.array([
                1, 2, 3, 4, 10, 18, 26, 34, 42, 48, 52, 51,
                50, 49, 43, 35, 27, 19, 11, 5])
        elif name == 'checker':
            inds = np.array([
                11, 27,
                5, 20, 36,
                1, 13, 29, 44,
                7, 22, 38, 50,
                3, 15, 31, 46,
                9, 24, 40, 52,
                17, 33, 48,
                26, 42])
        elif name == 'arrows':
            inds = np.array([
                1, 5, 13, 6, 7, 8,
                10, 16, 23, 30, 37, 43, 28, 36, 44, 45,
                40, 41, 47])
        else:
            raise NotImplementedError(name)
        u = np.zeros((MRO_NB_COMMAND_VALUES,))
        inds = np.unique(inds)
        inds.sort()
        u[inds] = mag
        return u

    def get_transform(self):
        return self.transform

    def set_transform(self, tx):
        self.transform = tx

    def get_serial_number(self):
        if self.opened:
            return self.defaultName
        else:
            return None

    def get_last_command(self):
        cdef int status = 0

        c = np.zeros((MRO_NB_COMMAND_VALUES,))
        cdef np.ndarray[np.float64_t, ndim=1] buf = c

        if mro_getLastAppliedCommand(<double *>buf.data, &status) == MRO_FALSE:
            raise Exception(
                f'Error in mro_getLastAppliedCommand(): {getMiraoErrorMessage(status)}')

        return c

    def set_monitoring(self, int onoff):
        cdef int status = 0

        if mro_setMonitoringEnabled(onoff, &status) == MRO_FALSE:
            raise Exception(
                f'Error in mro_setMonitoringEnabled(): {getMiraoErrorMessage(status)}')

    def get_monitoring(self):
        cdef int status = 0
        cdef MroBoolean ison = 0

        if mro_isMonitoringEnabled(&ison, &status) == MRO_FALSE:
            raise Exception(
                f'Error in mro_isMonitoringEnabled(): {getMiraoErrorMessage(status)}')

        return int(ison)

    def get_temperatures(self):
        cdef int status = 0
        cdef MroTemperature val = 0

        d = {}

        if mro_getMirrorTemperature(&val, &status) == MRO_FALSE:
            raise Exception(
                f'Error in mro_getMirrorTemperature(): {getMiraoErrorMessage(status)}')
        d['mirror'] = val

        if mro_getPowerSupplyTemperature(&val, &status) == MRO_FALSE:
            raise Exception(
                f'Error in mro_getPowerSupplyTemperature(): {getMiraoErrorMessage(status)}')
        d['power_supply'] = val

        return d

    def get_lock_temperatures(self):
        cdef int status = 0
        cdef MroTemperature val = 0

        d = {}

        if mro_getMirrorLockTemperature(&val, &status) == MRO_FALSE:
            raise Exception(
                f'Error in mro_getMirrorLockTemperature(): {getMiraoErrorMessage(status)}')
        d['mirror'] = val

        if mro_getPowerSupplyLockTemperature(&val, &status) == MRO_FALSE:
            raise Exception(
                f'Error in mro_getPowerSupplyLockTemperature(): {getMiraoErrorMessage(status)}')
        d['power_supply'] = val

        return d

    def get_coils_intensity(self):
        cdef int status = 0
        cdef MroIntensity val1 = 0
        cdef MroIntensity val2 = 0

        if mro_getNegativeCoilsIntensity(&val1, &status) == MRO_FALSE:
            raise Exception(
                f'Error in mro_getNegativeCoilsIntensity(): {getMiraoErrorMessage(status)}')

        if mro_getPositiveCoilsIntensity(&val2, &status) == MRO_FALSE:
            raise Exception(
                f'Error in mro_getPositiveCoilsIntensity(): {getMiraoErrorMessage(status)}')

        return (val1, val2)

    def get_coils_lock_intensity(self):
        cdef int status = 0
        cdef MroIntensity val1 = 0
        cdef MroIntensity val2 = 0

        if mro_getNegativeCoilsLockIntensity(&val1, &status) == MRO_FALSE:
            raise Exception(
                f'Error in mro_getNegativeCoilsLockIntensity(): {getMiraoErrorMessage(status)}')

        if mro_getPositiveCoilsLockIntensity(&val2, &status) == MRO_FALSE:
            raise Exception(
                f'Error in mro_getPositiveCoilsLockIntensity(): {getMiraoErrorMessage(status)}')

        return (val1, val2)

    def is_locked(self):
        cdef int status = 0
        cdef MroBoolean ison = 0

        if mro_isLocked(&ison, &status) == MRO_FALSE:
            raise Exception(
                f'Error in mro_isLocked(): {getMiraoErrorMessage(status)}')

        return int(ison)

    def is_connected(self):
        cdef int status = 0
        cdef MroBoolean ison = 0

        if mro_isConnected(&ison, &status) == MRO_FALSE:
            raise Exception(
                f'Error in mro_isConnected(): {getMiraoErrorMessage(status)}')

        return int(ison)

    @cython.boundscheck(False)
    @cython.wraparound(False)
    def load_stock(self, np.ndarray[double, ndim=2] array):
        cdef int status = 0
        cdef int max_size = 0

        if self.transform is not None:
            array = self.transform(array)

        if not self.opened:
            raise Exception('DM not opened')

        self.stock_size = 0
        if mro_resetCommandStock(&status) == MRO_FALSE:
            raise Exception(
                f'Error in mro_resetCommandStock(): {getMiraoErrorMessage(status)}')

        if mro_getCommandStockMaxSize(&max_size, &status) == MRO_FALSE:
            raise Exception(
                f'Error in mro_getCommandStockMaxSize(): {getMiraoErrorMessage(status)}')

        if array is None or array.shape[0] < 0:
            return

        if not isinstance(array, np.ndarray):
            raise Exception('array must be numpy.ndarray')
        elif array.ndim != 2:
            raise Exception('array must be a matrix')
        elif array.shape[1] != MRO_NB_COMMAND_VALUES:
            raise Exception(f'array.shape[1] must be {MRO_NB_COMMAND_VALUES}')
        elif array.dtype != np.float64:
            raise Exception('array.dtype must be np.float64')
        elif array.shape[0] > max_size:
            raise Exception(f'array.shape[0] must be <= {max_size}')

        for j in range(array.size[0]):
            for i in range(MRO_NB_COMMAND_VALUES):
                val = array[j, i]

                if val > 1.0:
                    val = 1.0
                elif val < -1.0:
                    val = -1.0

                self.doubles[i] = val

            if mro_setStockCommand(self.doubles, j, &status) == MRO_FALSE:
                raise Exception(
                    f'Error in mro_setStockCommand(): {getMiraoErrorMessage(status)}')

        self.stock_size = array.shape[0]

    def write_stock(self, int index, int trig=0, int smooth=0):
        cdef int status = 0

        if index >= self.stock_size:
            raise ValueError(
                f'Index {index} exceeds the current stock size {self.stock_size}')

        if smooth:
            if mro_applySmoothStockCommand(index, trig, &status) == MRO_FALSE:
                raise Exception(
                    f'Error in mro_applySmoothStockCommand(): {getMiraoErrorMessage(status)}')
        else:
            if mro_applyStockCommand(index, trig, &status) == MRO_FALSE:
                raise Exception(
                    f'Error in mro_applyStockCommand(): {getMiraoErrorMessage(status)}')
