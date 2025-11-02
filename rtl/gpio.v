// gpio.v
// A simple 32-bit GPIO (General Purpose Input/Output) controller.
module gpio (
    input         clk,
    input         rst,
    
    // --- CPU Interface (Memory-Mapped) ---
    input         chip_select,   // 1 = This module is being accessed
    input         write_enable,
    input  [1:0]  addr,          // 2-bit address (for 2 registers)
    input  [31:0] write_data,
    output reg [31:0] read_data,
    
    // --- Physical Pins ---
    inout  [31:0] pins // The actual connection to the outside world
);

    reg [31:0] direction_reg; // 0 = Input, 1 = Output
    reg [31:0] data_reg;      // Data to drive to output pins

    localparam ADDR_DIR  = 2'b00; // Address 0
    localparam ADDR_DATA = 2'b10; // Address 4 (word-aligned)

    // --- Write Logic (CPU writes to our registers) ---
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            direction_reg <= 32'd0; // Default to all inputs
            data_reg      <= 32'd0;
        end 
        else if (chip_select && write_enable) begin
            if (addr == ADDR_DIR) begin
                direction_reg <= write_data;
            end
            else if (addr == ADDR_DATA) begin
                data_reg <= write_data;
            end
        end
    end

    // --- Read Logic (CPU reads from our registers) ---
    always @(*) begin
        if (chip_select && !write_enable) begin
            if (addr == ADDR_DIR) begin
                read_data = direction_reg;
            end
            else if (addr == ADDR_DATA) begin
                // When reading data, we read the *actual pin values*
                read_data = pins; 
            end
            else begin
                read_data = 32'h0;
            end
        end 
        else begin
            read_data = 32'h0;
        end
    end

    // --- Pin Tri-State Logic ---
    // This is the core of the GPIO.
    // It uses a continuous assign to control each pin.
    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin
            // If direction_reg[i] is 1 (output), drive the pin with data_reg[i].
            // If direction_reg[i] is 0 (input), set pin to 'Z' (high-impedance)
            // so it can be driven by an external signal.
            assign pins[i] = (direction_reg[i]) ? data_reg[i] : 1'bz;
        end
    endgenerate

endmodule