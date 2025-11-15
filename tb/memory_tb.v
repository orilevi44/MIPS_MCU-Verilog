// memory_tb.v
`timescale 1ns/1ps

module memory_tb;

    // --- Testbench Registers ---
    reg        tb_clk;
    reg        tb_write_enable;
    reg [9:0]  tb_addr;
    reg [31:0] tb_write_data;

    // --- Testbench Wires ---
    wire [31:0] tb_read_data;

    // --- Instantiate the DUT ---
    memory dut (
        .clk(tb_clk),
        .write_enable(tb_write_enable),
        .addr(tb_addr),
        .write_data(tb_write_data),
        .read_data(tb_read_data)
    );

    // --- Clock Generator (100MHz clock = 10ns period) ---
    initial begin
        tb_clk = 1'b0;
    end
    always begin
        #5 tb_clk = ~tb_clk; // Toggle clock every 5ns
    end

    // --- Task for writing to memory ---
    task mem_write;
        input [9:0]  addr;
        input [31:0] data;
        begin
            @(posedge tb_clk);
            tb_write_enable = 1'b1;
            tb_addr         = addr;
            tb_write_data   = data;
            @(posedge tb_clk);
            tb_write_enable = 1'b0;
            #1;
        end
    endtask

    // --- Task for checking memory ---
    task mem_check;
        input [9:0]  addr;
        input [31:0] expected_data;
        begin
            @(posedge tb_clk);
            tb_write_enable = 1'b0; // Ensure we are in read mode
            tb_addr         = addr;
            #1; // Wait for combinational read
            
            if (tb_read_data !== expected_data) begin
                $display("--- !!! TEST FAILED !!! ---");
                $display("Time: %t", $time);
                $display("Read from addr %d. Expected: 0x%h, Got: 0x%h",
                         addr, expected_data, tb_read_data);
                $finish;
            end else begin
                $display("--- Test Passed --- (Read addr %d = 0x%h)",
                         addr, tb_read_data);
            end
        end
    endtask

    // --- Main Test Sequence ---
    initial begin
        // Setup VCD dump
        $dumpfile("memory.vcd");
        $dumpvars(0, memory_tb);

        $display("--- Starting Memory Test ---");

        // Initialize signals
        tb_write_enable = 1'b0;
        tb_addr         = 10'd0;
        tb_write_data   = 32'd0;

        // Test 1: Write to address 10
        $display("--- Writing 0xAAAAAAAA to addr 10 ---");
        mem_write(10'd10, 32'hAAAAAAAA);

        // Test 2: Read back from address 10
        mem_check(10'd10, 32'hAAAAAAAA);

        // Test 3: Write to address 500
        $display("--- Writing 0xBBBBBBBB to addr 500 ---");
        mem_write(10'd500, 32'hBBBBBBBB);

        // Test 4: Read back from address 500
        mem_check(10'd500, 32'hBBBBBBBB);

        // Test 5: Check persistence
        $display("--- Checking addr 10 again (persistence) ---");
        mem_check(10'd10, 32'hAAAAAAAA);

        // Test 6: read and write at the same time
        $display("--- cheking read and write at the same time");
        
        mem_write(10'd20, 32'd15);
        mem_check(10'd20, 32'd15);
        @(posedge tb_clk)
        tb_write_enable = 1'b1;  
        tb_addr = 10'd20;  
        tb_write_data = 32'd7;

        if (tb_read_data == 32'd7) begin
            $display("--- !!! TEST FAILED !!! ---");
            $display("Time: %t", $time);
            $display("Read and write from/to addr %d. Expected: 15 (old value), Got: %d (new value)",
                         tb_addr, tb_write_data);
        end
        else $display("---Test 6 : Passed -the value that we read is not the new one");
        
        @(posedge tb_clk)
        tb_write_enable = 1'b0;  
        #1;
        if (tb_read_data == 32'd7) begin
            $display("--- Test Passed ---  we Read from addr %d the value %d (old value-that we put the same time we write)",tb_addr,tb_write_data);
        end   
        else $display("--- Test 6 : Faild! the value in addr %d is %d",tb_addr,tb_write_data);

        $display("--- All Memory Tests Passed! ---");
        $finish;
    end

endmodule