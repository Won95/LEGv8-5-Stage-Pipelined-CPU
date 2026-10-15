module core_pd_top (
    input  wire        clk,
    input  wire        rst,

    // Instruction-memory block interface
    output wire [63:0] imem_req_addr,
    output wire        imem_req_valid,
    input  wire        imem_req_ready,

    input  wire        imem_rsp_valid,
    output wire        imem_rsp_ready,
    input  wire [63:0] imem_rsp_addr,
    input  wire [31:0] imem_rsp_data,

    output wire        imem_flush,

    // Data-memory block interface
    output wire [63:0] dmem_addr,
    output wire [63:0] dmem_wdata,
    output wire        dmem_we,
    output wire        dmem_re,
    input  wire        dmem_ready,
    input  wire [63:0] dmem_rdata
);

    // Core-only physical-design wrapper.
    //
    // Memories intentionally remain outside this block.  Their timing is modeled
    // at the primary I/O boundary by top.con.  Full memory/macro integration is
    // analyzed separately at soc_top level.
    core u_core (
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

        .dmem_addr      (dmem_addr),
        .dmem_wdata     (dmem_wdata),
        .dmem_we        (dmem_we),
        .dmem_re        (dmem_re),
        .dmem_ready     (dmem_ready),
        .dmem_rdata     (dmem_rdata)
    );

endmodule
