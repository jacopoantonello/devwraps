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


from libc.stdint cimport (
    uint8_t, int16_t, uint16_t, int32_t, uint32_t, int64_t, uint64_t)


cdef extern from "asdkType.h":
    ctypedef char Char
    ctypedef uint8_t UChar
    ctypedef int16_t Short
    ctypedef uint16_t UShort

    ctypedef int32_t Int
    ctypedef uint32_t UInt

    ctypedef int64_t Long
    ctypedef uint64_t ULong

    ctypedef size_t Size_T
    ctypedef double Scalar

    cdef enum Bool:
        False
        True

    ctypedef char* CString
    ctypedef const char* CStrConst


cdef extern from "asdkWrapper.h":
    ctypedef enum COMPL_STAT:
        SUCCESS = 0
        FAILURE = -1

    ctypedef struct asdkDM:
        pass

    cdef asdkDM *asdkInit(CStrConst serialName)
    cdef COMPL_STAT asdkRelease(asdkDM *pDm)
    cdef COMPL_STAT asdkSend(asdkDM *pDm, const Scalar *value)
    cdef COMPL_STAT asdkReset(asdkDM *pDm)
    cdef COMPL_STAT asdkSendPattern(
        asdkDM *pDm, const Scalar *pattern, UInt nPattern, UInt nRepeat)
    cdef COMPL_STAT asdkStop(asdkDM *pDm)
    cdef COMPL_STAT asdkGet(asdkDM *pDm, CStrConst command, Scalar *value)
    cdef COMPL_STAT asdkSet(asdkDM *pDm, CStrConst command, Scalar value)
    cdef COMPL_STAT asdkSetString(
        asdkDM *pDm, CStrConst command, CStrConst cstr)
    cdef void asdkPrintLastError()
    cdef COMPL_STAT asdkGetLastError(
        UInt *errorNo, CString errMsg, Size_T errSize)
