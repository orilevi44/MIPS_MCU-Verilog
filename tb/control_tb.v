// control_tb.v
`timescale 1ns/1ps

module control_tb;

    // --- Testbench Registers ---
    reg [5:0] tb_opcode;

    // --- Testbench Wires ---
    wire reg_write;
    wire [3:0] alu_op;
    wire mem_write;
    wire mem_read;
    wire mem_to_reg;
    wire alu_src;
    wire branch;

    // --- Instantiate the DUT ---
    control dut (
        .opcode(tb_opcode),
        .reg_write(reg_write),
        .alu_op(alu_op),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .mem_to_reg(mem_to_reg),
        .alu_src(alu_src),
        .branch(branch)
    );
    
    // --- Local Opcodes ---
    localparam OP_R_TYPE = 6'b000000;
    localparam OP_LW     = 6'b100011; // 35
    localparam OP_SW     = 6'b101011; // 43
    localparam OP_BEQ    = 6'b000100; // 4
    localparam OP_JUNK   = 6'b111111; // 63
    
    // --- ALU Operations (from alu.v) ---
    localparam ALU_OP_ADD = 4'b0010;
    localparam ALU_OP_SUB = 4'b0110;

    // --- Main Test Sequence ---
    initial begin
        // 1. Setup VCD dump
        $dumpfile("control.vcd");
        $dumpvars(0, control_tb);

        $display("--- Starting Control Unit Test ---");

        // --- Test 1: R-Type ---
        tb_opcode = OP_R_TYPE;
        #1; // Wait for combinational logic
        if (reg_write !== 1'b1 || alu_src !== 1'b0 || mem_write !== 1'b0) begin
            $display("--- !!! TEST FAILED: R-Type !!! ---"); $finish;
        end else $display("--- Test Passed: R-Type ---");

        // --- Test 2: LW (Load Word) ---
        tb_opcode = OP_LW;
        #1;
        if (reg_write !== 1'b1 || mem_read !== 1'b1 || mem_to_reg !== 1'b1 || alu_src !== 1'b1 || alu_op !== ALU_OP_ADD) begin
            $display("--- !!! TEST FAILED: LW !!! ---"); $finish;
        end else $display("--- Test Passed: LW ---");
        
        // --- Test 3: SW (Store Word) ---
        tb_opcode = OP_SW;
        #1;
        if (reg_write !== 1'b0 || mem_write !== 1'b1 || alu_src !== 1'b1 || alu_op !== ALU_OP_ADD) begin
            $display("--- !!! TEST FAILED: SW !!! ---"); $finish;
        end else $display("--- Test Passed: SW ---");

        // --- Test 4: BEQ (Branch if Equal) ---
        tb_opcode = OP_BEQ;
        #1;
        if (reg_write !== 1'b0 || branch !== 1'b1 || alu_src !== 1'b0 || alu_op !== ALU_OP_SUB) begin
            $display("--- !!! TEST FAILED: BEQ !!! ---"); $finish;
        end else $display("--- Test Passed: BEQ ---");
        
        // --- Test 5: Unknown Opcode ---
        tb_opcode = OP_JUNK;
        #1;
        if (reg_write !== 1'b0 || mem_write !== 1'b0 || mem_read !== 1'b0 || branch !== 1'b0) begin
            $display("--- !!! TEST FAILED: Unknown Opcode !!! ---"); $finish;
        end else $display("--- Test Passed: Unknown Opcode ---");

        
        $display("--- All Control Unit Tests Passed! ---");
        $finish;
    end

endmodule