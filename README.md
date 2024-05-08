# VHDL Modules and FPGA IP Cores
Target is Zynqberry SoC TE0726 with Xilinx FPGA

## Supported Wave
IP only supports sine wave thus far.

## DAC
The IP's output is a single PIN containing a PWM signal. You will need to create a simple low pass filter to see the wave on the oscilloscope

## Instantiating Block RAM with values at synthesis
Doucmentation can be found in bram_single_port_rom

## Simulating "Instantiated" Block RAM with Modelsim
Doucmentation can be found in bram_single_port_rom
