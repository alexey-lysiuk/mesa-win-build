@echo off

if not defined VS140COMNTOOLS (
    echo ERROR: Visual Studio 2015 is not installed
    goto exit
)

if not exist mesa\SConstruct (
    echo ERROR: No Mesa 3D source code found
    echo.
    echo Either initialize Git submodule, e.g. using command line: git submodule update --init
    echo or download source code from http://www.mesa3d.org and put it into mesa directory
    goto exit
)

if not exist llvm\src\CMakeLists.txt (
    echo ERROR: No LLVM source code found
    echo.
    echo Either initialize Git submodule, e.g. using command line: git submodule update --init
    echo or download source code from http://llvm.org/ and put it into llvm\src directory
    goto exit
)

call "%VS140COMNTOOLS%vsvars32.bat"

pushd "%~dp0"

set PATH=%~dp0\tools;%PATH%
set LLVM=%~dp0\llvm\dist

:: Build LLVM

if not exist llvm\build (
    md llvm\build
)

cd llvm\build

..\..\tools\cmake\bin\cmake.exe ^
    -T v140_xp ^
    -DCMAKE_INSTALL_PREFIX=%LLVM% ^
    -DLLVM_TARGETS_TO_BUILD=X86 ^
    -DLLVM_INCLUDE_DOCS=NO ^
    -DLLVM_INCLUDE_EXAMPLES=NO ^
    -DLLVM_INCLUDE_TESTS=NO ^
    -DLLVM_INCLUDE_TOOLS=NO ^
    -DLLVM_INCLUDE_UTILS=NO ^
    -DLLVM_BUILD_DOCS=NO ^
    -DLLVM_BUILD_EXAMPLES=NO ^
    -DLLVM_BUILD_RUNTIME=NO ^
    -DLLVM_BUILD_TESTS=NO ^
    -DLLVM_BUILD_TOOLS=NO ^
    -DLLVM_USE_CRT_DEBUG=MTd ^
    -DLLVM_USE_CRT_MINSIZEREL=MT ^
    -DLLVM_USE_CRT_RELEASE=MT ^
    -DLLVM_USE_CRT_RELWITHDEBINFO=MT ^
    ..\src

devenv LLVM.sln /build Release /project INSTALL

cd ..\..

:: Build Mesa 3D

cd mesa
python.exe ..\tools\scripts\scons.py build=release llvm=yes MSVC_VERSION=14.0 %*

popd

:exit
echo.
pause
