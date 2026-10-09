module chip_top (
    input  wire        clk,
    input  wire        rst,

    // Package-level GPIO model. Only the lower 16 MMIO GPIO bits are bonded out.
    inout  wire [15:0] gpio,

    // Runtime UART is intentionally kept at the byte-stream boundary.
    // A bit-level UART PHY is outside the scope of this PD-focused project.
    input  wire        uart_rx_valid,
    input  wire [7:0]  uart_rx_data,
    output wire        uart_rx_ready,

    output wire        uart_tx_valid,
    output wire [7:0]  uart_tx_data,
    input  wire        uart_tx_ready,

    output wire        load_done
);

    /*==============================
      Package GPIO <-> internal MMIO GPIO

      The SoC keeps a 64-bit GPIO register interface internally, while the
      package-facing wrapper bonds out only 16 bidirectional GPIO signals.
      ==============================*/
    wire [63:0] gpio_in_internal;
    wire [63:0] gpio_out_internal;
    wire [63:0] gpio_oe_internal;

    assign gpio_in_internal[15:0]  = gpio;
    assign gpio_in_internal[63:16] = 48'd0;

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : GPIO_PAD_MODEL
            assign gpio[i] = gpio_oe_internal[i] ? gpio_out_internal[i] : 1'bz;
        end
    endgenerate

    /*==============================
      PD-only startup abstraction

      The real program/data image loading path is verified at soc_top through
      the external-memory model and FIFO/Loader path. It is not exposed as a
      package interface here.

      For chip-level synthesis/PD, issue one internal final loader packet after
      reset so the CPU can leave its load hold state without implementing a
      UART/SPI boot protocol in this project.
      ==============================*/
    reg         pd_boot_valid;
    wire        ext_ready;

    always @(posedge clk) begin
        if (rst)
            pd_boot_valid <= 1'b1;
        else if (pd_boot_valid && ext_ready)
            pd_boot_valid <= 1'b0;
    end

    /*==============================
      Internal SoC
      ==============================*/
    soc_top soc (
        .clk           (clk),
        .rst           (rst),

        .ext_valid     (pd_boot_valid),
        .ext_target    (1'b1),
        .ext_last      (1'b1),
        .ext_addr      (64'd0),
        .ext_wdata     (64'd0),
        .ext_ready     (ext_ready),

        .gpio_in       (gpio_in_internal),
        .gpio_out      (gpio_out_internal),
        .gpio_oe       (gpio_oe_internal),

        .uart_rx_valid (uart_rx_valid),
        .uart_rx_data  (uart_rx_data),
        .uart_rx_ready (uart_rx_ready),

        .uart_tx_valid (uart_tx_valid),
        .uart_tx_data  (uart_tx_data),
        .uart_tx_ready (uart_tx_ready),

        .load_done     (load_done)
    );

endmodule
