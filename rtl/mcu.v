// mcu.v (FINAL VERSION)
// It connects the CPU, memories, GPIO, and UART.
module mcu (
    input         clk,
    input         rst,
    
    // External pins
    inout  [31:0] gpio_pins,
    output        uart_tx_pin
);

    // --- CPU Wires ---
    wire [31:0] inst_addr;
    wire [31:0] inst_in;
    wire [31:0] data_addr;
    wire [31:0] data_out;
    wire        data_mem_write;
    wire        data_mem_read;
    wire [31:0] data_in; // Data to CPU

    // --- Peripheral Wires ---
    wire [31:0] ram_read_data;
    wire [31:0] gpio_read_data;
    wire [31:0] uart_read_data; // UART is write-only, will be 0
    wire        cs_ram;  // Chip Select for RAM
    wire        cs_gpio; // Chip Select for GPIO
    wire        cs_uart; // Chip Select for UART
    wire        uart_tx_busy;

    // --- 1. Instantiate CPU ---
    cpu the_cpu (
        .clk(clk),
        .rst(rst),
        .inst_in(inst_in),
        .inst_addr(inst_addr),
        .data_in(data_in),
        .data_addr(data_addr),
        .data_out(data_out),
        .data_mem_write(data_mem_write),
        .data_mem_read(data_mem_read)
    );

    // --- 2. Instantiate Instruction Memory (ROM) ---
    memory inst_mem (
        .clk(clk),
        .write_enable(1'b0), // Never write
        .addr(inst_addr[11:2]), // 10 bits for 1K
        .write_data(32'd0),
        .read_data(inst_in)
    );
    
    // --- 3. Address Decoder ---
    // RAM:   0x0000_0000 - 0x0000_0FFF
    // GPIO:  0x0000_1000 - 0x0000_1007
    // UART:  0x0000_1008 - 0x0000_100F
    assign cs_ram  = (data_addr < 32'h0000_1000);
    assign cs_gpio = (data_addr >= 32'h0000_1000) && (data_addr < 32'h0000_1008);
    assign cs_uart = (data_addr == 32'h0000_1008); // UART at one address

    // --- 4. Instantiate Data Memory (RAM) ---
    memory data_mem (
        .clk(clk),
        .write_enable(data_mem_write & cs_ram), // Write only if CS is active
        .addr(data_addr[11:2]), // Use 10 bits for 1K
        .write_data(data_out),
        .read_data(ram_read_data)
    );

    // --- 5. Instantiate GPIO ---
    gpio gpio_controller (
        .clk(clk),
        .rst(rst),
        .chip_select(cs_gpio),
        .write_enable(data_mem_write),
        .addr(data_addr[2:1]), // 00=DIR, 10=DATA
        .write_data(data_out),
        .read_data(gpio_read_data),
        .pins(gpio_pins)
    );
    
    // --- 6. Instantiate UART TX ---
    // The CPU will write to the UART. This 1-cycle write
    // will act as the 'tx_start' pulse.
    wire uart_start_pulse = data_mem_write & cs_uart & !uart_tx_busy;
    
    uart_tx uart_transmitter (
        .clk(clk),
        .rst(rst),
        .tx_start(uart_start_pulse),
        .tx_data_in(data_out[7:0]), // Send the lowest byte
        .tx_busy(uart_tx_busy),
        .tx_serial_out(uart_tx_pin)
    );
    assign uart_read_data = {{31'd0}, uart_tx_busy}; // CPU can read busy status

    // --- 7. Read Data MUX ---
    // Select which peripheral's data to send back to the CPU
    assign data_in = (cs_ram) ? ram_read_data :
                     (cs_gpio) ? gpio_read_data :
                     (cs_uart) ? uart_read_data :
                     32'h0; // Default

endmodule







// //-----THIS IS THE FIRST VERSION BEFORE I WROTE uart.v-----
// // mcu.v 
// // This is the top-level MCU module.
// // It connects the CPU, memories, and peripherals.
// module mcu (
//     input         clk,
//     input         rst,
    
//     // External pins for the GPIO
//     inout  [31:0] gpio_pins
// );

//     // --- CPU Wires ---
//     wire [31:0] inst_addr;
//     wire [31:0] inst_in;
//     wire [31:0] data_addr;
//     wire [31:0] data_out;
//     wire        data_mem_write;
//     wire        data_mem_read;
//     wire [31:0] data_in; // Data to CPU

//     // --- Peripheral Wires ---
//     wire [31:0] ram_read_data;
//     wire [31:0] gpio_read_data;
//     wire        cs_ram;  // Chip Select for RAM
//     wire        cs_gpio; // Chip Select for GPIO

//     // --- 1. Instantiate CPU ---
//     cpu the_cpu (
//         .clk(clk),
//         .rst(rst),
//         .inst_in(inst_in),
//         .inst_addr(inst_addr),
//         .data_in(data_in),
//         .data_addr(data_addr),
//         .data_out(data_out),
//         .data_mem_write(data_mem_write),
//         .data_mem_read(data_mem_read)
//     );

//     // --- 2. Instantiate Instruction Memory (ROM) ---
//     memory inst_mem (
//         .clk(clk),
//         .write_enable(1'b0), // Never write
//         .addr(inst_addr[11:2]), // 10 bits for 1K
//         .write_data(32'd0),
//         .read_data(inst_in)
//     );
    
//     // --- 3. Address Decoder ---
//     // Decodes the data address from the CPU
//     // RAM is at 0x0000_0000 - 0x0000_0FFF
//     // GPIO is at 0x0000_1000 - 0x0000_1007
//     assign cs_ram  = (data_addr < 32'h0000_1000);
//     assign cs_gpio = (data_addr >= 32'h0000_1000) && (data_addr < 32'h0000_1008);

//     // --- 4. Instantiate Data Memory (RAM) ---
//     memory data_mem (
//         .clk(clk),
//         .write_enable(data_mem_write & cs_ram), // Write only if CS is active
//         .addr(data_addr[11:2]), // Use 10 bits for 1K
//         .write_data(data_out),
//         .read_data(ram_read_data)
//     );

// // --- 5. Instantiate GPIO (FIXED) ---
//     gpio gpio_controller (
//         .clk(clk),
//         .rst(rst),
//         .chip_select(cs_gpio),                   // <-- FIX 1
//         .write_enable(data_mem_write),           // <-- FIX 2
//         .addr(data_addr[2:1]), // Use bits 2 and 1 for 4-byte alignment
//         .write_data(data_out),
//         .read_data(gpio_read_data),
//         .pins(gpio_pins)
//     );

//     // --- 6. Read Data MUX ---
//     // Select which peripheral's data to send back to the CPU
//     assign data_in = (cs_ram) ? ram_read_data :
//                      (cs_gpio) ? gpio_read_data :
//                      32'h0; // Default

// endmodule