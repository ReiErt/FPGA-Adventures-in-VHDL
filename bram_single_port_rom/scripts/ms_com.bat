@echo off

:: If a refrence path is used, please first change directory to reference directory

cd C:/hdl-Clone/single_port_rom/scripts

if not exist "..\tmp" mkdir ..\tmp
cd ..\tmp
echo on

:: please map Unimacro and Unisim here

vmap unimacro ../../ms_sim_lib/unimacro
vmap unisim ../../ms_sim_lib/unisim
vmap xpm ../../ms_sim_lib/xpm

:: Verilog lib for simulation
:: vlog C:\Xilinx\Vivado\2018.3\data\verilog\src\unisim_comp.v


:: please put compile order commands here


vcom -2008 -check_synthesis ../../package/type_definitions_pckg.vhd
vcom -2008 -check_synthesis ../../package/function_pckg.vhd
::vcom -2008 -check_synthesis ../../package/vhdl_printf-master/PCK_FIO.vhd
::vcom -2008 -check_synthesis ../../reg_mem/src/reg_mem.vhd
::vcom -2008 -check_synthesis ../../mult_sign_v1/src/mult_sign_v1.vhd
::vcom -2008 -check_synthesis ../../saw_tooth_gen/src/saw_tooth_gen_pckg.vhd
::vcom -2008 -check_synthesis ../../saw_tooth_gen/src/saw_tooth_gen.vhd
::vcom -2008 -check_synthesis ../../trunc/src/trunc.vhd
::vcom -2008 -check_synthesis ../../round/src/round.vhd
::vcom -2008 -check_synthesis ../../addsub_sign/src/addsub_sign.vhd
vcom -2008 -check_synthesis ../../single_port_rom/src/single_port_rom.vhd
vcom -2008 -check_synthesis ../../single_port_rom/TestBench/tb_single_port_rom.vhd
