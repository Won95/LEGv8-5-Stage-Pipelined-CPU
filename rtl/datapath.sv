`timescale 1ns / 1ps

module datapath(
    input wire clk,
    input wire rst,
    input wire Reg2Loc_id, Unconditionbranch_id, Branch_id, Memread_id, MemtoReg_id, Memwrite_id, ALUSrc_id, Regwrite_id,
    input wire [3:0] ALUop_id,
    input logic hazardmux_id, idhold_id, pchold_id,
    input logic [1:0] muxa, muxb,

    // Instruction memory pipelined request/response interface
    output wire [63:0] imem_req_addr,
    output wire        imem_req_valid,
    input  wire        imem_req_ready,

    input  wire        imem_rsp_valid,
    output wire        imem_rsp_ready,
    input  wire [63:0] imem_rsp_addr,
    input  wire [31:0] imem_rsp_data,

    output wire        imem_flush,

    // Data memory request/ack interface
    output wire [63:0] dmem_addr,
    output wire [63:0] dmem_wdata,
    output wire        dmem_we,
    output wire        dmem_re,
    input  wire        dmem_ready,
    input  wire [63:0] dmem_rdata,

    output wire [4:0] Rn_id, Rm_id,
    output logic [31:0] instruction_id,
    output logic [4:0] Rd_ex, Rd_mem,
    output logic Memread_ex, Regwrite_ex, MemtoReg_mem,
    output logic [4:0] Rm_ex, Rn_ex, Rd_wb,
    output logic Regwrite_mem, Regwrite_wb
);

    /*==============
         IF stage
         ==============*/

    wire [63:0] pc_if, pc_next, pc_4_if;
    wire [31:0] instruction_if;

    wire imem_req_fire;
    wire imem_rsp_fire;
    wire front_stall;
    wire pc_hold_all;

    assign pc_4_if = pc_if + 64'd4;
    assign pc_next = PCSrc_id ? pc_s2_id : pc_4_if;

    // Hazard/data-memory stall 중에는 새 instruction request를 만들지 않는다.
    assign front_stall = pchold_id | idhold_id | mem_wait;

    // Request address는 항상 next-to-fetch PC이다.
    // Branch가 결정된 cycle에는 sequential request를 추가로 발행하지 않는다.
    assign imem_req_addr  = pc_if;
    assign imem_req_valid = !rst && !front_stall && !PCSrc_id;
    assign imem_req_fire  = imem_req_valid && imem_req_ready;

    // IF/ID가 instruction을 받을 수 있을 때만 response를 consume한다.
    // stall 중 response는 IMEM wrapper queue에 그대로 보존된다.
    assign imem_rsp_ready = !rst && !front_stall && !PCSrc_id;
    assign imem_rsp_fire  = imem_rsp_valid && imem_rsp_ready;

    // Taken branch는 wrapper 안의 buffered/inflight sequential fetch를 모두 폐기한다.
    assign imem_flush = PCSrc_id;

    // Normal path에서는 request가 실제 accept될 때만 PC를 +4 한다.
    // Branch는 request handshake와 무관하게 target PC로 redirect한다.
    assign pc_hold_all = !PCSrc_id && !imem_req_fire;

    programcounter PC(
        .clk(clk),
        .rst(rst),
        .pc_next(pc_next),
        .pchold(pc_hold_all),
        .pc(pc_if)
    );

    assign instruction_if = imem_rsp_data;

    /*==============
         ID stage
         ==============*/

    logic [63:0] pc_id, SE_Dtaddr_id;
    wire [63:0] Readdata1_id, Readdata2_id;
    wire [5:0] shamt_id;
    wire [4:0] Rd_id;

    assign shamt_id = instruction_id[15:10];
    assign Rm_id = Reg2Loc_id ? instruction_id[4:0] : instruction_id[20:16];
    assign Rn_id = instruction_id[9:5];
    assign Rd_id = instruction_id[4:0];

    wire [63:0] pc_s2_id;
    wire PCSrc_id, zero_id;
    logic [63:0] branch_cmp_data_id;

    assign pc_s2_id = pc_id + (SE_Dtaddr_id << 2);

    // CBZ용 ID-stage compare data forwarding
    always_comb begin
        branch_cmp_data_id = Readdata2_id;

        if (Regwrite_mem && !MemtoReg_mem && (Rd_mem != 5'd31) && (Rd_mem == Rm_id)) begin
            branch_cmp_data_id = result_mem;
        end
        else if (Regwrite_wb && (Rd_wb != 5'd31) && (Rd_wb == Rm_id)) begin
            branch_cmp_data_id = Regwritedata_wb;
        end
    end

    assign zero_id = (branch_cmp_data_id == 64'd0);

    // older memory instruction이 끝나기 전에는 ID branch도 진행시키지 않는다.
    assign PCSrc_id = !mem_wait && !idhold_id &&
                      (Unconditionbranch_id | (Branch_id & zero_id));

    // mux to ID/EX
    logic Memread_id_mux, MemtoReg_id_mux, Memwrite_id_mux, ALUSrc_id_mux, Regwrite_id_mux;
    logic [3:0] ALUop_id_mux;

    always_comb begin : ha
        Memread_id_mux  = Memread_id;
        MemtoReg_id_mux = MemtoReg_id;
        Memwrite_id_mux = Memwrite_id;
        ALUSrc_id_mux   = ALUSrc_id;
        Regwrite_id_mux = Regwrite_id;
        ALUop_id_mux    = ALUop_id;

        if (hazardmux_id) begin
            Memread_id_mux  = 1'b0;
            MemtoReg_id_mux = 1'b0;
            Memwrite_id_mux = 1'b0;
            ALUSrc_id_mux   = 1'b0;
            Regwrite_id_mux = 1'b0;
            ALUop_id_mux    = 4'b0000;
        end
    end

    (* KEEP_HIERARCHY="yes" *)
    signextension SE(
        .instruction(instruction_id),
        .SE_Dtaddr(SE_Dtaddr_id)
    );

    (* KEEP_HIERARCHY="yes" *)
    register REG(
        .clk(clk),
        .Rm(Rm_id),
        .Rn(Rn_id),
        .Rd(Rd_wb),
        .Regwrite(Regwrite_wb),
        .Regwritedata(Regwritedata_wb),
        .Readdata1(Readdata1_id),
        .Readdata2(Readdata2_id)
    );

    /*==============
         EX stage
         ==============*/

    reg [63:0] Readdata1_ex, Readdata2_ex, SE_Dtaddr_ex;
    reg MemtoReg_ex, Memwrite_ex, ALUSrc_ex;
    reg [3:0] ALUop_ex;
    reg [5:0] shamt_ex;
    wire [63:0] result_ex, Readdata2_ex_Src;
    wire [63:0] Readdata1_ex_mux, Readdata2_ex_mux;

    assign Readdata1_ex_mux =
        (muxa == 2'b00) ? Readdata1_ex :
        (muxa == 2'b01) ? Regwritedata_wb :
        (muxa == 2'b10) ? result_mem :
                          Readdata1_ex;

    assign Readdata2_ex_mux =
        (muxb == 2'b00) ? Readdata2_ex :
        (muxb == 2'b01) ? Regwritedata_wb :
        (muxb == 2'b10) ? result_mem :
                          Readdata2_ex;

    assign Readdata2_ex_Src = ALUSrc_ex ? SE_Dtaddr_ex : Readdata2_ex_mux;

    (* KEEP_HIERARCHY="yes" *)
    ALU ALU(
        .ALUop(ALUop_ex),
        .Readdata1(Readdata1_ex_mux),
        .Readdata2(Readdata2_ex_Src),
        .shamt(shamt_ex),
        .result(result_ex)
    );

    /*==============
         MEM stage
         ==============*/

    reg Memread_mem, Memwrite_mem;
    reg [63:0] result_mem;
    reg [63:0] Readdata2_mem_mux;
    wire [63:0] Readmemdata_mem;

    // MEM stage에 들어온 request는 memory가 ready를 줄 때까지 유지된다.
    assign dmem_addr  = result_mem;
    assign dmem_wdata = Readdata2_mem_mux;
    assign dmem_we    = Memwrite_mem;
    assign dmem_re    = Memread_mem;

    assign Readmemdata_mem = dmem_rdata;

    wire mem_access;
    wire mem_wait;
    assign mem_access = Memread_mem | Memwrite_mem;
    assign mem_wait   = mem_access && !dmem_ready;

    /*==============
         WB stage
         ==============*/

    reg MemtoReg_wb;
    reg [63:0] result_wb;
    reg [63:0] Readmemdata_wb;
    logic [63:0] Regwritedata_wb;

    always_comb begin : M2R
        if (MemtoReg_wb) begin
            Regwritedata_wb = Readmemdata_wb;
        end
        else begin
            Regwritedata_wb = result_wb;
        end
    end

    /*==============
         Pipeline registers
         ==============*/

    always @(posedge clk) begin
        if (rst) begin
            // IF/ID
            instruction_id <= 32'd0;
            pc_id <= 64'd0;

            // ID/EX
            Readdata1_ex <= 64'd0;
            Readdata2_ex <= 64'd0;
            Memread_ex   <= 1'b0;
            MemtoReg_ex  <= 1'b0;
            Memwrite_ex  <= 1'b0;
            ALUSrc_ex    <= 1'b0;
            Regwrite_ex  <= 1'b0;
            ALUop_ex     <= 4'd0;
            shamt_ex     <= 6'd0;
            Rm_ex        <= 5'd0;
            Rn_ex        <= 5'd0;
            Rd_ex        <= 5'd0;
            SE_Dtaddr_ex <= 64'd0;

            // EX/MEM
            Memread_mem <= 1'b0;
            MemtoReg_mem <= 1'b0;
            Memwrite_mem <= 1'b0;
            Regwrite_mem <= 1'b0;
            Rd_mem <= 5'd0;
            result_mem <= 64'd0;
            Readdata2_mem_mux <= 64'd0;

            // MEM/WB
            MemtoReg_wb <= 1'b0;
            Regwrite_wb <= 1'b0;
            Rd_wb <= 5'd0;
            result_wb <= 64'd0;
            Readmemdata_wb <= 64'd0;
        end

        else begin
            /*==============
                 Memory wait
                 ==============*/
            if (mem_wait) begin
                // MEM의 older load/store가 끝날 때까지 앞단 전체를 hold한다.
                // IMEM rsp_ready도 0이므로 fetch response는 wrapper에서 보존된다.
                instruction_id <= instruction_id;
                pc_id <= pc_id;

                Readdata1_ex <= Readdata1_ex;
                Readdata2_ex <= Readdata2_ex;
                Memread_ex   <= Memread_ex;
                MemtoReg_ex  <= MemtoReg_ex;
                Memwrite_ex  <= Memwrite_ex;
                ALUSrc_ex    <= ALUSrc_ex;
                Regwrite_ex  <= Regwrite_ex;
                ALUop_ex     <= ALUop_ex;
                shamt_ex     <= shamt_ex;
                Rm_ex        <= Rm_ex;
                Rn_ex        <= Rn_ex;
                Rd_ex        <= Rd_ex;
                SE_Dtaddr_ex <= SE_Dtaddr_ex;

                Memread_mem <= Memread_mem;
                MemtoReg_mem <= MemtoReg_mem;
                Memwrite_mem <= Memwrite_mem;
                Regwrite_mem <= Regwrite_mem;
                Rd_mem <= Rd_mem;
                result_mem <= result_mem;
                Readdata2_mem_mux <= Readdata2_mem_mux;

                // 기존 WB instruction은 이 edge에서 retire하고,
                // wait 중에는 같은 write가 반복되지 않도록 bubble을 넣는다.
                MemtoReg_wb <= 1'b0;
                Regwrite_wb <= 1'b0;
                Rd_wb <= 5'd0;
                result_wb <= 64'd0;
                Readmemdata_wb <= 64'd0;
            end

            /*==============
                 Data hazard stall
                 ==============*/
            else if (idhold_id) begin
                // IF/ID hold. IMEM response도 consume하지 않는다.
                instruction_id <= instruction_id;
                pc_id <= pc_id;

                // ID/EX bubble through control mux
                Readdata1_ex <= Readdata1_id;
                Readdata2_ex <= Readdata2_id;
                Memread_ex   <= Memread_id_mux;
                MemtoReg_ex  <= MemtoReg_id_mux;
                Memwrite_ex  <= Memwrite_id_mux;
                ALUSrc_ex    <= ALUSrc_id_mux;
                Regwrite_ex  <= Regwrite_id_mux;
                ALUop_ex     <= ALUop_id_mux;
                shamt_ex     <= shamt_id;
                Rm_ex        <= Rm_id;
                Rn_ex        <= Rn_id;
                Rd_ex        <= Rd_id;
                SE_Dtaddr_ex <= SE_Dtaddr_id;

                // EX/MEM 정상 진행
                Memread_mem <= Memread_ex;
                MemtoReg_mem <= MemtoReg_ex;
                Memwrite_mem <= Memwrite_ex;
                Regwrite_mem <= Regwrite_ex;
                Rd_mem <= Rd_ex;
                result_mem <= result_ex;
                Readdata2_mem_mux <= Readdata2_ex_mux;

                // MEM/WB 정상 진행
                MemtoReg_wb <= MemtoReg_mem;
                Regwrite_wb <= Regwrite_mem;
                Rd_wb <= Rd_mem;
                result_wb <= result_mem;
                Readmemdata_wb <= Readmemdata_mem;
            end

            /*==============
                 Branch
                 ==============*/
            else if (PCSrc_id) begin
                // IF/ID flush. IMEM wrapper도 imem_flush로 outstanding fetch를 버린다.
                instruction_id <= 32'd0;
                pc_id <= 64'd0;

                // ID/EX 정상 진행
                Readdata1_ex <= Readdata1_id;
                Readdata2_ex <= Readdata2_id;
                Memread_ex   <= Memread_id_mux;
                MemtoReg_ex  <= MemtoReg_id_mux;
                Memwrite_ex  <= Memwrite_id_mux;
                ALUSrc_ex    <= ALUSrc_id_mux;
                Regwrite_ex  <= Regwrite_id_mux;
                ALUop_ex     <= ALUop_id_mux;
                shamt_ex     <= shamt_id;
                Rm_ex        <= Rm_id;
                Rn_ex        <= Rn_id;
                Rd_ex        <= Rd_id;
                SE_Dtaddr_ex <= SE_Dtaddr_id;

                // EX/MEM
                Memread_mem <= Memread_ex;
                MemtoReg_mem <= MemtoReg_ex;
                Memwrite_mem <= Memwrite_ex;
                Regwrite_mem <= Regwrite_ex;
                Rd_mem <= Rd_ex;
                result_mem <= result_ex;
                Readdata2_mem_mux <= Readdata2_ex_mux;

                // MEM/WB
                MemtoReg_wb <= MemtoReg_mem;
                Regwrite_wb <= Regwrite_mem;
                Rd_wb <= Rd_mem;
                result_wb <= result_mem;
                Readmemdata_wb <= Readmemdata_mem;
            end

            /*==============
                 Normal
                 ==============*/
            else begin
                // IF/ID에는 실제 valid/ready handshake가 완료된 response만 넣는다.
                if (imem_rsp_fire) begin
                    instruction_id <= instruction_if;
                    pc_id <= imem_rsp_addr;
                end
                else begin
                    instruction_id <= 32'd0;
                    pc_id <= 64'd0;
                end

                // ID/EX
                Readdata1_ex <= Readdata1_id;
                Readdata2_ex <= Readdata2_id;
                Memread_ex   <= Memread_id_mux;
                MemtoReg_ex  <= MemtoReg_id_mux;
                Memwrite_ex  <= Memwrite_id_mux;
                ALUSrc_ex    <= ALUSrc_id_mux;
                Regwrite_ex  <= Regwrite_id_mux;
                ALUop_ex     <= ALUop_id_mux;
                shamt_ex     <= shamt_id;
                Rm_ex        <= Rm_id;
                Rn_ex        <= Rn_id;
                Rd_ex        <= Rd_id;
                SE_Dtaddr_ex <= SE_Dtaddr_id;

                // EX/MEM
                Memread_mem <= Memread_ex;
                MemtoReg_mem <= MemtoReg_ex;
                Memwrite_mem <= Memwrite_ex;
                Regwrite_mem <= Regwrite_ex;
                Rd_mem <= Rd_ex;
                result_mem <= result_ex;
                Readdata2_mem_mux <= Readdata2_ex_mux;

                // MEM/WB
                MemtoReg_wb <= MemtoReg_mem;
                Regwrite_wb <= Regwrite_mem;
                Rd_wb <= Rd_mem;
                result_wb <= result_mem;
                Readmemdata_wb <= Readmemdata_mem;
            end
        end
    end

endmodule
