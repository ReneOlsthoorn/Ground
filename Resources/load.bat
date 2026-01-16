@echo off


rem  *** SDL3.dll ***
set THEFILE="SDL3-win32-x64.zip"
if exist %THEFILE% (
  echo File %THEFILE% already exists. Skipping download.
) else (
  echo Downloading %THEFILE%...
  curl -L -o %THEFILE% "https://github.com/libsdl-org/SDL/releases/download/release-3.4.0/SDL3-3.4.0-win32-x64.zip"
)
tar -xf %THEFILE% SDL3.dll


rem  *** SDL3_image.dll ***
set THEFILE="SDL3_image-win32-x64.zip"
if exist %THEFILE% (
  echo File %THEFILE% already exists. Skipping download.
) else (
  echo Downloading %THEFILE%...
  curl -L -o %THEFILE% "https://github.com/libsdl-org/SDL_image/releases/download/release-3.2.4/SDL3_image-3.2.4-win32-x64.zip"
)
tar -xf %THEFILE% SDL3_image.dll


rem  *** libcurl-x64.dll ***  Needed for the ConnectFour example
set THEFILE="curl-win64-mingw.zip"
if exist %THEFILE% (
  echo File %THEFILE% already exists. Skipping download.
) else (
  echo Downloading %THEFILE%...
  curl -L -o %THEFILE% "https://curl.se/windows/dl-8.16.0_2/curl-8.16.0_2-win64-mingw.zip"
)
tar -xf %THEFILE%
move curl-8.16.0_2-win64-mingw\bin\libcurl-x64.dll .
rmdir /s /q curl-8.16.0_2-win64-mingw


rem  *** zstd.exe decompresser ***  Needed to decompress mikmod and other MSYS2 packages
set THEFILE="zstd-win64.zip"
if exist %THEFILE% (
  echo File %THEFILE% already exists. Skipping download.
) else (
  echo Downloading %THEFILE%...
  curl -L -o %THEFILE% "https://github.com/facebook/zstd/releases/latest/download/zstd-v1.5.7-win64.zip"
)
tar -xf %THEFILE%
move zstd-v1.5.7-win64\zstd.exe .
rmdir /s /q zstd-v1.5.7-win64


rem  *** libmikmod-3.dll ***  Needed to play Amiga Soundtracker files
set THEFILE="libmikmod.tar.zst"
if exist %THEFILE% (
  echo File %THEFILE% already exists. Skipping download.
) else (
  echo Downloading %THEFILE%...
  curl -L -o %THEFILE% "https://mirror.msys2.org/mingw/mingw64/mingw-w64-x86_64-libmikmod-3.3.13-1-any.pkg.tar.zst"
)
zstd.exe -df %THEFILE%
mkdir libmikmod
tar -xf libmikmod.tar -C libmikmod
move libmikmod\mingw64\bin\libmikmod-3.dll .
rmdir /s /q libmikmod
del /Q /F libmikmod.tar


rem  *** libcglm-0.dll ***  3d matrix
set THEFILE="libcglm.tar.zst"
if exist %THEFILE% (
  echo File %THEFILE% already exists. Skipping download.
) else (
  echo Downloading %THEFILE%...
  curl -L -o %THEFILE% "https://mirror.msys2.org/mingw/mingw64/mingw-w64-x86_64-cglm-0.9.6-1-any.pkg.tar.zst"
)
zstd.exe -df %THEFILE%
mkdir libcglm
tar -xf libcglm.tar -C libcglm
move libcglm\mingw64\bin\libcglm-0.dll .
rmdir /s /q libcglm
del /Q /F libcglm.tar


rem  *** soloud_x64.dll ***  Needed to play Sound effects
set THEFILE="soloud.zip"
if exist %THEFILE% (
  echo File %THEFILE% already exists. Skipping download.
) else (
  echo Downloading %THEFILE%...
  curl -L -o %THEFILE% "https://solhsa.com/soloud/soloud_20200207.zip"
)
tar -xf %THEFILE%
move soloud20200207\bin\soloud_x64.dll .
rmdir /s /q soloud20200207


rem  *** stockfish-windows-x86-64-avx2.exe ***  This is the worlds best Chess engine.
set THEFILE="stockfish-windows-x86-64-avx2.zip"
if exist %THEFILE% (
  echo File %THEFILE% already exists. Skipping download.
) else (
  echo Downloading %THEFILE%...
  curl -L -o %THEFILE% "https://github.com/official-stockfish/Stockfish/releases/latest/download/stockfish-windows-x86-64-avx2.zip"
)
tar -xf %THEFILE%
move stockfish\stockfish-windows-x86-64-avx2.exe .
rmdir /s /q stockfish
