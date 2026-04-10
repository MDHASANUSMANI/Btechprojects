module array_multiplier_top (
    input [7:0] A,
    input [7:0] B,
    output [15:0] P
);

wire [15:0] pp [7:0];
wire [15:0] sum1, carry1, sum2, carry2;

// Partial products
genvar i;
generate
    for (i = 0; i < 8; i = i + 1) begin
        partial_product_generator ppg (
            .A(A),
            .b(B[i]),
            .shift(i),
            .pp(pp[i])
        );
    end
endgenerate

// CSA stages
csa csa1 (pp[0], pp[1], pp[2], sum1, carry1);
csa csa2 (pp[3], pp[4], pp[5], sum2, carry2);

// Final addition
wire [15:0] temp1, temp2;
assign temp1 = sum1 + (carry1 << 1);
assign temp2 = sum2 + (carry2 << 1);

final_adder fa (
    .A(temp1),
    .B(temp2 + pp[6] + pp[7]),
    .P(P)
);

endmodule