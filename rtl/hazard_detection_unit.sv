module hazarddetectionunit (
    input  wire [4:0] Rd_ex,
    input  wire Memread_ex,
    input  wire Regwrite_ex,
    input  wire [4:0] Rd_mem,
    input  wire MemtoReg_mem,
    input  wire [4:0] Rn_id,
    input  wire [4:0] Rm_id,
    input  wire Branch_id,
    output logic hazardmux_id,
    output logic idhold,
    output logic pchold
);

    logic load_use_hazard;
    logic branch_dep_ex;
    logic branch_dep_mem_load;
    logic stall_req;

    always_comb begin
        // 기본 load-use hazard
        load_use_hazard =
            Memread_ex &&
            (Rd_ex != 5'd31) &&
            ((Rn_id == Rd_ex) || (Rm_id == Rd_ex));

        // CBZ가 ID에서 비교하려는 레지스터가
        // 바로 앞 EX 결과를 필요로 하면 stall
        branch_dep_ex =
            Branch_id &&
            Regwrite_ex &&
            (Rd_ex != 5'd31) &&
            (Rm_id == Rd_ex);

        // CBZ가 ID에서 비교하려는 레지스터가
        // MEM stage의 load 결과를 필요로 하면 stall
        branch_dep_mem_load =
            Branch_id &&
            MemtoReg_mem &&
            (Rd_mem != 5'd31) &&
            (Rm_id == Rd_mem);

        stall_req = load_use_hazard | branch_dep_ex | branch_dep_mem_load;

        hazardmux_id   = stall_req;
        idhold = stall_req;
        pchold = stall_req;
    end

endmodule