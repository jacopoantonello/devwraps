# devwraps

A collection of device wrappers for Python 3 in Windows. This library includes support for some scientific cameras and deformable mirrors.

### Supported devices
* [Boston Micromachines](http://www.bostonmicromachines.com/) deformable mirrors
  - Multi-DM (`bmc`)
* [ALPAO](https://www.alpao.com/) deformable mirrors
  - (`asdk`)
* [Thorlabs](https://www.thorlabs.com/software_pages/ViewSoftwarePage.cfm?Code=ThorCam) scientific cameras
  - Grayscale devices (`thorcam`)
* [IDS](https://en.ids-imaging.com/) scientific cameras
  - Grayscale devices (`ueye`)
* [Andor](http://www.andor.com/scientific-software/software-development-kit) scientific cameras
  - Grayscale devices (`sdk3`)
* [Ximea](https://www.ximea.com/) scientific cameras
  - Grayscale devices (`ximea`)

### Install
* Download and install the drivers for the devices you want to use from the ones listed above. Make sure to install the development API in case this is optional.
* You should then install the following software requirements:
    * [Anaconda for Python 3](https://www.anaconda.com/download). This includes Python as well as some necessary scientific libraries.
    * [Build Tools for Visual Studio](https://go.microsoft.com/fwlink/?linkid=840931). Note that this is not *Visual Studio* ifself, but the command-line interface *Build Tools for Visual Studio 2019*. You can find that under *Tools for Visual Studio*. During the installation use the default configuration but make sure that the *Windows 10 SDK* and the *C++ x64/x86 build tools* options are enabled.
    * [Git](https://git-scm.com/download/win). This is necessary for the automatic version numbering of this package. Also make sure you choose *Git from the command line and also 3rd-party software* in *Adjusting your PATH environment*.
* *Clone* this repository using Git. Do not use GitHub's *Download ZIP* button above.
* Finally double-click on `install.bat`.

### Known bugs
* `asdk` and `sdk3` are mostly untested
* timeout error handling in `grab_image()` is incomplete
* continuous acquisition (`start_video()` and `stop_video()`) mostly untested
