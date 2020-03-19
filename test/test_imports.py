#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import re
import sys

from subprocess import run
from tempfile import TemporaryDirectory


from devwraps.version import get_packages


print()
print('Test importing device libraries')
devices = get_packages()
with TemporaryDirectory() as tmpd:
    for d in devices:
        p = run(
            f'{sys.executable} -c "from devwraps import {d}; print({d})',
            cwd=tmpd, capture_output=True, shell=True)
        out = p.stdout.decode().strip()
        err = re.search(r'(\w*Error)', p.stderr.decode().strip())
        try:
            err = err.group(1)
        except Exception:
            err = ''
        out = re.sub(r"'.*", '', re.sub(r'.*\\', '', out))
        if out.endswith('.pyd'):
            print(f'{d} success: {out}')
        else:
            print(f'{d} failure: {err}')
