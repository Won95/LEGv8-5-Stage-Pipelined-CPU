module core_pd_top (
    input  wire        clk,
    input  wire        rst,

    // Observation ports keep the standalone core implementation meaningful
    // after synthesis and make block-level timing reports easier to inspect.
    output wire [63:0] monitor_imem_addr,
    output wire        monitor_imem_req_valid,
    output wire [63:0] monitor_dmem_addr,
    output wire [63:0] monitor_dmem_wdata,
    output wire        monitor_dmem_we,
    output wire        monitor_dmem_re
);

    /*======================================================================
      Core memory interfaces
      ======================================================================*/
    wire [63:0] imem_req_addr;
    wire        imem_req_valid;
    wire        imem_req_ready;

    wire        imem_rsp_valid;
    wire        imem_rsp_ready;
    wire [63:0] imem_rsp_addr;
    wire [31:0] imem_rsp_data;
    wire        imem_flush;

    wire [63:0] dmem_addr;
    wire [63:0] dmem_wdata;
    wire        dmem_we;
    wire        dmem_re;
    wire        dmem_ready;
    wire [63:0] dmem_rdata;

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

    /*======================================================================
      Behavioral instruction memory

      The legacy InstructionMem is combinational.  A one-entry response
      register adapts it to the current pipelined core request/response
      protocol and holds a response while the front end is stalled.
      ======================================================================*/
    wire [31:0] imem_behavioral_data;
    reg         imem_rsp_valid_q;
    reg  [63:0] imem_rsp_addr_q;
    reg  [31:0] imem_rsp_data_q;

    InstructionMem u_behavioral_imem (
        .pc          (imem_req_addr),
        .instruction (imem_behavioral_data)
    );

    assign imem_req_ready = !imem_rsp_valid_q || imem_rsp_ready;
    assign imem_rsp_valid = imem_rsp_valid_q;
    assign imem_rsp_addr  = imem_rsp_addr_q;
    assign imem_rsp_data  = imem_rsp_data_q;

    always @(posedge clk) begin
        if (rst || imem_flush) begin
            imem_rsp_valid_q <= 1'b0;
            imem_rsp_addr_q  <= 64'd0;
            imem_rsp_data_q  <= 32'd0;
        end
        else begin
            if (imem_req_valid && imem_req_ready) begin
                imem_rsp_valid_q <= 1'b1;
                imem_rsp_addr_q  <= imem_req_addr;
                imem_rsp_data_q  <= imem_behavioral_data;
            end
            else if (imem_rsp_valid_q && imem_rsp_ready) begin
                imem_rsp_valid_q <= 1'b0;
            end
        end
    end

    /*======================================================================
      Behavioral data memory

      dataMem is used directly and responds in the same cycle.  This removes
      SRAM-macro timing/placement from the first PD stage while preserving the
      core's load/store datapath and memory-stall interface.
      ======================================================================*/
    dataMem u_behavioral_dmem (
        .clk          (clk),
        .Address      (dmem_addr),
        .Memwritedata (dmem_wdata),
        .Memwrite     (dmem_we),
        .Memread      (dmem_re),
        .Memreaddata  (dmem_rdata)
    );

    assign dmem_ready = 1'b1;

    assign monitor_imem_addr      = imem_req_addr;
    assign monitor_imem_req_valid = imem_req_valid;
    assign monitor_dmem_addr      = dmem_addr;
    assign monitor_dmem_wdata     = dmem_wdata;
    assign monitor_dmem_we        = dmem_we;
    assign monitor_dmem_re        = dmem_re;

endmodule
