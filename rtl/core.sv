     `timescale 1ns / 1ps

     module core(
     input wire clk,
     input wire rst,
     );
     
     // ctrl nets
     wire [31:0] instruction_id;
     wire Reg2Loc_id, Unconditionbranch_id, Branch_id, Memread_id, MemtoReg_id, Memwrite_id, ALUSrc_id, Regwrite_id; 
     wire [3:0] ALUop_id;
     
     // hazard nets
     wire [4:0] Rd_ex, Rd_mem, Rn_id,Rm_id;
     wire Memread_ex, Regwrite_ex, MemtoReg_mem, Branch_id, hazardmux_id, idhold, pchold;
     
     // fwd nets
     wire [1:0] fwdmuxa_ex, fwdmuxb_ex;
     wire [4:0] Rm_ex, Rn_ex, Rd_mem, Rd_wb;
     wire Regwrite_mem, Regwrite_wb;

     datapath datapath (.clk(clk),
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
                    .idhold(idhold),
                    .pchold(pchold),
                    .muxa(fwdmuxa_ex),
                    .muxb(fwdmuxb_ex),
                    .instruction_id(instruction_id),
                    .Rd_ex(Rd_ex),
                    .Rd_mem(Rd_mem),
                    .Rn_id(Rn_id),
                    .Rm_id(Rm_id),
                    .Memread_ex(Memread_ex),
                    .Regwrite_ex(Regwrite_ex),
                    .MemtoReg_mem(MemtoReg_mem),
                    .Branch_id(Branch_id),
                    .Rm_ex(Rm_ex),
                    .Rn_ex(Rn_ex),
                    .Rd_mem(Rd_mem),
                    .Rd_wb(Rd_wb),
                    .Regwrite_mem(Regwrite_mem),
                    .Regwrite_wb(Regwrite_wb)
                    .);
     
     (* KEEP_HIERARCHY="yes" *)                  
     Control ctrl(.instruction(instruction_id),
                    .Reg2Loc(Reg2Loc_id),
                    .Unconditionbranch(Unconditionbranch_id),
                    .Branch(Branch_id),
                    .Memread(Memread_id),
                    .MemtoReg(MemtoReg_id),
                    .ALUop(ALUop_id),
                    .Memwrite(Memwrite_id),
                    .ALUSrc(ALUSrc_id),
                    .Regwrite(Regwrite_id));
     
     (* KEEP_HIERARCHY ="yes" *)
     hazarddetectionunit hazard(.Rd_ex(Rd_ex),
                                .Memread_ex(Memread_ex),
                                .Regwrite_ex(Regwrite_ex),
                                .Rd_mem(Rd_mem),
                                .MemtoReg_mem(MemtoReg_mem),
                                .Rn_id(Rn_id),
                                .Rm_id(Rm_id),
                                .Branch_id(Branch_id),
                                .hazardmux_id(hazardmux_id),
                                .idhold(idhold_id),
                                .pchold(pchold_id));

     (* KEEP_HIERARCHY ="yes" *)
     forwardingunit fwd(.Rm_ex(Rm_ex),
                         .Rn_ex(Rn_ex),
                         .Rd_mem(Rd_mem),
                         .Rd_wb(Rd_wb),
                         .Regwrite_mem(Regwrite_mem),
                         .Regwrite_wb(Regwrite_wb),
                         .muxa(fwdmuxa_ex),
                         .muxb(fwdmuxb_ex));

endmodule