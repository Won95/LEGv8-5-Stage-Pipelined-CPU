module chip_top #(
    parameter integer CLK_FREQ_HZ = 50_000_000,
    parameter integer UART_BAUD   = 115200
) (
    input  wire        clk,
    input  wire        rst,

    input  wire        uart_rx,
    output wire        uart_tx,

    inout  wire [31:0] gpio,

    output wire        load_done
);

    /*==============================
      Package GPIO <-> internal MMIO GPIO
      ==============================*/
    wire [63:0] gpio_in_internal;
    wire [63:0] gpio_out_internal;
    wire [63:0] gpio_oe_internal;

    assign gpio_in_internal[31:0]  = gpio;
    assign gpio_in_internal[63:32] = 32'd0;

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : GPIO_PAD_MODEL
            assign gpio[i] = gpio_oe_internal[i] ? gpio_out_internal[i] : 1'bz;
        end
    endgenerate

    /*==============================
      Bit-level UART RX PHY

      Before load_done : UART bytes feed boot receiver.
      After  load_done : UART bytes feed runtime MMIO UART.
      ==============================*/
    wire       rx_byte_valid;
    wire [7:0] rx_byte_data;
    wire       rx_byte_ready;

    uart_rx_phy #(
        .CLK_FREQ_HZ (CLK_FREQ_HZ),
        .BAUD        (UART_BAUD)
    ) uart_rx_phy_inst (
        .clk       (clk),
        .rst       (rst),
        .rx        (uart_rx),
        .out_valid (rx_byte_valid),
        .out_data  (rx_byte_data),
        .out_ready (rx_byte_ready)
    );

    /*==============================
      UART boot receiver -> existing external image stream
      ==============================*/
    wire        boot_byte_ready;
    wire        ext_valid;
    wire        ext_target;
    wire        ext_last;
    wire [63:0] ext_addr;
    wire [63:0] ext_wdata;
    wire        ext_ready;

    uart_boot_receiver boot_receiver (
        .clk        (clk),
        .rst        (rst),
        .byte_valid (rx_byte_valid && !load_done),
        .byte_data  (rx_byte_data),
        .byte_ready (boot_byte_ready),

        .ext_valid  (ext_valid),
        .ext_target (ext_target),
        .ext_last   (ext_last),
        .ext_addr   (ext_addr),
        .ext_wdata  (ext_wdata),
        .ext_ready  (ext_ready)
    );

    /*==============================
      Runtime UART byte stream
      ==============================*/
    wire       soc_uart_rx_ready;
    wire       soc_uart_tx_valid;
    wire [7:0] soc_uart_tx_data;
    wire       soc_uart_tx_ready;

    assign rx_byte_ready = load_done ? soc_uart_rx_ready : boot_byte_ready;

    wire       tx_byte_ready;

    assign soc_uart_tx_ready = load_done && tx_byte_ready;

    uart_tx_phy #(
        .CLK_FREQ_HZ (CLK_FREQ_HZ),
        .BAUD        (UART_BAUD)
    ) uart_tx_phy_inst (
        .clk      (clk),
        .rst      (rst),
        .in_valid (load_done && soc_uart_tx_valid),
        .in_data  (soc_uart_tx_data),
        .in_ready (tx_byte_ready),
        .tx       (uart_tx)
    );

    /*==============================
      Internal SoC
      ==============================*/
    soc_top soc (
        .clk           (clk),
        .rst           (rst),

        .ext_valid     (ext_valid),
        .ext_target    (ext_target),
        .ext_last      (ext_last),
        .ext_addr      (ext_addr),
        .ext_wdata     (ext_wdata),
        .ext_ready     (ext_ready),

        .gpio_in       (gpio_in_internal),
        .gpio_out      (gpio_out_internal),
        .gpio_oe       (gpio_oe_internal),

        .uart_rx_valid (rx_byte_valid && load_done),
        .uart_rx_data  (rx_byte_data),
        .uart_rx_ready (soc_uart_rx_ready),

        .uart_tx_valid (soc_uart_tx_valid),
        .uart_tx_data  (soc_uart_tx_data),
        .uart_tx_ready (soc_uart_tx_ready),

        .load_done     (load_done)
    );

endmodule
