module partial_product_generator (
    input [7:0] A,
    input b,
    input [2:0] shift,
    output [15:0] pp
);

assign pp = b ? (A << shift) : 16'd0;

endmodule