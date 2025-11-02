// mips_core.v
// The complete Single-Cycle MIPS CPU Core
module mips_core (
    input clk,
    input rst
);

    // --- Internal Wires ---

    // Program Counter (PC) Logic
    reg  [31:0] pc;         // The PC register
    wire [31:0] pc_plus_4;  // PC + 4
    wire [31:0] branch_addr;
    wire [31:0] next_pc;
    wire        pc_src;     // 1 = branch, 0 = pc+4

    // Instruction Fetch
    wire [31:0] instruction;

    // Control Unit
    wire [5:0]  opcode;
    wire        reg_write;
    wire [3:0]  alu_op;
    wire        mem_write;
    wire        mem_read;
    wire        mem_to_reg;
    wire        alu_src;
    wire        branch;

    // Register File
    wire [4:0]  rs_addr;
    wire [4:0]  rt_addr;
    wire [4:0]  rd_addr;
    wire [4:0]  write_reg_addr;
    wire [31:0] rs_data;
    wire [31:0] rt_data;
    wire [31:0] write_reg_data;

    // ALU
    wire [31:0] alu_in_b;
    wire [31:0] alu_result;
    wire        alu_zero;

    // Sign Extender
    wire [15:0] immediate;
    wire [31:0] sign_extended_imm;

    // Data Memory
    wire [31:0] mem_read_data;


    // --- 1. Program Counter (PC) ---
    // The PC is a 32-bit register
    always @(posedge clk or posedge rst) begin
        if (rst)
            pc <= 32'd0;
        else
            pc <= next_pc;
    end

    // Logic to calculate PC+4
    assign pc_plus_4 = pc + 32'd4;
    
    // Logic to choose the next PC
    assign pc_src = branch & alu_zero; // Branch only if (BEQ=1) AND (Zero=1)
    assign next_pc = (pc_src) ? branch_addr : pc_plus_4;
    
    
    // --- 2. Instruction Fetch ---
    // We use one 'memory' module for Instruction Memory.
    // Reading is combinational (no clk needed for read).
    memory inst_mem (
        .clk(clk), // Not used for read, but module needs it
        .write_enable(1'b0), // NEVER write to instruction memory
        .addr(pc[11:2]),     // We use 10 bits [11:2] to address 1K memory
        .write_data(32'd0),
        .read_data(instruction)
    );

    
    // --- 3. Instruction Decode & Control Unit ---
    // Break down the instruction into its parts
    assign opcode  = instruction[31:26];
    assign rs_addr = instruction[25:21];
    assign rt_addr = instruction[20:16];
    assign rd_addr = instruction[15:11]; // For R-Type
    assign immediate = instruction[15:0];

    // Feed the opcode to the main control unit
    control main_control (
        .opcode(opcode),
        .reg_write(reg_write),
        .alu_op(alu_op),
        .mem_write(mem_write),
        .mem_read(mem_read),
        .mem_to_reg(mem_to_reg),
        .alu_src(alu_src),
        .branch(branch)
    );

    
    // --- 4. Register File Read ---
    // A MUX to select the correct write address
    // R-Type uses 'rd', I-Type (lw) uses 'rt'
    assign write_reg_addr = (opcode == 6'b000000) ? rd_addr : rt_addr;

    register_file reg_file (
        .clk(clk),
        .rst(rst),
        .reg_write(reg_write),
        .read_addr1(rs_addr),
        .read_addr2(rt_addr),
        .write_addr(write_reg_addr),
        .write_data(write_reg_data),
        .read_data1(rs_data),
        .read_data2(rt_data)
    );
    
    
    // --- 5. Execute (ALU) ---
    // Sign Extender
    assign sign_extended_imm = {{16{immediate[15]}}, immediate};
    
    // MUX for ALU input B
    assign alu_in_b = (alu_src) ? sign_extended_imm : rt_data;
    
    // Calculate branch address
    // (Note: This is a simplified branch calculation)
    assign branch_addr = pc_plus_4 + (sign_extended_imm << 2);

    // The ALU itself
    alu main_alu (
        .a(rs_data),
        .b(alu_in_b),
        .alu_control(alu_op), // We'll simplify ALU control for now
        .result(alu_result),
        .zero(alu_zero)
    );

    
    // --- 6. Memory Access ---
    // We use another 'memory' module for Data Memory
    memory data_mem (
        .clk(clk),
        .write_enable(mem_write),
        .addr(alu_result[11:2]), // ALU result is the memory address
        .write_data(rt_data),    // rt data is written for SW
        .read_data(mem_read_data)
    );

    
    // --- 7. Write Back ---
    // MUX to select what to write back to the register file
    assign write_reg_data = (mem_to_reg) ? mem_read_data : alu_result;

endmodule