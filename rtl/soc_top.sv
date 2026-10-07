module soc_top (
    input wire clk,
    input wire rst
);

    wire [63:0] imem_addr;
    wire [31:0] imem_rdata;

    wire [63:0] dmem_addr;
    wire [63:0] dmem_wdata;
    wire [63:0] dmem_rdata;
    wire        dmem_we;
    wire        dmem_re;
    wire        dmem_ready;

    core core(
        .clk(clk),
        .rst(rst),
        .imem_addr(imem_addr),
        .imem_rdata(imem_rdata),
        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_we(dmem_we),
        .dmem_re(dmem_re),
        .dmem_ready(dmem_ready),
        .dmem_rdata(dmem_rdata)
    );

    InstructionMem IM(
        .pc(imem_addr),
        .instruction(imem_rdata)
    );

    sram_wrapper32b instruction_sram();

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
