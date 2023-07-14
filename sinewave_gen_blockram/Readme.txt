-- Description: Sine wave generator makes sine wave in desired amplitude and frequency using FPGA block ram.
-- takes x values and delivers y values for a sine wave

  -- Our block memory stores values for sine wave from 0 to pi/2.
  -- This module takes an incoming value from -1 to +1 and maps that value to an address in block memory.
  -- For requested x values outside of 0 to pi/2, combinational logic calculates the requested address.
  -- Output is the amplitude of a sine wave.
  -- After mapping, if the input address is less than 0, we negate the value found in address. (see process 3)

  -- To map a linear plane (values from -1 to +1) to another linear plane...
  -- (values from [-2*gi_bram_sample_rate] to [2*gi_bram_sample_rate])
  -- ...we use the affine transformation equation:

  -- output_value = (input_value + 1) * ((ci_highest_address - ci_lowest_address) / (1 + 1)) + ci_lowest_address

  -- ((ci_highest_address - ci_lowest_address) / (1 + 1)) is held as a constant called "ci_affine_transformation"
  -- note this equation assumes the value of our incoming signal is between -1 and 1