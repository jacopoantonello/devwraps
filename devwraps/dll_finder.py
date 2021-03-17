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
from glob import glob
from os import path, walk
from shutil import copyfile

from devwraps.dll_paths import get_paths

PROGFILES = os.environ['PROGRAMFILES']
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


def remove_dlls():
    here = get_root_folder()
    for g in glob(path.join(here, '*.dll')):
        os.remove(g)


def get_root_folder():
    return path.dirname(path.realpath(__file__))


def look_for_dlls():
    dll_lookup_ximea()
    dll_lookup_asdk()
    dll_lookup_bmc()
    dll_lookup_thorcam()
    dll_lookup_ueye()
    dll_lookup_sdk3()
    dll_lookup_mirao52e()


def dll_lookup_ximea():
    dll_name = 'xiapi64.dll'
    dll_pat = r'^xiapi64\.dll$'

    here = path.dirname(path.realpath(__file__))
    target = path.join(here, dll_name)
    found = path.isfile(target)

    log.debug(f'here: {here}; found: {found}')
    if not found:
        expats = ['32bit']
        tops = get_paths('ximea')
        try:
            dllpath = path.dirname(find_file(tops, dll_pat, expats=expats))
        except ValueError:
            log.debug(f'Unable to find Ximea\'s {dll_name}. ' +
                      'Is the driver installed?')
            return
        src = path.join(dllpath, dll_name)
        copyfile(src, target)
        log.debug(f'copied: {src} to {target}')


def dll_lookup_asdk():
    dll_name = 'ASDK.dll'
    dll_pat = r'^ASDK\.dll$'

    here = path.dirname(path.realpath(__file__))
    target = path.join(here, dll_name)
    found = path.isfile(target)

    log.debug(f'here: {here}; found: {found}')
    if not found:
        expats = ['x86']
        tops = get_paths('asdk')
        try:
            dllpath = path.dirname(find_file(tops, dll_pat, expats=expats))
        except ValueError:
            log.debug(f'Unable to find ASDK\'s {dll_name}. ' +
                      'Is the driver installed?')
            return
        src = path.join(dllpath, dll_name)
        copyfile(src, target)
        log.debug(f'copied: {src} to {target}')


def dll_lookup_mirao52e():
    tups = [('mirao52e.dll', r'^mirao52e\.dll$')]
    for dll_name, dll_pat in tups:
        here = path.dirname(path.realpath(__file__))
        target = path.join(here, dll_name)
        found = path.isfile(target)

        log.debug(f'here: {here}; found: {found}')
        if not found:
            expats = ['i386']
            tops = get_paths('mirao52e')
            try:
                dllpath = path.dirname(find_file(tops, dll_pat, expats=expats))
            except ValueError:
                log.debug(f'Unable to find Mirao52e\'s {dll_name}. ' +
                          'Is the driver installed?')
                return
            src = path.join(dllpath, dll_name)
            copyfile(src, target)
            log.debug(f'copied: {src} to {target}')

    here = path.dirname(path.realpath(__file__))
    target = path.join(here, 'ftd2xx.dll')
    found = path.isfile(target)

    log.debug(f'here: {here}; found: {found}')
    if not found:
        expats = ['i386']
        tops = get_paths('mirao52e')
        try:
            dllpath = path.dirname(
                find_file(tops, r'^ftd2xx64\.dll$', expats=expats))
        except ValueError:
            log.debug(f'Unable to find Mirao52e\'s ftd2xx64.dll. ' +
                      'Is the driver installed?')
            return
        src = path.join(dllpath, 'ftd2xx64.dll')
        copyfile(src, target)
        log.debug(f'copied: {src} to {target}')


def dll_lookup_bmc():
    dll_pat = r'^BMC[0-9]+\.dll$'

    here = path.dirname(path.realpath(__file__))
    try:
        find_file([here], dll_pat, expats=[])
        return
    except ValueError:
        pass

    tops = get_paths('bmc')
    try:
        dll_path = find_file(tops, dll_pat, expats=[])
    except ValueError:
        log.debug('Unable to find BMC\'s DLL. Is the driver installed?')
        return

    dll_name = path.basename(dll_path)
    target = path.join(here, dll_name)

    found = path.isfile(target)
    log.debug(f'here: {here}; found: {found}')
    copyfile(dll_path, target)
    log.debug(f'copied: {dll_path} to {target}')


def dll_lookup_thorcam():
    dll_name = 'uc480_64.dll'
    dll_pat = r'^uc480_64\.dll$'

    here = path.dirname(path.realpath(__file__))
    target = path.join(here, dll_name)
    found = path.isfile(target)

    log.debug(f'here: {here}; found: {found}')
    if not found:
        tops = get_paths('thorcam')
        try:
            dllpath = path.dirname(find_file(tops, dll_pat, expats=[]))
        except ValueError:
            log.debug(f'Unable to find Thorlabs {dll_name}. ' +
                      'Is the driver installed?')
            return
        src = path.join(dllpath, dll_name)
        copyfile(src, target)
        log.debug(f'copied: {src} to {target}')


def dll_lookup_ueye():
    dll_name = 'ueye_api_64.dll'
    dll_pat = r'^ueye_api_64\.dll$'

    here = path.dirname(path.realpath(__file__))
    target = path.join(here, dll_name)
    found = path.isfile(target)

    log.debug(f'here: {here}; found: {found}')
    if not found:
        tops = get_paths('ueye')
        try:
            dllpath = path.dirname(find_file(tops, dll_pat, expats=[]))
        except ValueError:
            log.debug(f'Unable to find IDS {dll_name}. ' +
                      'Is the driver installed?')
            return
        src = path.join(dllpath, dll_name)
        copyfile(src, target)
        log.debug(f'copied: {src} to {target}')


def dll_lookup_sdk3():
    dll_name = 'atcore.dll'
    dll_pat = r'^atcore\.dll$'

    here = path.dirname(path.realpath(__file__))
    target = path.join(here, dll_name)
    found = path.isfile(target)

    log.debug(f'here: {here}; found: {found}')
    if not found:
        tops = get_paths('sdk3')
        try:
            dllpath = path.dirname(find_file(tops, dll_pat, expats=[]))
        except ValueError:
            log.debug(f'Unable to find SDK3\'s {dll_name}. ' +
                      'Is the driver installed?')
            return
        src = path.join(dllpath, dll_name)
        copyfile(src, target)
        log.debug(f'copied: {src} to {target}')
