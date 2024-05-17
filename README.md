# VHDL Modules and FPGA IP Cores
Target is Zynqberry SoC TE0726 with Xilinx FPGA. Features AXI interface to help pipelining.

## Supported Wave
IP has been optimsed for the sine wave, as only a fourth of a sinewave's period is necessary to recreate it in full. Adding other wave forms is a simple matter of plotting their data with numpy over python and instantiating block ram with those values.

## DAC
The IP's output is a single PIN containing a PWM signal. You will need to create a simple low pass filter to see the wave on the oscilloscope

## Instantiating Block RAM with values at synthesis
Doucmentation can be found in bram_single_port_rom

## Simulating "Instantiated" Block RAM with Modelsim
Doucmentation can be found in bram_single_port_rom
