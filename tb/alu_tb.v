// alu_tb.v (FIXED VERSION 4)
`timescale 1ns/1ps

module alu_tb;

    // --- Testbench Registers ---
    reg [31:0] tb_a;
    reg [31:0] tb_b;
    reg [3:0]  tb_alu_control;
    reg        tb_clk;

    // --- Testbench Wires ---
    wire [31:0] tb_result;
    wire        tb_zero;

    // --- Operation Codes (must match alu.v) ---
    localparam ALU_OP_ADD = 4'b0010;
    localparam ALU_OP_SUB = 4'b0110;
    localparam ALU_OP_AND = 4'b0000;
    localparam ALU_OP_OR  = 4'b0001;
    localparam ALU_OP_SLT = 4'b0111;

    // --- Instantiate the DUT ---
    alu dut (
        .a(tb_a),
        .b(tb_b),
        .alu_control(tb_alu_control),
        .result(tb_result),
        .zero(tb_zero)
    );

    // --- Clock Generator ---
    initial begin
        tb_clk = 1'b0;
    end
    always begin
        #5 tb_clk = ~tb_clk; // Toggle clock every 5ns (10ns period = 100MHz)
    end

    // --- Task for applying stimulus ---
    task apply_stimulus;
        input [31:0] a;
        input [31:0] b;
        input [3:0]  op;
        begin
            @(posedge tb_clk); // Wait for the next clock edge
            tb_a           = a;
            tb_b           = b;
            tb_alu_control = op;
            #1; // Wait 1 time unit for values to propagate
        end
    endtask

    // --- Task for checking results ---
    task check_result;
        input [31:0] expected_result;
        input        expected_zero;
        begin
            if (tb_result !== expected_result || tb_zero !== expected_zero) begin
                $display("--- !!! TEST FAILED !!! ---");
                $display("Time: %t", $time);
                $display("Test Case: A=0x%h, B=0x%h, Op=0x%h", tb_a, tb_b, tb_alu_control);
                $display("Expected: Result=0x%h, Zero=%b", expected_result, expected_zero);
                $display("Got:      Result=0x%h, Zero=%b", tb_result, tb_zero);
                $finish; // Stop simulation on failure
            end
            else begin
                $display("--- Test Passed --- (A=0x%h, B=0x%h, Op=0x%h -> Result=0x%h)", tb_a, tb_b, tb_alu_control, tb_result);
            end
        end
    endtask


    // --- Main Test Sequence ---
    initial begin
        // 1. Setup VCD dump (for GTKWave)
        $dumpfile("alu.vcd"); // File name
        $dumpvars(0, alu_tb);  // Dump all signals in this module
        
        $display("--- Starting ALU Test ---");

        // Test 1: Simple Add (5 + 10 = 15)
        apply_stimulus(32'd5, 32'd10, ALU_OP_ADD);
        check_result(32'd15, 1'b0);

        // Test 2: Simple Sub (100 - 20 = 80)
        apply_stimulus(32'd100, 32'd20, ALU_OP_SUB);
        check_result(32'd80, 1'b0);

        // Test 3: Corner Case - Sub to Zero (50 - 50 = 0)
        apply_stimulus(32'd50, 32'd50, ALU_OP_SUB);
        check_result(32'd0, 1'b1); // Expect Zero flag!

        // Test 4: AND (0xAAAA & 0x00FF = 0x00AA)
        apply_stimulus(32'h0000AAAA, 32'h000000FF, ALU_OP_AND);
        check_result(32'h000000AA, 1'b0);

        // Test 5: OR (0xAAAA | 0x00FF = 0xAAFF)
        apply_stimulus(32'h0000AAAA, 32'h000000FF, ALU_OP_OR);
        check_result(32'h0000AAFF, 1'b0);

        // Test 6: SLT (Set on Less Than) (5 < 10 -> True (1))
        apply_stimulus(32'd5, 32'd10, ALU_OP_SLT);
        check_result(32'd1, 1'b0);
        
        // Test 7: SLT (10 < 5 -> False (0))
        apply_stimulus(32'd10, 32'd5, ALU_OP_SLT);
        check_result(32'd0, 1'b1); // Result is 0, so Zero flag is 1!

        // --- !!! FIXED TEST 8 !!! ---
        // Test 8: SLT with negative numbers (-10 < 5 -> True (1))
        // We use the hex value for -10 (32'hFFFFFFF6)
        apply_stimulus(32'hFFFFFFF6, 32'd5, ALU_OP_SLT);
        check_result(32'd1, 1'b0);
        
        // --- !!! FIXED TEST 9 !!! ---
        // Test 9: SLT with negative numbers (-5 < -10 -> False (0))
        // We use hex value for -5 (32'hFFFFFFFB) and -10 (32'hFFFFFFF6)
        apply_stimulus(32'hFFFFFFFB, 32'hFFFFFFF6, ALU_OP_SLT);
        check_result(32'd0, 1'b1);
        
        $display("--- All ALU Tests Passed! ---");
        $finish; // End simulation
    end

endmodule