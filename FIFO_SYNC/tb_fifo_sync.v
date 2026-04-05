
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 25.03.2026 19:55:48
// Design Name: 
// Module Name: tb_fifo_sync
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
`timescale 1ns/1ns
module tb_fifo_sync();
	
	// Testbench variables
	parameter FIFO_DEPTH = 8;
	parameter DATA_WIDTH = 32;
    reg clk = 0; 
    reg rst_n;
    reg cs;	 
    reg wr_en;
    reg rd_en;
    reg [DATA_WIDTH-1:0] data_in;
    wire [DATA_WIDTH-1:0] data_out;
	wire empty;
	wire full;
	
    integer i;
	
	// Instantiate the DUT
	fifo_sync 
	    #(.FIFO_DEPTH(FIFO_DEPTH),
          .DATA_WIDTH(DATA_WIDTH))
        dut
  	    (.clk     (clk     ), 
         .rst_n   (rst_n   ),
         .cs      (cs      ),	 
         .wr_en   (wr_en   ), 
         .rd_en   (rd_en   ), 
         .data_in (data_in ), 
         .data_out(data_out), 
	     .empty   (empty   ),
	     .full    (full    ));

  	// Create the clock signal
	always begin #5 clk = ~clk; end
  
    task write_data(input [DATA_WIDTH-1:0] d_in);
	    begin
		    @(posedge clk); // sync to positive edge of clock
			cs = 1; wr_en = 1;
			data_in = d_in;
			$display($time, " write_data data_in = %0d", data_in);
			@(posedge clk);
		    cs = 1; wr_en = 0;
		end
	endtask
	
	task read_data();
	    begin
		    @(posedge clk);  // sync to positive edge of clock
			cs = 1; rd_en = 1;
			@(posedge clk);
			//#1;
		    $display($time, " read_data data_out = %0d", data_out);
		    cs = 1; rd_en = 0;
		end
	endtask
	

	
    // Create stimulus	  
    initial begin
	    #1; 
		rst_n = 0; rd_en = 0; wr_en = 0;
		
        @(posedge clk) 
		rst_n = 1;
		$display($time, "\n SCENARIO 1");
		write_data(1);
		write_data(10);
		write_data(100);
		read_data();
		read_data();
		read_data();
		//read_data();
		
        $display($time, "\n SCENARIO 2");
		for (i=0; i<FIFO_DEPTH; i=i+1) begin
		    write_data(2**i);
			read_data();        
		end

        $display($time, "\n SCENARIO 3");		
		for (i=0; i<=FIFO_DEPTH; i=i+1) begin
		    write_data(2**i);
		end
		
		for (i=0; i<FIFO_DEPTH; i=i+1) begin
			read_data();
		end
		
	    #40 $finish;
	end
  
  initial begin
    $dumpfile("dump.vcd"); $dumpvars;
  end
endmodule


/*module tb_fifo_sync;

parameter FIFO_DEPTH = 8;
parameter DATA_WIDTH = 32;

reg clk = 0;
reg rst_n;
reg cs;
reg wr_en;
reg rd_en;
reg [DATA_WIDTH-1:0] data_in;

wire [DATA_WIDTH-1:0] data_out;
wire empty;
wire full;

// Reference model (queue)
reg [DATA_WIDTH-1:0] ref_mem [0:FIFO_DEPTH-1];
integer wr_ptr = 0;
integer rd_ptr = 0;
integer count  = 0;

integer i;

// DUT
fifo_sync #(
    .FIFO_DEPTH(FIFO_DEPTH),
    .DATA_WIDTH(DATA_WIDTH)
) dut (
    .clk(clk),
    .rst_n(rst_n),
    .cs(cs),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .data_in(data_in),
    .data_out(data_out),
    .empty(empty),
    .full(full)
);

// Clock
always #5 clk = ~clk;

//////////////////////////////////////////////////
// TASK: WRITE
//////////////////////////////////////////////////
task write_data(input [DATA_WIDTH-1:0] din);
begin
    @(posedge clk);
    if (!full) begin
        cs=1; wr_en=1; rd_en=0;
        data_in = din;

        ref_mem[wr_ptr] = din;
        wr_ptr = (wr_ptr + 1) % FIFO_DEPTH;
        count = count + 1;

        $display("%0t WRITE: %0d", $time, din);
    end
    else begin
        $display("%0t FIFO FULL - WRITE BLOCKED", $time);
    end

    @(posedge clk);
    wr_en = 0;
end
endtask

//////////////////////////////////////////////////
// TASK: READ
//////////////////////////////////////////////////
task read_data();
reg [DATA_WIDTH-1:0] expected;
begin
    @(posedge clk);
    if (!empty) begin
        cs=1; rd_en=1; wr_en=0;

        expected = ref_mem[rd_ptr];
        rd_ptr = (rd_ptr + 1) % FIFO_DEPTH;
        count = count - 1;

        @(posedge clk);

        if (data_out !== expected)
            $display("%0t ERROR: Expected=%0d Got=%0d", 
                      $time, expected, data_out);
        else
            $display("%0t READ OK: %0d", $time, data_out);
    end
    else begin
        $display("%0t FIFO EMPTY - READ BLOCKED", $time);
    end

    rd_en = 0;
end
endtask

//////////////////////////////////////////////////
// TEST SEQUENCE
//////////////////////////////////////////////////
initial begin
    rst_n = 0; cs=0; wr_en=0; rd_en=0;
    #20 rst_n = 1;

    $display("\n===== SCENARIO 1: BASIC WRITE/READ =====");
    write_data(10);
    write_data(20);
    write_data(30);

    read_data();
    read_data();
    read_data();

    $display("\n===== SCENARIO 2: FILL FIFO =====");
    for (i=0; i<FIFO_DEPTH; i=i+1)
        write_data(i);

    write_data(999); // overflow test

    $display("\n===== SCENARIO 3: EMPTY FIFO =====");
    for (i=0; i<FIFO_DEPTH; i=i+1)
        read_data();

    read_data(); // underflow test

    $display("\n===== SCENARIO 4: RANDOM TEST =====");
    for (i=0; i<20; i=i+1) begin
        if ($random % 2)
            write_data($random);
        else
            read_data();
    end

    #50 $finish;
end

//////////////////////////////////////////////////
// DUMP
//////////////////////////////////////////////////
initial begin
    $dumpfile("fifo.vcd");
    $dumpvars(0, tb_fifo_sync);
end

endmodule*/



