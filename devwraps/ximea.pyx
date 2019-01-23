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

from libc.string cimport memcpy, memset
from libc.stdint cimport uintptr_t
from libc.stdlib cimport free, malloc
from cpython cimport PyObject, Py_INCREF, PyInt_FromLong, PyFloat_FromDouble

from .ximead cimport (
    XI_OK, XI_INVALID_HANDLE, XI_READREG, XI_WRITEREG,
    XI_FREE_RESOURCES, XI_FREE_CHANNEL, XI_FREE_BANDWIDTH,
    XI_READBLK, XI_WRITEBLK, XI_NO_IMAGE, XI_TIMEOUT,
    XI_INVALID_ARG, XI_NOT_SUPPORTED, XI_ISOCH_ATTACH_BUFFERS,
    XI_GET_OVERLAPPED_RESULT, XI_MEMORY_ALLOCATION, XI_DLLCONTEXTISNULL,
    XI_DLLCONTEXTISNONZERO, XI_DLLCONTEXTEXIST, XI_TOOMANYDEVICES,
    XI_ERRORCAMCONTEXT, XI_UNKNOWN_HARDWARE, XI_INVALID_TM_FILE,
    XI_INVALID_TM_TAG, XI_INCOMPLETE_TM, XI_BUS_RESET_FAILED,
    XI_NOT_IMPLEMENTED, XI_SHADING_TOOBRIGHT, XI_SHADING_TOODARK,
    XI_TOO_LOW_GAIN, XI_INVALID_BPL, XI_BPL_REALLOC,
    XI_INVALID_PIXEL_LIST, XI_INVALID_FFS, XI_INVALID_PROFILE,
    XI_INVALID_CALIBRATION, XI_INVALID_BUFFER, XI_INVALID_DATA,
    XI_TGBUSY, XI_IO_WRONG, XI_ACQUISITION_ALREADY_UP,
    XI_OLD_DRIVER_VERSION, XI_GET_LAST_ERROR, XI_CANT_PROCESS,
    XI_ACQUISITION_STOPED, XI_ACQUISITION_STOPED_WERR,
    XI_INVALID_INPUT_ICC_PROFILE, XI_INVALID_OUTPUT_ICC_PROFILE,
    XI_DEVICE_NOT_READY, XI_SHADING_TOOCONTRAST, XI_ALREADY_INITIALIZED,
    XI_NOT_ENOUGH_PRIVILEGES, XI_NOT_COMPATIBLE_DRIVER,
    XI_TM_INVALID_RESOURCE, XI_DEVICE_HAS_BEEN_RESETED,
    XI_NO_DEVICES_FOUND, XI_RESOURCE_OR_FUNCTION_LOCKED,
    XI_BUFFER_SIZE_TOO_SMALL, XI_COULDNT_INIT_PROCESSOR,
    XI_NOT_INITIALIZED, XI_RESOURCE_NOT_FOUND, XI_UNKNOWN_PARAM,
    XI_WRONG_PARAM_VALUE, XI_WRONG_PARAM_TYPE, XI_WRONG_PARAM_SIZE,
    XI_BUFFER_TOO_SMALL, XI_NOT_SUPPORTED_PARAM, XI_NOT_SUPPORTED_PARAM_INFO,
    XI_NOT_SUPPORTED_DATA_FORMAT, XI_READ_ONLY_PARAM,
    XI_BANDWIDTH_NOT_SUPPORTED, XI_INVALID_FFS_FILE_NAME,
    XI_FFS_FILE_NOT_FOUND, XI_PARAM_NOT_SETTABLE,
    XI_SAFE_POLICY_NOT_SUPPORTED, XI_GPUDIRECT_NOT_AVAILABLE,
    XI_PROC_OTHER_ERROR, XI_PROC_PROCESSING_ERROR,
    XI_PROC_INPUT_FORMAT_UNSUPPORTED, XI_PROC_OUTPUT_FORMAT_UNSUPPORTED,
    XI_OUT_OF_RANGE, xiGetParam, xiSetParam, xiTypeInteger, xiTypeFloat,
    xiTypeString, xiTypeEnum, xiTypeBoolean, xiTypeCommand,
    xiGetNumberDevices, xiGetDeviceInfoString, XI_OPEN_BY_SN,
    xiOpenDevice, xiOpenDeviceBy, xiCloseDevice, xiGetParamInt, xiSetParamInt,
    xiGetParamFloat, xiSetParamFloat, xiGetParamString, XI_MONO8, XI_MONO16,
    XI_RGB24, XI_RGB32, XI_RGB_PLANAR, XI_RAW8, XI_RAW16,
    XI_FRM_TRANSPORT_DATA, XI_RGB48, XI_RGB64, XI_RGB16_PLANAR, XI_RAW8X2,
    XI_RAW8X4, XI_RAW16X2, XI_RAW16X4, XI_BINNING, XI_SKIPPING, xiGetImage,
    XI_IMG, xiStartAcquisition,  xiStopAcquisition)


np.import_array()

cdef extern from "numpy/ndarraytypes.h":
    int NPY_ARRAY_CARRAY_RO

DEF DEBUG = 0
DEF DEFNBUFS = 10
DEF STRLEN = 1024
DEF LONGBUF = 1024*1024

# from Ximea's xidefs.py
VAL_TYPE = {
    "exposure": xiTypeInteger,
    "exposure_burst_count": xiTypeInteger,
    "gain_selector": xiTypeEnum,
    "gain": xiTypeFloat,
    "downsampling": xiTypeEnum,
    "downsampling_type": xiTypeEnum,
    "test_pattern_generator_selector": xiTypeEnum,
    "test_pattern": xiTypeEnum,
    "imgdataformat": xiTypeEnum,
    "shutter_type": xiTypeEnum,
    "sensor_taps": xiTypeEnum,
    "aeag": xiTypeBoolean,
    "aeag_roi_offset_x": xiTypeInteger,
    "aeag_roi_offset_y": xiTypeInteger,
    "aeag_roi_width": xiTypeInteger,
    "aeag_roi_height": xiTypeInteger,
    "bpc_list_selector": xiTypeEnum,
    "sens_defects_corr_list_content": xiTypeString,
    "bpc": xiTypeBoolean,
    "auto_wb": xiTypeBoolean,
    "manual_wb": xiTypeCommand,
    "wb_kr": xiTypeFloat,
    "wb_kg": xiTypeFloat,
    "wb_kb": xiTypeFloat,
    "width": xiTypeInteger,
    "height": xiTypeInteger,
    "offsetX": xiTypeInteger,
    "offsetY": xiTypeInteger,
    "region_selector": xiTypeInteger,
    "region_mode": xiTypeInteger,
    "horizontal_flip": xiTypeBoolean,
    "vertical_flip": xiTypeBoolean,
    "ffc": xiTypeBoolean,
    "ffc_flat_field_file_name": xiTypeString,
    "ffc_dark_field_file_name": xiTypeString,
    "binning_selector": xiTypeEnum,
    "binning_vertical_mode": xiTypeEnum,
    "binning_vertical": xiTypeInteger,
    "binning_horizontal_mode": xiTypeEnum,
    "binning_horizontal": xiTypeInteger,
    "binning_horizontal_pattern": xiTypeEnum,
    "binning_vertical_pattern": xiTypeEnum,
    "decimation_selector": xiTypeEnum,
    "decimation_vertical": xiTypeInteger,
    "decimation_horizontal": xiTypeInteger,
    "decimation_horizontal_pattern": xiTypeEnum,
    "decimation_vertical_pattern": xiTypeEnum,
    "exp_priority": xiTypeFloat,
    "ag_max_limit": xiTypeFloat,
    "ae_max_limit": xiTypeInteger,
    "aeag_level": xiTypeInteger,
    "limit_bandwidth": xiTypeInteger,
    "limit_bandwidth_mode": xiTypeEnum,
    "sensor_line_period": xiTypeFloat,
    "sensor_bit_depth": xiTypeEnum,
    "output_bit_depth": xiTypeEnum,
    "image_data_bit_depth": xiTypeEnum,
    "output_bit_packing": xiTypeBoolean,
    "output_bit_packing_type": xiTypeEnum,
    "iscooled": xiTypeBoolean,
    "cooling": xiTypeEnum,
    "target_temp": xiTypeFloat,
    "temp_selector": xiTypeEnum,
    "temp": xiTypeFloat,
    "device_temperature_ctrl_mode": xiTypeEnum,
    "chip_temp": xiTypeFloat,
    "hous_temp": xiTypeFloat,
    "hous_back_side_temp": xiTypeFloat,
    "sensor_board_temp": xiTypeFloat,
    "device_temperature_element_sel": xiTypeEnum,
    "device_temperature_element_val": xiTypeFloat,
    "cms": xiTypeEnum,
    "cms_intent": xiTypeEnum,
    "apply_cms": xiTypeBoolean,
    "input_cms_profile": xiTypeString,
    "output_cms_profile": xiTypeString,
    "iscolor": xiTypeBoolean,
    "cfa": xiTypeEnum,
    "gammaY": xiTypeFloat,
    "gammaC": xiTypeFloat,
    "sharpness": xiTypeFloat,
    "ccMTX00": xiTypeFloat,
    "ccMTX01": xiTypeFloat,
    "ccMTX02": xiTypeFloat,
    "ccMTX03": xiTypeFloat,
    "ccMTX10": xiTypeFloat,
    "ccMTX11": xiTypeFloat,
    "ccMTX12": xiTypeFloat,
    "ccMTX13": xiTypeFloat,
    "ccMTX20": xiTypeFloat,
    "ccMTX21": xiTypeFloat,
    "ccMTX22": xiTypeFloat,
    "ccMTX23": xiTypeFloat,
    "ccMTX30": xiTypeFloat,
    "ccMTX31": xiTypeFloat,
    "ccMTX32": xiTypeFloat,
    "ccMTX33": xiTypeFloat,
    "defccMTX": xiTypeCommand,
    "trigger_source": xiTypeEnum,
    "trigger_software": xiTypeCommand,
    "trigger_selector": xiTypeEnum,
    "trigger_overlap": xiTypeEnum,
    "acq_frame_burst_count": xiTypeInteger,
    "gpi_selector": xiTypeEnum,
    "gpi_mode": xiTypeEnum,
    "gpi_level": xiTypeInteger,
    "gpo_selector": xiTypeEnum,
    "gpo_mode": xiTypeEnum,
    "led_selector": xiTypeEnum,
    "led_mode": xiTypeEnum,
    "dbnc_en": xiTypeBoolean,
    "dbnc_t0": xiTypeInteger,
    "dbnc_t1": xiTypeInteger,
    "dbnc_pol": xiTypeInteger,
    "lens_mode": xiTypeBoolean,
    "lens_aperture_value": xiTypeFloat,
    "lens_focus_movement_value": xiTypeInteger,
    "lens_focus_move": xiTypeCommand,
    "lens_focus_distance": xiTypeFloat,
    "lens_focal_length": xiTypeFloat,
    "lens_feature_selector": xiTypeEnum,
    "lens_feature": xiTypeFloat,
    "lens_comm_data": xiTypeString,
    "device_name": xiTypeString,
    "device_type": xiTypeString,
    "device_model_id": xiTypeInteger,
    "sensor_model_id": xiTypeInteger,
    "device_sn": xiTypeString,
    "device_sens_sn": xiTypeString,
    "device_id": xiTypeString,
    "device_inst_path": xiTypeString,
    "device_loc_path": xiTypeString,
    "device_user_id": xiTypeString,
    "device_manifest": xiTypeString,
    "image_user_data": xiTypeInteger,
    "imgdataformatrgb32alpha": xiTypeInteger,
    "imgpayloadsize": xiTypeInteger,
    "transport_pixel_format": xiTypeEnum,
    "transport_data_target": xiTypeEnum,
    "sensor_clock_freq_hz": xiTypeFloat,
    "sensor_clock_freq_index": xiTypeInteger,
    "sensor_output_channel_count": xiTypeEnum,
    "framerate": xiTypeFloat,
    "counter_selector": xiTypeEnum,
    "counter_value": xiTypeInteger,
    "acq_timing_mode": xiTypeEnum,
    "available_bandwidth": xiTypeInteger,
    "buffer_policy": xiTypeEnum,
    "LUTEnable": xiTypeBoolean,
    "LUTIndex": xiTypeInteger,
    "LUTValue": xiTypeInteger,
    "trigger_delay": xiTypeInteger,
    "ts_rst_mode": xiTypeEnum,
    "ts_rst_source": xiTypeEnum,
    "isexist": xiTypeBoolean,
    "acq_buffer_size": xiTypeInteger,
    "acq_buffer_size_unit": xiTypeInteger,
    "acq_transport_buffer_size": xiTypeInteger,
    "acq_transport_packet_size": xiTypeInteger,
    "buffers_queue_size": xiTypeInteger,
    "acq_transport_buffer_commit": xiTypeInteger,
    "recent_frame": xiTypeBoolean,
    "device_reset": xiTypeCommand,
    "column_fpn_correction": xiTypeEnum,
    "row_fpn_correction": xiTypeEnum,
    "image_correction_selector": xiTypeEnum,
    "image_correction_value": xiTypeFloat,
    "sensor_mode": xiTypeEnum,
    "hdr": xiTypeBoolean,
    "hdr_kneepoint_count": xiTypeInteger,
    "hdr_t1": xiTypeInteger,
    "hdr_t2": xiTypeInteger,
    "hdr_kneepoint1": xiTypeInteger,
    "hdr_kneepoint2": xiTypeInteger,
    "image_black_level": xiTypeInteger,
    "api_version": xiTypeString,
    "drv_version": xiTypeString,
    "version_mcu1": xiTypeString,
    "version_mcu2": xiTypeString,
    "version_mcu3": xiTypeString,
    "version_fpga1": xiTypeString,
    "version_xmlman": xiTypeString,
    "hw_revision": xiTypeString,
    "debug_level": xiTypeEnum,
    "auto_bandwidth_calculation": xiTypeBoolean,
    "new_process_chain_enable": xiTypeBoolean,
    "cam_enum_golden_enabled": xiTypeBoolean,
    "reset_usb_if_bootloader": xiTypeBoolean,
    "cam_simulators_count": xiTypeInteger,
    "cam_sensor_init_disabled": xiTypeBoolean,
    "read_file_ffs": xiTypeString,
    "write_file_ffs": xiTypeString,
    "ffs_file_name": xiTypeString,
    "ffs_file_id": xiTypeInteger,
    "ffs_file_size": xiTypeInteger,
    "free_ffs_size": xiTypeInteger,
    "used_ffs_size": xiTypeInteger,
    "ffs_access_key": xiTypeInteger,
    "xiapi_context_list": xiTypeString,
    "sensor_feature_selector": xiTypeEnum,
    "sensor_feature_value": xiTypeInteger,
    "ext_feature_selector": xiTypeEnum,
    "ext_feature": xiTypeInteger,
    "device_unit_selector": xiTypeEnum,
    "device_unit_register_selector": xiTypeInteger,
    "device_unit_register_value": xiTypeInteger,
    "api_progress_callback": xiTypeString,
    "acquisition_status_selector": xiTypeEnum,
    "acquisition_status": xiTypeEnum,
    }

cdef check(ret):
    if ret != XI_OK:
        raise Exception(error_string(ret))


cdef str error_string(int e):
    if e == XI_OK:
        return None
    elif e == XI_INVALID_HANDLE:
        return 'Invalid handle'
    elif e == XI_READREG:
        return 'Register read error'
    elif e == XI_WRITEREG:
        return 'Register write error'
    elif e == XI_FREE_RESOURCES:
        return 'Freeing resources error'
    elif e == XI_FREE_CHANNEL:
        return 'Freeing channel error'
    elif e == XI_FREE_BANDWIDTH:
        return 'Freeing bandwith error'
    elif e == XI_READBLK:
        return 'Read block error'
    elif e == XI_WRITEBLK:
        return 'Write block error'
    elif e == XI_NO_IMAGE:
        return 'No image'
    elif e == XI_TIMEOUT:
        return 'Timeout'
    elif e == XI_INVALID_ARG:
        return 'Invalid arguments supplied'
    elif e == XI_NOT_SUPPORTED:
        return 'Not supported'
    elif e == XI_ISOCH_ATTACH_BUFFERS:
        return 'Attach buffers error'
    elif e == XI_GET_OVERLAPPED_RESULT:
        return 'Overlapped result'
    elif e == XI_MEMORY_ALLOCATION:
        return 'Memory allocation error'
    elif e == XI_DLLCONTEXTISNULL:
        return 'DLL context is NULL'
    elif e == XI_DLLCONTEXTISNONZERO:
        return 'DLL context is non zero'
    elif e == XI_DLLCONTEXTEXIST:
        return 'DLL context exists'
    elif e == XI_TOOMANYDEVICES:
        return 'Too many devices connected'
    elif e == XI_ERRORCAMCONTEXT:
        return 'Camera context error'
    elif e == XI_UNKNOWN_HARDWARE:
        return 'Unknown hardware'
    elif e == XI_INVALID_TM_FILE:
        return 'Invalid TM file'
    elif e == XI_INVALID_TM_TAG:
        return 'Invalid TM tag'
    elif e == XI_INCOMPLETE_TM:
        return 'Incomplete TM'
    elif e == XI_BUS_RESET_FAILED:
        return 'Bus reset error'
    elif e == XI_NOT_IMPLEMENTED:
        return 'Not implemented'
    elif e == XI_SHADING_TOOBRIGHT:
        return 'Shading is too bright'
    elif e == XI_SHADING_TOODARK:
        return 'Shading is too dark'
    elif e == XI_TOO_LOW_GAIN:
        return 'Gain is too low'
    elif e == XI_INVALID_BPL:
        return 'Invalid sensor defect correction list'
    elif e == XI_BPL_REALLOC:
        return 'Error while sensor defect correction list reallocation'
    elif e == XI_INVALID_PIXEL_LIST:
        return 'Invalid pixel list'
    elif e == XI_INVALID_FFS:
        return 'Invalid Flash File System'
    elif e == XI_INVALID_PROFILE:
        return 'Invalid profile'
    elif e == XI_INVALID_CALIBRATION:
        return 'Invalid calibration'
    elif e == XI_INVALID_BUFFER:
        return 'Invalid buffer'
    elif e == XI_INVALID_DATA:
        return 'Invalid data'
    elif e == XI_TGBUSY:
        return 'Timing generator is busy'
    elif e == XI_IO_WRONG:
        return 'Wrong operation open/write/read/close'
    elif e == XI_ACQUISITION_ALREADY_UP:
        return 'Acquisition already started'
    elif e == XI_OLD_DRIVER_VERSION:
        return 'Old version of device driver installed to the system.'
    elif e == XI_GET_LAST_ERROR:
        return 'To get error code please call GetLastError function.'
    elif e == XI_CANT_PROCESS:
        return 'Data cannot be processed'
    elif e == XI_ACQUISITION_STOPED:
        return 'Acquisition is stopped. It needs to be started.'
    elif e == XI_ACQUISITION_STOPED_WERR:
        return 'Acquisition has been stopped with an error.'
    elif e == XI_INVALID_INPUT_ICC_PROFILE:
        return 'Input ICC profile missing or corrupted'
    elif e == XI_INVALID_OUTPUT_ICC_PROFILE:
        return 'Output ICC profile missing or corrupted'
    elif e == XI_DEVICE_NOT_READY:
        return 'Device not ready to operate'
    elif e == XI_SHADING_TOOCONTRAST:
        return 'Shading is too contrast'
    elif e == XI_ALREADY_INITIALIZED:
        return 'Module already initialized'
    elif e == XI_NOT_ENOUGH_PRIVILEGES:
        return 'Application does not have enough privileges (one or more app)'
    elif e == XI_NOT_COMPATIBLE_DRIVER:
        return 'Installed driver is not compatible with current software'
    elif e == XI_TM_INVALID_RESOURCE:
        return 'TM file was not loaded successfully from resources'
    elif e == XI_DEVICE_HAS_BEEN_RESETED:
        return 'Device has been reset, abnormal initial state'
    elif e == XI_NO_DEVICES_FOUND:
        return 'No Devices Found'
    elif e == XI_RESOURCE_OR_FUNCTION_LOCKED:
        return 'Resource (device) or function locked by mutex'
    elif e == XI_BUFFER_SIZE_TOO_SMALL:
        return 'Buffer provided by user is too small'
    elif e == XI_COULDNT_INIT_PROCESSOR:
        return 'Couldnt initialize processor.'
    elif e == XI_NOT_INITIALIZED:
        return 'The object being referred to has not been started.'
    elif e == XI_RESOURCE_NOT_FOUND:
        return 'Resource not found.'
    elif e == XI_UNKNOWN_PARAM:
        return 'Unknown parameter'
    elif e == XI_WRONG_PARAM_VALUE:
        return 'Wrong parameter value'
    elif e == XI_WRONG_PARAM_TYPE:
            return 'Wrong parameter type'
    elif e == XI_WRONG_PARAM_SIZE:
        return 'Wrong parameter size'
    elif e == XI_BUFFER_TOO_SMALL:
            return 'Input buffer is too small'
    elif e == XI_NOT_SUPPORTED_PARAM:
        return 'Parameter is not supported'
    elif e == XI_NOT_SUPPORTED_PARAM_INFO:
        return 'Parameter info not supported'
    elif e == XI_NOT_SUPPORTED_DATA_FORMAT:
        return 'Data format is not supported'
    elif e == XI_READ_ONLY_PARAM:
        return 'Read only parameter'
    elif e == XI_BANDWIDTH_NOT_SUPPORTED:
        return 'Bandwidth not supported'
    elif e == XI_INVALID_FFS_FILE_NAME:
        'FFS file selector is invalid or NULL'
    elif e == XI_FFS_FILE_NOT_FOUND:
        return 'FFS file not found'
    elif e == XI_PARAM_NOT_SETTABLE:
        return 'Parameter value cannot be set'
    elif e == XI_SAFE_POLICY_NOT_SUPPORTED:
        return 'Safe buffer policy is not supported'
    elif e == XI_GPUDIRECT_NOT_AVAILABLE:
        return 'GPUDirect is not available'
    elif e == XI_PROC_OTHER_ERROR:
        return 'Other processing error'
    elif e == XI_PROC_PROCESSING_ERROR:
        return 'Error while image processing'
    elif e == XI_PROC_INPUT_FORMAT_UNSUPPORTED:
        return 'Input format is not supported for processing'
    elif e == XI_PROC_OUTPUT_FORMAT_UNSUPPORTED:
        return 'Output format is not supported for processing'
    elif e == XI_OUT_OF_RANGE:
        return 'Parameter value is out of range'
    else:
        return f'Unknown error {e}'


cdef class BufWrap:
    cdef int safe
    cdef int size
    cdef uintptr_t data

    cdef np.npy_intp shape[2]
    cdef np.npy_intp strides[2]
    cdef int dtype

    cdef allocate(self, int size, int safe):
        self.size = size
        self.safe = safe
        
        if self.safe:
            self.data = <uintptr_t>malloc(size)
            if not self.data:
                raise MemoryError('cannot allocate buffer')
        else:
            self.data = 0

        if DEBUG:
            print(
                f'BufWrap alloc {self.data:x} siz:{self.size} saf:{self.safe}')

    def __array__(self):
        ndarray = np.PyArray_New(
            np.ndarray, 2, self.shape, self.dtype, self.strides,
            <void*>self.data, 0, NPY_ARRAY_CARRAY_RO, 0)
        return ndarray

    def __dealloc__(self):
        if DEBUG:
            print(
                f'BufWrap free {self.data:x} siz:{self.size} saf:{self.safe}')
        if self.safe:
            free(<void*>self.data)

    def get_data(self):
        return self.data

    def set_data(self, uintptr_t data):
        self.data = data

    def set_params(
            self,
            unsigned long shape0, unsigned long shape1,
            unsigned long stride0, unsigned long stride1,
            int dtype):
        self.shape[0] = shape0
        self.shape[1] = shape1
        self.strides[0] = stride0
        self.strides[1] = stride1
        self.dtype = dtype

    def get_size(self):
        return self.size

    def get_safe(self):
        return self.safe

    def detach(self):
        cdef uintptr_t olddata

        if not self.safe and self.data != 0:
            olddata = self.data
            self.data = 0
            self.data = <uintptr_t>malloc(self.size)
            if not self.data:
                raise MemoryError('cannot allocate buffer')
            memcpy(<void*>self.data, <const void*>olddata, self.size)
            self.safe = 1
            if DEBUG:
                print(
                    f'BufWrap det {self.data:x} siz:{self.size} ' +
                    f'saf:{self.safe}')


cdef class Ximea:

    cdef void *dev

    cdef dict imgformats
    cdef tuple imgformats_keys
    cdef tuple imgformats_vals
    cdef tuple supported_formats

    cdef list bufwraps
    cdef int nbufs
    cdef int safe
    cdef int lastBufInd
    cdef int bufdtype
    cdef int bufstride1

    cdef int liveMode

    def __cinit__(self):
        self.dev = NULL

        self.imgformats = {
                'MONO8':                XI_MONO8,
                'MONO16':               XI_MONO16,
                'RGB24':                XI_RGB24,
                'RGB32':                XI_RGB32,
                'RGB_PLANAR':           XI_RGB_PLANAR,
                'RAW8':                 XI_RAW8,
                'RAW16':                XI_RAW16,
                'FRM_TRANSPORT_DATA':   XI_FRM_TRANSPORT_DATA,
                'RGB48':                XI_RGB48,
                'RGB64':                XI_RGB64,
                'RGB16_PLANAR':         XI_RGB16_PLANAR,
                'RAW8X2':               XI_RAW8X2,
                'RAW8X4':               XI_RAW8X4,
                'RAW16X2':              XI_RAW16X2,
                'RAW16X4':              XI_RAW16X4,
                }
        self.imgformats_keys = tuple(self.imgformats.keys())
        self.imgformats_vals = tuple(self.imgformats.values())
        self.supported_formats = (
            XI_MONO8, XI_MONO16, XI_RAW8, XI_RAW16, XI_RAW8X2)

        self.bufwraps = []
        self.safe = 0
        self.nbufs = DEFNBUFS
        self.lastBufInd = 0
        self.bufdtype = 0
        self.bufstride1 = 0
        self.liveMode = 0

    def get_number_of_cameras(self):
        cdef unsigned long num
        
        check(xiGetNumberDevices(&num))
        return num

    def get_devices(self):
        cdef unsigned long num
        cdef char sn[STRLEN]
        cdef devs = []
        
        check(xiGetNumberDevices(&num))
        for i in range(num):
            check(xiGetDeviceInfoString(i, "device_sn", sn, STRLEN))
            devs.append(sn.decode('utf-8'))

        return devs

    def open(self, str serial=None, int safe=1):
        cdef unsigned long num

        if self.dev != NULL and serial is not None:
            # camera already opened but a name specified
            raise Exception('Camera already opened')
        elif self.dev != NULL:
            # open has been called twice, keep quiet
            return

        if serial is None:
            check(xiGetNumberDevices(&num))
            if num <= 0:
                raise Exception('No camera found')
            check(xiOpenDevice(0, &self.dev))
        else:
            str1 = serial
            check(xiOpenDeviceBy(
                XI_OPEN_BY_SN, serial.encode('utf-8'), &self.dev))

        assert(self.dev)
        self.safe = safe
        if self.safe:
            self.nbufs = DEFNBUFS

        self._init_bufs()

    def _get_dtype(self, int fmt):
        if fmt in (XI_MONO8, XI_RAW8):
            return np.NPY_UINT8
        elif fmt in (XI_MONO16, XI_RAW16, XI_RAW8X2):
            return np.NPY_UINT16
        else:
            raise NotImplementedError(
                'Format ' +
                self.imgformats_keys[self.imgformats_vals.index(fmt)] +
                ' not supported')

    def _init_bufs(self):
        cdef int size
        cdef int fmt
        cdef int ret

        check(xiSetParamInt(self.dev, 'buffer_policy', self.safe))

        if not self.safe and len(self.bufwraps) == 1:
            self.bufwraps[0].detach()
        self.bufwraps.clear()

        if self.safe and self.nbufs < 2:
            self.nbufs = 2
        elif not self.safe:
            self.nbufs = 1

        check(xiGetParamInt(self.dev, 'imgdataformat', &fmt))
        if fmt not in self.supported_formats:
            ret = xiSetParamInt(self.dev, 'imgdataformat',
                self.imgformats['MONO8'])
            if ret != XI_OK:
                raise NotImplementedError(
                    'Only ' + ', '.join([
                        self.imgformats_keys[self.imgformats_vals.index(d)]
                        for d in self.supported_formats]))

        self.bufdtype = self._get_dtype(fmt)
        if self.bufdtype == np.NPY_UINT8:
            self.bufstride1 = 1
        elif self.bufdtype == np.NPY_UINT16:
            self.bufstride1 = 2
        else:
            raise NotImplementedError(f'Unknown stride for {self.bufstride1}')
        
        check(xiGetParamInt(self.dev, 'imgpayloadsize', &size))
        for i in range(self.nbufs):
            bw = BufWrap()
            bw.allocate(size, self.safe)
            self.bufwraps.append(bw)

    def close(self):
        if self.dev:
            if not self.safe and len(self.bufwraps) == 1:
                self.bufwraps[0].detach()

            self.bufwraps.clear()
            self.lastBufInd = 0
            self.bufdtype = 0
            self.bufstride1 = 0
            self.liveMode = 0

            check(xiCloseDevice(self.dev))
            self.dev = NULL

    def shape(self):
        cdef int width
        cdef int height

        if self.dev:
            check(xiGetParamInt(self.dev, 'width', &width))
            check(xiGetParamInt(self.dev, 'height', &height))
            return (height, width)
        else:
            return None

    def get_serial_number(self):
        cdef char sn[STRLEN]

        if self.dev:
            check(xiGetParamString(self.dev, 'device_sn', sn, STRLEN))
            return sn.decode('utf-8')
        else:
            return None

    def set_exposure(self, double exp):
        "Set exposure in ms."
        cdef int i

        if self.dev:
            i = int(exp*1000)
            check(xiSetParamInt(self.dev, 'exposure', i))
            check(xiGetParamInt(self.dev, 'exposure', &i))
            return i/1000
        else:
            return 0.

    def get_exposure(self):
        "Get exposure in ms."
        cdef int i

        if self.dev:
            check(xiGetParamInt(self.dev, 'exposure', &i))
            return i/1e3
        else:
            return 0.

    def get_exposure_range(self):
        """Get exposure range.

        Returns
        -------
        -   `(min, max, step)`: exposure range

        """
        cdef int i0
        cdef int i1
        cdef int i2

        if self.dev:
            check(xiGetParamInt(self.dev, 'exposure:min', &i0))
            check(xiGetParamInt(self.dev, 'exposure:max', &i1))
            check(xiGetParamInt(self.dev, 'exposure:inc', &i2))

            return (1e-3*i0, 1e-3*i1, 1e-3*i2)
        else:
            return None

    def set_framerate(self, float fps):
        if self.dev:
            check(xiSetParamFloat(self.dev, 'framerate', fps))
            check(xiGetParamFloat(self.dev, 'framerate', &fps))

            return fps
        else:
            return 0.

    def get_framerate(self):
        cdef float f

        if self.dev:
            check(xiGetParamFloat(self.dev, 'framerate', &f))
            return f
        else:
            return 0.

    def get_framerate_range(self):
        cdef float f0
        cdef float f1
        cdef float f2

        if self.dev:
            check(xiGetParamFloat(self.dev, 'framerate:min', &f0))
            check(xiGetParamFloat(self.dev, 'framerate:max', &f1))
            check(xiGetParamFloat(self.dev, 'framerate:inc', &f2))

            return (f0, f1, f2)
        else:
            return None

    def get_pixel_size(self):
        "Get pixel size (height, width) in um."
        cdef char sn[STRLEN]
        cdef str sn1

        if self.dev:
            check(xiGetParamString(self.dev, 'device_name', sn, STRLEN))
            sn1 = sn.decode('utf-8')
            if sn1.endswith('-UB'):
                sn1 = sn1.rstrip('-UB')

            if sn1 in ['MQ003MG-CM', 'MQ003CG-CM']:
                return (7.4, 7.4)
            elif sn1 in ['MQ013MG-E2', 'MQ013CG-E2', 'MQ013RG-E2']:
                return (5.3, 5.3)
            elif sn1 in ['MQ013MG-ON', 'MQ013CG-ON']:
                return (4.8, 4.8)
            elif sn1 in [
                    'MQ022MG-CM', 'MQ022CG-CM', 'MQ022RG-CM',
                    'MQ042MG-CM', 'MQ042CG-CM', 'MQ042RG-CM']:
                return (5.5, 5.5)
            elif sn1 in [
                    'MC023MG-SY', 'MC023CG-SY']:
                return (5.86, 5.86)
            elif sn1 in [
                    'MC031MG-SY', 'MC031CG-SY', 'MC050MG-SY',
                    'MC050CG-SY', 'MC089MG-SY', 'MC089CG-SY',
                    'MC124MG-SY', 'MC124CG-SY'
                    ]:
                return (3.45, 3.45)
            else:
                raise ValueError(f'Unknown pixel size for model {sn1}')
        else:
            return None

    def get_camera_model(self):
        cdef char sn[STRLEN]

        if self.dev:
            check(xiGetParamString(self.dev, 'device_name', sn, STRLEN))
            return sn.decode('utf-8')
        else:
            return None

    def set_gain(self, float fps):
        if self.dev:
            check(xiSetParamFloat(self.dev, 'gain', fps))
            check(xiGetParamFloat(self.dev, 'gain', &fps))

            return fps
        else:
            return 0.

    def get_gain(self):
        cdef float f

        if self.dev:
            check(xiGetParamFloat(self.dev, 'gain', &f))
            return f
        else:
            return 0.

    def get_gain_range(self):
        cdef float f0
        cdef float f1
        cdef float f2

        if self.dev:
            check(xiGetParamFloat(self.dev, 'gain:min', &f0))
            check(xiGetParamFloat(self.dev, 'gain:max', &f1))
            check(xiGetParamFloat(self.dev, 'gain:inc', &f2))

            return (f0, f1, f2)
        else:
            return None

    def get_settings(self):
        """Save camera settings into an string."""
        cdef char sn[LONGBUF]

        if self.dev:
            check(xiGetParamString(self.dev, "device_manifest", sn, LONGBUF))
            return sn.decode('utf-8')

        else:
            return None

    def get_sensor_bit_depth(self):
        cdef int i

        if self.dev:
            check(xiGetParamInt(self.dev, 'sensor_bit_depth', &i))
            return i
        else:
            return 0

    def get_output_bit_depth(self):
        cdef int i

        if self.dev:
            check(xiGetParamInt(self.dev, 'output_bit_depth', &i))
            return i
        else:
            return 0

    def get_image_bit_depth(self):
        cdef int i

        if self.dev:
            check(xiGetParamInt(self.dev, 'image_data_bit_depth', &i))
            return i
        else:
            return 0

    def get_image_max(self):
        cdef int i

        if self.dev:
            check(xiGetParamInt(self.dev, 'image_data_bit_depth', &i))
            return 2**i - 1
        else:
            return 0

    def get_image_data_format(self):
        cdef int i
        cdef int p

        if self.dev:
            check(xiGetParamInt(self.dev, 'imgdataformat', &i))
            if i not in self.imgformats_vals:
                raise NotImplementedError(f'imgdataformat {i}')
            p = self.imgformats_vals.index(i)
            return self.imgformats_keys[p]
        else:
            return None

    def get_image_data_format_range(self):
        return self.imgformats_keys

    def set_image_data_format(self, str fmt):
        cdef int i

        if self.dev:
            if fmt not in self.imgformats.keys():
                raise ValueError(f'{fmt} not recognised')
            else:
                i = self.imgformats[fmt]
                check(xiSetParamInt(self.dev, 'imgdataformat', i))

            self._init_bufs()
        else:
            raise ValueError('Camera not opened')

    def get_image_dtype(self):
        cdef int fmt

        check(xiGetParamInt(self.dev, 'imgdataformat', &fmt))
        assert(self.bufdtype == self._get_dtype(fmt))

        if self.dev:
            if self.bufdtype == np.NPY_UINT8:
                return 'uint8' 
            elif self.bufdtype == np.NPY_UINT16:
                return 'uint16'
            else:
                raise NotImplementedError(f'Image format {fmt}')
        else:
            return None

    def get_downsampling(self):
        cdef int d
        cdef int t

        if self.dev:
            check(xiGetParamInt(self.dev, 'downsampling', &d))
            check(xiGetParamInt(self.dev, 'downsampling_type', &t))
            if t == XI_BINNING:
                return (d, 'BINNING')
            elif t == XI_SKIPPING:
                return (d, 'SKIPPING')
            else:
                raise NotImplementedError(f'Image format {t}')
        else:
            return None

    def set_downsampling(self, int d=1, str ds_type='BINNING'):
        if not self.dev:
            raise ValueError('Camera not opened')
        else:
            if ds_type not in ('BINNING', 'SKIPPING'):
                raise ValueError(f'Unknown downsampling type {ds_type}')

            check(xiSetParamInt(self.dev, 'downsampling', d))
            if ds_type == 'BINNING':
                check(xiSetParamInt(self.dev, 'downsampling_type', XI_BINNING))
            elif ds_type == 'SKIPPING':
                check(xiSetParamInt(self.dev, 'downsampling_type', XI_SKIPPING))

            self._init_bufs()

    def get_param(self, str name, int bufsize=512):
        cdef void *buf
        cdef unsigned long size
        cdef int type1
        cdef int ret
        cdef str p1
        cdef object obj

        if self.dev:
            p1 = name.split(':', 1)[0]
            if p1 not in VAL_TYPE.keys():
                raise ValueError(f'Unknown parameter {name}')
            elif bufsize <= 0:
                raise ValueError(f'bufsize must be positive')

            type1 = VAL_TYPE[p1]
            buf = malloc(sizeof(char)*bufsize)
            if buf == NULL:
                raise MemoryError('get_param')
            size = bufsize

            # presumably for the future
            if type1 in (xiTypeEnum, xiTypeBoolean, xiTypeCommand):
                type1 = xiTypeInteger

            ret = xiGetParam(
                self.dev, name.encode('utf-8'), buf, &size, &type1)
            if ret != XI_OK:
                free(buf)
                raise Exception(error_string(ret))
            else:
                if type1 in (
                        xiTypeInteger, xiTypeEnum, xiTypeBoolean,
                        xiTypeCommand):
                    obj = PyInt_FromLong((<int *>buf)[0])
                    assert(size == 4)
                elif type1 == xiTypeFloat:
                    floatp = <float *>buf
                    obj = PyFloat_FromDouble((<float *>buf)[0])
                    assert(size == 4)
                elif type1 == xiTypeString:
                    obj = ((<char *>buf)[:size]).decode('utf-8')
                else:
                    free(buf)
                    raise Exception(f'Unknown object type {type1}')
    
                free(buf)
                return obj

    def set_param(self, str name, value):
        cdef void *buf
        cdef unsigned long bufsize
        cdef int type1
        cdef int ret
        cdef str p1
        cdef object obj

        cdef int int1
        cdef float float1
        cdef int *intp
        cdef float *floatp
        cdef char *charp

        if self.dev:
            p1 = name.split(':', 1)[0]
            if p1 not in VAL_TYPE.keys():
                raise ValueError(f'Unknown parameter {name}')

            type1 = VAL_TYPE[p1]
            # presumably for the future
            if type1 in (xiTypeEnum, xiTypeBoolean, xiTypeCommand):
                type1 = xiTypeInteger

            if type1 in (
                        xiTypeInteger, xiTypeEnum, xiTypeBoolean,
                        xiTypeCommand):
                int1 = int(value)
                bufsize = sizeof(int)
                buf = malloc(sizeof(char)*bufsize)
                if buf == NULL:
                    raise MemoryError('set_param')
                intp = <int *>buf
                intp[0] = int1
            elif type1 == xiTypeFloat:
                float1 = <float>float(value)
                bufsize = sizeof(float)
                buf = malloc(sizeof(char)*bufsize)
                if buf == NULL:
                    raise MemoryError('set_param')
                floatp = <float *>buf
                floatp[0] = float1
            elif type1 == xiTypeString:
                value = str(value)
                bufsize = <unsigned long>len(value) + 1
                buf = malloc(sizeof(char)*bufsize)
                if buf == NULL:
                    raise MemoryError('set_param')
                charp = <char *>buf
                charp[:len(value)] = (value.encode())[:len(value)]
                charp[len(value)] = 0
            else:
                raise Exception(f'Unknown object type {type1}')

            ret = xiSetParam(
                self.dev, name.encode('utf-8'), buf, bufsize, type1)

            if ret != XI_OK:
                free(buf)
                raise Exception(error_string(ret))
            else:
                free(buf)

            self._init_bufs()

    def start_video(self):
        if not self.liveMode:
            if not self.safe and len(self.bufwraps) == 1:
                self.bufwraps[0].detach()
            ret = xiStartAcquisition(self.dev)
            if ret != XI_OK:
                xiStopAcquisition(self.dev)
                self.liveMode = 0
                self.lastBufInd = 0
                check(ret)
            else:
                self.liveMode = 1

    def stop_video(self):
        if self.liveMode:
            if not self.safe and len(self.bufwraps) == 1:
                self.bufwraps[0].detach()
            ret = xiStopAcquisition(self.dev)
            if ret != XI_OK:
                self.liveMode = 0
                self.lastBufInd = 0
                check(ret)
            else:
                self.liveMode = 0

    def grab_image(self, int wait=0xffffffff):
        """Acquire a single image.

        Parameters
        ----------
        - `wait`: timeout in milliseconds

        Returns
        -------
        - `img`: `numpy` image

        """
        cdef XI_IMG img
        cdef int ret
        cdef int bufsizecheck
        cdef int safecheck
        cdef object buf
        cdef uintptr_t dataptr
        cdef unsigned long stride0
        cdef unsigned long stride1
        cdef np.ndarray ndarray

        if not self.dev:
            return None

        if wait <= 0:
            wait2 = 0xffffffff
        else:
            wait2 = wait

        if not self.liveMode:
            ret = xiStartAcquisition(self.dev)
            if ret != XI_OK:
                xiStopAcquisition(self.dev)
                self.liveMode = 0
                self.lastBufInd = 0
                check(ret)

        memset(&img, 0, sizeof(img))
        img.size = sizeof(img)
        if self.safe:
            buf = self.bufwraps[self.lastBufInd]
            dataptr = buf.get_data()
            img.bp = <void *>dataptr
            img.bp_size = buf.get_size()
        else:
            buf = self.bufwraps[0]

        if DEBUG:
            check(xiGetParamInt(self.dev, 'buffer_policy', &safecheck))
            check(xiGetParamInt(self.dev, 'imgpayloadsize', &bufsizecheck))
            assert(bufsizecheck == buf.get_size())
            assert(self.safe == safecheck)
            assert(self.safe == buf.get_safe())

        ret = xiGetImage(self.dev, wait2, &img)
        if ret != XI_OK:
            xiStopAcquisition(self.dev)
            self.liveMode = 0
            self.lastBufInd = 0
            check(ret)

        if not self.safe:
            buf.set_data(<uintptr_t>img.bp)

        stride0 = img.width*self.bufstride1 + img.padding_x
        buf.set_params(
            img.height, img.width, stride0, self.bufstride1, self.bufdtype)
        if self.safe:  # not apparently set in unsafe mode
            assert(stride0*img.height == img.bp_size)
        assert(stride0*img.height <= buf.get_size())

        if not self.liveMode:
            ret = xiStopAcquisition(self.dev)
            if ret != XI_OK:
                self.liveMode = 0
                self.lastBufInd = 0
                check(ret)

        if self.safe:
            self.lastBufInd += 1
            self.lastBufInd %= self.nbufs

        if DEBUG:
            assert(self.lastBufInd >= 0)
            assert(self.lastBufInd <= self.nbufs)

        ndarray = np.array(buf, copy=False)
        ndarray.base = <PyObject*>buf
        Py_INCREF(buf)
        
        return ndarray
