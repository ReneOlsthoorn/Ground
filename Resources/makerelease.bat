@echo off

del /Q /F curl-win64-mingw.zip
del /Q /F libcurl-x64.dll
del /Q /F libmikmod.tar.zst
del /Q /F libcglm.tar.zst
del /Q /F load.bat
del /Q /F raylib-6.0.zip
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
call :compileExample electronic_life
call :compileExample fire
call :compileExample fireworks
call :compileExample game_of_life
call :compileExample hello_world
call :compileExample hexacubes
call :compileExample high_noon
call :compileExample jump
call :compileExample memory
call :compileExample mode7
call :compileExample mode7_optimized
call :compileExample plasma
call :compileExample plasma_non_colorcycling
call :compileExample racer
call :compileExample raylib_atan_spiral
call :compileExample raylib_circles
call :compileExample raylib_cosmic_cycles
call :compileExample raylib_cube
call :compileExample raylib_cyber
call :compileExample raylib_exitmatrix
call :compileExample raylib_fireball
call :compileExample raylib_genuary24
call :compileExample raylib_interference
call :compileExample raylib_introduction
call :compileExample raylib_logacircles
call :compileExample raylib_octahedralis
call :compileExample raylib_onderwater
call :compileExample raylib_plasma
call :compileExample raylib_quantumfield
call :compileExample raylib_ringtwister
call :compileExample raylib_rubber_cube
call :compileExample raylib_slitscan
call :compileExample raylib_starfall
call :compileExample raylib_starnest
call :compileExample raylib_swirl
call :compileExample raylib_zoom
call :compileExample smoothscroller
call :compileExample snake
call :compileExample snippet_circles
call :compileExample snippet_fern
call :compileExample snippet_spiral
call :compileExample snippet_squares
call :compileExample star_taste
call :compileExample sudoku
call :compileExample tetrus
call :compileExample win32_screengrab

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
