module final_adder (
    input [15:0] A,
    input [15:0] B,
    output [15:0] P
);

assign P = A + B;

endmodule