#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from devwraps import version
from devwraps.dll_finder import get_root_folder, look_for_dlls, remove_dlls

__author__ = 'Jacopo Antonello'
__copyright__ = 'Copyright 2018-2021, Jacopo Antonello'
__license__ = 'GPLv3+'
__email__ = 'jacopo@antonello.org'
__status__ = 'Beta'
__doc__ = f"""
devwraps - some device wrappers for Python 3

author:  {__author__}
date:    {version.__date__}
version: {version.__version__}
commit:  {version.__commit__}
"""

look_for_dlls()
assert (remove_dlls)
assert (get_root_folder)
