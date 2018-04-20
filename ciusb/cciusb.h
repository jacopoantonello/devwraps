/*

author: J. Antonello <jacopo.antonello@dpag.ox.ac.uk>
date: Mon Feb 26 07:32:24 GMT 2018

*/

#ifndef _WIN32_WINNT
#define _WIN32_WINNT 0x0500     // The DPIO2 driver was written for Windows 2000
#endif							// Keep this at 0x500

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
