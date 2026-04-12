module booth_rad2_multiplier (
    input signed [7:0] A,
    input signed [7:0] B,
    output [15:0] P
);

wire [15:0] pp [7:0];
wire [15:0] sum1, carry1, sum2, carry2;

wire [8:0] B_ext;
assign B_ext = {B, 1'b0};

// Generate partial products
genvar i;
generate
    for (i = 0; i < 8; i = i + 1) begin
        wire [1:0] code;
        assign code = {B_ext[i+1], B_ext[i]};

        wire signed [15:0] pp_temp;

        booth_encoder_rad2 enc (
            .code(code),
            .A(A),
            .pp(pp_temp)
        );

        assign pp[i] = pp_temp <<< i;
    end
endgenerate

// CSA tree
csa c1 (pp[0], pp[1], pp[2], sum1, carry1);
csa c2 (pp[3], pp[4], pp[5], sum2, carry2);

wire [15:0] temp1, temp2;
assign temp1 = sum1 + (carry1 << 1);
assign temp2 = sum2 + (carry2 << 1);

// Final adder
final_adder fa (
    .A(temp1),
    .B(temp2 + pp[6] + pp[7]),
    .P(P)
);

endmodule