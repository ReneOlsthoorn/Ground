@echo off

del /Q /F gallery.bat
del /Q /F curl-win64-mingw.zip
del /Q /F libcurl-x64.dll
del /Q /F libmikmod.tar.zst
del /Q /F libcglm.tar.zst
del /Q /F load.bat
del /Q /F SDL3_image-win32-x64.zip
del /Q /F SDL3-win32-x64.zip
del /Q /F soloud.zip
del /Q /F stockfish-windows-x86-64-avx2.zip
del /Q /F zstd.exe
del /Q /F zstd-win64.zip

call :compileExample 3d
call :compileExample bertus
call :compileExample bugs
call :compileExample chess
call :compileExample fire
call :compileExample fireworks
call :compileExample game_of_life
call :compileExample hello_world
call :compileExample high_noon
call :compileExample jump
call :compileExample memory
call :compileExample mode7
call :compileExample mode7_optimized
call :compileExample plasma
call :compileExample plasma_non_colorcycling
call :compileExample racer
call :compileExample smoothscroller
call :compileExample snake
call :compileExample star_taste
call :compileExample sudoku
call :compileExample tetrus
call :compileExample win32_screengrab
call :compileExample electronic_life

del /Q /F GroundCompiler.pdb
del /Q /F GroundCompiler.deps.json
del /Q /F sudoku.exe

rem removing chessrelated files
rmdir /Q /S chessgames
rmdir /Q /S image\chess
del /Q /F image\connect4_board.png
del /Q /F image\connect4_p1.png
del /Q /F image\connect4_p2.png
rmdir /Q /S misc
del /Q /F chess.exe
del /Q /F stockfish-windows-x86-64-avx2.exe

goto :eof

:compileExample
GroundCompiler.exe %1.g
del /Q /F %1.asm
goto :eof
