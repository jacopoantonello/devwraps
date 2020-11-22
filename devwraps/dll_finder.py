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

import logging
import os
import re
from os import path, walk
from shutil import copyfile

PROGFILES = os.environ['PROGRAMFILES']
WINDIR = os.environ['WINDIR']
log = logging.getLogger('dll_finder')


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


def look_for_dlls():
    dll_lookup_ximea()
    dll_lookup_asdk()
    dll_lookup_bmc()
    dll_lookup_thorcam()
    dll_lookup_ueye()
    dll_lookup_sdk3()


def dll_lookup_ximea():
    dllname = 'xiapi64.dll'
    here = os.path.dirname(os.path.realpath(__file__))
    target = path.join(here, dllname)
    found = path.isfile(target)

    log.debug(f'here: {here}; found: {found}')
    if not found:
        expats = ['32bit']
        tops = [
            path.join(PROGFILES, r'XIMEA'),
            path.join(path.join(PROGFILES, path.pardir), r'XIMEA')
        ]
        try:
            dllpath = path.dirname(find_file(tops, dllname, expats=expats))
        except ValueError:
            log.debug(
                f'Unable to find Ximea\'s {dllname}. Is the driver installed?')
            return
        src = path.join(dllpath, dllname)
        copyfile(src, target)
        log.debug(f'copied: {src} to {target}')


def dll_lookup_asdk():
    dllname = 'ASDK.dll'
    here = os.path.dirname(os.path.realpath(__file__))
    target = path.join(here, dllname)
    found = path.isfile(target)

    log.debug(f'here: {here}; found: {found}')
    if not found:
        expats = ['x86']
        tops = [
            path.join(PROGFILES, r'Alpao'),
        ]
        try:
            dllpath = path.dirname(find_file(tops, dllname, expats=expats))
        except ValueError:
            log.debug(
                f'Unable to find Alpao\'s {dllname}. Is the driver installed?')
            return
        src = path.join(dllpath, dllname)
        copyfile(src, target)
        log.debug(f'copied: {src} to {target}')


def dll_lookup_bmc():
    dllname = r'BMC[0-9]*\.dll'
    here = os.path.dirname(os.path.realpath(__file__))
    target = path.join(here, dllname)
    found = path.isfile(target)

    log.debug(f'here: {here}; found: {found}')
    if not found:
        tops = [
            path.join(PROGFILES, r'Boston Micromachines'),
        ]
        try:
            dllpath = path.dirname(find_file(tops, dllname, expats=[]))
        except ValueError:
            log.debug(
                f'Unable to find BMC\'s {dllname}. Is the driver installed?')
            return
        src = path.join(dllpath, dllname)
        copyfile(src, target)
        log.debug(f'copied: {src} to {target}')


def dll_lookup_thorcam():
    dllname = 'uc480_64.dll'
    here = os.path.dirname(os.path.realpath(__file__))
    target = path.join(here, dllname)
    found = path.isfile(target)

    log.debug(f'here: {here}; found: {found}')
    if not found:
        tops = [
            path.join(PROGFILES, 'Thorlabs', 'Scientific Imaging'),
        ]
        try:
            dllpath = path.dirname(find_file(tops, dllname, expats=[]))
        except ValueError:
            log.debug(
                f'Unable to find Thorlabs {dllname}. Is the driver installed?')
            return
        src = path.join(dllpath, dllname)
        copyfile(src, target)
        log.debug(f'copied: {src} to {target}')


def dll_lookup_ueye():
    dllname = 'ueye_api_64.dll'
    here = os.path.dirname(os.path.realpath(__file__))
    target = path.join(here, dllname)
    found = path.isfile(target)

    log.debug(f'here: {here}; found: {found}')
    if not found:
        tops = [
            path.join(PROGFILES, 'IDS', 'uEye'),
        ]
        try:
            dllpath = path.dirname(find_file(tops, dllname, expats=[]))
        except ValueError:
            log.debug(
                f'Unable to find IDS {dllname}. Is the driver installed?')
            return
        src = path.join(dllpath, dllname)
        copyfile(src, target)
        log.debug(f'copied: {src} to {target}')


def dll_lookup_sdk3():
    dllname = 'atcorem.dll'
    here = os.path.dirname(os.path.realpath(__file__))
    target = path.join(here, dllname)
    found = path.isfile(target)

    log.debug(f'here: {here}; found: {found}')
    if not found:
        tops = [
            path.join(PROGFILES, 'Andor SDK3'),
        ]
        try:
            dllpath = path.dirname(find_file(tops, dllname, expats=[]))
        except ValueError:
            log.debug(
                f'Unable to find SDK3\'s {dllname}. Is the driver installed?')
            return
        src = path.join(dllpath, dllname)
        copyfile(src, target)
        log.debug(f'copied: {src} to {target}')
