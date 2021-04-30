# devwraps

A collection of device wrappers for Python 3 in Windows. This library includes support for some scientific cameras and deformable mirrors.

### Supported devices
* [Boston Micromachines](http://www.bostonmicromachines.com/) deformable mirrors
  - Multi-DM and Kilo-C-S-DM (`bmc`)
* [ALPAO](https://www.alpao.com/) deformable mirrors
  - (`asdk`)
* [Imagine Optic](https://www.imagine-optic.com) Mirao52e deformable mirrors
  - (`mirao52e`)
* [Thorlabs](https://www.thorlabs.com/software_pages/ViewSoftwarePage.cfm?Code=ThorCam) scientific cameras
  - Grayscale DCx compact USB cameras (`thorcam`)
* [IDS](https://en.ids-imaging.com/) scientific cameras
  - Grayscale DCx USB cameras (`ueye`)
* [Andor](http://www.andor.com/scientific-software/software-development-kit) scientific cameras
  - Grayscale devices (`sdk3`)
* [Ximea](https://www.ximea.com/) scientific cameras
  - Grayscale devices (`ximea`)

### DLLs and device drivers paths
If some device drivers are not installed in their default location then you should edit `dll_paths.py`. Just add the non-standard *absolute* paths to the corresponding dictionary entry. For example, if the Mirao52e folder is in `C:\dir1\dir2\Mirao`, then you should add `'C:\\dir1\\dir2\\Mirao'` to `'mirao52e'`. You may want to add the DLLs manually after installation.

```python
import devwraps

# removes all DLLs
devwraps.remove_dlls()

# look for DLLs according to the paths specified in `dll_paths.py`
devwraps.look_for_dlls()

# print the root folder of this module
print(devwraps.get_root_folder)
```

### Install
* Download and install the drivers for the devices you want to use from the ones listed above. Make sure to install the development API in case this is optional.
* You should then install the following software requirements:
    * [Anaconda for Python 3](https://www.anaconda.com/download). This includes Python as well as some necessary scientific libraries.
    * [Build Tools for Visual Studio](https://go.microsoft.com/fwlink/?linkid=840931). Note that this is not *Visual Studio* ifself, but the command-line interface *Build Tools for Visual Studio 2019*. You can find that under *Tools for Visual Studio*. During the installation use the default configuration but make sure that the *Windows 10 SDK* and the *C++ x64/x86 build tools* options are enabled.
    * [Git](https://git-scm.com/download/win). This is necessary for the automatic version numbering of this package. Also make sure you choose *Git from the command line and also 3rd-party software* in *Adjusting your PATH environment*.
* *Clone* this repository using Git. Do not use GitHub's *Download ZIP* button above.
* Finally double-click on `install.bat`.

### Testing
* Open an `Anaconda Prompt` and type `python -m devwraps.test`

### Known bugs
* The `asdk`, `sdk3`, and `mirao52e` modules are mostly untested
* Timeout error handling in `grab_image()` is incomplete
* Continuous acquisition (`start_video()` and `stop_video()`) is mostly untested
