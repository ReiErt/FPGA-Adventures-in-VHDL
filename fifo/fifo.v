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

// vld_in - write_en_in
// rdy_out - not(full)
//
// vld_out - not(empty)
// rdy_in - read_en_in


module fifo
  #(parameter WORD_WIDTH = 8,
  parameter ADD_WIDTH = 4)
  (
  input clk_in, reset_in,
  input write_en_in,
  input read_en_in,
  input [WORD_WIDTH-1:0] data_in, 
  output wire [WORD_WIDTH-1:0] data_out,
  output wire fifo_full_out, 
  output wire fifo_empty_out
);

// Signal Area
reg [ADD_WIDTH:0] r_write_ptr, r_read_ptr;
reg [WORD_WIDTH-1:0] r_memory [2**ADD_WIDTH-1:0];
reg [WORD_WIDTH-1:0] r_data_out;
wire [WORD_WIDTH-1:0] r_data_in;
wire w_read_en_in;
wire w_write_en_in;

// Wiring Area
assign w_read_en_in = read_en_in;
assign w_write_en_in = write_en_in;
assign r_data_in = data_in;
assign data_out = r_data_out;
//
// wrap around = 1, if pointers MSB are different
assign wrap_around = r_write_ptr[ADD_WIDTH] ^ r_read_ptr[ADD_WIDTH];

assign fifo_full_out = wrap_around & (r_write_ptr[ADD_WIDTH-1:0] == r_read_ptr[ADD_WIDTH-1:0]); 
assign fifo_empty_out = !wrap_around & (r_write_ptr[ADD_WIDTH-1:0] == r_read_ptr[ADD_WIDTH-1:0]);

// Procedure Area
// write
integer j;
always@(posedge clk_in) begin
  if (reset_in) begin
    for (j=0; j < 2**ADD_WIDTH; j=j+1) begin
      r_memory[j] <= 0; end
    /* r_memory[0] <= 8'b0; 
    r_memory[1] <= 8'b0; 
    r_memory[2] <= 8'b0; 
    r_memory[3] <= 8'b0; 
    r_memory[4] <= 8'b0; 
    r_memory[5] <= 8'b0; 
    r_memory[6] <= 8'b0; 
    r_memory[7] <= 8'b0; */
    r_write_ptr <= 0;
  end
  if (write_en_in & !fifo_full_out) begin
    r_memory[r_write_ptr[ADD_WIDTH-1:0]] <= r_data_in;
    r_write_ptr <= r_write_ptr + 1;
  end
end

// read
always@(posedge clk_in) begin
  if (reset_in) begin
    r_data_out <= 0;
    r_read_ptr <= 0;
  end
  if (read_en_in & !fifo_empty_out) begin
    r_data_out <= r_memory[r_read_ptr[ADD_WIDTH-1:0]];
    r_read_ptr <= r_read_ptr + 1;
  end
end

endmodule