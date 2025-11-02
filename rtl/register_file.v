// register_file.v (FIXED VERSION 2)
// MIPS Register File (32 registers, 32-bits each)
module register_file (
    input         clk,
    input         rst,         // Reset signal
    input         reg_write,   // Write Enable (1 = Write)
    input  [4:0]  read_addr1,  // Address for read port 1 (5 bits -> 2^5=32)
    input  [4:0]  read_addr2,  // Address for read port 2
    input  [4:0]  write_addr,  // Address for write port
    input  [31:0] write_data,  // Data to write
    output [31:0] read_data1,  // Data from read port 1
    output [31:0] read_data2   // Data from read port 2
);

    // This is the core memory: an array of 32 elements,
    // where each element is 32 bits wide.
    reg [31:0] registers [0:31];

    // --- !!! MOVED HERE !!! ---
    // Declaring 'i' here at the module level
    // to fix the SystemVerilog error.
    integer i;

    // --- Sequential Write Logic ---
    // This block triggers on the clock edge OR reset edge
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // On reset, clear all registers to 0
            // The 'i' variable is now declared at the top
            for (i = 0; i < 32; i = i + 1) begin
                registers[i] <= 32'd0;
            end
        end 
        else if (reg_write) begin
            // On a clock edge, if write is enabled:
            // Write the data to the specified address
            
            // --- CRITICAL: Handle register $zero ---
            // We must ensure that register 0 ALWAYS stays 0.
            if (write_addr != 5'd0) begin
                registers[write_addr] <= write_data;
            end
        end
    end

    // --- Combinational Read Logic ---
    // Reading is asynchronous (no clock).
    assign read_data1 = registers[read_addr1];
    assign read_data2 = registers[read_addr2];

endmodule