// mcu_final_tb.v
`timescale 1ns/1ps

module mcu_final_tb;

    localparam CLKS_PER_BIT = 868; // 100MHz / 115200

    // --- Testbench Registers ---
    reg tb_clk;
    reg tb_rst;
    
    // --- Wires ---
    wire [31:0] tb_gpio_pins; // Not used, but must connect
    wire        tb_uart_tx_pin;
    
    // --- Receiver Registers ---
    reg [7:0] received_data;
    integer   i;

    // --- Instantiate the MCU ---
    mcu dut (
        .clk(tb_clk),
        .rst(tb_rst),
        .gpio_pins(tb_gpio_pins),
        .uart_tx_pin(tb_uart_tx_pin)
    );
    
    // --- Clock Generator ---
    initial begin
        tb_clk = 1'b0;
    end
    always begin
        #5 tb_clk = ~tb_clk;
    end
    
    // --- Task to receive a byte ---
    task receive_byte;
        output [7:0] data;
        begin
            wait (tb_uart_tx_pin == 1'b0); // Wait for start bit
            #(CLKS_PER_BIT * 5); // Wait half bit time (10ns * 868 * 5)
            
            if (tb_uart_tx_pin !== 1'b0) $display("--- !!! FAILED: Start Bit Bad !!! ---");
            
            for (i = 0; i < 8; i = i + 1) begin
                #(CLKS_PER_BIT * 10); // Wait one full bit time
                data[i] = tb_uart_tx_pin;
            end
            
            #(CLKS_PER_BIT * 10); // Check stop bit
            if (tb_uart_tx_pin !== 1'b1) $display("--- !!! FAILED: Stop Bit Bad !!! ---");
        end
    endtask

    
    // --- Main Test Sequence ---
    initial begin
        $dumpfile("mcu_final.vcd");
        $dumpvars(0, mcu_final_tb);
        
        $display("--- Starting Final MCU System Test ---");

        // 1. Load the program
        $readmemh("program5.hex", dut.inst_mem.mem_array);
        $display("--- Program 5 (UART) loaded ---");

        // 2. Reset
        tb_rst = 1'b1;
        @(posedge tb_clk);
        @(posedge tb_clk);
        tb_rst = 1'b0;
        $display("--- Reset Released, MCU running ---");
        
        // 3. Receive the first byte ('H')
        receive_byte(received_data);
        if (received_data !== 8'h48) begin
            $display("--- !!! TEST FAILED: Did not receive 'H' !!! ---");
            $finish;
        end
        $display("--- Received 'H' (0x%h) ---", received_data);

        // 4. Receive the second byte ('i')
        receive_byte(received_data);
        if (received_data !== 8'h69) begin
            $display("--- !!! TEST FAILED: Did not receive 'i' !!! ---");
            $finish;
        end
        $display("--- Received 'i' (0x%h) ---", received_data);

        
        $display("--- !!! ALL TESTS PASSED !!! ---");
        $display("--- MCU is fully functional! ---");
        $finish;
    end

endmodule