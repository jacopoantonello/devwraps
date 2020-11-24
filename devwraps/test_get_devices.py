#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import argparse
import importlib
import inspect
import sys

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description='Test get_devices',
        formatter_class=argparse.ArgumentDefaultsHelpFormatter)
    parser.add_argument('module', type=str)
    args = parser.parse_args()

    mod = importlib.import_module(f'devwraps.{args.module}')
    for name, obj in inspect.getmembers(mod):
        if inspect.isclass(obj):
            try:
                a = obj()
                print(a.get_devices())
            except Exception:
                pass
