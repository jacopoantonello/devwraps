#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#cython: embedsignature=True

"""Wrapper for Boston Micromachines Multi-DM

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


import numpy as np
import os

cimport cython
cimport numpy as np

from os import path
from glob import glob
from libc.string cimport memset, memcpy
from .bmcd cimport BMCRC, DM, BMCOpen, BMCClearArray, BMCClose
from .bmcd cimport BMCErrorString, BMCSetArray
from libc.stdlib cimport malloc, free


IGNORE_DM_SERIALS = [
    'FAKE137TEST',
    'Hex1011#000',
    'Hex1011#USB',
    'HexW111#000',
    'HexW111#USB',
    'HexW111#XCL',
    'HEX3072_000',
    'HexW507#000',
    'HexW507#USB',
    'HVA137_0000',
    'HVA140_0000',
    'HVA32_00000',
    'HVA4K_00000',
    'KILO1024_00',
    'KILO2040_00',
    'KILO492_000',
    'KILO952_000',
    'MiniTestRng',
    'MiniUSB0000',
    'MultiUSB000',
    'SD1024_0000',
    'TestInactiv',
    ]


np.import_array()


cdef class BMC:
    cdef DM dm
    cdef char serial_number[12]
    cdef int opened
    cdef double *doubles
    cdef object transform

    def __cinit__(self):
        memset(self.serial_number, 0, 12)
        self.opened = 0
        self.transform = None

    def get_devices(self, dpath=None, ignore=None, try_open=False):
        if dpath is None:
            dpath = path.join(
                os.environ['PROGRAMFILES'], r'Boston Micromachines\Profiles')
        l = [
                path.basename(p).rstrip('.dm') for p in
                glob(path.join(dpath, '*.dm'))]
        if ignore is None:
            ignore = IGNORE_DM_SERIALS
        devs = set(l) - set(ignore)

        if try_open and self.opened:
            raise ValueError('try_open supplied but {} is opened already'.format(
                self.serial_number))

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
        cdef BMCRC rv
        cdef char *cp
        cdef unsigned int i
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

        if type(dev) != str or len(dev) != 11:
            raise Exception(dev + ' is not an 11 character serial number')

        pystr = dev.encode('utf-8')
        cp = pystr
        memcpy(self.serial_number, cp, 11)
        self.serial_number[11] = 0

        rv = BMCOpen(&self.dm, self.serial_number)
        if rv != 0:
            raise Exception(BMCErrorString(rv).decode('utf-8'))

        self.doubles = <double *>malloc(self.dm.ActCount*sizeof(double))
        if not self.doubles:
            raise MemoryError()
        for i in range(self.dm.ActCount):
            self.doubles[i] = 0.0

        self.opened = 1

    def close(self):
        cdef BMCRC rv

        if self.opened:
            rv = BMCClearArray(&self.dm)
            if rv:
                raise Exception(BMCErrorString(rv).decode('utf-8'))
            rv = BMCClose(&self.dm)
            if rv:
                raise Exception(BMCErrorString(rv).decode('utf-8'))

            free(self.doubles)
            self.doubles = NULL

        self.opened = 0

    def size(self):
        "Number of actuators."
        if self.opened:
            return self.dm.ActCount
        else:
            raise Exception('dm not opened')

    @cython.boundscheck(False)
    @cython.wraparound(False)
    def write(self, np.ndarray[double, ndim=1] array not None):
        """Write actuators.

        This function writes raw voltage values to the DM driver. No conversion
        is applied. The input array should contain voltages in the range [-1,
        1]. This voltage is linearly transformed to the [0, 1] range that is
        accepted by the driver. If you want to use a non-linear transformation
        like applying the square root, then apply this to the input array
        before calling this function.

        Parameters
        ----------
        - `array`: `numpy` actuator values in the range [-1, 1]
        
        """

        cdef unsigned int i
        cdef double val

        if self.transform is not None:
            array = self.transform(array)

        if not self.opened:
            raise Exception('DM not opened')
        elif not isinstance(array, np.ndarray):
            raise Exception('array must be numpy.ndarray')
        elif array.ndim != 1:
            raise Exception('array must be a vector')
        elif array.size != self.dm.ActCount:
            raise Exception('array.size must be ' + str(self.dm.ActCount))
        elif array.dtype != np.float64:
            raise Exception('array.dtype must be np.float64')
        # TODO check if aligned

        for i in range(self.dm.ActCount):
            val = (array[i] + 1.0)/2.0

            if val > 1.0:
                val = 1.0
            elif val < 0.0:
                val = 0.0

            self.doubles[i] = val

        BMCSetArray(&self.dm, self.doubles, NULL)

    def preset(self, name, mag=0.7):
        u = np.zeros((140,))
        if name == 'centre':
            u[63:65] = mag
            u[75:77] = mag
        elif name == 'cross':
            u[58:82] = mag
            u[4:6] = mag
            u[134:136] = mag
            for i in range(10):
                off = 15 + 12*i
                u[off:(off + 2)] = mag
        elif name == 'x':
            inds = np.array([
                11, 24, 37, 50, 63, 76, 89, 102, 115, 128,
                20, 31, 42, 53, 64, 75, 86, 97, 108, 119])
            u[inds] = mag
        elif name == 'rim':
            u[0:10] = mag
            u[130:140] = mag
            for i in range(10):
                u[10 + 12*i] = mag
                u[21 + 12*i] = mag
        elif name == 'checker':
            c = 0
            s = mag
            for i in range(10):
                u[c] = s
                c += 1
                s *= -1
            for j in range(10):
                for i in range(12):
                    u[c] = s
                    c += 1
                    s *= -1
                s *= -1
            s *= -1
            for i in range(10):
                u[c] = s
                c += 1
                s *= -1
        elif name == 'arrows':
            inds = np.array([
                20, 31, 42, 53, 64, 75, 86, 97, 108, 119,
                16, 17, 18, 19,
                29, 30,
                32, 44, 56, 68,
                43, 55,
                34, 23, 12, 25, 38, 24, 36, 48, 60,
                89, 102, 115, 128, 101, 113, 90, 91,
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
