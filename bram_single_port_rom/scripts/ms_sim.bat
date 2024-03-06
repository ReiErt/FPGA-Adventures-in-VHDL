@echo off

:: If a refrence path is used, please first change directory to reference directory

cd C:/hdl-Clone/single_port_rom/scripts

cd ..\tmp
IF "%1" == "-gui" GOTO GUI
GOTO BATCH

:GUI

:: Please add the topfilename that should be simulated into the next line

vsim -t ps work.tb_single_port_rom   -do ../scripts/ms_wave.tcl -do ../scripts/test.tcl

GOTO END

:BATCH

:: Please add the topfilename that should be simulated into the next line

vsim -t ps -batch work.tb_single_port_rom -do ../scripts/test.tcl

:END


