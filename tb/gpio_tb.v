// gpio_tb.v
`timescale 1ns/1ps

module gpio_tb;

    // --- Testbench Registers (CPU side) ---
    reg        tb_clk;
    reg        tb_rst;
    reg        tb_chip_select;
    reg        tb_write_enable;
    reg [1:0]  tb_addr;
    reg [31:0] tb_write_data;

    // --- Testbench Wires (CPU side) ---
    wire [31:0] tb_read_data;

    // --- Testbench Wires (External Pin side) ---
    // 'pins' is a wire here. We use pull-up/pull-down
    // to simulate external signals when pins are inputs.
    wire [31:0] tb_pins;

    // Instantiate the DUT
    gpio dut (
        .clk(tb_clk),
        .rst(tb_rst),
        .chip_select(tb_chip_select),
        .write_enable(tb_write_enable),
        .addr(tb_addr),
        .write_data(tb_write_data),
        .read_data(tb_read_data),
        .pins(tb_pins)
    );

    // --- External World Simulation ---
    // Simulate a pull-down resistor on pin 7
    // and a pull-up resistor on pin 8 (making it '1')
    assign tb_pins[7] = 1'b0;
    assign tb_pins[8] = 1'b1;
    // All other pins are floating (Z)

    // --- Clock Generator ---
    initial begin
        tb_clk = 1'b0;
    end
    always begin
        #5 tb_clk = ~tb_clk;
    end

    // --- Main Test Sequence ---
    initial begin
        $dumpfile("gpio.vcd");
        $dumpvars(0, gpio_tb);
        
        $display("--- Starting GPIO Test ---");

        // 1. Reset
        tb_rst = 1'b1;
        tb_chip_select = 1'b0;
        tb_write_enable = 1'b0;
        @(posedge tb_clk);
        @(posedge tb_clk);
        tb_rst = 1'b0;
        $display("--- Reset Released ---");

        // 2. Test 1: Set pin 5 and pin 7 to OUTPUT
        $display("--- Test 1: Setting pins 5 and 7 to OUTPUT ---");
        @(posedge tb_clk);
        tb_chip_select = 1'b1;
        tb_write_enable = 1'b1;
        tb_addr = 2'b00; // Direction Register
        tb_write_data = 32'h000000A0; // Sets pin 7 (1000...) and pin 5 (0010...)
        @(posedge tb_clk);
        tb_chip_select = 1'b0;
        tb_write_enable = 1'b0;

        // 3. Test 2: Write '1' to pin 5 and '0' to pin 7
        $display("--- Test 2: Writing 1 to pin 5, 0 to pin 7 ---");
        @(posedge tb_clk);
        tb_chip_select = 1'b1;
        tb_write_enable = 1'b1;
        tb_addr = 2'b01; // Data Register
        tb_write_data = 32'h00000020; // Sets pin 5 to 1, all others 0
        @(posedge tb_clk);
        tb_chip_select = 1'b0;
        tb_write_enable = 1'b0;
        #1; // Let values propagate
        
        if (tb_pins[5] !== 1'b1 || tb_pins[7] !== 1'b0) begin
            $display("--- !!! TEST FAILED: Output Write !!! ---");
            $display("Pin 5: %b (Expected 1), Pin 7: %b (Expected 0)",
                     tb_pins[5], tb_pins[7]);
            $finish;
        end
        $display("--- Test Passed: Output Write (Pin 5=1, Pin 7=0) ---");


        // 4. Test 3: Read the Data Register
        // Should read the *external pin values*
        // We expect to read '1' from pin 8 (pull-up)
        // and '0' from pin 7 (which we are driving to 0)
        // and '0' from pin 0 (floating, but has pull-down)
        $display("--- Test 3: Reading input pins 7 and 8 ---");
        @(posedge tb_clk);
        tb_chip_select = 1'b1;
        tb_write_enable = 1'b0; // Read mode
        tb_addr = 2'b01; // Data Register
        @(posedge tb_clk);
        #1; // Let values propagate
        
        if (tb_read_data[8] !== 1'b1 || tb_read_data[7] !== 1'b0) begin
             $display("--- !!! TEST FAILED: Input Read !!! ---");
             $display("Read Data: 0x%h", tb_read_data);
             $finish;
        end
        $display("--- Test Passed: Input Read (Pin 8=1, Pin 7=0) ---");
        
        tb_chip_select = 1'b0;
        
        $display("--- All GPIO Tests Passed! ---");
        $finish;
    end

endmodule