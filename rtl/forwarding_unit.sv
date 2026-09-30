module forwardingunit (
    input  wire [4:0] Rm_ex,
    input  wire [4:0] Rn_ex,
    input  wire [4:0] Rd_mem,
    input  wire [4:0] Rd_wb,
    input  wire       Regwrite_mem,
    input  wire       Regwrite_wb,
    output logic [1:0] muxa,
    output logic [1:0] muxb
);

    assign muxa =
        (Regwrite_mem && (Rd_mem != 5'd31) && (Rd_mem == Rn_ex)) ? 2'b10 :
        (Regwrite_wb  && (Rd_wb  != 5'd31) && (Rd_wb  == Rn_ex) &&
        !(Regwrite_mem && (Rd_mem != 5'd31) && (Rd_mem == Rn_ex))) ? 2'b01 :
        2'b00;

    assign muxb =
        (Regwrite_mem && (Rd_mem != 5'd31) && (Rd_mem == Rm_ex)) ? 2'b10 :
        (Regwrite_wb  && (Rd_wb  != 5'd31) && (Rd_wb  == Rm_ex) &&
        !(Regwrite_mem && (Rd_mem != 5'd31) && (Rd_mem == Rm_ex))) ? 2'b01 :
        2'b00;

endmodule