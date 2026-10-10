module chip_top (
`ifdef USE_POWER_PINS
    // Core / I/O power-domain rails.
    inout wire        vccd1,
    inout wire        vssd1,
    inout wire        vddio,
    inout wire        vssio,
    inout wire        vdda,
    inout wire        vssa,
    inout wire        vswitch,
    inout wire        vcchib,
    inout wire        vddio_q,
    inout wire        vssio_q,
`endif

    // Physical package-facing signal pads.
    inout wire        pad_clk,
    inout wire        pad_rst,
    inout wire [15:0] pad_gpio
);

    /*======================================================================
      Sky130 signal I/O pads

      chip_top is the physical-design boundary.  The SoC itself keeps simple
      core-side logic signals; this wrapper translates them through real
      sky130_ef_io__gpiov2_pad macros.
      ======================================================================*/
    wire        clk_internal;
    wire        rst_internal;
    wire [15:0] gpio_in_pad;
    wire [15:0] gpio_out_pad;
    wire [15:0] gpio_oe_pad;

    io_pad_ring io_pads (
`ifdef USE_POWER_PINS
        .vccd1    (vccd1),
        .vssd1    (vssd1),
        .vddio    (vddio),
        .vssio    (vssio),
        .vdda     (vdda),
        .vssa     (vssa),
        .vswitch  (vswitch),
        .vcchib   (vcchib),
        .vddio_q  (vddio_q),
        .vssio_q  (vssio_q),
`endif
        .pad_clk   (pad_clk),
        .pad_rst   (pad_rst),
        .pad_gpio  (pad_gpio),
        .core_clk  (clk_internal),
        .core_rst  (rst_internal),
        .gpio_out  (gpio_out_pad),
        .gpio_oe   (gpio_oe_pad),
        .gpio_in   (gpio_in_pad)
    );

    /*======================================================================
      Internal 64-bit MMIO GPIO interface

      Only GPIO[15:0] are bonded out.  The remaining internal GPIO inputs are
      tied low and their output/OE bits are intentionally not package-visible.
      ======================================================================*/
    wire [63:0] gpio_in_internal;
    wire [63:0] gpio_out_internal;
    wire [63:0] gpio_oe_internal;

    assign gpio_in_internal[15:0]  = gpio_in_pad;
    assign gpio_in_internal[63:16] = 48'd0;
    assign gpio_out_pad            = gpio_out_internal[15:0];
    assign gpio_oe_pad             = gpio_oe_internal[15:0];

    /*======================================================================
      PD-only startup abstraction

      Functional program/data loading remains verified at soc_top through the
      external-memory model and FIFO/loader path.  A full UART/SPI boot PHY is
      intentionally outside this PD-focused project.

      For chip-level synthesis/PD, submit one final DMEM loader packet after
      reset so load_done can release the CPU.  This is only a startup
      abstraction; it is not a real bootloader and does not load a program.
      ======================================================================*/
    reg  pd_boot_valid;
    wire ext_ready;
    wire load_done_internal;

    always @(posedge clk_internal) begin
        if (rst_internal)
            pd_boot_valid <= 1'b1;
        else if (pd_boot_valid && ext_ready)
            pd_boot_valid <= 1'b0;
    end

    /*======================================================================
      UART byte-stream boundary

      UART MMIO/FIFOs remain inside soc_top for functional verification, but
      no bit-level UART PHY is bonded out at chip_top.  RX is therefore idle
      and TX is always allowed to drain in this physical-design wrapper.
      ======================================================================*/
    wire       uart_rx_ready_unused;
    wire       uart_tx_valid_unused;
    wire [7:0] uart_tx_data_unused;

    /*======================================================================
      Internal SoC
      ======================================================================*/
    soc_top soc (
`ifdef USE_POWER_PINS
        .vccd1         (vccd1),
        .vssd1         (vssd1),
`endif
        .clk           (clk_internal),
        .rst           (rst_internal),

        .ext_valid     (pd_boot_valid),
        .ext_target    (1'b1),
        .ext_last      (1'b1),
        .ext_addr      (64'd0),
        .ext_wdata     (64'd0),
        .ext_ready     (ext_ready),

        .gpio_in       (gpio_in_internal),
        .gpio_out      (gpio_out_internal),
        .gpio_oe       (gpio_oe_internal),

        .uart_rx_valid (1'b0),
        .uart_rx_data  (8'd0),
        .uart_rx_ready (uart_rx_ready_unused),

        .uart_tx_valid (uart_tx_valid_unused),
        .uart_tx_data  (uart_tx_data_unused),
        .uart_tx_ready (1'b1),

        .load_done     (load_done_internal)
    );

endmodule
