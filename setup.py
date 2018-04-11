#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""

author: J. Antonello <jacopo.antonello@dpag.ox.ac.uk>
date: Mon Feb 26 07:29:11 GMT 2018

"""

# https://github.com/cython/cython/wiki/CythonExtensionsOnWindows
# https://matthew-brett.github.io/pydagogue/python_msvc.html
# http://landinghub.visualstudio.com/visual-cpp-build-tools
# MSVC 2015 command line tools

import os
import numpy
import re

from os import path
from shutil import copyfile
from distutils.core import setup
from distutils.extension import Extension
from Cython.Build import cythonize

# python setup.py build_ext --inplace

PROGFILES = os.environ['PROGRAMFILES']


def make_ciusb(fillout, remove):
    dir1 = path.join(PROGFILES, r'Boston Micromachines\Usb\CIUsbLib')
    f1 = path.join(
        PROGFILES,
        r'Boston Micromachines\Usb\Examples\UsbExMulti\_CIUsbLib.tlb')
    dst = path.join('ciusb', '_CIUsbLib.tlb')

    if not path.isdir(dir1):
        return

    copyfile(f1, dst)
    fillout.append(Extension(
        'ciusb', [r'ciusb\ciusb.pyx', r'ciusb\cciusb.cpp'],
        include_dirs=['ciusb', numpy.get_include(), dir1],
        library_dirs=[dir1],
        libraries=['CIUsbLib'],
        language='c++',
    ))
    remove.append(dst)


def make_bmc(fillout, remove):
    dir1 = path.join(PROGFILES, r'Boston Micromachines\Lib64')
    dir2 = path.join(PROGFILES, r'Boston Micromachines\Include')

    if not path.isdir(dir1) or not path.isdir(dir2):
        return

    fillout.append(Extension(
        'bmc', [r'bmc\bmc.pyx'],
        include_dirs=['bmc', numpy.get_include(), dir2],
        library_dirs=[dir1],
        libraries=['BMC2'],
    ))


def make_thorcam(fillout, remove):
    p1 = r'Thorlabs\Scientific Imaging\DCx Camera Support\Develop'
    dir1 = path.join(PROGFILES, p1, r'Include')
    dir2 = path.join(PROGFILES, p1, r'Lib')
    pristine = path.join(dir1, 'uc480.h')
    patched = path.join('thorcam', 'uc480.h')

    if not path.isdir(dir1) or not path.isdir(dir2):
        return

    with open(pristine, 'r') as f:
        incl = f.read()
    incl = re.sub(r'#define IS_SENSOR_C1280G12M *0x021E', '', incl, 1)
    incl = re.sub(r'#define IS_SENSOR_C1280G12C *0x021F', '', incl, 1)
    incl = re.sub(r'#define IS_SENSOR_C1280G12N *0x0220', '', incl, 1)
    incl = re.sub(r'extern "C" __declspec', r'extern __declspec', incl, 2)
    with open(patched, 'w') as f:
        f.write(incl)

    fillout.append(Extension(
        'thorcam', [r'thorcam\thorcam.pyx'],
        include_dirs=['thorcam', numpy.get_include()],
        library_dirs=[dir2],
        libraries=['uc480_64'],
    ))
    remove.append(patched)


exts = []
remove = []
make_ciusb(exts, remove)
make_bmc(exts, remove)
make_thorcam(exts, remove)
print('exts', exts)

setup(ext_modules=cythonize(exts, compiler_directives={'language_level': 3}),)

try:
    for f in remove:
        os.remove(f)
except OSError:
    pass
