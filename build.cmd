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

for /f "delims=" %%v in (mesa\VERSION) do set MESA_VERSION=%%v

call :build x86  Win32  x86
call :build x64  x64    x86_64
::           ^     ^     ^
::           |     |     |
::           |     |     +------- Mesa 3D (SCons) architecture
::           |     +------------- Visual Studio and CMake architecture
::           +------------------- Target architecture, name for build and binary directories

popd

:exit
    echo.
    pause
    goto :eof

:build
    set ARCH=%1
    set VS_ARCH=%2
    set MESA_ARCH=%3

    :: Build LLVM

    set LLVM=%~dp0\llvm\dist\%ARCH%
    set LLVM_BUILD_DIR=llvm\build\%ARCH%

    if not exist %LLVM_BUILD_DIR% (
        md %LLVM_BUILD_DIR%
    )

    cd %LLVM_BUILD_DIR%

    "%~dp0\tools\cmake\bin\cmake.exe" ^
        -A %VS_ARCH% ^
        -T v140_xp ^
        -DCMAKE_BUILD_TYPE=Release ^
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
        "%~dp0\llvm\src"

    devenv LLVM.sln /build Release /project INSTALL

    :: Build Mesa 3D

    cd "%~dp0\mesa"
    python.exe ..\tools\scripts\scons.py machine=%MESA_ARCH% build=release llvm=yes MSVC_VERSION=14.0

    cd "%~dp0"
    devenv dxtn\dxtn.sln /build "Release|%VS_ARCH%"

    set BIN_DIR=bin\%ARCH%

    if not exist %BIN_DIR% (
        md %BIN_DIR%
    )

    xcopy mesa\build\windows-%MESA_ARCH%\gallium\targets\libgl-gdi\opengl32.dll %BIN_DIR% /D /Y
    xcopy mesa\build\windows-%MESA_ARCH%\compiler\glsl_compiler.exe %BIN_DIR% /D /Y
    xcopy dxtn\build\%VS_ARCH%\Release\dxtn.dll %BIN_DIR% /D /Y

    7z.exe a bin\mesa3d-%MESA_VERSION%-%1.7z -y -t7z -mx=9 -ms=off .\bin\%1\*.* .\mesa\docs\VERSIONS

    goto :eof
