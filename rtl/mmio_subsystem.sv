module mmio_subsystem (
    input  wire        clk,
    input  wire        rst,

    input  wire        valid,
    input  wire        write,
    input  wire [63:0] addr,
    input  wire [63:0] wdata,
    output wire        ready,
    output wire [63:0] rdata,

    input  wire [63:0] gpio_in,
    output wire [63:0] gpio_out,

    input  wire        uart_rx_valid,
    input  wire [7:0]  uart_rx_data,
    output wire        uart_rx_ready,

    output wire        uart_tx_valid,
    output wire [7:0]  uart_tx_data,
    input  wire        uart_tx_ready
);

    // MMIO sub-map inside 0x0100~0x01FF
    //   0x0100~0x011F : GPIO
    //   0x0120~0x013F : UART
    wire select_gpio;
    wire select_uart;

    assign select_gpio = (addr[63:8] == 56'd1) && (addr[7:5] == 3'b000);
    assign select_uart = (addr[63:8] == 56'd1) && (addr[7:5] == 3'b001);

    wire        gpio_ready;
    wire [63:0] gpio_rdata;

    wire        uart_ready;
    wire [63:0] uart_rdata;

    mmio_gpio gpio (
        .clk      (clk),
        .rst      (rst),
        .valid    (valid && select_gpio),
        .write    (write),
        .addr     (addr),
        .wdata    (wdata),
        .ready    (gpio_ready),
        .rdata    (gpio_rdata),
        .gpio_in  (gpio_in),
        .gpio_out (gpio_out)
    );

    mmio_uart uart (
        .clk      (clk),
        .rst      (rst),
        .valid    (valid && select_uart),
        .write    (write),
        .addr     (addr),
        .wdata    (wdata),
        .ready    (uart_ready),
        .rdata    (uart_rdata),

        .rx_valid (uart_rx_valid),
        .rx_data  (uart_rx_data),
        .rx_ready (uart_rx_ready),

        .tx_valid (uart_tx_valid),
        .tx_data  (uart_tx_data),
        .tx_ready (uart_tx_ready)
    );

    // Unmapped MMIO accesses complete immediately with zero.
    assign ready = select_gpio ? gpio_ready :
                   select_uart ? uart_ready :
                                 valid;

    assign rdata = select_gpio ? gpio_rdata :
                   select_uart ? uart_rdata :
                                 64'd0;

endmodule
