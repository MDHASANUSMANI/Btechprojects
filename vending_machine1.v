`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: MD HASAN USMANI
// 
// Create Date: 04.08.2026 21:53:53
// Design Name: MOORE_FSM
// Module Name: vending_machine1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module vending_machine1(
    input clk,
    input rst,
    input coin5,
    input coin10,

    output reg dispense,
    output reg change
);


// State Encoding
parameter S0       = 2'b00;
parameter S5       = 2'b01;
parameter S10      = 2'b10;
parameter DISPENSE = 2'b11;

reg [1:0] current_state, next_state;
reg change_flag;


// State Register
always @(posedge clk or posedge rst)
begin
    if(rst)
        current_state <= S0;
    else
        current_state <= next_state;
end


// Next State Logic
always @(*)
begin

    next_state = current_state;
    change_flag = 1'b0;

    case(current_state)

        
        S0:
        begin
            if(coin5)
                next_state = S5;
            else if(coin10)
                next_state = S10;
            else
                next_state = S0;
        end

        S5:
        begin
            if(coin5)
                next_state = S10;

            else if(coin10)
                next_state = DISPENSE;

            else
                next_state = S5;
        end

        S10:
        begin
            if(coin5)
            begin
                next_state = DISPENSE;
                change_flag = 1'b0;
            end

            else if(coin10)
            begin
                next_state = DISPENSE;
                change_flag = 1'b1;
            end

            else
                next_state = S10;
        end

        DISPENSE:
        begin
            next_state = S0;
        end

        default:
            next_state = S0;

    endcase

end

// Output Logic (Moore)

always @(*)
begin

    dispense = 1'b0;
    change   = 1'b0;

    case(current_state)

        DISPENSE:
        begin
            dispense = 1'b1;
            change   = change_flag;
        end

        default:
        begin
            dispense = 1'b0;
            change   = 1'b0;
        end

    endcase

end
endmodule
