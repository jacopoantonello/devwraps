#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#cython: embedsignature=True, language_level=3

"""Wrapper for Alpao DM

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


from libc.stdint cimport (
    uint8_t, int16_t, uint16_t, int32_t, uint32_t, int64_t, uint64_t)


cdef extern from "asdkType.h":
    ctypedef char Char
    ctypedef uint8_t UChar
    ctypedef int16_t Short
    ctypedef uint16_t UShort

    ctypedef int32_t Int
    ctypedef uint32_t UInt

    ctypedef int64_t Long
    ctypedef uint64_t ULong

    ctypedef size_t Size_T
    ctypedef double Scalar

    cdef enum Bool:
        False
        True

    ctypedef char* CString
    ctypedef const char* CStrConst


cdef extern from "asdkWrapper.h":
    ctypedef enum COMPL_STAT:
        SUCCESS = 0
        FAILURE = -1

    ctypedef struct asdkDM:
        pass

    cdef asdkDM *asdkInit(CStrConst serialName)
    cdef COMPL_STAT asdkRelease(asdkDM *pDm)
    cdef COMPL_STAT asdkSend(asdkDM *pDm, const Scalar *value)
    cdef COMPL_STAT asdkReset(asdkDM *pDm)
    cdef COMPL_STAT asdkSendPattern(
        asdkDM *pDm, const Scalar *pattern, UInt nPattern, UInt nRepeat)
    cdef COMPL_STAT asdkStop(asdkDM *pDm)
    cdef COMPL_STAT asdkGet(asdkDM *pDm, CStrConst command, Scalar *value)
    cdef COMPL_STAT asdkSet(asdkDM *pDm, CStrConst command, Scalar value)
    cdef COMPL_STAT asdkSetString(
        asdkDM *pDm, CStrConst command, CStrConst cstr)
    cdef void asdkPrintLastError()
    cdef COMPL_STAT asdkGetLastError(
        UInt *errorNo, CString errMsg, Size_T errSize)

np.import_array()
DEF MAX_SERIAL_NUMBER = 128


cdef class ASDK:
    cdef asdkDM *dm
    cdef UInt nacts
    cdef char serial_number[MAX_SERIAL_NUMBER]
    cdef int opened
    cdef Scalar *doubles
    cdef object transform

    def __cinit__(self):
        memset(self.serial_number, 0, MAX_SERIAL_NUMBER)
        self.opened = 0
        self.transform = None

    def get_devices(self, dpath=None, ignore=[], try_open=False):
        if dpath is None:
            dpath = path.join(
                os.environ['PROGRAMFILES'], r'Alpao\SDK\Config')
        l = [
                path.basename(p).rstrip('.acfg') for p in
                glob(path.join(dpath, '*.acfg'))]
        devs = set(l) - set(ignore)

        if try_open and self.opened:
            raise ValueError(
                f'try_open supplied but {self.serial_number} already opened')

        if try_open:
            devs2 = []
            for d in devs:
                try:
                    self.open(d)
                    devs2.append(d)
                except Exception:
                    pass
                finally:
                    self.close()
            devs = devs2

        return list(devs)

    def open(self, dev=None):
        cdef COMPL_STAT ret
        cdef char *cp
        cdef unsigned int i
        cdef Scalar tmp = 0.
        pystr = None

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

        if type(dev) != str or len(dev) >= MAX_SERIAL_NUMBER:
            raise Exception(
                f'{dev} must be less than {MAX_SERIAL_NUMBER} characters long')

        pystr = dev.encode('utf-8')
        cp = pystr
        memset(self.serial_number, 0, MAX_SERIAL_NUMBER)
        memcpy(self.serial_number, cp, min(len(pystr), MAX_SERIAL_NUMBER))

        self.dm = asdkInit(self.serial_number)
        if self.dm is NULL:
            raise Exception(f'failed to open {dev}')

        ret = asdkGet(self.dm, 'NbOfActuator', &tmp)
        if ret != SUCCESS:
            asdkRelease(self.dm)
            self.dm = NULL
            raise ValueError('Failed NbOfActuator in open')
        else:
            self.nacts = <UInt>tmp

        self.doubles = <Scalar *>malloc(self.nacts*sizeof(Scalar))
        if not self.doubles:
            asdkRelease(self.dm)
            self.dm = NULL
            raise MemoryError()
        for i in range(self.nacts):
            self.doubles[i] = 0.0

        self.opened = 1

    def close(self):
        cdef COMPL_STAT ret1
        cdef COMPL_STAT ret2

        if self.opened:
            ret1 = asdkReset(self.dm)
            ret2 = asdkRelease(self.dm)

            free(self.doubles)
            self.doubles = NULL
            self.opened = 0
            self.dm = NULL

            if ret1 or ret2:
                raise Exception(f'Error closing DM {ret1} {ret2}')

        self.opened = 0

    def size(self):
        "Number of actuators."
        if self.opened:
            return self.nacts
        else:
            raise Exception('dm not opened')

    @cython.boundscheck(False)
    @cython.wraparound(False)
    def write(self, np.ndarray[double, ndim=1] array not None):
        """Write actuators.

        This function writes raw voltage values to the DM driver. No conversion
        is applied. The input array should contain voltages in the range [-1,
        1].

        Parameters
        ----------
        - `array`: `numpy` actuator values in the range [-1, 1]

        """

        cdef unsigned int i
        cdef double val
        cdef COMPL_STAT ret

        if self.transform is not None:
            array = self.transform(array)

        if not self.opened:
            raise Exception('DM not opened')
        elif not isinstance(array, np.ndarray):
            raise Exception('array must be numpy.ndarray')
        elif array.ndim != 1:
            raise Exception('array must be a vector')
        elif array.size != self.nacts:
            raise Exception(f'array.size must be {self.nacts}')
        elif array.dtype != np.float64:
            raise Exception('array.dtype must be np.float64')

        for i in range(self.nacts):
            val = array[i]

            if val > 1.0:
                val = 1.0
            elif val < -1.0:
                val = -1.0

            self.doubles[i] = val

        ret = asdkSend(self.dm, self.doubles)
        if ret != SUCCESS:
            raise ValueError('Error in write')

    def preset(self, name, mag=0.7):
        if self.nacts == 69:
            u = np.zeros((69, ))
            if name == 'centre':
                u[34] = mag
            elif name == 'cross':
                inds = np.array(
                    [2, 8, 16, 25, 34, 43, 52, 60, 66, 30, 31, 32, 33, 35, 36, 37, 38])
                u[inds] = mag
            elif name == 'x':
                inds = np.array([11, 18, 26, 34, 42, 50, 57, 5, 14, 24, 44, 54, 63])
                u[inds] = mag
            elif name == 'rim':
                inds = np.concatenate((
                    np.arange(0, 5),
                    (11, ),
                    (20, 29, 38, 47, 56),
                    (63, ),
                    np.arange(64, 69),
                    (57, ),
                    (12, 21, 30, 39, 48),
                    (5, ),
                ))
                u[inds] = mag
            elif name == 'checker':
                inds = np.array([
                    20, 38, 56, 11, 28, 46, 63, 4, 18, 36, 54, 68, 9, 26, 44, 61, 2,
                    16, 34, 52, 66, 7, 24, 42, 59, 0, 14, 32, 50, 64, 5, 22, 40, 57,
                    12, 30, 48
                ])
                u[inds] = mag
            elif name == 'arrows':
                inds = np.array([
                    11,
                    18,
                    9,
                    17,
                    26,
                    27,
                    28,
                    7,
                    6,
                    5,
                    13,
                    22,
                    14,
                    24,
                    34,
                    44,
                    54,
                    60,
                    59,
                    58,
                    57,
                    50,
                ])
                u[inds] = mag
            else:
                raise NotImplementedError(name)
            return u
        else:
            raise NotImplementedError()

    def get_transform(self):
        return self.transform

    def set_transform(self, tx):
        self.transform = tx

    def get_serial_number(self):
        if self.opened:
            return self.serial_number.decode('utf-8')
        else:
            return None
