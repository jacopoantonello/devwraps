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


#include "cciusb.h"

namespace shapes {

	CCIUsb::CCIUsb() {
		mydevice = -1;
		pIHostDrv = NULL;

		CoInitialize(NULL);

		/*
		 * Creates a single uninitialized object of the class associated with
		 * specified CLSID=__uuidof(CHostDrv) his object will be found on the
		 * system if CIUsbLib.dll is egistered via regsvr32.exe
		 */
		HRESULT hr = CoCreateInstance(__uuidof(CHostDrv), NULL, CLSCTX_INPROC,
				__uuidof(IHostDrv), (LPVOID *) &pIHostDrv);
		if (hr == REGDB_E_CLASSNOTREG) {
			throw std::invalid_argument("The CHostDrv class is not registered");
		}
		else if (FAILED(hr)) {
			throw std::invalid_argument("Error creating CHostDrv object");
		}
	}

	CCIUsb::~CCIUsb() { }

	int CCIUsb::open(int skip) {
		long lCurDev = -1;
		long lStatus = 0;
		HRESULT hr;

		if (mydevice != -1) {
			throw std::invalid_argument("Device already opened");
		}

		/*
		 * Check for USB devices supported by the CIUsbLib The array lDevices is
		 * set by CIUsb_GetAvailableDevices to indicate which devices are present
		 * in the system In order to recognize MULTI DM devices, {CiGenUSB.sys,
		 * CiGenUSB.inf} need to be installed properly
		 */
		long lDevices[MAX_USB_DEVICES] = {-1};
		hr = pIHostDrv->CIUsb_GetAvailableDevices(lDevices,
				sizeof(lDevices)/sizeof(long), &lStatus);
		if FAILED(hr) {
			throw std::invalid_argument("Failure to get available USB devices");
		}

		for (int i = 0; i < MAX_USB_DEVICES; i++)
		{
			if (lDevices[i] != -1) {
				char cDevName[4096] = {0};
				hr = pIHostDrv->CIUsb_GetStatus(
						i, CIUsb_STATUS_DEVICENAME, (long *) cDevName);
				if FAILED(hr) {
					throw std::invalid_argument(
							"Failure to get available USB device name");
				}

				bool fFoundMulti = (strstr(cDevName, USB_DEVNAME) != NULL);
				// printf("%s", cDevName);
				// Cambridge Innovations Multi DM Driver USB Device
				if (fFoundMulti) {
					if (skip) {
						skip--;
					} else {
						lCurDev = i;
						break;
					}
				}
			}
		}

		if (lCurDev == -1) {
			// throw std::invalid_argument("No Multi DM devices were found");
			return -1;
		}

		// reset the hardware: control signal FRESET is active low
		hr = pIHostDrv->CIUsb_SetControl(lCurDev,
				CIUsb_CONTROL_DEASSERT_FRESET, &lStatus);
		if FAILED(hr) {
			throw std::invalid_argument(
					"Failure to deassert MULTI hardware reset control");
		}

		hr = pIHostDrv->CIUsb_SetControl(lCurDev,
				CIUsb_CONTROL_ASSERT_FRESET,   &lStatus);
		if FAILED(hr) {
			throw std::invalid_argument(
					"Failure to assert MULTI hardware reset control");
		}

		// assert high voltage enable
		hr = pIHostDrv->CIUsb_SetControl(lCurDev,
				CIUsb_CONTROL_ASSERT_HV_ENAB,  &lStatus);
		if FAILED(hr) {
			throw std::invalid_argument(
					"Failure to enable MULTI hardware high voltage enable");
		}

		mydevice = lCurDev;

		return 0;
	}

	int CCIUsb::get_devices() {
		int ndevices = 0;
		long lCurDev = -1;
		long lStatus = 0;
		HRESULT hr;

		/*
		 * Check for USB devices supported by the CIUsbLib The array lDevices is
		 * set by CIUsb_GetAvailableDevices to indicate which devices are present
		 * in the system In order to recognize MULTI DM devices, {CiGenUSB.sys,
		 * CiGenUSB.inf} need to be installed properly
		 */
		long lDevices[MAX_USB_DEVICES] = {-1};
		hr = pIHostDrv->CIUsb_GetAvailableDevices(lDevices,
				sizeof(lDevices)/sizeof(long), &lStatus);
		if FAILED(hr) {
			throw std::invalid_argument("Failure to get available USB devices");
		}

		for (int i = 0; i < MAX_USB_DEVICES; i++)
		{
			if (lDevices[i] != -1) {
				char cDevName[4096] = {0};
				hr = pIHostDrv->CIUsb_GetStatus(
						i, CIUsb_STATUS_DEVICENAME, (long *) cDevName);
				if FAILED(hr) {
					throw std::invalid_argument(
							"Failure to get available USB device name");
				}

				bool fFoundMulti = (strstr(cDevName, USB_DEVNAME) != NULL);
				if (fFoundMulti) {
					ndevices++;
				}
			}
		}

		return ndevices;
	}

	void CCIUsb::write(unsigned short *values, int vsize) {
		long lStatus = 0;
		unsigned short sMapData [NUM_ACTUATORS] = {0x0000};
		HRESULT hr;

		if (mydevice == -1) {
			throw std::invalid_argument("Device not opened");
		}

		// MultiDM-04.map
		int i160TestMap[NUM_ACTUATORS] = {
			125,  21, 135,  71, 136, 137, 85,  55,   0, 124,  76,  57,  67,
			33,  91,  86,  32,  30,  59,  16, 126,  41, 134, 106, 138, 102,
			90,  37,  70,  14,  89,  69, 132,  34, 122,  50,   8, 123,  19,
			18, 114,  61,  25,  95, 109, 103,  49, 121,  45, 131,  64,  20,
			42,  46,   2,  73,  31, 130,  44, 120,  79,  88,  26, 117, 159,
			115, 101, 110,  58, 140,  63,  56, 108,   9, 141,  99,  68,  29,
			36, 142,  92,  87, 107, 105, 143, 127,  54, 112,  97, 144,  51,
			43, 119,   1, 145,  53,  80,  48,  24, 146, 128,  98,   3,  11,
			147, 104,  52, 111,  35, 148,  38,  17,  60,   4, 149,  78, 139,
			133,  13, 150,  81,  75,  84,  12, 151, 129,  77,  15,  23, 152,
			65, 113,  83,  27, 153,  66, 116,  96,  28, 154,  93,  74,  82,
			47, 155,   7,  62,  94,  22, 156,  39,   5, 118,   6, 157,  40,
			100,  72,  10, 158};

		if (vsize != NUM_ACTUATORS) {
			throw std::invalid_argument("Wrong number of actuators");
		}

		for (int j = 0; j < NUM_ACTUATORS; j++)
			sMapData[j] = values[i160TestMap[j]];

		hr = pIHostDrv->CIUsb_StepFrameData(mydevice, (unsigned char *)sMapData,
				NUM_ACTUATORS*sizeof(short), &lStatus);
		if FAILED(hr) {
			throw std::invalid_argument("Failure to send MULTI frame data");
		}

		if (lStatus == H_DEVICE_NOT_FOUND) {
			throw std::invalid_argument("Framing error: device not found");
		}
		else {
			if (lStatus == H_DEVICE_TIMEOUT) {
				throw std::invalid_argument("Framing error: device timeout");
			}
		}
	}

	int CCIUsb::size() {
		return NUM_ACTUATORS;
	}

	void CCIUsb::close() {
		long lStatus = 0;
		HRESULT hr;
		unsigned short sMapData[NUM_ACTUATORS] = {0x0000};

		if (mydevice == -1) {
			throw std::invalid_argument("Device not opened");
		}

		hr = pIHostDrv->CIUsb_StepFrameData(mydevice, (unsigned char *)
				sMapData, NUM_ACTUATORS*sizeof(short), &lStatus);
		if FAILED(hr) {
			throw std::invalid_argument("Failure to send MULTI frame data");
		}

		// deassert high voltage enable
		hr = pIHostDrv->CIUsb_SetControl(mydevice,
				CIUsb_CONTROL_DEASSERT_HV_ENAB,  &lStatus);
		if FAILED(hr) {
			throw std::invalid_argument(
					"Failure to enable MULTI hardware high voltage enable");
		}

		// reset the hardware: control signal FRESET is active low
		hr = pIHostDrv->CIUsb_SetControl(mydevice,
				CIUsb_CONTROL_DEASSERT_FRESET, &lStatus);
		if FAILED(hr) {
			throw std::invalid_argument(
					"Failure to deassert MULTI hardware reset control");
		}
		hr = pIHostDrv->CIUsb_SetControl(mydevice,
				CIUsb_CONTROL_ASSERT_FRESET,   &lStatus);
		if FAILED(hr) {
			throw std::invalid_argument(
					"Failure to assert MULTI hardware reset control");
		}

		/*
		hr = pIHostDrv->Release();
		if FAILED(hr) {
			throw std::invalid_argument("Failed release");
		}
		*/

		mydevice = -1;

		// CoUninitialize(NULL);
	}
}
