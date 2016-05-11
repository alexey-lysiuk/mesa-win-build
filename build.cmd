@echo off

pushd "%~dp0"

if not exist mesa\SConstruct (
    echo No Mesa 3D source code found
    echo.
    echo Either initialize Git submodule, e.g. using command line: git submodule update --init
    echo or download source code from http://www.mesa3d.org and put it into mesa directory
    goto exit
)

set PATH=%~dp0\tools;%PATH%

cd mesa
python.exe ..\tools\scripts\scons.py build=release

:exit
echo.
pause

popd
