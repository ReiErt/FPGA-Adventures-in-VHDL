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
  // values stored in local signals
  assign sign_a = a_in[WIDTH-1];
  assign sign_b = b_in[WIDTH-1];
  assign exponent_a = a_in[EXP+MANTISSA-1:MANTISSA];
  assign exponent_b = b_in[EXP+MANTISSA-1:MANTISSA];
  assign mantissa_a = a_in[MANTISSA-1:0];
  assign mantissa_b = b_in[MANTISSA-1:0];
  
  assign debiased_exponent_a = BIAS + exponent_a;
  assign debiased_exponent_b = BIAS + exponent_b;

  // Purpose: error detection. exponent must be between 1 and 254.
  always@(*)
  begin
    if((exponent_a == 8'h00) || (exponent_b == 8'h00))
      // underflow
      begin
        underflow_flag = 1'b1;
        overflow_flag = 0'b0;
      end
    else if(exponent_a == 8'hff || exponent_b == 8'hff)
      // overflow
      begin
        overflow_flag = 1'b1;
        underflow_flag = 0'b0;
      end
    else // 1 <= exponent <= 254
      // good. we can proceed
      begin
        overflow_flag = 1'b0;
        underflow_flag = 1'b0;
      end
  end

  // Purpose: compare both operands. find which has more magnitude
  always@(*)
  begin
    if(exponent_a != exponent_b)
    // if not equal, we need to find which is larger
    begin


      if (exponent_a > exponent_b)
      begin
        greater_num = exponent_a;
        lesser_num = exponent_b;
        tmp_bias_diff = exponent_a - exponent_b;
        new_mantissa_b = (mantissa_b >> tmp_bias_diff);
        new_mantissa_a = mantissa_a;
        combined_mantissa = new_mantissa_a + new_mantissa_b;
        sum_out = {sign_a,exponent_a,combined_mantissa[22:0]};
      end
      else // exponent_b > exponent_a
      begin
        tmp_bias_diff = exponent_b - exponent_a;
        new_mantissa_a = (mantissa_a >> tmp_bias_diff);
        new_mantissa_b = mantissa_b;
        combined_mantissa = new_mantissa_b + new_mantissa_a;
        sum_out = {sign_b,exponent_b,combined_mantissa[22:0]};
      end
    end
    else  //if exponents are equal, measure mantissa
    begin
      if (mantissa_a >= mantissa_b)
      begin
        tmp_bias_diff = 8'b0;
        new_mantissa_a = mantissa_a;
        new_mantissa_b = mantissa_b;
        combined_mantissa = new_mantissa_b + new_mantissa_a;
        sum_out = {sign_a,exponent_a,combined_mantissa[22:0]};
      end
      else // manstissa_b > mantissa_b
      begin
        tmp_bias_diff = 8'b0;
        new_mantissa_a = mantissa_a;
        new_mantissa_b = mantissa_b;
        combined_mantissa = new_mantissa_a + new_mantissa_b;
        sum_out = {sign_b,exponent_b,combined_mantissa[22:0]};
      end
    end
  end


/*
      // determine whether mantissa_a or mantissa_b is higher
      if (mantissa_a >= mantissa_b)
        mantissa_sum = mantissa_a - mantissa_b;
      else // mantissa_a < mantissa_b
        mantissa_sum = mantissa_b - mantissa;
      sum_out = 32'h00_00_00_00;
    else if(exponent_a > exponent_b)

      sum_out = 32'h11_11_11_11;
    else // (exponent_a < exponent_b)
      sum_out = 32'h22_22_22_22;
  end
*/
/*
  always @*
  begin
    // seperate magnitude and a
    mag_a = a[N-2:0];
    mag_b = b[N-2:0];
    sign_a = a[N-1];
    sign_b = b[N-1];
    
    if (mag_a > mag_b)
      begin
          max = mag_a;
          min = mag_b;
          sign_sum = sign_a;
      end
    else
      begin
          max = mag_b;
          min = mag_a;
          sign_sum = sign_b;
          
    if (sign_a == sign_b)
      mag_sum = max + min;
    else 
      mag_sum = max - min;
    sum = {sign_sum, mag_sum};
      end
  end
    */
endmodule