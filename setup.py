#!/usr/bin/env python3
# -*- coding: utf-8 -*-

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

# https://github.com/cython/cython/wiki/CythonExtensionsOnWindows
# https://matthew-brett.github.io/pydagogue/python_msvc.html
# http://landinghub.visualstudio.com/visual-cpp-build-tools

# To compile install MSVC 2015 command line tools and run
# python setup.py build_ext --inplace


import sys
import os
import numpy
import re
import subprocess

from subprocess import check_output
from os import path
from shutil import copyfile
from setuptools import setup
from setuptools.extension import Extension
from Cython.Build import cythonize


here = path.abspath(path.dirname(__file__))
with open(path.join(here, 'README.md'), encoding='utf-8') as f:
    long_description = f.read()

PROGFILES = os.environ['PROGRAMFILES']
WINDIR = os.environ['WINDIR']


def update_version():
    try:
        check_output('git --version', universal_newlines=True, shell=True)
    except Exception:
        raise RuntimeError(
            'Git must be installed and added to the PATH ' +
            '(https://stackoverflow.com/questions/19290899)')

    try:
        subprocess.call(['git', 'config', 'core.autocrlf', 'true'])
        subprocess.call(['git', 'config', 'core.fileMode', 'false'])
        toks = check_output(
            'git describe --tags --long --dirty', universal_newlines=True,
            shell=True).strip().split('-')
        version = toks[0].strip('v') + '+' + toks[1] + '.' + toks[2]
        if toks[-1] == 'dirty':
            version += '.dirty'
        last = check_output(
            'git log -n 1', universal_newlines=True, shell=True)
        date = re.search(
            r'^Date:\s+([^\s].*)$', last, re.MULTILINE).group(1)
        commit = re.search(
            r'^commit\s+([^\s]{40})', last, re.MULTILINE).group(1)

        with open(
                path.join('devwraps', 'version.py'), 'w', newline='\n') as f:
            f.write('#!/usr/bin/env python3\n')
            f.write('# -*- coding: utf-8 -*-\n\n')
            f.write(f"__version__ = '{version}'\n")
            f.write(f"__date__ = '{date}'\n")
            f.write(f"__commit__ = '{commit}'")
        subprocess.call(['git', 'config', '--unset', 'core.autocrlf'])
        subprocess.call(['git', 'config', '--unset', 'core.fileMode'])
    except Exception as e:
        print(f'Cannot update version: {str(e)}', file=sys.stderr)
        print('Is Git installed?', file=sys.stderr)


update_version()


def lookup_version():
    with open(os.path.join('devwraps', 'version.py'), 'r') as f:
        m = re.search(r"^__version__ = ['\"]([^'\"]*)['\"]", f.read(), re.M)
    return m.group(1)


def make_asdk(fillout, remove, pkgdata):
    dir1 = path.join(PROGFILES, r'Alpao\SDK')
    dl = path.join(dir1, r'Lib\x64')
    di = path.join(dir1, r'Include')

    if not path.isdir(dl) or not path.isdir(di):
        return

    fillout.append(Extension(
        'devwraps.asdk', [r'devwraps\asdk.pyx'],
        include_dirs=[r'devwraps', numpy.get_include(), di],
        library_dirs=[dl],
        libraries=['ASDK']
    ))
    remove.append(r'devwraps\asdk.c')


def make_ciusb(fillout, remove, pkgdata):
    dir1 = path.join(PROGFILES, r'Boston Micromachines\Usb\CIUsbLib')
    f1 = path.join(
        PROGFILES,
        r'Boston Micromachines\Usb\Examples\UsbExMulti\_CIUsbLib.tlb')
    dst = path.join(r'devwraps', '_CIUsbLib.tlb')

    if not path.isdir(dir1):
        return

    copyfile(f1, dst)
    fillout.append(Extension(
        'devwraps.ciusb', [r'devwraps\ciusb.pyx', r'devwraps\cciusb.cpp'],
        include_dirs=[r'devwraps', numpy.get_include(), dir1],
        library_dirs=[dir1],
        libraries=['CIUsbLib'],
        language='c++',
    ))
    remove.append(dst)
    remove.append(r'devwraps\ciusb.cpp')


def make_bmc(fillout, remove, pkgdata):
    dir1 = path.join(PROGFILES, r'Boston Micromachines\Lib64')
    dir2 = path.join(PROGFILES, r'Boston Micromachines\Include')

    if not path.isdir(dir1) or not path.isdir(dir2):
        return
    if path.isfile(path.join(dir1, 'BMC2.lib')):
        libname = 'BMC2'
    elif path.isfile(path.join(dir1, 'BMC3.lib')):
        libname = 'BMC3'
    else:
        return

    fillout.append(Extension(
        'devwraps.bmc', [r'devwraps\bmc.pyx'],
        include_dirs=[r'devwraps', numpy.get_include(), dir2],
        library_dirs=[dir1],
        libraries=[libname],
    ))
    remove.append(r'devwraps\bmc.c')


def make_thorcam(fillout, remove, pkgdata):
    p1 = r'Thorlabs\Scientific Imaging\DCx Camera Support\Develop'
    p2 = r'Thorlabs\Scientific Imaging\ThorCam\uc480_64.dll'
    dir1 = path.join(PROGFILES, p1, r'Include')
    dir2 = path.join(PROGFILES, p1, r'Lib')
    pristine = path.join(dir1, 'uc480.h')
    patched = path.join(r'devwraps', 'uc480.h')

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
        'devwraps.thorcam', [r'devwraps\thorcam.pyx'],
        include_dirs=[r'devwraps', numpy.get_include()],
        library_dirs=[dir2],
        libraries=['uc480_64'],
    ))
    remove.append(patched)
    remove.append(r'devwraps\thorcam.c')
    pkgdata.append((r'lib\site-packages\devwraps', [path.join(PROGFILES, p2)]))


def make_ueye(fillout, remove, pkgdata):
    p1 = r'IDS\uEye\Develop'
    p2 = r'IDS\uEye\USB driver package\ueye_api_64.dll'
    dir1 = path.join(PROGFILES, p1, r'Include')
    dir2 = path.join(PROGFILES, p1, r'Lib')
    pristine = path.join(dir1, 'uEye.h')
    patched = path.join(r'devwraps', 'uEye.h')

    if not path.isdir(dir1) or not path.isdir(dir2):
        return

    with open(pristine, 'r') as f:
        incl = f.read()
    incl = re.sub(r'extern "C" __declspec', r'extern __declspec', incl)
    with open(patched, 'w') as f:
        f.write(incl)

    fillout.append(Extension(
        'devwraps.ueye', [r'devwraps\ueye.pyx'],
        include_dirs=[r'devwraps', numpy.get_include()],
        library_dirs=[dir2],
        libraries=['ueye_api_64'],
    ))
    remove.append(patched)
    remove.append(r'devwraps\ueye.c')
    pkgdata.append((r'lib\site-packages\devwraps', [path.join(PROGFILES, p2)]))


def make_sdk3(fillout, remove, pkgdata):
    dir1 = path.join(PROGFILES, r'Andor SDK3')

    if not path.isdir(dir1):
        return

    fillout.append(Extension(
        'devwraps.sdk3', [r'devwraps\sdk3.pyx'],
        include_dirs=[r'devwraps', numpy.get_include(), dir1],
        library_dirs=[dir1],
        libraries=['atcorem'],
    ))
    remove.append(r'devwraps\sdk3.c')


def make_ximea(fillout, remove, pkgdata):
    dir1 = None
    for p in [
            path.join(PROGFILES, r'XIMEA'),
            path.join(path.join(PROGFILES, path.pardir), r'XIMEA')]:
        if path.isdir(p):
            dir1 = p
            break
    if dir1 is None:
        return

    dir2 = path.join(dir1, r'API')
    dir3 = path.join(dir2, r'x64')

    for f in ['m3ErrorCodes.h', 'm3Identify.h', 'sensorsIdentify.h']:
        copyfile(path.join(dir2, f), path.join('devwraps', f))
    with open(path.join(dir2, 'xiApi.h'), 'r') as f:
        incl = f.read().replace('WIN32', '_WIN64')
    with open(path.join('devwraps', 'xiApi.h'), 'w') as f:
        f.write(incl)

    fillout.append(Extension(
        'devwraps.ximea', [r'devwraps\ximea.pyx'],
        include_dirs=[r'devwraps', numpy.get_include(), dir2],
        library_dirs=[dir3],
        libraries=['xiapi64'],
    ))
    remove.append(r'devwraps\ximea.c')
    for f in [
            'm3ErrorCodes.h', 'm3Identify.h', 'sensorsIdentify.h', 'xiApi.h']:
        remove.append(path.join('devwraps', f))
    pkgdata.append((
        r'lib\site-packages\devwraps', [path.join(dir3, 'xiapi64.dll')]))


exts = []
remove = []
pkgdata = []
make_asdk(exts, remove, pkgdata)
make_ciusb(exts, remove, pkgdata)
make_bmc(exts, remove, pkgdata)
make_thorcam(exts, remove, pkgdata)
make_ueye(exts, remove, pkgdata)
make_sdk3(exts, remove, pkgdata)
make_ximea(exts, remove, pkgdata)
names = [e.name for e in exts]
if len(names) == 0:
    raise ValueError('No drivers found')


setup(
    name='devwraps',
    version=lookup_version(),
    description='Python wrappers for deformable mirrors and cameras',
    long_description=long_description,
    url='https://github.com/jacopoantonello/devwraps',
    author='Jacopo Antonello',
    author_email='jacopo@antonello.org',
    license='GPLv3+',
    classifiers=[
        'Development Status :: 4 - Beta',
        'Intended Audience :: Developers',
        'Topic :: Scientific/Engineering :: Physics', (
            'License :: OSI Approved :: GNU General Public License v3 ' +
            'or later (GPLv3+)'),
        'Programming Language :: Python :: 3',
        'Operating System :: Microsoft :: Windows'
    ],
    packages=['devwraps'],
    ext_modules=cythonize(exts, compiler_directives={'language_level': 3}),
    install_requires=['numpy', 'cython'],
    zip_safe=False,
    data_files=pkgdata)

try:
    for f in remove:
        os.remove(f)
except OSError:
    pass

print(f'installed extensions are {", ".join(names)}')
