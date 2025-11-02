// mips_core_tb.v
`timescale 1ns/1ps

module mips_core_tb;

    // --- Testbench Registers ---
    reg tb_clk;
    reg tb_rst;

    // --- Instantiate the DUT ---
    mips_core dut (
        .clk(tb_clk),
        .rst(tb_rst)
    );

    // --- Clock Generator (100MHz clock = 10ns period) ---
    initial begin
        tb_clk = 1'b0;
    end
    always begin
        #5 tb_clk = ~tb_clk; // Toggle clock every 5ns
    end

    // --- Main Test Sequence ---
    initial begin
        // 1. Setup VCD dump
        $dumpfile("mips_core.vcd");
        $dumpvars(0, mips_core_tb);

        $display("--- Starting MIPS Core Test ---");
        
        // 2. Load the program into the Instruction Memory
        // This is a "backdoor" load, not part of the CPU design
        // It uses the hierarchical path to the memory module.
        // Make sure the path matches your design!
        $readmemh("program.hex", dut.inst_mem.mem_array);
        $display("--- Program loaded into Instruction Memory ---");

        // 3. Apply Reset
        tb_rst = 1'b1;
        @(posedge tb_clk);
        @(posedge tb_clk);
        tb_rst = 1'b0;
        $display("--- Reset Released, CPU is running ---");

        // 4. Let the CPU run for 4 clock cycles
        @(posedge tb_clk); // Cycle 1 (addi $t0)
        @(posedge tb_clk); // Cycle 2 (addi $t1)
        @(posedge tb_clk); // Cycle 3 (add $t2)
        @(posedge tb_clk); // Cycle 4 (to settle)

        // 5. Check the result
        // We peek "backdoor" into the register file to see if $t2
        // (register 10) has the correct value (15).
        
        // Register $t2 is register #10
        // Register $t0 is register #8
        // Register $t1 is register #9
        
        // Check final value in $t2 (register 10)
        if (dut.reg_file.registers[10] === 32'd15) begin
            $display("--- !!! TEST PASSED !!! ---");
            $display("Register $t2 (reg 10) = 0x%h (Expected 15)",
                     dut.reg_file.registers[10]);
        end else begin
            $display("--- !!! TEST FAILED !!! ---");
            $display("Register $t2 (reg 10) = 0x%h (Expected 15)",
                     dut.reg_file.registers[10]);
        end
        
        // Also check intermediate values
        $display("Register $t0 (reg 8)  = 0x%h (Expected 5)",
                 dut.reg_file.registers[8]);
        $display("Register $t1 (reg 9)  = 0x%h (Expected 10)",
                 dut.reg_file.registers[9]);

        $finish;
    end

endmodule