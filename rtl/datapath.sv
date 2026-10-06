     `timescale 1ns / 1ps

     module datapath(
     input wire clk,
     input wire rst,
     input wire Reg2Loc_id, Unconditionbranch_id, Branch_id, Memread_id, MemtoReg_id, Memwrite_id, ALUSrc_id, Regwrite_id, 
     input wire [3:0] ALUop_id,
     input logic hazardmux_id, idhold_id, pchold_id,
     input logic [1:0] muxa, muxb,
     
     // Instruction memory interface
     output wire [63:0] imem_addr,
     input  wire [31:0] imem_rdata,

     // Data memory interface
     output wire [63:0] dmem_addr,
     output wire [63:0] dmem_wdata,
     output wire        dmem_we,
     output wire        dmem_re,
     input  wire [63:0] dmem_rdata,

     output wire [4:0] Rn_id, Rm_id,
     output logic [31:0] instruction_id,
     output logic [4:0] Rd_ex, Rd_mem, 
     output logic Memread_ex, Regwrite_ex, MemtoReg_mem,
     output logic [4:0] Rm_ex, Rn_ex, Rd_wb,
     output logic Regwrite_mem, Regwrite_wb
     );

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
                    Stall
                    ==============*/  
               if (idhold_id) begin

                    // IF/ID hold
                    instruction_id <= instruction_id;
                    pc_id <= pc_id;

                    // ID/EX bubble
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
                    Readdata2_mem_mux <= Readdata2_ex_Src;

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

                    // IF/ID flush
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
                    Readdata2_mem_mux <= Readdata2_ex_Src;

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

                    // IF/ID
                    instruction_id <= instruction_if;
                    pc_id <= pc_if;

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
                    Readdata2_mem_mux <= Readdata2_ex_Src;

                    // MEM/WB
                    MemtoReg_wb <= MemtoReg_mem;
                    Regwrite_wb <= Regwrite_mem;
                    Rd_wb <= Rd_mem;
                    result_wb <= result_mem;
                    Readmemdata_wb <= Readmemdata_mem;
               end
          end
     end

     /*==============
          IF stage
          ==============*/

     wire [63:0] pc_if, pc_next, pc_4_if;
     assign pc_4_if = pc_if + 64'd4;  
     assign pc_next = PCSrc_id ? pc_s2_id : pc_4_if; 
     
     programcounter PC(.clk(clk),
                         .rst(rst),
                         .pc_next(pc_next),
                         .pchold(pchold_id),
                         .pc(pc_if));
     
     wire [31:0] instruction_if;

     assign imem_addr      = pc_if;
     assign instruction_if = imem_rdata;

     /*==============
          ID stage
          ==============*/

     logic [63:0] pc_id, SE_Dtaddr_id;
     wire [63:0] Readdata1_id, Readdata2_id;
     wire [5:0] shamt_id;
     wire [4:0] Rd_id;

     assign shamt_id = instruction_id [15:10];
     assign Rm_id = Reg2Loc_id ? instruction_id[4:0] : instruction_id[20:16];
     assign Rn_id = instruction_id[9:5];
     assign Rd_id = instruction_id[4:0];

     //pc
     wire [63:0] pc_s2_id;
     wire PCSrc_id, zero_id;
     logic [63:0] branch_cmp_data_id;

     assign pc_s2_id = pc_id + (SE_Dtaddr_id<<2);

     // CBZ용 ID-stage compare data forwarding
     always_comb begin
          // 기본값: regfile에서 읽은 값
          branch_cmp_data_id = Readdata2_id;

          // MEM stage의 ALU 결과는 ID로 forwarding 가능
          if (Regwrite_mem && !MemtoReg_mem && (Rd_mem != 5'd31) && (Rd_mem == Rm_id)) begin
               branch_cmp_data_id = result_mem;
          end
          // WB stage 결과도 forwarding
          else if (Regwrite_wb && (Rd_wb != 5'd31) && (Rd_wb == Rm_id)) begin
               branch_cmp_data_id = Regwritedata_wb;
          end
     end

     assign zero_id  = (branch_cmp_data_id == 64'd0);
     assign PCSrc_id = !idhold_id && (Unconditionbranch_id | (Branch_id & zero_id));

     //mux to ID/EX
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
     signextension SE(.instruction(instruction_id),
                         .SE_Dtaddr(SE_Dtaddr_id));

     (* KEEP_HIERARCHY="yes" *)
     register REG(.clk(clk),
                    .Rm(Rm_id),
                    .Rn(Rn_id),
                    .Rd(Rd_wb),
                    .Regwrite(Regwrite_wb),
                    .Regwritedata(Regwritedata_wb),
                    .Readdata1(Readdata1_id),
                    .Readdata2(Readdata2_id));
     
     /*==============
          EX stage
          ==============*/
     reg [63:0] Readdata1_ex, Readdata2_ex, SE_Dtaddr_ex;
     reg MemtoReg_ex, Memwrite_ex, ALUSrc_ex ;
     reg [3:0] ALUop_ex;
     reg [5:0] shamt_ex;
     wire [63:0] result_ex,Readdata2_ex_Src;
     wire [63:0] Readdata1_ex_mux, Readdata2_ex_mux;

     assign Readdata1_ex_mux =
     (muxa == 2'b00) ? Readdata1_ex :
     (muxa == 2'b01) ? Regwritedata_wb :
     (muxa == 2'b10) ? result_mem :
                    Readdata1_ex;
     
     assign Readdata2_ex_Src = ALUSrc_ex ? SE_Dtaddr_ex : Readdata2_ex_mux; 
     
     assign Readdata2_ex_mux =
     (muxb == 2'b00) ? Readdata2_ex :
     (muxb == 2'b01) ? Regwritedata_wb :                                                                                                                                           
     (muxb == 2'b10) ? result_mem :
                    Readdata2_ex;
     
     (* KEEP_HIERARCHY="yes" *)
     ALU ALU(.ALUop(ALUop_ex),
               .Readdata1(Readdata1_ex_mux),
               .Readdata2(Readdata2_ex_Src),
               .shamt(shamt_ex),
               .result(result_ex));

     /*==============
          MEM stage
          ==============*/
     reg Memread_mem, Memwrite_mem;
     reg [63:0] result_mem;
     reg [63:0] Readdata2_mem_mux;
     wire [63:0] Readmemdata_mem;

     assign dmem_addr  = result_mem;
     assign dmem_wdata = Readdata2_mem_mux;
     assign dmem_we    = Memwrite_mem;
     assign dmem_re    = Memread_mem;

     assign Readmemdata_mem = dmem_rdata;


     /*==============
          WB stage
          ==============*/
     reg MemtoReg_wb;
     reg [63:0] result_wb;
     reg [63:0] Readmemdata_wb;
     logic [63:0] Regwritedata_wb;
     always_comb begin : M2R
          if(MemtoReg_wb) begin
               Regwritedata_wb = Readmemdata_wb;
          end
          else begin
               Regwritedata_wb = result_wb;
          end
     end

endmodule