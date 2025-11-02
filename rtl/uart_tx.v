// uart_tx.v (FIXED)
// A simple UART Transmitter module.
module uart_tx #(
    parameter CLKS_PER_BIT = 868 // 100,000,000 / 115200 = 868
) (
    input clk,
    input rst,
    
    // --- CPU Interface ---
    input        tx_start,      // 1-cycle pulse to start
    input [7:0]  tx_data_in,    // 8-bit data to send
    output reg   tx_busy,       // 1 = busy sending
    
    // --- Physical Pin ---
    output reg   tx_serial_out  // The serial line
);

    // --- State Machine ---
    localparam STATE_IDLE = 3'b000;
    localparam STATE_START= 3'b001;
    localparam STATE_DATA = 3'b010;
    localparam STATE_STOP = 3'b011;

    reg [2:0] state;
    reg [15:0] clk_divider; // Counter for baud rate
    reg [3:0] bit_index;   // Counts which bit we're on (0-7)
    reg [7:0] data_reg;    // Latched data
    
    // --- !!! MOVED HERE !!! ---
    reg tick;              // Baud rate tick signal

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= STATE_IDLE;
            clk_divider <= 0;
            bit_index <= 0;
            tx_busy <= 1'b0;
            tx_serial_out <= 1'b1; // TX line is idle high
            data_reg <= 8'd0;
        end 
        else begin
            // --- Baud Rate Clock Divider ---
            // This 'tick' will go high once every CLKS_PER_BIT cycles
            tick = 1'b0; // <-- SET DEFAULT HERE
            if (clk_divider == (CLKS_PER_BIT - 1)) begin
                clk_divider <= 0;
                tick = 1'b1;
            end else if (state != STATE_IDLE) begin
                clk_divider <= clk_divider + 1;
            end
            
            // --- FSM ---
            case (state)
                STATE_IDLE: begin
                    tx_serial_out <= 1'b1; // Keep line high
                    tx_busy <= 1'b0;
                    if (tx_start) begin
                        state <= STATE_START;
                        data_reg <= tx_data_in; // Latch the data
                        clk_divider <= 0;
                        tx_busy <= 1'b1;
                    end
                end
                
                STATE_START: begin
                    tx_serial_out <= 1'b0; // Start bit (low)
                    if (tick) begin
                        state <= STATE_DATA;
                        bit_index <= 0;
                    end
                end
                
                STATE_DATA: begin
                    tx_serial_out <= data_reg[bit_index];
                    if (tick) begin
                        if (bit_index == 7) begin
                            state <= STATE_STOP;
                        end else begin
                            bit_index <= bit_index + 1;
                        end
                    end
                end
                
                STATE_STOP: begin
                    tx_serial_out <= 1'b1; // Stop bit (high)
                    if (tick) begin
                        state <= STATE_IDLE; // Back to idle
                    end
                end
                
                default:
                    state <= STATE_IDLE;

            endcase
        end
    end

endmodule