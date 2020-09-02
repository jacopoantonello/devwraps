#!/usr/bin/env python3
# -*- coding: utf-8 -*-

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
