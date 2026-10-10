module forwardingunit (
    input  wire [4:0] Rm_ex,
    input  wire [4:0] Rn_ex,
    input  wire [4:0] Rd_mem,
    input  wire [4:0] Rd_wb,
    input  wire       Regwrite_mem,
    input  wire       MemtoReg_mem,
    input  wire       Regwrite_wb,
    output logic [1:0] muxa,
    output logic [1:0] muxb
);

    wire mem_can_forward;
    wire wb_can_forward;

    // A load in MEM does not yet have its load data on result_mem, so only
    // ALU-type MEM results are eligible for EX/MEM forwarding.
    assign mem_can_forward = Regwrite_mem && !MemtoReg_mem && (Rd_mem != 5'd31);
    assign wb_can_forward  = Regwrite_wb && (Rd_wb != 5'd31);

    always_comb begin
        muxa = 2'b00;
        if (mem_can_forward && (Rd_mem == Rn_ex))
            muxa = 2'b10;
        else if (wb_can_forward && (Rd_wb == Rn_ex))
            muxa = 2'b01;

        muxb = 2'b00;
        if (mem_can_forward && (Rd_mem == Rm_ex))
            muxb = 2'b10;
        else if (wb_can_forward && (Rd_wb == Rm_ex))
            muxb = 2'b01;
    end

endmodule
