#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import numpy as np

from ximea import xiapi


class ximea:

    serials = None
    cam = None
    opened = False
    img = None

    def __init__(self):
        self.serials = []
        ndevs = xiapi.Camera().get_number_devices()
        for i in range(ndevs):
            ci = xiapi.Camera(dev_id=i)
            self.serials.append(ci.get_device_sn())

    def open(self, serial=None):
        if self.opened and serial is None:
            return
        elif self.opened:
            raise ValueError(
                self.cam.get_device_sn() + ' device already opened')

        if serial is None:
            self.cam = xiapi.Camera()
        else:
            self.cam = xiapi.Camera(dev_id=self.serial.index(serial))
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
            return self.cam.get_device_sn()
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
            return self.cam.get_exposure()
        else:
            return None

    def set_exposure(self, fps):
        if self.opened:
            self.cam.set_exposure(fps)
            return self.cam.get_exposure()
        else:
            return None

    def get_exposure_range(self):
        if self.opened:
            return (
                self.cam.get_exposure_minimum(),
                self.cam.get_exposure_maximum(),
                self.cam.get_exposure_increment())
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
            return 2**num - 1
        else:
            return 0

    def get_image_dtype(self):
        if self.opened:
            num = self.cam.get_image_data_bit_depth()
            if num <= 8:
                return np.uint8
            elif num <= 16:
                return np.uint16
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
        assert(img.dtype == self.cam.get_image_dtype)

        return img
