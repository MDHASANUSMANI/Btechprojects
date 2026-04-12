`timescale 1ns/1ps

module tb_multiplier;


reg signed [7:0] A, B;
wire signed [15:0] P;

// Change module name here for testing
booth_rad4_multiplier uut (
    .A(A),
    .B(B),
    .P(P)
);


initial begin

    A = 10;   B = 5;    #10;
    A = -10;  B = 5;    #10;
    A = 10;   B = -5;   #10;
    A = -10;  B = -5;   #10;
    A = 127;  B = -1;   #10;
    A = -128; B = 1;    #10;

    #50 $finish;
end

endmodule
