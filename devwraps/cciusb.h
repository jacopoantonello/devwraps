/*
 * devwraps - some device wrappers for Python
 * Copyright 2018 J. Antonello <jacopo.antonello@dpag.ox.ac.uk>
 *
 * This file is part of devwraps.
 *
 * devwraps is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * devwraps is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with devwraps.  If not, see <http://www.gnu.org/licenses/>.
*/


#ifndef _WIN32_WINNT
#define _WIN32_WINNT 0x0500
#endif

#include <stdio.h>
#include <stdlib.h>
#include <tchar.h>
#include <atlbase.h>
#include <atlcom.h>
#include <stdexcept>

#include "Windows.h"

#pragma warning (disable : 4192)
// be sure to get the latest release of the following
#include "CIUsbLib.h"
#import "_CIUsbLib.tlb" no_namespace
using namespace std;

#define NUM_ACTUATORS	USB_NUM_ACTUATORS_MULTI
#define USB_DEVNAME		"Multi"

// define a macro for short-hand error processing
#define CheckHr(s) if (FAILED(hr)){printf(s);exit(EXIT_FAILURE);}
			
namespace shapes {
    class CCIUsb {
		private:
			long mydevice;
			CComPtr<IHostDrv> pIHostDrv;
    public:
        CCIUsb();
        ~CCIUsb();
 				int open(int skip);
				int get_devices();
        void write(unsigned short *values, int vsize);
        int size();
        void close();
    };
}
