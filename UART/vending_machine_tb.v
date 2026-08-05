`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04.08.2026 22:00:49
// Design Name: 
// Module Name: vending_machine_tb
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


`timescale 1ns/1ps

module vending_machine_tb;

reg clk;
reg rst;
reg coin5;
reg coin10;

wire dispense;
wire change;

vending_machine1 DUT(

    .clk(clk),
    .rst(rst),
    .coin5(coin5),
    .coin10(coin10),
    .dispense(dispense),
    .change(change)

);


// Clock Generation


always #5 clk = ~clk;


// Test Sequence

initial
begin

    clk = 0;
    rst = 1;
    coin5 = 0;
    coin10 = 0;

    #15;
    rst = 0;

 
    // Test Case 1 : 5 + 5 + 5
    

    #10 coin5 = 1;
    #10 coin5 = 0;

    #20 coin5 = 1;
    #10 coin5 = 0;

    #20 coin5 = 1;
    #10 coin5 = 0;

    #40;

   
    // Test Case 2 : 10 + 5
   

    #10 coin10 = 1;
    #10 coin10 = 0;

    #20 coin5 = 1;
    #10 coin5 = 0;

    #40;

    
    // Test Case 3 : 10 + 10
   

    #10 coin10 = 1;
    #10 coin10 = 0;

    #20 coin10 = 1;
    #10 coin10 = 0;

    #50;


    $finish;

end

// Monitor

initial
begin
    $monitor("Time=%0t  coin5=%b coin10=%b dispense=%b change=%b",
              $time,coin5,coin10,dispense,change);
end

endmodule

