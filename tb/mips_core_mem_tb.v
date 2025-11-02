// mips_core_mem_tb.v
// This testbench verifies LW and SW instructions
`timescale 1ns/1ps

module mips_core_mem_tb;

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
        $dumpfile("mips_core_mem.vcd");
        $dumpvars(0, mips_core_mem_tb);

        $display("--- Starting MIPS Core MEMORY Test ---");
        
        // 2. Load the program into the Instruction Memory
        $readmemh("program2.hex", dut.inst_mem.mem_array);
        $display("--- Program 2 loaded into Instruction Memory ---");

        // 3. Apply Reset
        tb_rst = 1'b1;
        @(posedge tb_clk);
        @(posedge tb_clk);
        tb_rst = 1'b0;
        $display("--- Reset Released, CPU is running ---");

        // 4. Let the CPU run for 4 clock cycles
        @(posedge tb_clk); // Cycle 1 (addi $t0)
        @(posedge tb_clk); // Cycle 2 (sw $t0)
        @(posedge tb_clk); // Cycle 3 (lw $t1)
        @(posedge tb_clk); // Cycle 4 (to settle)

        // 5. Check the result
        // We check if $t1 was loaded with the value from $t0 (123)
        
        // $t0 is register #8
        // $t1 is register #9
        
        if (dut.reg_file.registers[9] === 32'd123) begin
            $display("--- !!! TEST PASSED !!! ---");
            $display("Register $t1 (reg 9) = 0x%h (Expected 123)",
                     dut.reg_file.registers[9]);
        end else begin
            $display("--- !!! TEST FAILED !!! ---");
            $display("Register $t1 (reg 9) = 0x%h (Expected 123)",
                     dut.reg_file.registers[9]);
        end
        
        // Also check intermediate values
        $display("Register $t0 (reg 8)  = 0x%h (Expected 123)",
                 dut.reg_file.registers[8]);
        
        // We can also peek into the Data Memory to be sure!
        // We are checking word index 1 (which is byte address 4)
        
        $display("Data Memory[addr 1] = 0x%h (Expected 123)",
                 dut.data_mem.mem_array[1]);

        $finish;
    end

endmodule