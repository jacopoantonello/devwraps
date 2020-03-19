Activate-Anaconda
if (-not $?) {
	exit
}
pip uninstall -y devwraps
if (-not $?) {
	exit
}
rm dist\*.whl -ErrorAction SilentlyContinue
python setup.py bdist_wheel
if (-not $?) {
	exit
}
pip install (get-item .\dist\*.whl)
python test\test_imports.py
