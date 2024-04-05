`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 28.03.2024 20:02:39
// Design Name: 
// Module Name: DUT
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


/*
 How the IEEE 754 shows a bit
  1|   8    |          23
31 | 30-23  |        22 - 0
  0|00000000|00000000000000000000000
*/

/* ------------  EXPONENT SPECIAL CASES --------------
EXP is UNSIGNED.
 must be between 1 and 254. between 0000_0001 and 1111_1110.
Values 0 and 255 are illegal.
IF EXP = 0, Number is 0
IF EXP = 255, not a number. EXCEPTION

De-biased is SIGNED.
De-biased exponent must between 127 and -126
  between 0111_1111 and 1000_0010
  -126 <= debias-exp <= 127
*/


/* ------------ HOW TO DO THIS. STEP BY STEP GUIDE

1. Analyse exponent of both operands. DONE
2. Error checking NOW. Exponent must be between 1 and 254. DONE
3. Subtract 127 from EXP to receive bias.  (ex. 132-127 = 5) DONE
4. Compare both biases (and mantissa) to find which operand is higher in value DONE
5. If biases !=, shift mantissa x spaces to right (thereby making it smaller) DONE
6. With biases equal, add Mantissa. Add carry out flag.
7. If result is 2 or greater, shift mantissa to right and increase bias
8. Add 127 to bias.
9. Concatonate sign, exponent, mantissa and output to TB.

*/
module tb_fifo #()();

parameter T = 10;
parameter WORD_WIDTH = 8;
parameter ADD_WIDTH = 3;

// DUT inputs
reg tb_clk_in;
reg tb_reset_in;
reg [WORD_WIDTH-1:0] tb_data_in; 
reg tb_write_en_in;
reg tb_read_en_in;

// DUT outputs
wire [WORD_WIDTH-1:0] tb_data_out;
wire tb_fifo_full_out;
wire tb_fifo_empty_out;

// instantiation area
fifo #(.WORD_WIDTH(WORD_WIDTH), .ADD_WIDTH(ADD_WIDTH)) 
fifo_inst
  (.clk_in(tb_clk_in),
  .reset_in(tb_reset_in),
  .data_in(tb_data_in),
  .write_en_in(tb_write_en_in),
  .read_en_in(tb_read_en_in),
  .data_out(tb_data_out),
  .fifo_full_out(tb_fifo_full_out),
  .fifo_empty_out(tb_fifo_empty_out)
);

//clock program
always begin
  tb_clk_in = 1'b1;
  #(T/2);
  tb_clk_in = 1'b0;
  #(T/2);
end

//reset program
initial begin
  tb_reset_in = 1'b1;
  @(posedge tb_clk_in);
  tb_reset_in = 1'b0; 
  @(posedge tb_clk_in);
end
integer i;

// program to fed fifo
initial begin
  tb_data_in = 0;
  tb_write_en_in = 0;
  @(negedge tb_reset_in);
  for(i = 0; i<100; i=i+1) begin
    @(posedge tb_clk_in);
    tb_write_en_in = (i%2 == 0)? 1'b1 : 1'b0;
      // if write enable set and data valid
      if (tb_write_en_in & !tb_fifo_full_out) 
      tb_data_in = $random;
  end
end

initial begin
  tb_read_en_in = 0;
  #20;
  for(i = 0; 20<i<100; i=i+1) begin
    @(posedge tb_clk_in);
    tb_read_en_in = (i%2 == 0) ? 1'b1 : 1'b0;
    //if (tb_read_en_in & !tb_fifo_empty_out)
  end
end

endmodule