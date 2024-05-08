# VHDL Modules and FPGA IP Cores
Target is Zynqberry SoC TE0726 with Xilinx FPGA

## Supported Wave
IP only supports sine wave thus far.

## DAC
The IP's output is a single PIN containing a PWM signal. You will need to create a simple low pass filter to see the wave on the oscilloscope
