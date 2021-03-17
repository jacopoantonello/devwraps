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

import os
from os import path

PROGFILES = os.environ['PROGRAMFILES']

paths = {
    'ximea': [
        path.join(PROGFILES, r'XIMEA'),
        path.join(path.join(PROGFILES, path.pardir), r'XIMEA'),
    ],
    'asdk': [
        path.join(PROGFILES, r'Alpao'),
    ],
    'mirao52e': [
        # NOTE: to use the Mirao52e you need the following files:
        # mirao52e.h; mirao52e.lib; mirao52e.dll; ftd2xx64.dll;

        # Just copy the Mirao52e CD to C:\Program Files\ImagineOptic or
        # add a custom path below
        path.join(PROGFILES, r'ImagineOptic'),
        path.join(PROGFILES, r'ImagineEyes'),
    ],
    'bmc': [
        path.join(PROGFILES, r'Boston Micromachines'),
    ],
    'thorcam': [
        path.join(PROGFILES, 'Thorlabs', 'Scientific Imaging'),
    ],
    'ueye': [
        path.join(PROGFILES, 'IDS', 'uEye'),
    ],
    'sdk3': [
        path.join(PROGFILES, 'Andor SDK3'),
    ],
}


def get_paths(k):
    return paths[k]
