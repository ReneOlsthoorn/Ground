@echo off

if not exist bin\Debug (
  mkdir bin\Debug
)

tar -xf Resources\GroundResources.zip -C bin\Debug
copy Resources\load.bat bin\Debug\load.bat /Y
copy Resources\makerelease.bat bin\Debug\makerelease.bat /Y

pushd bin\Debug
call load.bat
popd 

robocopy bin\Debug bin\Release /MIR /E

goto :eof
