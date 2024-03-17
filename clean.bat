@echo off

set sourcedir=%~dp0
rmdir /Q /S %sourcedir%.vs
rmdir /Q /S %sourcedir%bin
rmdir /Q /S %sourcedir%obj
rem del /Q /F %sourcedir%Log.txt
