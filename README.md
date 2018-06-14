devwraps
========

Some device wrappers for Python 3.


Compiling requirements
----------------------
* [Anaconda](https://www.anaconda.com/download)
* [Build Tools](https://www.visualstudio.com/downloads/#build-tools-for-visual-studio-2017)
* [ATL](https://docs.microsoft.com/en-us/cpp/mfc/mfc-and-atl) (required for `ciusb`)


Supported devices
-----------------
* [Boston Micromachines](http://www.bostonmicromachines.com/)
  - Multi-DM (`ciusb`, `bmc`)
* [Thorlabs cameras](https://www.thorlabs.com/software_pages/ViewSoftwarePage.cfm?Code=ThorCam)
  - Grayscale devices (`thorcam`)
* [Andor cameras](http://www.andor.com/scientific-software/software-development-kit)
  - Grayscale devices (`sdk3`)


Known bugs
----------
* timeout error handling in `grab_image()`
* continuous acquisition (`start_video()` and `stop_video()`) mostly untested


Install
-------

    $ python setup.py bdist_wheel
    $ pip install dist\devwraps-*.whl


Develop
-------

    $ python setup.py develop --user
