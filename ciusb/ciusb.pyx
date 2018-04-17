#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#cython: embedsignature=True

"""

author: J. Antonello <jacopo.antonello@dpag.ox.ac.uk>
date: Mon Feb 26 07:32:24 GMT 2018

"""

import numpy as np
cimport numpy as np

from libc.math cimport round
from numpy.linalg import norm


np.import_array()


cdef extern from "cciusb.h" namespace "shapes":
    cdef cppclass CCIUsb:
        CCIUsb() except +
        int open(int skip) except +
        void write(unsigned short *values, int vsize) except +
        int size()
        void close()


cdef class CIUsb:
    cdef CCIUsb c_ciusb
    cdef unsigned short array2[160]
    cdef int opened
    cdef skip

    def __cinit__(self):
        self.c_ciusb = CCIUsb()
        self.opened = 0

    def open(self, int skip=0):
        if self.c_ciusb.open(skip):
            raise Exception('no device found')
        else:
            self.opened = 1
            self.skip = skip

    def write(self, np.ndarray[double, ndim=1, mode='c'] array1 not None):
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

        if not self.opened:
            raise Exception('device is not opened')
        elif array1.ndim != 1:
            raise Exception('array must be a vector')
        elif array1.dtype != np.float64:
            raise Exception('wrong data type')
        elif array1.size != 140:
            raise Exception('array1 must be a vector of 140 elements')

        if norm(array1, np.inf) > 1.:
            array1[array1 > 1.] == 1.
            array1[array1 < -1.] == -1.

        assert(norm(array1, np.inf) <= 1.)

        for i in range(140):
            db = round((array1[i] + 1.0)/2.0*0xffff)
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

        for i in range(140):
            if self.array2[i] < xmin:
                xmin = self.array2[i]
            if self.array2[i] > xmax:
                xmax = self.array2[i]
        self.c_ciusb.write(self.array2, 160)

    def size(self):
        "Number of actuators."
        # return self.c_ciusb.size()
        return 140

    def close(self):
        if self.opened:
            self.c_ciusb.close()
            self.opened = 0

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
        else:
            raise NotImplementedError(name)
        return u

    def get_transform(self):
        return None

    def get_serial_number(self):
        if self.opened:
            return self.serial_number
        else:
            return None
