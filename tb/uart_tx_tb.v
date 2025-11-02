// uart_tx_tb.v (FIXED)
`timescale 1ns/1ps

module uart_tx_tb;

    localparam CLKS_PER_BIT = 868; // Must match the DUT

    // --- Testbench Registers ---
    reg        tb_clk;
    reg        tb_rst;
    reg        tb_tx_start;
    reg [7:0]  tb_tx_data_in;

    // --- Testbench Wires ---
    wire       tb_tx_busy;
    wire       tb_tx_serial_out;
    
    // --- !!! MOVED HERE !!! ---
    reg [7:0] received_data;
    integer i;

    // --- Instantiate the DUT ---
    uart_tx #(
        .CLKS_PER_BIT(CLKS_PER_BIT)
    ) dut (
        .clk(tb_clk),
        .rst(tb_rst),
        .tx_start(tb_tx_start),
        .tx_data_in(tb_tx_data_in),
        .tx_busy(tb_tx_busy),
        .tx_serial_out(tb_tx_serial_out)
    );

    // --- Clock Generator (100MHz) ---
    initial begin
        tb_clk = 1'b0;
    end
    always begin
        #5 tb_clk = ~tb_clk; // 10ns period
    end
    
    // --- Main Test Sequence ---
    initial begin
        $dumpfile("uart.vcd");
        $dumpvars(0, uart_tx_tb);
        
        $display("--- Starting UART TX Test ---");

        // 1. Reset
        tb_rst = 1'b1;
        tb_tx_start = 1'b0;
        tb_tx_data_in = 8'd0;
        @(posedge tb_clk);
        @(posedge tb_clk);
        tb_rst = 1'b0;
        $display("--- Reset Released ---");
        
        // Wait until DUT is not busy
        wait (tb_tx_busy == 1'b0);
        
        // 2. Send the letter 'A' (0x41 = 0b01000001)
        $display("--- Sending 'A' (0x41) ---");
        @(posedge tb_clk);
        tb_tx_data_in = 8'h41;
        tb_tx_start = 1'b1;
        @(posedge tb_clk);
        tb_tx_start = 1'b0; // De-assert start pulse
        
        // 3. --- Receiver Logic ---
        // Wait for the start bit to begin
        wait (tb_tx_serial_out == 1'b0);
        $display("Start bit detected.");
        
        // Wait half a bit time to get to the middle of the start bit
        #(CLKS_PER_BIT * 5); 
        
        // Check Start Bit
        if (tb_tx_serial_out !== 1'b0) $display("--- !!! FAILED: Start Bit Bad !!! ---");
        
        // Read 8 data bits
        // 'received_data' and 'i' are now declared at the top
        for (i = 0; i < 8; i = i + 1) begin
            #(CLKS_PER_BIT * 10); // Wait one full bit time (10ns * 868)
            received_data[i] = tb_tx_serial_out;
        end
        
        // Check Stop Bit
        #(CLKS_PER_BIT * 10);
        if (tb_tx_serial_out !== 1'b1) $display("--- !!! FAILED: Stop Bit Bad !!! ---");
        
        $display("Byte re-assembled.");

        // 4. Check results
        if (received_data === 8'h41) begin
            $display("--- !!! TEST PASSED !!! ---");
            $display("Received 0x%h (Expected 0x41)", received_data);
        end else begin
            $display("--- !!! TEST FAILED !!! ---");
            $display("Received 0x%h (Expected 0x41)", received_data);
        end
        
        $finish;
    end

endmodule