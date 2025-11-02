// memory.v
// A simple 1K-word (1024 lines) x 32-bit RAM module.
// We will use this for both Instruction and Data memory.
module memory (
    input         clk,
    input         write_enable,  // 1 = Write, 0 = Read
    input  [9:0]  addr,          // 10 bits = 2^10 = 1024 addresses
    input  [31:0] write_data,
    output [31:0] read_data
);

    // This is our 1KB memory array.
    // 1024 entries, from 0 to 1023.
    reg [31:0] mem_array [0:1023];

    // --- Sequential Write Logic ---
    // Writing happens only on the positive clock edge.
    always @(posedge clk) begin
        if (write_enable) begin
            mem_array[addr] <= write_data;
        end
    end

    // --- Combinational Read Logic ---
    // Reading is asynchronous (combinational).
    // The output 'read_data' will always show what's
    // at the current 'addr'.
    assign read_data = mem_array[addr];

endmodule