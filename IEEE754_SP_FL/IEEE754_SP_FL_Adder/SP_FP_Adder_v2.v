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
module IEEE_SP_FP_Addr
  #(parameter WIDTH = 32,
  parameter EXP = 8,
  parameter MANTISSA = 23)
  (
  input [WIDTH-1:0] a_in,b_in,
  output reg [WIDTH-1:0] sum_out,
  output reg underflow_flag,
  output reg overflow_flag
);

  //parameter area
  localparam BIAS = 8'b10000001;

  // signal declaration
  wire sign_a,sign_b;
  wire [EXP-1:0] debiased_exponent_a;
  wire [EXP-1:0] debiased_exponent_b;
  reg [7:0] tmp_bias_diff;

  // debiased
  wire [EXP-1:0] exponent_a, exponent_b;
  wire [MANTISSA-1:0] mantissa_a, mantissa_b;

  reg [MANTISSA-1:0] new_mantissa_a;
  reg [MANTISSA-1:0] new_mantissa_b;
    // combined mantissa is 1 big longer -> to catch overflow
  reg [MANTISSA:0] combined_mantissa;
  reg [32-1:0] greater_num, lesser_num;
  reg [MANTISSA:0] mantissa_sum;
  // values stored in local signals

  wire xor_output;
  assign sign_a = a_in[WIDTH-1];
  assign sign_b = b_in[WIDTH-1];
  assign exponent_a = a_in[EXP+MANTISSA-1:MANTISSA];
  assign exponent_b = b_in[EXP+MANTISSA-1:MANTISSA];
  assign mantissa_a = a_in[MANTISSA-1:0];
  assign mantissa_b = b_in[MANTISSA-1:0];
  
  assign debiased_exponent_a = BIAS + exponent_a;
  assign debiased_exponent_b = BIAS + exponent_b;


  // if a is greater or equal to b, comp = 1, otherwise 0;
  comp = (a_in[WIDTH-2] >= b_in[WIDTH-2]) ? 1'b1 : 1'b0;
  // establish magnitude
  max = comp ? a_in : b_in;
  min = ~comp ? a_in : b_in;

  assign xor_output = a_in[31] ^ b_in[31];
  // check sign. if sign are different, we subtract
  // if signs same, we add
  always@(xor_output)
  begin
    case(xor_output)
      // signs are same, we add mantissa
      1'd0: mantissa_sum = max[MANTISSA-1] + min[MANTISSA-1];
      1'd0: mantissa_sum = max[MANTISSA-1] - min[MANTISSA-1];
      default: mantissa_sum = max[MANTISSA-1] + min[MANTISSA-1];;
    endcase
  end

  // after adding, if new leading bit of mantissa == 1, shift
  always@(mantissa_sum[MANTISSA])
  begin 
    case (mantissa_sum[MANTISSA])
      1'd1: 
      begin
        mantissa_sum = (mantissa_sum >> 1);
        exponent = exponent + 1;
      end
      1'd0: mantissa_sum = mantissa_sum       
    default:
    endcase
  end


endmodule