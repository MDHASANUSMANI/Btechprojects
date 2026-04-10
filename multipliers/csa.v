module csa (
    input [15:0] A,
    input [15:0] B,
    input [15:0] C,
    output [15:0] SUM,
    output [15:0] CARRY
);

assign SUM   = A ^ B ^ C;
assign CARRY = (A & B) | (B & C) | (C & A);

endmodule