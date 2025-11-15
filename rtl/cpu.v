
// cpu.v (Upgraded version with alu_control_unit)
// This is the CPU core, connected to a hierarchical control unit.

module cpu (
    input clk,
    input rst,
    
    // --- Instruction Memory .Interface ---
    input  [31:0] inst_in,
    output [31:0] inst_addr,

    // --- Data Memory Interface ---
    input  [31:0] data_in,
    output [31:0] data_addr,
    output [31:0] data_out,
    output        data_mem_write,
    output        data_mem_read
);

    // --- Internal Wires ---

    // PC Logic
    reg  [31:0] pc;
    wire [31:0] pc_plus_4;
    wire [31:0] branch_addr;
    wire [31:0] next_pc;
    wire        pc_src;

    // Instruction Decode
    wire [31:0] instruction;
    wire [5:0]  opcode;
    wire [5:0]  funct; // New wire for the funct field

    // Control Signals
    wire        reg_write;
    wire [1:0]  alu_op_main;     // 2-bit signal from main control
    wire [3:0]  alu_control_final; // 4-bit "translated" signal for ALU
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


    // --- 1. Program Counter (PC) ---
    // This register holds the address of the current instruction
    always @(posedge clk or posedge rst) begin
        if (rst)
            pc <= 32'd0;
        else
            pc <= next_pc;
    end
    
    // Logic to calculate PC+4 (default next instruction)
    assign pc_plus_4 = pc + 32'd4;
    
    // MUX logic for the next PC
    assign pc_src = branch & alu_zero; // Branch is taken if branch=1 AND zero=1
    assign next_pc = (pc_src) ? branch_addr : pc_plus_4;
    
    
    // --- 2. Instruction Fetch ---
    // We output the current PC as the address for instruction memory
    assign inst_addr = pc;
    // We receive the instruction from the outside world
    assign instruction = inst_in;

    
    // --- 3. Instruction Decode & Control Unit ---
    // Splitting the instruction into its parts
    assign opcode  = instruction[31:26];
    assign rs_addr = instruction[25:21];
    assign rt_addr = instruction[20:16];
    assign rd_addr = instruction[15:11];
    assign immediate = instruction[15:0];
    assign funct = instruction[5:0]; // Extracting the funct field
    

    // --- Main Control Unit ---
    control main_control (
        .opcode(opcode),
        .reg_write(reg_write),
        .mem_write(data_mem_write), // Now an output
        .mem_read(data_mem_read),   // Now an output
        .mem_to_reg(mem_to_reg),
        .alu_src(alu_src),
        .branch(branch),
        .alu_op_main(alu_op_main) // Updated 2-bit output
    );
    
    // --- New Component: The "Translator" ---
    alu_control_unit alu_decoder (
        .funct(funct),                 // Input: 6-bit funct
        .alu_op_main(alu_op_main),     // Input: 2-bit control signal
        .alu_control_out(alu_control_final) // Output: 4-bit "translated" signal
    );

    
    // --- 4. Register File Read ---
    // MUX to select the destination register
    // R-Type uses 'rd', I-Type (like lw) uses 'rt'
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
    // Sign Extender (converts 16-bit immediate to 32-bit)
    assign sign_extended_imm = {{16{immediate[15]}}, immediate};
    
    // MUX for ALU input B
    // Selects between a register (rt_data) or the immediate value
    assign alu_in_b = (alu_src) ? sign_extended_imm : rt_data;
    
    // Calculate branch address
    assign branch_addr = pc_plus_4 + (sign_extended_imm << 2);

    // --- The ALU itself ---
    alu main_alu (
        .a(rs_data),
        .b(alu_in_b),
        .alu_control(alu_control_final), // Using the translated 4-bit signal
        .result(alu_result),
        .zero(alu_zero)
    );

    
    // --- 6. Memory Access ---
    // Implementation moved to mcu.v, these are just outputs
    assign data_addr = alu_result;
    assign data_out = rt_data;

    
    // --- 7. Write Back ---
    // MUX to select what to write back to the register file
    // Either the result from the ALU, or the data from memory
    assign write_reg_data = (mem_to_reg) ? data_in : alu_result;

endmodule