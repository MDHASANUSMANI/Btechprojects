module booth_rad4_multiplier (
    input signed [7:0] A,
    input signed [7:0] B,
    output [15:0] P
);

wire [15:0] pp [3:0];
wire [15:0] sum, carry;

wire [9:0] B_ext;
assign B_ext = {B[7], B, 1'b0};  // sign extend

genvar i;
generate
    for (i = 0; i < 4; i = i + 1) begin
        wire [2:0] code;
        assign code = {B_ext[2*i+2], B_ext[2*i+1], B_ext[2*i]};

        wire signed [15:0] pp_temp;

        booth_encoder_rad4 enc (
            .code(code),
            .A(A),
            .pp(pp_temp)
        );

        assign pp[i] = pp_temp <<< (2*i);
    end
endgenerate

// CSA reduction (fewer levels → faster)
csa c1 (pp[0], pp[1], pp[2], sum, carry);

wire [15:0] temp;
assign temp = sum + (carry << 1);

// Final adder
final_adder fa (
    .A(temp),
    .B(pp[3]),
    .P(P)
);

endmodule