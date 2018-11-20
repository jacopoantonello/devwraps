#!/usr/bin/env python3
# -*- coding: utf-8 -*-

#cython: embedsignature=True

"""Wrapper for Alpao DM

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
import os

cimport cython
cimport numpy as np

from os import path
from glob import glob
from libc.string cimport memset, memcpy
from libc.stdlib cimport malloc, free

from .asdkd cimport (
    asdkDM, UInt, Scalar, asdkInit, asdkReset, asdkRelease, COMPL_STAT,
    asdkGet, SUCCESS)


np.import_array()
DEF MAX_SERIAL_NUMBER = 128


cdef class ASDK:
    cdef asdkDM *dm
    cdef UInt nacts
    cdef char serial_number[MAX_SERIAL_NUMBER]
    cdef int opened
    cdef Scalar *doubles
    # cdef object transform

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
