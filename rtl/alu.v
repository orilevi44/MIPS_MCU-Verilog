// alu.v
// This is our Design Under Test (DUT)
module alu (
    input  [31:0] a,          // Operand A
    input  [31:0] b,          // Operand B
    input  [3:0]  alu_control, // Control signal (4 bits = 16 operations)
    output reg [31:0] result, // The output result
    output reg        zero    // Zero flag: 1 if result is 0
);

    // --- Operation Codes (localparam definitions) ---
    localparam ALU_OP_ADD  = 4'b0010;
    localparam ALU_OP_SUB  = 4'b0110;
    localparam ALU_OP_AND  = 4'b0000;
    localparam ALU_OP_OR   = 4'b0001;
    localparam ALU_OP_SLT  = 4'b0111; // Set on Less Than
    localparam ALU_OP_XOR  = 4'b1000;
    localparam ALU_OP_NOR  = 4'b1001;
    localparam ALU_OP_SLLV = 4'b1010; // Shift Left Logical Variable
    localparam ALU_OP_SRLV = 4'b1011; // Shift Right Logical Variable


    // --- Combinational Logic for ALU ---
    // This block calculates the result based on the inputs
    always @(*) begin
        case (alu_control)
            ALU_OP_ADD:  result = a + b;
            ALU_OP_SUB:  result = a - b;
            ALU_OP_AND:  result = a & b;
            ALU_OP_OR:   result = a | b;
            ALU_OP_SLT:
                if ($signed(a) < $signed(b))
                    result = 32'd1;
                else
                    result = 32'd0;
            ALU_OP_XOR:  result = a ^ b; 
            ALU_OP_NOR:  result = ~(a | b); 
            ALU_OP_SLLV: result = b << a[4:0]; 
            ALU_OP_SRLV: result = b >> a[4:0];

            default: 
                result = 32'hDEADBEEF; // Default, indicates an error
        endcase
    end

    // --- Zero Flag Logic ---
    // This is also combinational, based on the *final* result
    always @(*) begin
        if (result == 32'd0)
            zero = 1'b1;
        else
            zero = 1'b0;
    end

endmodule