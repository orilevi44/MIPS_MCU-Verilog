// cpu.v (גרסה משודרגת עם alu_control_unit)
// זהו הליבה של המעבד, מחובר ליחידת בקרה היררכית.
module cpu (
    input clk,
    input rst,
    
    // --- ממשק זיכרון הוראות ---
    input  [31:0] inst_in,
    output [31:0] inst_addr,

    // --- ממשק זיכרון נתונים ---
    input  [31:0] data_in,
    output [31:0] data_addr,
    output [31:0] data_out,
    output        data_mem_write,
    output        data_mem_read
);

    // --- חוטים פנימיים ---

    // PC Logic
    reg  [31:0] pc;
    wire [31:0] pc_plus_4;
    wire [31:0] branch_addr;
    wire [31:0] next_pc;
    wire        pc_src;

    // Instruction Decode
    wire [31:0] instruction;
    wire [5:0]  opcode;
    wire [5:0]  funct; // <-- חוט חדש עבור שדה ה-funct

    // Control Signals
    wire        reg_write;
    wire [1:0]  alu_op_main;     // <-- חוט חדש (מה-control הראשי)
    wire [3:0]  alu_control_final; // <-- חוט חדש (אל ה-ALU הסופי)
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
    always @(posedge clk or posedge rst) begin
        if (rst)
            pc <= 32'd0;
        else
            pc <= next_pc;
    end
    assign pc_plus_4 = pc + 32'd4;
    assign pc_src = branch & alu_zero;
    assign next_pc = (pc_src) ? branch_addr : pc_plus_4;
    
    
    // --- 2. Instruction Fetch ---
    assign inst_addr = pc;
    assign instruction = inst_in;

    
    // --- 3. Instruction Decode & Control Unit ---
    // פיצול הפקודה לחלקיה
    assign opcode  = instruction[31:26];
    assign rs_addr = instruction[25:21];
    assign rt_addr = instruction[20:16];
    assign rd_addr = instruction[15:11];
    assign immediate = instruction[15:0];
    assign funct = instruction[5:0]; // <-- שולפים את שדה ה-funct
    

    // --- Main Control Unit ---
    control main_control (
        .opcode(opcode),
        .reg_write(reg_write),
        .mem_write(data_mem_write), // <-- שונה ל-data_mem_write
        .mem_read(data_mem_read),   // <-- שונה ל-data_mem_read
        .mem_to_reg(mem_to_reg),
        .alu_src(alu_src),
        .branch(branch),
        .alu_op_main(alu_op_main) // <-- יציאה מעודכנת (2 סיביות)
    );
    
    // --- !!! רכיב חדש: "המתרגם" !!! ---
    alu_control_unit alu_decoder (
        .funct(funct),                 // כניסה: 6 סיביות ה-funct
        .alu_op_main(alu_op_main),     // כניסה: 2 סיביות בקרה מה-control
        .alu_control_out(alu_control_final) // יציאה: 4 סיביות "מתורגמות" ל-ALU
    );

    
    // --- 4. Register File Read ---
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
    assign branch_addr = pc_plus_4 + (sign_extended_imm << 2);

    // --- The ALU itself ---
    alu main_alu (
        .a(rs_data),
        .b(alu_in_b),
        .alu_control(alu_control_final), // <-- חוט מעודכן (4 סיביות)
        .result(alu_result),
        .zero(alu_zero)
    );

    
    // --- 6. Memory Access ---
    // (המימוש עבר ל-mcu.v, אלו רק היציאות)
    assign data_addr = alu_result;
    assign data_out = rt_data;

    
    // --- 7. Write Back ---
    // MUX to select what to write back to the register file
    assign write_reg_data = (mem_to_reg) ? data_in : alu_result;

endmodule