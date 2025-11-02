// control.v (גרסה משודרגת)
// מפענח את ה-Opcode הראשי
module control (
    input  [5:0] opcode,      
    
    // --- To Register File ---
    output reg reg_write,     
    
    // --- To Data Memory ---
    output reg mem_write,     
    output reg mem_read,      
    
    // --- To MUXes ---
    output reg mem_to_reg,    
    output reg alu_src,       
    output reg branch,
    
    // --- יציאה חדשה ל-ALU Control Unit ---
    output reg [1:0] alu_op_main // אות בקרה ל"מתרגם"
);

    // --- קודי Opcode ראשיים (אמיתיים של MIPS) ---
    localparam OP_R_TYPE = 6'b000000;
    localparam OP_ADDI   = 6'b001000;
    localparam OP_LW     = 6'b100011;
    localparam OP_SW     = 6'b101011;
    localparam OP_BEQ    = 6'b000100;
    
    // --- סוגי הפעולות עבור ה"מתרגם" ---
    localparam OP_TYPE_LW_SW = 2'b00;
    localparam OP_TYPE_BEQ   = 2'b01;
    localparam OP_TYPE_R     = 2'b10;
    // (ADDI מטופל בנפרד כי הוא לא R-Type)

    always @(*) begin
        // --- Set default values ---
        reg_write = 1'b0;
        mem_write = 1'b0;
        mem_read  = 1'b0;
        mem_to_reg= 1'b0;
        alu_src   = 1'b0;
        branch    = 1'b0;
        alu_op_main = 2'bXX; // "Don't Care" כברירת מחדל

        // --- Decode the opcode ---
        case (opcode)
            OP_R_TYPE: begin
                reg_write = 1'b1;
                alu_src   = 1'b0;
                alu_op_main = OP_TYPE_R; // "זו פקודת R-Type, תסתכל ב-funct"
            end
            
            OP_ADDI: begin
                reg_write = 1'b1;
                alu_src   = 1'b1;
                // ADDI לא צריך את המתרגם, הוא תמיד ADD
                // נשמור על הקוד של R-Type ונאפשר ל-ALU Control להחליט
                // אבל זה לא אידיאלי. דרך טובה יותר היא להוסיף סוג 11
                // בינתיים נשאיר את זה פשוט:
                // ADDI יטופל כמו LW (חישוב כתובת)
                alu_op_main = OP_TYPE_LW_SW; 
            end

            OP_LW: begin
                reg_write = 1'b1;
                mem_read  = 1'b1;
                mem_to_reg= 1'b1;
                alu_src   = 1'b1;
                alu_op_main = OP_TYPE_LW_SW; // "תבצע חיבור"
            end

            OP_SW: begin
                mem_write = 1'b1;
                alu_src   = 1'b1;
                alu_op_main = OP_TYPE_LW_SW; // "תבצע חיבור"
            end
            
            OP_BEQ: begin
                branch    = 1'b1;
                alu_src   = 1'b0;
                alu_op_main = OP_TYPE_BEQ; // "תבצע חיסור"
            end

            default: begin
                // ...
            end
        endcase
    end

endmodule