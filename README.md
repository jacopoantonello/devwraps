# devwraps

Some device wrappers for Python 3.

### Supported devices
* [Boston Micromachines](http://www.bostonmicromachines.com/)
  - Multi-DM (`ciusb`, `bmc`)
* [Thorlabs cameras](https://www.thorlabs.com/software_pages/ViewSoftwarePage.cfm?Code=ThorCam)
  - Grayscale devices (`thorcam`)
* [Andor cameras](http://www.andor.com/scientific-software/software-development-kit)
  - Grayscale devices (`sdk3`)
* [Ximea cameras](https://www.ximea.com/)
  - Grayscale devices (`ximea`)

### Install
Download and install the manufacturer drivers. Then install the following components
* [Anaconda](https://www.anaconda.com/download)
* [Build Tools](https://www.visualstudio.com/downloads/#build-tools-for-visual-studio-2017)
* [ATL](https://docs.microsoft.com/en-us/cpp/mfc/mfc-and-atl) (obsolete and required for `ciusb` only)

Double click on `install.bat`.

### Known bugs
* timeout error handling in `grab_image()`
* continuous acquisition (`start_video()` and `stop_video()`) mostly untested
