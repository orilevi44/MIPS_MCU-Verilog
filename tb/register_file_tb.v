// register_file_tb.v
`timescale 1ns/1ps

module register_file_tb;

    // --- Testbench Registers ---
    reg        tb_clk;
    reg        tb_rst;
    reg        tb_reg_write;
    reg [4:0]  tb_read_addr1;
    reg [4:0]  tb_read_addr2;
    reg [4:0]  tb_write_addr;
    reg [31:0] tb_write_data;

    // --- Testbench Wires ---
    wire [31:0] tb_read_data1;
    wire [31:0] tb_read_data2;

    // --- Instantiate the DUT ---
    register_file dut (
        .clk(tb_clk),
        .rst(tb_rst),
        .reg_write(tb_reg_write),
        .read_addr1(tb_read_addr1),
        .read_addr2(tb_read_addr2),
        .write_addr(tb_write_addr),
        .write_data(tb_write_data),
        .read_data1(tb_read_data1),
        .read_data2(tb_read_data2)
    );

    // --- Clock Generator (100MHz clock = 10ns period) ---
    initial begin
        tb_clk = 1'b0;
    end
    always begin
        #5 tb_clk = ~tb_clk; // Toggle clock every 5ns
    end

    // --- Task for checking a register value ---
    task check_register;
        input [4:0]  addr;
        input [31:0] expected_value;
        begin
            // Set read address
            tb_read_addr1 = addr;
            #1; // Wait 1 time unit for combinational read
            
            if (tb_read_data1 !== expected_value) begin
                $display("--- !!! TEST FAILED !!! ---");
                $display("Time: %t", $time);
                $display("Read from reg %d. Expected: 0x%h, Got: 0x%h", 
                         addr, expected_value, tb_read_data1);
                $finish;
            end else begin
                $display("--- Test Passed --- (Read reg %d = 0x%h)", 
                         addr, tb_read_data1);
            end
        end
    endtask

    // --- Task for writing a register value ---
    task write_register;
        input [4:0]  addr;
        input [31:0] value;
        begin
            @(posedge tb_clk); // Wait for a clock edge
            tb_reg_write  = 1'b1;
            tb_write_addr = addr;
            tb_write_data = value;
            @(posedge tb_clk); // Wait one more clock cycle
            tb_reg_write  = 1'b0; // Stop writing
            #1;
        end
    endtask


    // --- Main Test Sequence ---
    initial begin
        // 1. Setup VCD dump
        $dumpfile("register_file.vcd");
        $dumpvars(0, register_file_tb);

        $display("--- Starting Register File Test ---");

        // 2. Apply Reset
        tb_rst = 1'b1;
        tb_reg_write = 1'b0; // Initialize signals
        tb_write_addr = 5'd0;
        tb_write_data = 32'd0;
        tb_read_addr1 = 5'd0;
        tb_read_addr2 = 5'd0;

        @(posedge tb_clk);
        @(posedge tb_clk);
        tb_rst = 1'b0; // Release reset
        $display("--- Reset Released ---");
        
        // 3. Test 1: Check if $zero (reg 0) is 0 after reset
        check_register(5'd0, 32'd0);

        // 4. Test 2: Write to reg 5
        $display("--- Writing 0xDEADBEEF to reg 5 ---");
        write_register(5'd5, 32'hDEADBEEF);
        
        // 5. Test 3: Read back from reg 5
        check_register(5'd5, 32'hDEADBEEF);

        // 6. Test 4: Write to reg 10
        $display("--- Writing 0xCAFECAFE to reg 10 ---");
        write_register(5'd10, 32'hCAFECAFE);

        // 7. Test 5: Read back from reg 10
        check_register(5'd10, 32'hCAFECAFE);

        // 8. Test 6: Check if reg 5 still has its value
        $display("--- Checking reg 5 value (persistence) ---");
        check_register(5'd5, 32'hDEADBEEF);

        // 9. Test 7: Corner Case - Try to write to $zero (reg 0)
        $display("--- Trying to write to reg 0 (should fail) ---");
        write_register(5'd0, 32'h12345678);

        // 10. Test 8: Check if $zero is still 0
        check_register(5'd0, 32'd0);
        
        // 11. Test 9: Check dual read ports
        $display("--- Checking dual read ports (reg 5 and reg 10) ---");
        @(posedge tb_clk);
        tb_read_addr1 = 5'd5;
        tb_read_addr2 = 5'd10;
        #1; // Wait for combinational read
        if (tb_read_data1 !== 32'hDEADBEEF || tb_read_data2 !== 32'hCAFECAFE) begin
            $display("--- !!! TEST FAILED !!! ---");
            $display("Dual Read Port Failure!");
            $finish;
        end else begin
            $display("--- Test Passed --- (Dual Read OK)");
        end


        $display("--- All Register File Tests Passed! ---");
        $finish;
    end

endmodule