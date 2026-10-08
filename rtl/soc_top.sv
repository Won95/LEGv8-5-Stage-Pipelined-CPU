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

    output wire        load_done
);

    // External image(IMEM + DMEM) loading이 모두 끝난 뒤 CPU 실행 시작.
    wire core_rst;
    assign core_rst = rst | !load_done;

    /*==============================
      Instruction memory interface
      ==============================*/
    wire [63:0] imem_addr;
    wire        imem_rvalid;
    wire [63:0] imem_raddr;
    wire [31:0] imem_rdata;

    /*==============================
      CPU data-memory master
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
      target=1 : shared data bus
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
      Single shared DATA bus
      loading 중: Loader master
      loading 후: CPU master
      ==============================*/
    wire        bus_valid;
    wire        bus_write;
    wire [63:0] bus_addr;
    wire [63:0] bus_wdata;
    wire        bus_ready;
    wire [63:0] bus_rdata;

    simple_bus data_bus (
        .loader_select (!load_done),

        .loader_valid  (loader_bus_valid),
        .loader_write  (loader_bus_write),
        .loader_addr   (loader_bus_addr),
        .loader_wdata  (loader_bus_wdata),
        .loader_ready  (loader_bus_ready),

        .cpu_valid     (cpu_bus_valid),
        .cpu_write     (cpu_bus_write),
        .cpu_addr      (cpu_dmem_addr),
        .cpu_wdata     (cpu_dmem_wdata),
        .cpu_ready     (cpu_dmem_ready),
        .cpu_rdata     (cpu_dmem_rdata),

        .slave_valid   (bus_valid),
        .slave_write   (bus_write),
        .slave_addr    (bus_addr),
        .slave_wdata   (bus_wdata),
        .slave_ready   (bus_ready),
        .slave_rdata   (bus_rdata)
    );

    /*==============================
      CPU core
      ==============================*/
    core core (
        .clk         (clk),
        .rst         (core_rst),

        .imem_addr   (imem_addr),
        .imem_rvalid (imem_rvalid),
        .imem_raddr  (imem_raddr),
        .imem_rdata  (imem_rdata),

        .dmem_addr   (cpu_dmem_addr),
        .dmem_wdata  (cpu_dmem_wdata),
        .dmem_we     (cpu_dmem_we),
        .dmem_re     (cpu_dmem_re),
        .dmem_ready  (cpu_dmem_ready),
        .dmem_rdata  (cpu_dmem_rdata)
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

        .cpu_re     (!core_rst),
        .cpu_addr   (imem_addr),
        .cpu_rvalid (imem_rvalid),
        .cpu_raddr  (imem_raddr),
        .cpu_rdata  (imem_rdata)
    );

    /*==============================
      DMEM slave
      ==============================*/
    sram_wrapper64b data_sram (
        .clk   (clk),
        .rst   (rst),
        .addr  (bus_addr),
        .wdata (bus_wdata),
        .we    (bus_valid &&  bus_write),
        .re    (bus_valid && !bus_write),
        .ready (bus_ready),
        .rdata (bus_rdata)
    );

endmodule
