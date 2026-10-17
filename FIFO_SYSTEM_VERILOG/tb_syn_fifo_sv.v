`timescale 1ns / 1ps

// Company: 
// Engineer: MD HASAN USMANI
// 
// Create Date: 15.10.2026 11:49:32
// Design Name: 
// Module Name: tb_syn_fifo_sv
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


// ============================================================
module tb_sync_fifo_sv()


//  INTERFACE
interface fifo_if;

    logic clk;
    logic rst_n;
    logic wr_en;
    logic rd_en;

    logic [31:0] data_in;
    logic [31:0] data_out;

    logic full;
    logic empty;
    logic [3:0] count;

endinterface



//  TRANSACTION
class fifo_transaction;

    bit rst_n;
    bit wr_en;
    bit rd_en;

    bit [31:0] data_in;

    bit reset_seen;
    bit write_accept;
    bit read_accept;
    bit end_sim;

    bit [31:0] data_out;
    bit [3:0] count;
    bit full;
    bit empty;

    function new();
        rst_n       = 1'b1;
        wr_en       = 1'b0;
        rd_en       = 1'b0;
        data_in     = '0;
        reset_seen  = 1'b0;
        write_accept = 1'b0;
        read_accept  = 1'b0;
        end_sim     = 1'b0;
    endfunction

endclass



//  GENERATOR

class fifo_generator;

    mailbox #(fifo_transaction) gen2drv;

    function new(mailbox #(fifo_transaction) mbx);
        gen2drv = mbx;
    endfunction

    task automatic send(
        input bit reset_value,
        input bit write_value,
        input bit read_value,
        input bit [31:0] input_data
    );

        fifo_transaction tr;

        tr = new();

        tr.rst_n   = reset_value;
        tr.wr_en   = write_value;
        tr.rd_en   = read_value;
        tr.data_in = input_data;

        gen2drv.put(tr);

    endtask

    task run();

        fifo_transaction tr;
        int i;

        $display("\n[GENERATOR] Starting FIFO tests");

        // Reset for two clock cycles
        send(0, 0, 0, 0);
        send(0, 0, 0, 0);

        // Fill all 8 locations
        $display("[GENERATOR] Filling FIFO");

        for (i = 0; i < 8; i++)
            send(1, 1, 0, 32'h1000 + i);

        // Attempt write when full
        $display("[GENERATOR] Testing full condition");
        send(1, 1, 0, 32'hDEAD_BEEF);

        // Read one element
        send(1, 0, 1, 0);

        // Simultaneous read and write
        send(1, 1, 1, 32'hAAAA_0001);

        // Drain the remaining seven elements
        $display("[GENERATOR] Draining FIFO");

        for (i = 0; i < 7; i++)
            send(1, 0, 1, 0);

        // Attempt read when empty
        $display("[GENERATOR] Testing empty condition");
        send(1, 0, 1, 0);

        // Simultaneous read/write while empty:
        // read is blocked, write is accepted
        send(1, 1, 1, 32'h1234_5678);

        // Read the element just written
        send(1, 0, 1, 0);

        // Randomized testing
        $display("[GENERATOR] Randomized testing");

        for (i = 0; i < 200; i++) begin

            tr = new();

            tr.rst_n   = 1'b1;
            tr.wr_en   = $urandom_range(0, 1);
            tr.rd_en   = $urandom_range(0, 1);
            tr.data_in = $urandom;

            gen2drv.put(tr);

        end

        // End-of-test marker
        tr = new();
        tr.end_sim = 1'b1;
        gen2drv.put(tr);

        $display("[GENERATOR] Transactions generated");

    endtask

endclass


//DRIVER
class fifo_driver;

    virtual fifo_if vif;
    mailbox #(fifo_transaction) gen2drv;

    bit done;

    function new(
        virtual fifo_if vif,
        mailbox #(fifo_transaction) mbx
    );
        this.vif   = vif;
        gen2drv    = mbx;
        done       = 1'b0;
    endfunction

    task run();

        fifo_transaction tr;

        forever begin

            gen2drv.get(tr);

            // Stop marker
            if (tr.end_sim) begin

                @(negedge vif.clk);

                vif.rst_n   = 1'b1;
                vif.wr_en   = 1'b0;
                vif.rd_en   = 1'b0;
                vif.data_in = '0;

                done = 1'b1;

                $display("[DRIVER] All transactions driven");
                return;

            end

            // Drive inputs away from the active clock edge
            @(negedge vif.clk);

            vif.rst_n   = tr.rst_n;
            vif.wr_en   = tr.wr_en;
            vif.rd_en   = tr.rd_en;
            vif.data_in = tr.data_in;

        end

    endtask

endclass


//MONITOR

class fifo_monitor;

    virtual fifo_if vif;
    mailbox #(fifo_transaction) mon2scb;

    function new(
        virtual fifo_if vif,
        mailbox #(fifo_transaction) mbx
    );
        this.vif  = vif;
        mon2scb   = mbx;
    endfunction

    task run();

        fifo_transaction tr;

        forever begin

            @(posedge vif.clk);

            tr = new();

            // Capture reset and accepted operations
            tr.rst_n = vif.rst_n;

            if (!vif.rst_n) begin
                tr.reset_seen = 1'b1;
            end
            else begin
                tr.reset_seen   = 1'b0;
                tr.write_accept = vif.wr_en && !vif.full;
                tr.read_accept  = vif.rd_en && !vif.empty;
                tr.data_in      = vif.data_in;
            end

            // Allow nonblocking assignments to complete
            #1;

            tr.data_out = vif.data_out;
            tr.count    = vif.count;
            tr.full     = vif.full;
            tr.empty    = vif.empty;

            mon2scb.put(tr);

        end

    endtask

endclass


//SCOREBOARD

class fifo_scoreboard;

    mailbox #(fifo_transaction) mon2scb;

    bit [31:0] expected_q[$];

    int errors;
    int checked_transactions;
    bit [31:0] expected_data;

    function new(mailbox #(fifo_transaction) mbx);
        mon2scb             = mbx;
        errors              = 0;
        checked_transactions = 0;
    endfunction

    task run();

        fifo_transaction tr;

        forever begin

            mon2scb.get(tr);

            checked_transactions++;

            // Reset the reference model
            if (tr.reset_seen) begin

                expected_q.delete();

                if (tr.count !== 4'd0) begin
                    $error("[SCOREBOARD] Count not zero after reset");
                    errors++;
                end

            end
            else begin

                // A read must return the oldest stored value
                if (tr.read_accept) begin

                    if (expected_q.size() == 0) begin

                        $error("[SCOREBOARD] Unexpected accepted read");
                        errors++;

                    end
                    else begin

                        expected_data = expected_q.pop_front();

                        if (tr.data_out !== expected_data) begin

                            $error(
                                "[SCOREBOARD] Data mismatch: expected=%h actual=%h",
                                expected_data,
                                tr.data_out
                            );

                            errors++;

                        end
                        else begin

                            $display(
                                "[SCOREBOARD] Read PASS: data=%h",
                                tr.data_out
                            );

                        end

                    end

                end

                // A write adds a new value at the FIFO tail
                if (tr.write_accept)
                    expected_q.push_back(tr.data_in);

                // Verify occupancy
                if (tr.count !== expected_q.size()) begin

                    $error(
                        "[SCOREBOARD] Count mismatch: expected=%0d actual=%0d",
                        expected_q.size(),
                        tr.count
                    );

                    errors++;

                end

                // Verify empty flag
                if (tr.empty !== (expected_q.size() == 0)) begin

                    $error("[SCOREBOARD] Empty flag mismatch");
                    errors++;

                end

                // Verify full flag
                if (tr.full !== (expected_q.size() == 8)) begin

                    $error("[SCOREBOARD] Full flag mismatch");
                    errors++;

                end

            end

        end

    endtask

endclass


//ENVIRONMENT

class fifo_environment;

    mailbox #(fifo_transaction) gen2drv;
    mailbox #(fifo_transaction) mon2scb;

    fifo_generator   gen;
    fifo_driver      drv;
    fifo_monitor     mon;
    fifo_scoreboard  scb;

    function new(virtual fifo_if vif);

        gen2drv = new();
        mon2scb = new();

        gen = new(gen2drv);
        drv = new(vif, gen2drv);
        mon = new(vif, mon2scb);
        scb = new(mon2scb);

    endfunction

    task run();

        fork
            gen.run();
            drv.run();
            mon.run();
            scb.run();
        join_none

    endtask

endclass


//TOP MODULE

module tb_sync_fifo;

    fifo_if intf();

    fifo_environment env;

    // DUT instantiation: signal names match the design
    sync_fifo #(
        .DATA_WIDTH(32),
        .DEPTH(8)
    ) dut (
        .clk      (intf.clk),
        .rst_n    (intf.rst_n),
        .wr_en    (intf.wr_en),
        .rd_en    (intf.rd_en),
        .data_in  (intf.data_in),
        .data_out (intf.data_out),
        .full     (intf.full),
        .empty    (intf.empty),
        .count    (intf.count)
    );

    // 10 ns clock period
    initial begin
        intf.clk = 1'b0;
        forever #5 intf.clk = ~intf.clk;
    end

    initial begin

        intf.rst_n   = 1'b0;
        intf.wr_en   = 1'b0;
        intf.rd_en   = 1'b0;
        intf.data_in = '0;

        env = new(intf);

        $display("====================================");
        $display(" SYNCHRONOUS FIFO LAYERED TESTBENCH");
        $display("====================================");

        env.run();

        // Wait for the driver to finish all transactions
        wait (env.drv.done == 1'b1);

        // Allow the monitor and scoreboard to process final cycles
        repeat (3) @(posedge intf.clk);
        #2;

        $display("------------------------------------");
        $display("Transactions checked: %0d",
                 env.scb.checked_transactions);
        $display("Total errors: %0d", env.scb.errors);

        if (env.scb.errors == 0)
            $display("FINAL RESULT: TEST PASSED");
        else
            $display("FINAL RESULT: TEST FAILED");

        $display("------------------------------------");

        $finish;

    end

endmodule


