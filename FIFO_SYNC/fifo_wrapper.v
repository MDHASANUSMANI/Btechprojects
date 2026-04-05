`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 26.03.2026 22:03:34
// Design Name: 
// Module Name: fifo_wrapper
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


module fifo_wrapper (
    input clk,              // 100 MHz clock
    input rst,              // reset button
    input cs,
    input wr_en,
    input rd_en,
    input [7:0] sw,         // switches (data input)

    output [7:0] led,       // data output
    output full_led,
    output empty_led
);

wire [31:0] data_out;

// Instantiate FIFO
fifo_sync #(
    .FIFO_DEPTH(8),
    .DATA_WIDTH(32)
) fifo_inst (
    .clk(clk),
    .rst_n(~rst),   // active low reset
    .cs(cs),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .data_in({24'b0, sw}),  // extend 8-bit switch to 32-bit
    .data_out(data_out),
    .empty(empty_led),
    .full(full_led)
);

// Output lower 8 bits to LED
assign led = data_out[7:0];

endmodule

