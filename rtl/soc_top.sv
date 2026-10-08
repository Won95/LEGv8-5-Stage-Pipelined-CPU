module soc_top (
    input  wire        clk,
    input  wire        rst,

    // External memory stream interface
    input  wire        ext_valid,
    input  wire        ext_target,
    input  wire        ext_last,
    input  wire [63:0] ext_addr,
    input  wire [63:0] ext_wdata,
    output wire        ext_ready,

    // Minimal GPIO MMIO pins
    input  wire [63:0] gpio_in,
    output wire [63:0] gpio_out,

    // UART byte-stream pins. Bit-level UART PHY is intentionally outside this SoC.
    input  wire        uart_rx_valid,
    input  wire [7:0]  uart_rx_data,
    output wire        uart_rx_ready,

    output wire        uart_tx_valid,
    output wire [7:0]  uart_tx_data,
    input  wire        uart_tx_ready,

    output wire        load_done
);

    // External image(IMEM + DMEM) loading이 모두 끝난 뒤 CPU 실행 시작.
    wire core_rst;
    assign core_rst = rst | !load_done;

    /*==============================
      Instruction memory interface
      ==============================*/
    wire [63:0] imem_req_addr;
    wire        imem_req_valid;
    wire        imem_req_ready;

    wire        imem_rsp_valid;
    wire        imem_rsp_ready;
    wire [63:0] imem_rsp_addr;
    wire [31:0] imem_rsp_data;

    wire        imem_flush;

    /*==============================
      CPU data-memory request interface
      ==============================*/
    wire [63:0] cpu_dmem_addr;
    wire [63:0] cpu_dmem_wdata;
    wire [63:0] cpu_dmem_rdata;
    wire        cpu_dmem_we;
    wire        cpu_dmem_re;
    wire        cpu_dmem_ready;

    wire cpu_bus_valid;
    wire cpu_bus_write;

    assign cpu_bus_valid = cpu_dmem_re | cpu_dmem_we;
    assign cpu_bus_write = cpu_dmem_we;

    /*==============================
      External stream -> FIFO
      packet = {last, target, addr, data}
      target: 0=IMEM, 1=DMEM
      ==============================*/
    wire [129:0] fifo_wr_data;
    wire         fifo_rd_valid;
    wire [129:0] fifo_rd_data;
    wire         fifo_rd_ready;

    assign fifo_wr_data = {ext_last, ext_target, ext_addr, ext_wdata};

    simple_fifo #(
        .WIDTH(130),
        .DEPTH(4)
    ) load_fifo (
        .clk      (clk),
        .rst      (rst),
        .wr_valid (ext_valid),
        .wr_data  (fifo_wr_data),
        .wr_ready (ext_ready),
        .rd_valid (fifo_rd_valid),
        .rd_data  (fifo_rd_data),
        .rd_ready (fifo_rd_ready)
    );

    /*==============================
      FIFO -> Loader
      target=0 : IMEM programming port
      target=1 : AHB-Lite data path
      ==============================*/
    wire        loader_bus_valid;
    wire        loader_bus_write;
    wire [63:0] loader_bus_addr;
    wire [63:0] loader_bus_wdata;
    wire        loader_bus_ready;

    wire        loader_imem_valid;
    wire [63:0] loader_imem_addr;
    wire [31:0] loader_imem_wdata;
    wire        loader_imem_ready;

    memory_loader loader (
        .clk        (clk),
        .rst        (rst),
        .fifo_valid (fifo_rd_valid),
        .fifo_data  (fifo_rd_data),
        .fifo_ready (fifo_rd_ready),

        .bus_valid  (loader_bus_valid),
        .bus_write  (loader_bus_write),
        .bus_addr   (loader_bus_addr),
        .bus_wdata  (loader_bus_wdata),
        .bus_ready  (loader_bus_ready),

        .imem_valid (loader_imem_valid),
        .imem_addr  (loader_imem_addr),
        .imem_wdata (loader_imem_wdata),
        .imem_ready (loader_imem_ready),

        .load_done  (load_done)
    );

    /*==============================
      AHB-Lite system bus

      loading 중 : Loader owns master
      loading 후 : CPU LOAD/STORE owns master
      ==============================*/
    wire [63:0] HADDR;
    wire [1:0]  HTRANS;
    wire        HWRITE;
    wire [2:0]  HSIZE;
    wire [2:0]  HBURST;
    wire [3:0]  HPROT;
    wire        HMASTLOCK;
    wire [63:0] HWDATA;
    wire [63:0] HRDATA;
    wire        HREADY;
    wire        HRESP;

    ahb_lite_master ahb_master (
        .clk            (clk),
        .rst            (rst),
        .loader_select  (!load_done),

        .loader_valid   (loader_bus_valid),
        .loader_write   (loader_bus_write),
        .loader_addr    (loader_bus_addr),
        .loader_wdata   (loader_bus_wdata),
        .loader_ready   (loader_bus_ready),

        .cpu_valid      (cpu_bus_valid),
        .cpu_write      (cpu_bus_write),
        .cpu_addr       (cpu_dmem_addr),
        .cpu_wdata      (cpu_dmem_wdata),
        .cpu_ready      (cpu_dmem_ready),
        .cpu_rdata      (cpu_dmem_rdata),

        .HADDR           (HADDR),
        .HTRANS          (HTRANS),
        .HWRITE          (HWRITE),
        .HSIZE           (HSIZE),
        .HBURST          (HBURST),
        .HPROT           (HPROT),
        .HMASTLOCK       (HMASTLOCK),
        .HWDATA          (HWDATA),
        .HRDATA          (HRDATA),
        .HREADY          (HREADY),
        .HRESP           (HRESP)
    );

    /*==============================
      CPU core
      ==============================*/
    core core (
        .clk            (clk),
        .rst            (core_rst),

        .imem_req_addr  (imem_req_addr),
        .imem_req_valid (imem_req_valid),
        .imem_req_ready (imem_req_ready),
        .imem_rsp_valid (imem_rsp_valid),
        .imem_rsp_ready (imem_rsp_ready),
        .imem_rsp_addr  (imem_rsp_addr),
        .imem_rsp_data  (imem_rsp_data),
        .imem_flush     (imem_flush),

        .dmem_addr      (cpu_dmem_addr),
        .dmem_wdata     (cpu_dmem_wdata),
        .dmem_we        (cpu_dmem_we),
        .dmem_re        (cpu_dmem_re),
        .dmem_ready     (cpu_dmem_ready),
        .dmem_rdata     (cpu_dmem_rdata)
    );

    /*==============================
      IMEM SRAM
      Port0 : Loader write
      Port1 : CPU pipelined read
      ==============================*/
    sram_wrapper32b instruction_sram (
        .clk        (clk),
        .rst        (rst),

        .prog_valid (loader_imem_valid),
        .prog_addr  (loader_imem_addr),
        .prog_wdata (loader_imem_wdata),
        .prog_ready (loader_imem_ready),

        .req_valid  (imem_req_valid),
        .req_ready  (imem_req_ready),
        .req_addr   (imem_req_addr),

        .rsp_valid  (imem_rsp_valid),
        .rsp_ready  (imem_rsp_ready),
        .rsp_addr   (imem_rsp_addr),
        .rsp_data   (imem_rsp_data),

        .flush      (imem_flush)
    );

    /*==============================
      AHB-Lite fabric backends

      boot : loader data transactions -> DMEM
      run  : 0x0000~0x00FF -> DMEM
             0x0100~0x01FF -> MMIO
      ==============================*/
    wire        dmem_slave_valid;
    wire        dmem_slave_write;
    wire [63:0] dmem_slave_addr;
    wire [63:0] dmem_slave_wdata;
    wire        dmem_slave_ready;
    wire [63:0] dmem_slave_rdata;

    wire        mmio_valid;
    wire        mmio_write;
    wire [63:0] mmio_addr;
    wire [63:0] mmio_wdata;
    wire        mmio_ready;
    wire [63:0] mmio_rdata;

    ahb_lite_fabric ahb_fabric (
        .clk           (clk),
        .rst           (rst),
        .boot_mode     (!load_done),

        .HADDR          (HADDR),
        .HTRANS         (HTRANS),
        .HWRITE         (HWRITE),
        .HSIZE          (HSIZE),
        .HBURST         (HBURST),
        .HPROT          (HPROT),
        .HMASTLOCK      (HMASTLOCK),
        .HWDATA         (HWDATA),
        .HRDATA         (HRDATA),
        .HREADY         (HREADY),
        .HRESP          (HRESP),

        .dmem_valid     (dmem_slave_valid),
        .dmem_write     (dmem_slave_write),
        .dmem_addr      (dmem_slave_addr),
        .dmem_wdata     (dmem_slave_wdata),
        .dmem_ready     (dmem_slave_ready),
        .dmem_rdata     (dmem_slave_rdata),

        .mmio_valid     (mmio_valid),
        .mmio_write     (mmio_write),
        .mmio_addr      (mmio_addr),
        .mmio_wdata     (mmio_wdata),
        .mmio_ready     (mmio_ready),
        .mmio_rdata     (mmio_rdata)
    );

    /*==============================
      DMEM backend
      ==============================*/
    sram_wrapper64b data_sram (
        .clk   (clk),
        .rst   (rst),
        .addr  (dmem_slave_addr),
        .wdata (dmem_slave_wdata),
        .we    (dmem_slave_valid &&  dmem_slave_write),
        .re    (dmem_slave_valid && !dmem_slave_write),
        .ready (dmem_slave_ready),
        .rdata (dmem_slave_rdata)
    );

    /*==============================
      MMIO subsystem

      0x0100 : GPIO_OUT
      0x0108 : GPIO_IN
      0x0120 : UART_RXDATA
      0x0128 : UART_TXDATA
      0x0130 : UART_STATUS
      ==============================*/
    mmio_subsystem mmio (
        .clk           (clk),
        .rst           (rst),
        .valid         (mmio_valid),
        .write         (mmio_write),
        .addr          (mmio_addr),
        .wdata         (mmio_wdata),
        .ready         (mmio_ready),
        .rdata         (mmio_rdata),

        .gpio_in       (gpio_in),
        .gpio_out      (gpio_out),

        .uart_rx_valid (uart_rx_valid),
        .uart_rx_data  (uart_rx_data),
        .uart_rx_ready (uart_rx_ready),

        .uart_tx_valid (uart_tx_valid),
        .uart_tx_data  (uart_tx_data),
        .uart_tx_ready (uart_tx_ready)
    );

endmodule
