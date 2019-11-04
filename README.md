# devwraps

A collection of device wrappers for Python 3 in Windows. This library includes
support for some scientific cameras and deformable mirrors.

### Supported devices
* [Boston Micromachines](http://www.bostonmicromachines.com/) deformable mirrors
  - Multi-DM (`bmc`)
* [ALPAO](https://www.alpao.com/) deformable mirrors
  - (`asdk`)
* [Thorlabs cameras](https://www.thorlabs.com/software_pages/ViewSoftwarePage.cfm?Code=ThorCam) scientific cameras
  - Grayscale devices (`thorcam`)
* [IDS cameras](https://en.ids-imaging.com/) scientific cameras
  - Grayscale devices (`ueye`)
* [Andor cameras](http://www.andor.com/scientific-software/software-development-kit) scientific cameras
  - Grayscale devices (`sdk3`)
* [Ximea cameras](https://www.ximea.com/) scientific cameras
  - Grayscale devices (`ximea`)

### Install
Download and install some of the manufacturer drivers above. Then install the
following requirements:
* [Anaconda](https://www.anaconda.com/download)
* [Build Tools for Visual Studio](https://www.visualstudio.com/downloads/#build-tools-for-visual-studio-2017)
	- NB: these are the tools to build Visual Studio projects from a command-line, not the full Visual Studio
* [Git](https://git-scm.com/download/win)
	- NB: Make sure you choose "Git from the command line and also 3rd-party software" in "Adjusting your PATH environment"

Double click on `install.bat`.

### Known bugs
* `asdk` and `sdk3` are mostly untested
* timeout error handling in `grab_image()` is incomplete
* continuous acquisition (`start_video()` and `stop_video()`) mostly untested
