// mips_core_branch_tb.v
// This testbench verifies BEQ instructions
`timescale 1ns/1ps

module mips_core_branch_tb;

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
        $dumpfile("mips_core_branch.vcd");
        $dumpvars(0, mips_core_branch_tb);

        $display("--- Starting MIPS Core BRANCH Test ---");
        
        // 2. Load the program into the Instruction Memory
        $readmemh("program3.hex", dut.inst_mem.mem_array);
        $display("--- Program 3 loaded into Instruction Memory ---");

        // 3. Apply Reset
        tb_rst = 1'b1;
        @(posedge tb_clk);
        @(posedge tb_clk);
        tb_rst = 1'b0;
        $display("--- Reset Released, CPU is running ---");

        // 4. Let the CPU run for 5 clock cycles
        @(posedge tb_clk); // Cycle 1 (addi $t0)
        @(posedge tb_clk); // Cycle 2 (addi $t1)
        @(posedge tb_clk); // Cycle 3 (beq $t0, $t1) -> Branch taken
        @(posedge tb_clk); // Cycle 4 (CPU is at SKIP label)
        @(posedge tb_clk); // Cycle 5 (addi $t2, $zero, 222)
        @(posedge tb_clk); // Cycle 6 (to settle)

        // 5. Check the result
        // We check if $t2 has the value 222 (0xDE)
        
        // $t0 is register #8
        // $t1 is register #9
        // $t2 is register #10
        
        if (dut.reg_file.registers[10] === 32'd222) begin
            $display("--- !!! TEST PASSED !!! ---");
            $display("Branch was taken (as expected).");
            $display("Register $t2 (reg 10) = 0x%h (Expected 222)",
                     dut.reg_file.registers[10]);
        end else begin
            $display("--- !!! TEST FAILED !!! ---");
            $display("Branch was NOT taken.");
            $display("Register $t2 (reg 10) = 0x%h (Expected 222)",
                     dut.reg_file.registers[10]);
        end
        
        $display("Register $t0 (reg 8)  = 0x%h (Expected 5)",
                 dut.reg_file.registers[8]);
        $display("Register $t1 (reg 9)  = 0x%h (Expected 5)",
                 dut.reg_file.registers[9]);
        
        $finish;
    end

endmodule