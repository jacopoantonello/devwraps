#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#cython: embedsignature=True

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

from .asdkd cimport (
    asdkDM, UInt, Scalar, asdkInit, asdkReset, asdkRelease, COMPL_STAT,
    asdkGet, SUCCESS, asdkSend)


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
        cdef Scalar tmp
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
        memcpy(self.serial_number, cp, len(pystr))

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

        self.doubles = <Scalar *>malloc(self.nact*sizeof(Scalar))
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

        ret = asdkSend(self.dm, self.doubles);
        if ret != SUCCESS:
            raise ValueError('Error in write')

    def preset(self, name, mag=0.7):
        u = np.zeros((140,))
        if name == 'centre':
            u[34] = mag
        elif name == 'cross':
            inds = np.array([
                2, 8, 16, 25, 34, 43, 52, 60, 66,
                30, 31, 32, 33, 35, 36, 37, 38])
            u[inds] = mag
        elif name == 'x':
            inds = np.array([
                11, 18, 26, 34, 42, 50, 57,
                5, 14, 24, 44, 54, 63])
            u[inds] = mag
        elif name == 'rim':
            inds = np.array([
                6, 7, 8, 9, 10,
                19, 28, 37, 46, 55,
                62, 61, 60, 59, 58,
                49, 48, 31, 22, 13])
            u[inds] = mag
        elif name == 'checker':
            c = 0
            s = mag
            inds = np.kron(
                [0, 1], np.ones(1, self.size()//2)).astype(np.bool)
            u[inds[:u.size]] = 1
        elif name == 'arrows':
            inds = np.array([
                11, 18,  9, 17, 26, 27, 28,
                16, 15, 14, 23, 32, 24, 34, 44, 54,
                42, 50, 59, 51, 52, 53
                ])
            u[inds] = mag
        else:
            raise NotImplementedError(name)
        return u

    def get_transform(self):
        return self.transform

    def set_transform(self, tx):
        self.transform = tx

    def get_serial_number(self):
        if self.opened:
            return self.serial_number.decode('utf-8')
        else:
            return None
