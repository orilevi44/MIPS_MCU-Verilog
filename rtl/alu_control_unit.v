// alu_control_unit.v
// alu_control is “translates” the MIPS instruction codes into the control signals that our ALU understands.
module alu_control_unit (
    input  [5:0] funct, // The 6-bit function field from the instruction    
    input  [1:0] alu_op_main, // The control signal from the Main Control
    output reg [3:0] alu_control_out // The 4-bit signal for our ALU
);

    // --- Internal ALU Codes (our ALU) ---
    localparam ALU_OP_ADD  = 4'b0010;
    localparam ALU_OP_SUB  = 4'b0110;
    localparam ALU_OP_AND  = 4'b0000;
    localparam ALU_OP_OR   = 4'b0001;
    localparam ALU_OP_SLT  = 4'b0111;
    localparam ALU_OP_XOR  = 4'b1000;
    localparam ALU_OP_NOR  = 4'b1001;
    localparam ALU_OP_SLLV = 4'b1010;
    localparam ALU_OP_SRLV = 4'b1011;

    // --- Real MIPS Funct Codes ---
    localparam FUNCT_ADD  = 6'b100000; // add
    localparam FUNCT_SUB  = 6'b100010; // sub
    localparam FUNCT_AND  = 6'b100100; // and
    localparam FUNCT_OR   = 6'b100101; // or
    localparam FUNCT_XOR  = 6'b100110; // xor
    localparam FUNCT_NOR  = 6'b100111; // nor
    localparam FUNCT_SLT  = 6'b101010; // slt
    localparam FUNCT_SLLV = 6'b000100; // sllv
    localparam FUNCT_SRLV = 6'b000110; // srlv
    
    // --- Main Control Signals ---
    localparam OP_TYPE_LW_SW = 2'b00; // ALU needs to ADD for address calculation
    localparam OP_TYPE_BEQ   = 2'b01; // ALU needs to SUB for comparison
    localparam OP_TYPE_R     = 2'b10; // ALU needs to look at the funct field

    always @(*) begin
        case (alu_op_main)
            OP_TYPE_LW_SW:
                alu_control_out = ALU_OP_ADD; // Regardless of the funct field, tell the ALU to ADD
                
            OP_TYPE_BEQ:
                alu_control_out = ALU_OP_SUB; // Regardless of the funct field, tell the ALU to SUB
                
            OP_TYPE_R: // Only the funct field is considered when the opcode indicates an R-type instruction
                case (funct)
                    FUNCT_ADD:  alu_control_out = ALU_OP_ADD;
                    FUNCT_SUB:  alu_control_out = ALU_OP_SUB;
                    FUNCT_AND:  alu_control_out = ALU_OP_AND;
                    FUNCT_OR:   alu_control_out = ALU_OP_OR;
                    FUNCT_XOR:  alu_control_out = ALU_OP_XOR;
                    FUNCT_NOR:  alu_control_out = ALU_OP_NOR;
                    FUNCT_SLT:  alu_control_out = ALU_OP_SLT;
                    FUNCT_SLLV: alu_control_out = ALU_OP_SLLV;
                    FUNCT_SRLV: alu_control_out = ALU_OP_SRLV;
                    default:    alu_control_out = 4'hX; // "Don't Care" 
                endcase
                
            default:
                alu_control_out = 4'hX; // "Don't Care"
        endcase
    end

endmodule