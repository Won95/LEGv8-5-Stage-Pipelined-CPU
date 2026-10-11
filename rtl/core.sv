`timescale 1ns / 1ps

module core(
    input wire clk,
    input wire rst,

    // instruction memory pipelined request/response interface
    output wire [63:0] imem_req_addr,
    output wire        imem_req_valid,
    input  wire        imem_req_ready,

    input  wire        imem_rsp_valid,
    output wire        imem_rsp_ready,
    input  wire [63:0] imem_rsp_addr,
    input  wire [31:0] imem_rsp_data,

    output wire        imem_flush,

    // data memory blocking request/completion interface
    output wire [63:0] dmem_addr,
    output wire [63:0] dmem_wdata,
    output wire        dmem_we,
    output wire        dmem_re,
    input  wire        dmem_ready,
    input  wire [63:0] dmem_rdata
);

    // ID-stage decode nets
    wire [31:0] instruction_id;
    wire Reg2Loc_id, Unconditionbranch_id, Branch_id;
    wire Memread_id, MemtoReg_id, Memwrite_id, ALUSrc_id, Regwrite_id;
    wire UseRn_id, UseRm_id;
    wire [3:0] ALUop_id;

    // Hazard / pipeline metadata
    wire [4:0] Rd_ex, Rd_mem, Rn_id, Rm_id, Rd_wb;
    wire Memread_ex, Regwrite_ex;
    wire hazardmux_id, idhold_id, pchold_id;
    wire Regwrite_mem, Regwrite_wb;

    // Forwarding decisions are computed while the consumer is still in ID,
    // then registered into ID/EX.  This removes destination compares and
    // priority logic from the EX -> ALU critical path.
    wire [1:0] fwdmuxa_id, fwdmuxb_id;
    wire [1:0] fwdmuxa_ex, fwdmuxb_ex;

    datapath datapath (
        .clk(clk),
        .rst(rst),
        .Reg2Loc_id(Reg2Loc_id),
        .Unconditionbranch_id(Unconditionbranch_id),
        .Branch_id(Branch_id),
        .Memread_id(Memread_id),
        .MemtoReg_id(MemtoReg_id),
        .Memwrite_id(Memwrite_id),
        .ALUSrc_id(ALUSrc_id),
        .Regwrite_id(Regwrite_id),
        .ALUop_id(ALUop_id),
        .hazardmux_id(hazardmux_id),
        .idhold_id(idhold_id),
        .pchold_id(pchold_id),
        .fwdmuxa_id(fwdmuxa_id),
        .fwdmuxb_id(fwdmuxb_id),

        .imem_req_addr(imem_req_addr),
        .imem_req_valid(imem_req_valid),
        .imem_req_ready(imem_req_ready),
        .imem_rsp_valid(imem_rsp_valid),
        .imem_rsp_ready(imem_rsp_ready),
        .imem_rsp_addr(imem_rsp_addr),
        .imem_rsp_data(imem_rsp_data),
        .imem_flush(imem_flush),

        .dmem_addr(dmem_addr),
        .dmem_wdata(dmem_wdata),
        .dmem_we(dmem_we),
        .dmem_re(dmem_re),
        .dmem_ready(dmem_ready),
        .dmem_rdata(dmem_rdata),

        .Rn_id(Rn_id),
        .Rm_id(Rm_id),
        .instruction_id(instruction_id),
        .Rd_ex(Rd_ex),
        .Rd_mem(Rd_mem),
        .Rd_wb(Rd_wb),
        .Memread_ex(Memread_ex),
        .Regwrite_ex(Regwrite_ex),
        .Regwrite_mem(Regwrite_mem),
        .Regwrite_wb(Regwrite_wb),
        .fwdmuxa_ex(fwdmuxa_ex),
        .fwdmuxb_ex(fwdmuxb_ex)
    );

    Control ctrl (
        .instruction(instruction_id),
        .Reg2Loc(Reg2Loc_id),
        .Unconditionbranch(Unconditionbranch_id),
        .Branch(Branch_id),
        .Memread(Memread_id),
        .MemtoReg(MemtoReg_id),
        .ALUop(ALUop_id),
        .Memwrite(Memwrite_id),
        .ALUSrc(ALUSrc_id),
        .Regwrite(Regwrite_id),
        .UseRn(UseRn_id),
        .UseRm(UseRm_id)
    );

    hazarddetectionunit hazard (
        .Rd_ex(Rd_ex),
        .Memread_ex(Memread_ex),
        .Rn_id(Rn_id),
        .Rm_id(Rm_id),
        .UseRn_id(UseRn_id),
        .UseRm_id(UseRm_id),
        .hazardmux_id(hazardmux_id),
        .idhold(idhold_id),
        .pchold(pchold_id)
    );

    forwardingunit fwd (
        .Rm_id(Rm_id),
        .Rn_id(Rn_id),
        .UseRm_id(UseRm_id),
        .UseRn_id(UseRn_id),
        .Rd_ex(Rd_ex),
        .Rd_mem(Rd_mem),
        .Regwrite_ex(Regwrite_ex),
        .Memread_ex(Memread_ex),
        .Regwrite_mem(Regwrite_mem),
        .muxa_id(fwdmuxa_id),
        .muxb_id(fwdmuxb_id)
    );

endmodule
