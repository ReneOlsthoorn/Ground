@echo off

if not exist bin\Debug (
  mkdir bin\Debug
)

tar -xf Resources\GroundResources.zip -C bin\Debug

pushd bin\Debug
call load.bat
popd 

robocopy bin\Debug bin\Release /MIR /E

goto :eof
