`timescale 1ns / 1ps
module array_multiplier (
    input signed [7:0] A,
    input signed [7:0] B,
    output signed [15:0] P
);

wire signed [15:0] pp [7:0];

genvar i;
generate
    for (i = 0; i < 8; i = i + 1) begin : partial_products
        assign pp[i] = B[i] ? (A <<< i) : 16'd0;
    end
endgenerate

// Accumulate all partial products
assign P = pp[0] + pp[1] + pp[2] + pp[3] +
           pp[4] + pp[5] + pp[6] + pp[7];

endmodule
