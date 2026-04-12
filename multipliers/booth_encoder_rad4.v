module booth_encoder_rad4 (
    input [2:0] code,
    input signed [7:0] A,
    output reg signed [15:0] pp
);

always @(*) begin
    case (code)
        3'b000, 3'b111: pp = 0;
        3'b001, 3'b010: pp = A;
        3'b011: pp = A << 1;
        3'b100: pp = -(A << 1);
        3'b101, 3'b110: pp = -A;
        default: pp = 0;
    endcase
end

endmodule