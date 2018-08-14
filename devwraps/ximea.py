#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import numpy as np

from ximea import xiapi


# TODO fix this horrible stub


class Ximea:

    serials = None
    cam = None
    opened = False
    img = None

    def __init__(self):
        self.serials = []
        ndevs = xiapi.Camera().get_number_devices()
        for i in range(ndevs):
            ci = xiapi.Camera(dev_id=i)
            ci.open_device()
            self.serials.append(ci.get_device_sn().decode('utf-8'))
            ci.close_device()

    def open(self, serial=None):
        if self.opened and serial is None:
            return
        elif self.opened:
            raise ValueError(
                self.cam.get_device_sn().decode('utf-8') +
                ' device already opened')

        if serial is None:
            self.cam = xiapi.Camera()
        else:
            self.cam = xiapi.Camera(dev_id=self.serials.index(serial))
        self.cam.open_device()
        self.img = xiapi.Image()
        self.opened = True

    def close(self):
        if self.opened:
            self.cam.close_device()
            self.img = None
            self.cam = None
            self.opened = False

    def get_number_of_cameras(self):
        return len(self.serial)

    def get_devices(self):
        return list(self.serials)

    def get_serial_number(self):
        if self.opened:
            return self.cam.get_device_sn().decode('utf-8')
        else:
            return None

    def shape(self):
        if self.opened:
            return (self.cam.get_height(), self.cam.get_width())
        else:
            return None

    def get_framerate(self):
        if self.opened:
            return self.cam.get_framerate()
        else:
            return None

    def set_framerate(self, fps):
        if self.opened:
            self.cam.set_framerate(fps)
            return self.cam.get_framerate()
        else:
            return None

    def get_framerate_range(self):
        if self.opened:
            return (
                self.cam.get_framerate_minimum(),
                self.cam.get_framerate_maximum(),
                self.cam.get_framerate_increment())
        else:
            return None

    def get_exposure(self):
        if self.opened:
            return self.cam.get_exposure()/1e3
        else:
            return None

    def set_exposure(self, fps):
        if self.opened:
            self.cam.set_exposure(int(fps*1e3))
            return self.cam.get_exposure()/1e3
        else:
            return None

    def get_exposure_range(self):
        if self.opened:
            return (
                self.cam.get_exposure_minimum()/1e3,
                self.cam.get_exposure_maximum()/1e3,
                self.cam.get_exposure_increment()/1e3)
        else:
            return None

    def get_pixel_size(self):
        if self.opened:
            return (5.3, 5.3)
        else:
            return None

    def get_image_max(self):
        if self.opened:
            num = self.cam.get_image_data_bit_depth()
            if num == 'XI_BPP_8':
                return 2**8 - 1
            elif num == 'XI_BPP_16':
                return 2**16 - 1
            else:
                raise NotImplementedError()
        else:
            return 0

    def get_image_dtype(self):
        if self.opened:
            num = self.cam.get_image_data_bit_depth()
            if num == 'XI_BPP_8':
                return 'uint8'
            elif num == 'XI_BPP_16':
                return 'uint16'
            else:
                raise NotImplementedError()
        else:
            return 0

    def start_video(self):
        self.cam.start_acquisition()

    def stop_video(self):
        self.cam.stop_acquisition()

    def grab_image(self):
        if not self.opened:
            return None

        self.cam.start_acquisition()
        self.cam.get_image(self.img)
        self.cam.stop_acquisition()

        img = self.img.get_image_data_numpy()

        return img

    def get_settings(self):
        "Save camera settings into an string."
        if not self.opened:
            raise Exception('Camera not opened')
        else:
            return self.cam.get_device_manifest(
                buffer_size=512*1024).decode('utf-8')
