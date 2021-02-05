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

# https://github.com/cython/cython/wiki/CythonExtensionsOnWindows
# https://matthew-brett.github.io/pydagogue/python_msvc.html
# http://landinghub.visualstudio.com/visual-cpp-build-tools

# To compile install MSVC 2015 command line tools and run
# python setup.py build_ext --inplace

import os
import re
import sys
from glob import glob
from os import path, walk
from shutil import copyfile
from subprocess import check_output

import numpy
from Cython.Build import cythonize
from setuptools import setup
from setuptools.extension import Extension

here = path.abspath(path.dirname(__file__))
with open(path.join(here, 'README.md'), encoding='utf-8') as f:
    long_description = f.read()

PROGFILES = os.environ['PROGRAMFILES']
WINDIR = os.environ['WINDIR']


def find_file(tops, pat, er=None, expats=[]):
    for top in tops:
        if path.isdir(top):
            for root, _, files in walk(top):
                badroot = False
                for ex in expats:
                    m = re.search(ex, root)
                    if m is not None:
                        badroot = True
                        break
                if not badroot:
                    for f in files:
                        m = re.search(pat, f)
                        if m is not None:
                            return path.join(root, f)
    if er is None:
        er = pat
    raise ValueError(f'Cannot find {er}')


def update_version():
    try:
        check_output('git --version', universal_newlines=True, shell=True)
    except Exception:
        raise RuntimeError('Git must be installed and added to the PATH ' +
                           '(https://stackoverflow.com/questions/19290899)')

    try:
        toks = check_output('git describe --tags --long --dirty',
                            universal_newlines=True,
                            shell=True).strip().split('-')
        version = toks[0].strip('v') + '.' + toks[1]
        last = check_output('git log -n 1',
                            universal_newlines=True,
                            shell=True)
        date = re.search(r'^Date:\s+([^\s].*)$', last, re.MULTILINE).group(1)
        commit = re.search(r'^commit\s+([^\s]{40})', last,
                           re.MULTILINE).group(1)

        with open(path.join('devwraps', 'version.py'), 'w', newline='\n') as f:
            f.write('#!/usr/bin/env python3\n')
            f.write('# -*- coding: utf-8 -*-\n\n')
            f.write(f"__version__ = '{version}'\n")
            f.write(f"__date__ = '{date}'\n")
            f.write(f"__commit__ = '{commit}'\n")
    except Exception as e:
        print(f'Cannot update version: {str(e)}', file=sys.stderr)
        print('Is Git installed?', file=sys.stderr)


update_version()


def lookup_version():
    with open(os.path.join('devwraps', 'version.py'), 'r') as f:
        m = re.search(r"^__version__ = ['\"]([^'\"]*)['\"]", f.read(), re.M)
    return m.group(1)


def make_mirao52(fillout, remove, pkgdata):
    hname = r'^mirao52e\.h$'
    tops = [
        # NOTE add here the path to the Mirao installation folder
        path.join(PROGFILES, r'ImagineOptic'),
        path.join(PROGFILES, r'ImagineEyes'),
    ]
    try:
        include_path = path.dirname(find_file(tops, hname, expats=[]))
    except ValueError:
        return

    hname1 = 'mirao52e.h'
    with open(path.join(include_path, hname1), 'r') as f:
        incl = f.read()
    incl = re.sub(r'static const (.*) = .*;', r'\1;', incl)
    with open(path.join('devwraps', hname1), 'w') as f:
        f.write(incl)

    libname = r'^mirao52e\.lib$'
    try:
        lib_path = path.dirname(find_file(tops, libname, expats=['i386']))
    except ValueError:
        return

    fillout.append(
        Extension('devwraps.mirao52e', [r'devwraps\mirao52e.pyx'],
                  include_dirs=[r'devwraps', numpy.get_include()],
                  library_dirs=[lib_path],
                  libraries=['mirao52e']))
    remove.append(r'devwraps\mirao52e.c')
    remove.append(r'devwraps\mirao52e.h')


def make_asdk(fillout, remove, pkgdata):
    hname = r'^asdkType\.h$'
    tops = [
        path.join(PROGFILES, r'Alpao'),
    ]
    try:
        include_path = path.dirname(find_file(tops, hname, expats=[]))
    except ValueError:
        return

    libname = r'^ASDK\.lib$'
    try:
        lib_path = path.dirname(find_file(tops, libname, expats=['x86']))
    except ValueError:
        return

    fillout.append(
        Extension(
            'devwraps.asdk', [r'devwraps\asdk.pyx'],
            include_dirs=[r'devwraps',
                          numpy.get_include(), include_path],
            library_dirs=[lib_path],
            libraries=['ASDK']))
    remove.append(r'devwraps\asdk.c')


def make_bmc(fillout, remove, pkgdata):
    libname = r'^BMC[0-9]*\.lib$'
    tops = [
        path.join(PROGFILES, r'Boston Micromachines'),
    ]
    try:
        lib_fname = find_file(tops, libname, expats=[])
        lib_path = path.dirname(lib_fname)
        lib_name = path.basename(lib_fname).replace('.lib', '')
    except ValueError:
        return

    iname = r'^BmcApi\.h$'
    try:
        include_path = path.dirname(find_file(tops, iname, expats=[]))
    except ValueError:
        return

    fillout.append(
        Extension(
            'devwraps.bmc',
            [r'devwraps\bmc.pyx'],
            include_dirs=[r'devwraps',
                          numpy.get_include(), include_path],
            library_dirs=[lib_path],
            libraries=[lib_name],
        ))
    remove.append(r'devwraps\bmc.c')


def make_thorcam(fillout, remove, pkgdata):
    hname = r'^uc480\.h$'
    tops = [
        path.join(PROGFILES, 'Thorlabs', 'Scientific Imaging'),
    ]
    try:
        include_path = path.dirname(find_file(tops, hname, expats=['Source']))
    except ValueError:
        return

    libname = r'^uc480_64\.lib$'
    try:
        lib_path = path.dirname(find_file(tops, libname, expats=['Source']))
    except ValueError:
        return

    pristine = path.join(include_path, 'uc480.h')
    patched = path.join(r'devwraps', 'uc480.h')

    with open(pristine, 'r') as f:
        incl = f.read()
    incl = re.sub(r'#define IS_SENSOR_C1280G12M *0x021E', '', incl, 1)
    incl = re.sub(r'#define IS_SENSOR_C1280G12C *0x021F', '', incl, 1)
    incl = re.sub(r'#define IS_SENSOR_C1280G12N *0x0220', '', incl, 1)
    incl = re.sub(r'extern "C" __declspec', r'extern __declspec', incl, 2)
    with open(patched, 'w') as f:
        f.write(incl)

    fillout.append(
        Extension(
            'devwraps.thorcam',
            [r'devwraps\thorcam.pyx'],
            include_dirs=[r'devwraps', numpy.get_include()],
            library_dirs=[lib_path],
            libraries=['uc480_64'],
        ))
    remove.append(patched)
    remove.append(r'devwraps\thorcam.c')


def make_ueye(fillout, remove, pkgdata):
    hname = r'^uEye\.h$'
    tops = [
        path.join(PROGFILES, 'IDS', 'uEye'),
    ]
    try:
        include_path = path.dirname(find_file(tops, hname, expats=[]))
    except ValueError:
        return

    libname = r'^uEye_api_64\.lib$'
    try:
        lib_path = path.dirname(find_file(tops, libname, expats=[]))
    except ValueError:
        return

    pristine = path.join(include_path, 'uEye.h')
    patched = path.join(r'devwraps', 'uEye.h')

    with open(pristine, 'r') as f:
        incl = f.read()
    incl = re.sub(r'extern "C" __declspec', r'extern __declspec', incl)
    with open(patched, 'w') as f:
        f.write(incl)

    fillout.append(
        Extension(
            'devwraps.ueye',
            [r'devwraps\ueye.pyx'],
            include_dirs=[r'devwraps', numpy.get_include()],
            library_dirs=[lib_path],
            libraries=['ueye_api_64'],
        ))
    remove.append(patched)
    remove.append(r'devwraps\ueye.c')


def make_sdk3(fillout, remove, pkgdata):
    hname = r'^atcore\.h$'
    tops = [
        path.join(PROGFILES, 'Andor SDK3'),
    ]
    try:
        include_path = path.dirname(find_file(tops, hname, expats=['win32']))
    except ValueError:
        return

    libname = r'^atcorem\.lib$'
    try:
        lib_path = path.dirname(find_file(tops, libname, expats=['Source']))
    except ValueError:
        return

    fillout.append(
        Extension(
            'devwraps.sdk3',
            [r'devwraps\sdk3.pyx'],
            include_dirs=[r'devwraps',
                          numpy.get_include(), include_path],
            library_dirs=[lib_path],
            libraries=['atcorem'],
        ))
    remove.append(r'devwraps\sdk3.c')


def make_ximea(fillout, remove, pkgdata):
    libname = r'^xiapi64\.lib$'
    expats = ['32bit']
    tops = [
        path.join(PROGFILES, r'XIMEA'),
        path.join(path.join(PROGFILES, path.pardir), r'XIMEA')
    ]
    try:
        dllpath = path.dirname(find_file(tops, libname, expats=expats))
    except ValueError:
        return

    copies = [
        (r'^m3ErrorCodes\.h$', 'm3ErrorCodes.h'),
        (r'^m3Identify\.h$', 'm3Identify.h'),
        (r'^sensorsIdentify\.h$', 'sensorsIdentify.h'),
        (r'^xiApi\.h$', 'xiApi.h'),
    ]
    for t in copies:
        pat, n = t
        hf = find_file(tops, pat, expats=expats)
        copyfile(hf, path.join('devwraps', n))

    with open(path.join('devwraps', 'xiApi.h'), 'r') as f:
        incl = f.read().replace('WIN32', '_WIN64')
    with open(path.join('devwraps', 'xiApi.h'), 'w') as f:
        f.write(incl)

    fillout.append(
        Extension(
            'devwraps.ximea',
            [r'devwraps\ximea.pyx'],
            include_dirs=[r'devwraps', numpy.get_include()],
            library_dirs=[dllpath],
            libraries=['xiapi64'],
        ))
    remove.append(r'devwraps\ximea.c')
    for t in copies:
        _, n = t
        remove.append(path.join('devwraps', n))


exts = []
remove = []
pkgdata = []
for g in glob('devwraps\\*.pyx'):
    fname = g.replace('.pyx', '.c')
    try:
        for f in remove:
            print(f'rm {f}')
            os.remove(f)
    except OSError:
        print(f'error {f}')
        pass
make_mirao52(exts, remove, pkgdata)
# make_asdk(exts, remove, pkgdata)
# make_bmc(exts, remove, pkgdata)
# make_thorcam(exts, remove, pkgdata)
# make_ueye(exts, remove, pkgdata)
# make_sdk3(exts, remove, pkgdata)
# make_ximea(exts, remove, pkgdata)
names = [e.name.replace('devwraps.', '') for e in exts]
if len(names) == 0:
    raise ValueError('No device driver was found')


def fill__all__(names):
    with open(path.join('devwraps', 'version.py'), 'a', newline='\n') as f:
        f.write('def get_packages():\n')
        f.write(f'    return {str(names)}\n')


fill__all__(names)

setup(name='devwraps',
      version=lookup_version(),
      description='Python wrappers for deformable mirrors and cameras',
      long_description=long_description,
      long_description_content_type='text/markdown',
      url='https://github.com/jacopoantonello/devwraps',
      author='Jacopo Antonello',
      author_email='jacopo@antonello.org',
      license='GPLv3+',
      classifiers=[
          'Development Status :: 4 - Beta', 'Intended Audience :: Developers',
          'Topic :: Scientific/Engineering :: Physics',
          ('License :: OSI Approved :: GNU General Public License v3 ' +
           'or later (GPLv3+)'), 'Programming Language :: Python :: 3',
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
