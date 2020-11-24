#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import re
import sys
from subprocess import run
from tempfile import TemporaryDirectory

from devwraps.version import get_packages

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Test imports',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    args = parser.parse_args()

    devices = get_packages()

    with TemporaryDirectory() as tmpd:
        print('Removing old DLLs')
        cmds = ['from devwraps.dll_finder import remove_dlls', 'remove_dlls()']
        cmdstr = '; '.join(cmds)
        p = run(f'{sys.executable} -c "{cmdstr}"',
                cwd=tmpd,
                capture_output=True,
                shell=True)
        print()

        print('Importing DLLs from device drivers')
        cmds = ['import devwraps', 'assert(devwraps)']
        cmdstr = '; '.join(cmds)
        p = run(f'{sys.executable} -c "{cmdstr}"',
                cwd=tmpd,
                capture_output=True,
                shell=True)
        print()

        # test imports
        print('Testing imports')
        for d in devices:
            cmds = [f'from devwraps import {d}', f'print({d})']
            cmdstr = '; '.join(cmds)
            p = run(f'{sys.executable} -c "{cmdstr}"',
                    cwd=tmpd,
                    capture_output=True,
                    shell=True)
            out = p.stdout.decode().strip()
            err = re.search(r'(\w*Error)', p.stderr.decode().strip())
            try:
                err = err.group(1)
            except Exception:
                err = ''
            if f'devwraps.{d}' in out:
                print(f'{d}: OK')
            else:
                print(f'{d}: FAIL: {err}')
        print()

        print('Testing get_devices()')
        for d in devices:
            cmdstr = '; '.join(cmds)
            p = run(f'{sys.executable} -m devwraps.test_get_devices {d}',
                    cwd=tmpd,
                    capture_output=True,
                    shell=True)
            out = p.stdout.decode().strip()
            err = p.stderr.decode().strip()
            print(d, out, err)
        print()
