@echo off

mkdir build\windows_debug 2>nul

pushd sauce\sokol
if not exist app\sokol_app_windows_x64_d3d11_debug.lib (
  echo Building sokol...
  call build_clibs_windows.cmd
)
popd

rem This package is a build script, see build.odin for more
odin run sauce\build
