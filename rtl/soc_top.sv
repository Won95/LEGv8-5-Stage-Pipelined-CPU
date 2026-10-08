module soc_top (
    input wire clk,
    input wire rst,

    // External boot-loader interface.
    // target: 1'b0 = IMEM (reserved for next step), 1'b1 = DMEM.
    input  wire        boot_mode,
    input  wire        boot_valid,
    input  wire        boot_target,
    input  wire [63:0] boot_addr,
    input  wire [63:0] boot_wdata,
    output wire        boot_ready
);

    wire core_rst;
    assign core_rst = rst | boot_mode;

    wire [63:0] imem_addr;
    wire [31:0] imem_rdata;

    // CPU-side data-memory interface
    wire [63:0] cpu_dmem_addr;
    wire [63:0] cpu_dmem_wdata;
    wire [63:0] cpu_dmem_rdata;
    wire        cpu_dmem_we;
    wire        cpu_dmem_re;
    wire        cpu_dmem_ready;

    // SRAM-side data-memory interface
    wire [63:0] dmem_addr;
    wire [63:0] dmem_wdata;
    wire [63:0] dmem_rdata;
    wire        dmem_we;
    wire        dmem_re;
    wire        dmem_ready;

    wire boot_dmem_access;
    assign boot_dmem_access = boot_mode && boot_valid && boot_target;

    // During boot the CPU is held in reset and the loader owns the DMEM port.
    // After boot_mode is released, ownership returns to the CPU.
    assign dmem_addr  = boot_dmem_access ? boot_addr  : cpu_dmem_addr;
    assign dmem_wdata = boot_dmem_access ? boot_wdata : cpu_dmem_wdata;
    assign dmem_we    = boot_dmem_access ? 1'b1       : cpu_dmem_we;
    assign dmem_re    = boot_dmem_access ? 1'b0       : cpu_dmem_re;

    assign cpu_dmem_rdata = dmem_rdata;
    assign cpu_dmem_ready = boot_mode ? 1'b0 : dmem_ready;

    // IMEM target is reserved until instruction SRAM is connected.
    assign boot_ready = (boot_mode && boot_target) ? dmem_ready : 1'b0;

    core core(
        .clk(clk),
        .rst(core_rst),
        .imem_addr(imem_addr),
        .imem_rdata(imem_rdata),
        .dmem_addr(cpu_dmem_addr),
        .dmem_wdata(cpu_dmem_wdata),
        .dmem_we(cpu_dmem_we),
        .dmem_re(cpu_dmem_re),
        .dmem_ready(cpu_dmem_ready),
        .dmem_rdata(cpu_dmem_rdata)
    );

    // Instruction memory remains behavioral until the next step.
    InstructionMem IM(
        .pc(imem_addr),
        .instruction(imem_rdata)
    );

    sram_wrapper64b data_sram(
        .clk(clk),
        .rst(rst),
        .addr(dmem_addr),
        .wdata(dmem_wdata),
        .we(dmem_we),
        .re(dmem_re),
        .ready(dmem_ready),
        .rdata(dmem_rdata)
    );

endmodule
