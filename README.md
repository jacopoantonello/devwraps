# devwraps

Some device wrappers for Python 3.

### Supported devices
* [Boston Micromachines](http://www.bostonmicromachines.com/)
  - Multi-DM (`bmc`)
* [ALPAO](https://www.alpao.com/)
  - (`asdk`)
* [Thorlabs cameras](https://www.thorlabs.com/software_pages/ViewSoftwarePage.cfm?Code=ThorCam)
  - Grayscale devices (`thorcam`)
* [IDS cameras](https://en.ids-imaging.com/)
  - Grayscale devices (`ueye`)
* [Andor cameras](http://www.andor.com/scientific-software/software-development-kit)
  - Grayscale devices (`sdk3`)
* [Ximea cameras](https://www.ximea.com/)
  - Grayscale devices (`ximea`)

### Install
Download and install the manufacturer drivers. Then install the following components:
* [Anaconda](https://www.anaconda.com/download)
* [Build Tools for Visual Studio](https://www.visualstudio.com/downloads/#build-tools-for-visual-studio-2017)
	- NB: these are the tools to build Visual Studio projects from a command-line, not the full Visual Studio)
* [Git](https://git-scm.com/download/win)
	- NB: Make sure you choose "Git from the command line and also 3rd-party software" in "Adjusting your PATH environment"

Double click on `install.bat`.

### Known bugs
* `asdk` mostly untested
* timeout error handling in `grab_image()` is incomplete
* continuous acquisition (`start_video()` and `stop_video()`) mostly untested
