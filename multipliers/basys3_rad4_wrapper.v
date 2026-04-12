module basys3_wrapper (
    input clk,
    input [15:0] sw,
    output reg [15:0] led
);

reg signed [7:0] A, B;
wire signed [15:0] P;

// Register inputs
always @(posedge clk) begin
    A <= sw[7:0];
    B <= sw[15:8];
end

booth_rad4_multiplier uut (
    .A(A),
    .B(B),
    .P(P)
);

// Register output
always @(posedge clk) begin
    led <= P;
end

endmodule