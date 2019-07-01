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


from libc.stddef cimport wchar_t

cdef extern from "atcore.h":

    ctypedef int ath
    ctypedef int atbool
    ctypedef long long at64
    ctypedef unsigned char atu8
    ctypedef Py_UNICODE atwc

    cdef int AT_INFINITE = 0xFFFFFFFF
    cdef int AT_CALLBACK_SUCCESS = 0
    cdef int AT_TRUE = 1
    cdef int AT_FALSE = 0

    cdef int AT_SUCCESS = 0
    cdef int AT_ERR_NOTINITIALISED = 1
    cdef int AT_ERR_NOTIMPLEMENTED = 2
    cdef int AT_ERR_READONLY = 3
    cdef int AT_ERR_NOTREADABLE = 4
    cdef int AT_ERR_NOTWRITABLE = 5
    cdef int AT_ERR_OUTOFRANGE = 6
    cdef int AT_ERR_INDEXNOTAVAILABLE = 7
    cdef int AT_ERR_INDEXNOTIMPLEMENTED = 8
    cdef int AT_ERR_EXCEEDEDMAXSTRINGLENGTH = 9
    cdef int AT_ERR_CONNECTION = 10
    cdef int AT_ERR_NODATA = 11
    cdef int AT_ERR_INVALIDHANDLE = 12
    cdef int AT_ERR_TIMEDOUT = 13
    cdef int AT_ERR_BUFFERFULL = 14
    cdef int AT_ERR_INVALIDSIZE = 15
    cdef int AT_ERR_INVALIDALIGNMENT = 16
    cdef int AT_ERR_COMM = 17
    cdef int AT_ERR_STRINGNOTAVAILABLE = 18
    cdef int AT_ERR_STRINGNOTIMPLEMENTED = 19

    cdef int AT_ERR_NULL_FEATURE = 20
    cdef int AT_ERR_NULL_HANDLE = 21
    cdef int AT_ERR_NULL_IMPLEMENTED_VAR = 22
    cdef int AT_ERR_NULL_READABLE_VAR = 23
    cdef int AT_ERR_NULL_READONLY_VAR = 24
    cdef int AT_ERR_NULL_WRITABLE_VAR = 25
    cdef int AT_ERR_NULL_MINVALUE = 26
    cdef int AT_ERR_NULL_MAXVALUE = 27
    cdef int AT_ERR_NULL_VALUE = 28
    cdef int AT_ERR_NULL_STRING = 29
    cdef int AT_ERR_NULL_COUNT_VAR = 30
    cdef int AT_ERR_NULL_ISAVAILABLE_VAR = 31
    cdef int AT_ERR_NULL_MAXSTRINGLENGTH = 32
    cdef int AT_ERR_NULL_EVCALLBACK = 33
    cdef int AT_ERR_NULL_QUEUE_PTR = 34
    cdef int AT_ERR_NULL_WAIT_PTR = 35
    cdef int AT_ERR_NULL_PTRSIZE = 36
    cdef int AT_ERR_NOMEMORY = 37
    cdef int AT_ERR_DEVICEINUSE = 38
    cdef int AT_ERR_DEVICENOTFOUND = 39

    cdef int AT_ERR_HARDWARE_OVERFLOW = 100

    cdef int AT_HANDLE_UNINITIALISED = -1
    cdef int AT_HANDLE_SYSTEM = 1

    cdef int AT_InitialiseLibrary()
    cdef int AT_FinaliseLibrary()

    cdef int AT_Open(int CameraIndex, ath *Hndl)
    cdef int AT_Close(ath Hndl)

    ctypedef int (*FeatureCallback)(
        ath Hndl, const atwc *Feature, void *Context)

    cdef int AT_RegisterFeatureCallback(
        ath Hndl, const atwc *Feature, FeatureCallback EvCallback,
        void *Context)
    cdef int AT_UnregisterFeatureCallback(
        ath Hndl, const atwc *Feature, FeatureCallback EvCallback,
        void *Context)

    cdef int AT_IsImplemented(
        ath Hndl, const atwc *Feature, atbool *Implemented)
    cdef int AT_IsReadable(ath Hndl, const atwc *Feature, atbool *Readable)
    cdef int AT_IsWritable(ath Hndl, const atwc *Feature, atbool *Writable)
    cdef int AT_IsReadOnly(ath Hndl, const atwc *Feature, atbool *ReadOnly)

    cdef int AT_SetInt(ath Hndl, const atwc *Feature, at64 Value)
    cdef int AT_GetInt(ath Hndl, const atwc *Feature, at64 *Value)
    cdef int AT_GetIntMax(ath Hndl, const atwc *Feature, at64 *MaxValue)
    cdef int AT_GetIntMin(ath Hndl, const atwc *Feature, at64 *MinValue)

    cdef int AT_SetFloat(ath Hndl, const atwc *Feature, double Value)
    cdef int AT_GetFloat(ath Hndl, const atwc *Feature, double *Value)
    cdef int AT_GetFloatMax(ath Hndl, const atwc *Feature, double *MaxValue)
    cdef int AT_GetFloatMin(ath Hndl, const atwc *Feature, double *MinValue)

    cdef int AT_SetBool(ath Hndl, const atwc *Feature, atbool Value)
    cdef int AT_GetBool(ath Hndl, const atwc *Feature, atbool *Value)

    cdef int AT_SetEnumerated(ath Hndl, const atwc *Feature, int Value)
    cdef int AT_SetEnumeratedString(
        ath Hndl, const atwc *Feature, const atwc *String)
    cdef int AT_GetEnumerated(ath Hndl, const atwc *Feature, int *Value)
    cdef int AT_GetEnumeratedCount(ath Hndl, const  atwc *Feature, int *Count)
    cdef int AT_IsEnumeratedIndexAvailable(
        ath Hndl, const atwc *Feature, int Index, atbool *Available)
    cdef int AT_IsEnumeratedIndexImplemented(
        ath Hndl, const atwc *Feature, int Index, atbool *Implemented)
    cdef int AT_GetEnumeratedString(
        ath Hndl, const atwc *Feature, int Index, atwc *String,
        int StringLength)

    cdef int AT_SetEnumIndex(ath Hndl, const atwc *Feature, int Value)
    cdef int AT_SetEnumString(
        ath Hndl, const atwc *Feature, const atwc *String)
    cdef int AT_GetEnumIndex(ath Hndl, const atwc *Feature, int *Value)
    cdef int AT_GetEnumCount(ath Hndl, const atwc *Feature, int *Count)
    cdef int AT_IsEnumIndexAvailable(
        ath Hndl, const atwc *Feature, int Index, atbool *Available)
    cdef int AT_IsEnumIndexImplemented(
        ath Hndl, const atwc *Feature, int Index, atbool *Implemented)
    cdef int AT_GetEnumStringByIndex(
        ath Hndl, const atwc *Feature, int Index, atwc *String,
        int StringLength)

    cdef int AT_Command(ath Hndl, const atwc *Feature)

    cdef int AT_SetString(ath Hndl, const atwc *Feature, const atwc *String)
    cdef int AT_GetString(
        ath Hndl, const atwc *Feature, atwc *String, int StringLength)
    cdef int AT_GetStringMaxLength(
        ath Hndl, const atwc *Feature, int *MaxStringLength)

    cdef int AT_QueueBuffer(ath Hndl, atu8 *Ptr, int PtrSize)
    cdef int AT_WaitBuffer(
        ath Hndl, atu8 **Ptr, int *PtrSize, unsigned int Timeout)
    cdef int AT_Flush(ath Hndl)
