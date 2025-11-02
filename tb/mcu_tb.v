// mcu_tb.v (FIXED)
`timescale 1ns/1ps

module mcu_tb;

    // --- Testbench Registers ---
    reg tb_clk;
    reg tb_rst;
    
    // --- Wires for GPIO ---
    wire [31:0] tb_gpio_pins;

    // --- !!! MOVED HERE !!! ---
    // Declaring 'i' at the module level
    // to fix the SystemVerilog error.
    integer i;

    // --- Instantiate the MCU ---
    mcu dut (
        .clk(tb_clk),
        .rst(tb_rst),
        .gpio_pins(tb_gpio_pins)
    );
    
    // --- Clock Generator ---
    initial begin
        tb_clk = 1'b0;
    end
    always begin
        #5 tb_clk = ~tb_clk;
    end
    
    // --- Main Test Sequence ---
    initial begin
        $dumpfile("mcu.vcd");
        $dumpvars(0, mcu_tb);
        
        $display("--- Starting MCU System Test ---");

        // 1. Load the program into the Instruction Memory
        // Note the new path to the inst_mem, *inside* the mcu
        $readmemh("program4.hex", dut.inst_mem.mem_array);
        $display("--- Program 4 (GPIO) loaded ---");

        // 2. Reset
        tb_rst = 1'b1;
        @(posedge tb_clk);
        @(posedge tb_clk);
        tb_rst = 1'b0;
        $display("--- Reset Released, MCU running ---");
        
        // 3. Let the CPU run (5 instructions)
        // 'i' is now declared at the top of the module
        for (i = 0; i < 7; i = i + 1) begin
            @(posedge tb_clk);
        end
        
        #1; // Let signals settle

        // 4. Check the external GPIO pins
        if (tb_gpio_pins[5] === 1'b1 && tb_gpio_pins[7] === 1'b0) begin
            $display("--- !!! TEST PASSED !!! ---");
            $display("GPIO Pin 5 is 1, Pin 7 is 0.");
        end else begin
            $display("--- !!! TEST FAILED !!! ---");
            $display("GPIO Pin 5 is %b (Expected 1)", tb_gpio_pins[5]);
            $display("GPIO Pin 7 is %b (Expected 0)", tb_gpio_pins[7]);
        end
        
        $finish;
    end

endmodule