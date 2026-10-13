module soc_pd_top (
`ifdef USE_POWER_PINS
    inout wire        vccd1,
    inout wire        vssd1,
`endif

    input  wire        clk,
    input  wire        rst,

    // GPIO MMIO boundary
    input  wire [63:0] gpio_in,
    output wire [63:0] gpio_out,
    output wire [63:0] gpio_oe
);

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
      CPU data-memory interface
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
      CPU core
      ==============================*/
    core core (
        .clk            (clk),
        .rst            (rst),

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
      IMEM hard SRAM

      Port0 is disabled in the PD-only wrapper.
      Port1 is the CPU pipelined fetch port.
      ==============================*/
    sram_wrapper32b_pd instruction_sram (
`ifdef USE_POWER_PINS
        .vccd1      (vccd1),
        .vssd1      (vssd1),
`endif
        .clk         (clk),
        .rst         (rst),
        .req_valid   (imem_req_valid),
        .req_ready   (imem_req_ready),
        .req_addr    (imem_req_addr),
        .rsp_valid   (imem_rsp_valid),
        .rsp_ready   (imem_rsp_ready),
        .rsp_addr    (imem_rsp_addr),
        .rsp_data    (imem_rsp_data),
        .flush       (imem_flush)
    );

    /*==============================
      CPU-only AHB-Lite master
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

    ahb_lite_master_pd ahb_master (
        .clk          (clk),
        .rst          (rst),

        .cpu_valid    (cpu_bus_valid),
        .cpu_write    (cpu_bus_write),
        .cpu_addr     (cpu_dmem_addr),
        .cpu_wdata    (cpu_dmem_wdata),
        .cpu_ready    (cpu_dmem_ready),
        .cpu_rdata    (cpu_dmem_rdata),

        .HADDR         (HADDR),
        .HTRANS        (HTRANS),
        .HWRITE        (HWRITE),
        .HSIZE         (HSIZE),
        .HBURST        (HBURST),
        .HPROT         (HPROT),
        .HMASTLOCK     (HMASTLOCK),
        .HWDATA        (HWDATA),
        .HRDATA        (HRDATA),
        .HREADY        (HREADY),
        .HRESP         (HRESP)
    );

    /*==============================
      AHB-Lite backends

      0x0000~0x00ff : DMEM
      0x0100~0x011f : GPIO MMIO
      ==============================*/
    wire        dmem_slave_valid;
    wire        dmem_slave_write;
    wire [63:0] dmem_slave_addr;
    wire [63:0] dmem_slave_wdata;
    wire        dmem_slave_ready;
    wire [63:0] dmem_slave_rdata;

    wire        gpio_bus_valid;
    wire        gpio_bus_write;
    wire [63:0] gpio_bus_addr;
    wire [63:0] gpio_bus_wdata;
    wire        gpio_bus_ready;
    wire [63:0] gpio_bus_rdata;

    ahb_lite_fabric_pd ahb_fabric (
        .clk          (clk),
        .rst          (rst),

        .HADDR        (HADDR),
        .HTRANS       (HTRANS),
        .HWRITE       (HWRITE),
        .HSIZE        (HSIZE),
        .HBURST       (HBURST),
        .HPROT        (HPROT),
        .HMASTLOCK    (HMASTLOCK),
        .HWDATA       (HWDATA),
        .HRDATA       (HRDATA),
        .HREADY       (HREADY),
        .HRESP        (HRESP),

        .dmem_valid   (dmem_slave_valid),
        .dmem_write   (dmem_slave_write),
        .dmem_addr    (dmem_slave_addr),
        .dmem_wdata   (dmem_slave_wdata),
        .dmem_ready   (dmem_slave_ready),
        .dmem_rdata   (dmem_slave_rdata),

        .gpio_valid   (gpio_bus_valid),
        .gpio_write   (gpio_bus_write),
        .gpio_addr    (gpio_bus_addr),
        .gpio_wdata   (gpio_bus_wdata),
        .gpio_ready   (gpio_bus_ready),
        .gpio_rdata   (gpio_bus_rdata)
    );

    /*==============================
      64-bit DMEM from two 32-bit hard SRAM macros
      ==============================*/
    sram_wrapper64b data_sram (
`ifdef USE_POWER_PINS
        .vccd1 (vccd1),
        .vssd1 (vssd1),
`endif
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
      GPIO-only MMIO

      0x0100 : GPIO_OUT
      0x0108 : GPIO_IN
      0x0110 : GPIO_OE
      ==============================*/
    mmio_gpio gpio (
        .clk      (clk),
        .rst      (rst),
        .valid    (gpio_bus_valid),
        .write    (gpio_bus_write),
        .addr     (gpio_bus_addr),
        .wdata    (gpio_bus_wdata),
        .ready    (gpio_bus_ready),
        .rdata    (gpio_bus_rdata),
        .gpio_in  (gpio_in),
        .gpio_out (gpio_out),
        .gpio_oe  (gpio_oe)
    );

endmodule
