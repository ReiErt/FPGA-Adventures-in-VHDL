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


module tb_IEEE_SP_FP_Addr
  #(parameter WIDTH = 32,
  parameter EXP = 8,
  parameter MANTISSA = 23)
  ();
  // signal declaration
  //wire tb_sign_a,tb_sign_b;
  //wire [EXP-1:0] tb_exponent_a, tb_exponent_b;
  //wire [MANTISSA-1:0] tb_mantissa_a, tb_mantissa_b;
  reg [WIDTH-1:0] tb_a_in, tb_b_in;
  wire [WIDTH-1:0] tb_sum_out;
  wire tb_underflow_flag;
  wire tb_overflow_flag;

  IEEE_SP_FP_Addr #() IEEE_SP_FP_Addr_inst
  (
    .a_in(tb_a_in),
    .b_in(tb_b_in),
    .sum_out(tb_sum_out),
    .underflow_flag(tb_underflow_flag),
    .overflow_flag(tb_overflow_flag)
  );
    
  initial begin

    //Test 1: is A or B greater?
    // EXP a is greater
    // then mantissa of B moves back x spaces
    // add mantissa and output on wire
    tb_a_in = 32'b1_01010111_1100000_00000000_00000000;
    tb_b_in = 32'b1_01010101_1100000_00000000_00000000;
    #10;

    //Test 2: is A or B greater? 
    // EXP b is greater
    // then mantissa of A moves back x spaces
   // add mantissa and output on wire
    tb_a_in = 32'b1_01010100_1100000_00000000_00000000;
    tb_b_in = 32'b1_01010111_1100000_00000000_00000000;
    #10;

    //Test 3: is A or B greater?
    // the larger number is negative
    tb_a_in = 32'b0_01010100_1100000_00000000_00000000;
    tb_b_in = 32'b1_01010111_1100000_00000000_00000000;
    #10; 

    //Test 4: is A or B greater?
    // the larger number is positive
    tb_b_in = 32'b1_01010100_1100000_00000000_00000000;
    tb_a_in = 32'b0_01011110_1100000_00000000_00000000;
    #10;

  end
    
endmodule