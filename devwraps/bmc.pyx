#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#cython: embedsignature=True, language_level=3

"""Wrapper for Boston Micromachines Multi-DM

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


cdef extern from "BmcApi.h":
    cdef enum BMCRC:
        NO_ERR
        ERR_UNKNOWN
        ERR_NO_HW
        ERR_INIT_DRIVER
        ERR_SERIAL_NUMBER
        ERR_MALLOC
        ERR_INVALID_DRIVER_TYPE
        ERR_INVALID_ACTUATOR_COUNT
        ERR_INVALID_LUT
        ERR_ACTUATOR_ID
        ERR_OPENFILE
        ERR_NOT_IMPLEMENTED
        ERR_TIMEOUT
        ERR_POKE
        ERR_REGISTRY
        ERR_PCIE_REGWR
        ERR_PCIE_REGRD
        ERR_PCIE_BURST
        ERR_X64_ONLY
        ERR_PULSE_RANGE
        ERR_INVALID_SEQUENCE
        ERR_INVALID_SEQUENCE_RATE
        ERR_INVALID_DITHER_WVFRM
        ERR_INVALID_DITHER_GAIN
        ERR_INVALID_DITHER_RATE
        ERR_BADARG
        ERR_SEGMENT_ID
        ERR_INVALID_CALIBRATION
        ERR_OUT_OF_LUT_RANGE
        ERR_DRIVER_NOT_OPEN
        ERR_DRIVER_ALREADY_OPEN
        ERR_FILE_PERMISSIONS

    ctypedef struct DM_DRIVER:
        unsigned int channel_count
        unsigned int reserved[7]
    
    ctypedef struct DM_PRIV:
        pass
    
    ctypedef struct DM:
        unsigned int Driver_Type
        unsigned int DevId
        unsigned int HVA_Type
        unsigned int use_fiber
        unsigned int use_CL
        unsigned int burst_mode
        unsigned int fiber_mode
        unsigned int ActCount
        unsigned int MaxVoltage
        unsigned int VoltageLimit
        char mapping[256]
        unsigned int inactive[4096]
        char profiles_path[256]
        char maps_path[256]
        char cals_path[256]
        char cal[256] 
        DM_DRIVER driver 
        DM_PRIV* priv

    cdef BMCRC BMCOpen(DM *dm, const char *serial_number)

    cdef BMCRC BMCLoadMap(DM *dm, const char *map_path, unsigned int *map_lut)
    
    cdef BMCRC BMCApplyMap(DM *dm, unsigned int *map_lut, unsigned int *mask)
    
    cdef BMCRC BMCSetArray(DM *dm, double *array, unsigned int *map_lut)
    
    cdef BMCRC BMCClearArray(DM *dm)
    
    cdef BMCRC BMCLoadCalibrationFile(DM *dm, const char *path)
    
    cdef BMCRC BMCClose(DM *dm)
    
    cdef const char *BMCErrorString(BMCRC err)
    
    cdef BMCRC BMCSetProfilesPath(DM *dm, const char *profiles_path)
    
    cdef BMCRC BMCSetMapsPath(DM *dm, const char *maps_path)
    
    cdef const char *BMCVersionString()


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


def kilocsdm952_preset(name, mag=0.7):
    Ntot = 952
    u = np.zeros((Ntot, ))
    if name == 'centre':
        inds = [458, 459, 492, 493]
    elif name == 'cross':
        inds = [
            5, 19, 37, 58, 81, 106, 133, 162, 192, 223, 255, 288, 322, 356,
            390, 424, 458, 492, 526, 560, 594, 628, 662, 695, 727, 758, 788,
            817, 844, 869, 892, 913, 931, 945
        ]
        inds.extend([t + 1 for t in inds])
        inds.extend([t for t in range(442, 476)])
        inds.extend([t for t in range(476, 510)])
    elif name == 'x':
        inds = [
            881, 855, 827, 797, 766, 734, 701, 667, 633, 598, 563, 528, 493,
            458, 423, 388, 353, 318, 283, 250, 217, 185, 154, 124, 96, 70, 95,
            123, 153, 184, 216, 249, 284, 319, 354, 389, 424, 527, 562, 597,
            632, 668, 702, 735, 767, 798, 828, 856, 93, 117, 143, 171, 200,
            230, 261, 294, 327, 360, 393, 426, 459, 492, 525, 558, 591, 624,
            658, 690, 721, 751, 780, 808, 834, 858, 118, 144, 172, 201, 231,
            262, 326, 326, 359, 392, 425, 526, 559, 592, 625, 657, 689, 720,
            750, 779, 807, 833, 293
        ]
    elif name == 'rim':
        inds = [
            679, 645, 611, 577, 543, 509, 475, 441, 407, 373, 339, 305, 271,
            239, 207, 177, 147, 119, 93, 69, 47, 46, 27, 26, 0, 1, 2, 3, 4, 5,
            6, 7, 8, 9, 10, 11, 12, 13, 29, 28, 48, 70, 94, 120, 148, 178, 208,
            240, 272, 306, 340, 374, 408, 442, 476, 510, 544, 578, 612, 646,
            680, 712, 744, 774, 804, 832, 858, 882, 904, 905, 924, 940, 941,
            942, 943, 944, 945, 946, 947, 948, 949, 950, 951, 938, 939, 922,
            923, 903, 881, 857, 831, 803, 773, 743, 711, 925
        ]
    elif name == 'checker':
        inds = np.arange(0, Ntot, 2)
    elif name == 'arrows':
        inds = [
            739, 769, 798, 826, 852, 824, 794, 763, 731, 825, 796, 766, 735,
            763, 670, 636, 602, 568, 534, 500, 466, 432, 426, 459, 492, 525,
            558, 591, 625, 658, 690, 721, 751, 780, 750, 719, 687, 654, 620,
            586, 703, 786, 388, 387, 386, 385, 384, 393, 354, 320, 286, 253,
            221, 190, 253, 318, 283, 249, 216, 184, 153, 785, 784, 783, 782,
            781
        ]
    else:
        raise NotImplementedError(name)
    u = np.zeros(Ntot)
    u[inds] = mag
    return u

def multidm140_preset(name, mag=0.7):
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
        for _ in range(10):
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
            raise Exception('DM already opened')
        elif self.opened:
            # open has been called twice, keep quiet
            return

        if dev is None:
            dev = 0

        if type(dev) == int:
            devs = self.get_devices()
            if dev >= len(devs):
                raise Exception('DM not found')
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
            raise Exception('DM not opened')

    @cython.boundscheck(False)
    @cython.wraparound(False)
    def write(self, np.ndarray[double, ndim=1] array not None):
        """Write actuators.

        Write DM actuators. The input array should be in the range [-1, 1]. If
        the `transform` object is not `None`, the array is transformed before
        writing the DM.

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
        size = self.size()
        if size == 140:
            return multidm140_preset(name, mag)
        elif size == 952:
            return kilocsdm952_preset(name, mag)
        else:
            raise NotImplementedError(f'Unknown presets for DM with size={size}')

    def get_transform(self):
        return self.transform

    def set_transform(self, tx):
        self.transform = tx

    def get_serial_number(self):
        if self.opened:
            return self.serial_number.decode('utf-8')
        else:
            return None
