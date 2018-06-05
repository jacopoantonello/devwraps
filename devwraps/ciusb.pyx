#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#cython: embedsignature=True

"""Wrapper for Boston Micromachines Multi-DM

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


import numpy as np

cimport cython
cimport numpy as np

from libc.math cimport round
from numpy.linalg import norm


DEF NUM_ACTUATORS = 140
DEF NUM_DAC = 160

np.import_array()


cdef extern from "cciusb.h" namespace "shapes":
    cdef cppclass CCIUsb:
        CCIUsb() except +
        int open(int skip) except +
        int get_devices() except +
        void write(unsigned short *values, int vsize) except +
        int size()
        void close()


cdef class CIUsb:
    cdef CCIUsb c_ciusb
    cdef unsigned short array2[NUM_DAC]
    cdef int opened
    cdef int dev
    cdef object transform

    def __cinit__(self):
        self.c_ciusb = CCIUsb()
        self.opened = 0
        self.dev = -1
        self.transform = None

    def open(self, dev=None):
        if self.opened and dev is not None:
            # already opened but a name or id was specified
            raise Exception('dm already opened')
        elif self.opened:
            # open has been called twice, keep quiet
            return

        if self.c_ciusb.get_devices() == 0:
            raise Exception('no devices found')
        elif dev is None:
            dev = 0
        elif type(dev) == str:
            dev = int(dev)

        if self.c_ciusb.open(dev):
            raise Exception('device {} not found'.format(dev))
        else:
            self.opened = 1
            self.dev = dev

    def get_devices(self):
        return ['dm' + str(i) for i in range(self.c_ciusb.get_devices())]

    @cython.boundscheck(False)
    @cython.wraparound(False)
    def write(self, np.ndarray[double, ndim=1] array not None):
        """Write actuators.

        This function writes raw voltage values to the DM driver. No conversion
        is applied. The input array should contain voltages in the range [-1,
        1]. This voltage is linearly transformed to the [0, 0xffff] range that
        is accepted by the driver. If you want to use a non-linear
        transformation like applying the square root, then apply this to the
        input array before calling this function.

        Parameters
        ----------
        - `array`: `numpy` actuator values in the range [-1, 1]
        
        """

        cdef double db
        cdef int i

        if self.transform is not None:
            array = self.transform(array)

        if not self.opened:
            raise Exception('DM is not opened')
        elif not isinstance(array, np.ndarray):
            raise Exception('array must be numpy.ndarray')
        elif array.ndim != 1:
            raise Exception('array must be a vector')
        elif array.size != NUM_ACTUATORS:
            raise Exception('array.size must be ' + str(NUM_ACTUATORS))
        elif array.dtype != np.float64:
            raise Exception('array.dtype must be np.float64')

        if norm(array, np.inf) > 1.:
            array[array > 1.] == 1.
            array[array < -1.] == -1.

        assert(norm(array, np.inf) <= 1.)

        for i in range(NUM_ACTUATORS):
            db = round((array[i] + 1.0)/2.0*0xffff)
            if db < 0.0 or db > 0xffff:
                raise Exception('write conversion error')

            self.array2[i] = <unsigned short>db

        self._write()

    def _write(self):
        cdef unsigned short xmin
        cdef unsigned short xmax
        
        if not self.opened:
            raise Exception('device is not opened')

        xmin = 0xffff
        xmax = 0x0

        for i in range(NUM_ACTUATORS):
            if self.array2[i] < xmin:
                xmin = self.array2[i]
            if self.array2[i] > xmax:
                xmax = self.array2[i]
        self.c_ciusb.write(self.array2, NUM_DAC)

    def size(self):
        "Number of actuators."
        # return self.c_ciusb.size()
        return NUM_ACTUATORS

    def close(self):
        if self.opened:
            self.c_ciusb.close()
            self.opened = 0
            self.dev = -1

    def preset(self, name, mag=0.7):
        u = np.zeros((NUM_ACTUATORS,))
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
            return 'dm' + str(self.dev)
        else:
            return None
