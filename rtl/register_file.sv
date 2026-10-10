module register (
    input  wire        clk,
    input  wire [4:0]  Rm,
    input  wire [4:0]  Rn,
    input  wire [4:0]  Rd,
    input  wire        Regwrite,
    input  wire [63:0] Regwritedata,
    output wire [63:0] Readdata1,
    output wire [63:0] Readdata2
);
    reg [63:0] registers [31:0];

    initial begin
        registers[0]  = 64'd1;
        registers[1]  = 64'd2;
        registers[2]  = 64'd3;
        registers[3]  = 64'd4;
        registers[4]  = 64'd5;
        registers[5]  = 64'd6;
        registers[6]  = 64'd7;
        registers[7]  = 64'd8;
        registers[8]  = 64'd9;
        registers[9]  = 64'd10;
        registers[10] = 64'd11;
        registers[11] = 64'd0;
        registers[12] = 64'd13;
        registers[13] = 64'd14;
        registers[14] = 64'd15;
        registers[15] = 64'd16;
        registers[16] = 64'd17;
        registers[17] = 64'd18;
        registers[18] = 64'd19;
        registers[19] = 64'd20;
        registers[20] = 64'd21;
        registers[21] = 64'd22;
        registers[22] = 64'd23;
        registers[23] = 64'd24;
        registers[24] = 64'd25;
        registers[25] = 64'd26;
        registers[26] = 64'd27;
        registers[27] = 64'd28;
        registers[28] = 64'd29;
        registers[29] = 64'd30;
        registers[30] = 64'd31;
        registers[31] = 64'd0; // XZR
    end

    // ------------------------------------------------------------------------
    // Timing-oriented asynchronous read decode
    // ------------------------------------------------------------------------
    // Split the 5-bit address into 2-bit and 3-bit predecoders.  This prevents
    // each raw address bit from directly driving all 32 word comparators, which
    // previously produced very large select-net fanout after standard-cell
    // mapping.  Each final one-hot select is then used by the 64-bit word mask.
    (* keep = "true" *) wire [3:0] rn_hi_sel, rm_hi_sel;
    (* keep = "true" *) wire [7:0] rn_lo_sel, rm_lo_sel;
    (* keep = "true" *) wire [31:0] rn_sel, rm_sel;

    assign rn_hi_sel[0] = ~Rn[4] & ~Rn[3];
    assign rn_hi_sel[1] = ~Rn[4] &  Rn[3];
    assign rn_hi_sel[2] =  Rn[4] & ~Rn[3];
    assign rn_hi_sel[3] =  Rn[4] &  Rn[3];

    assign rm_hi_sel[0] = ~Rm[4] & ~Rm[3];
    assign rm_hi_sel[1] = ~Rm[4] &  Rm[3];
    assign rm_hi_sel[2] =  Rm[4] & ~Rm[3];
    assign rm_hi_sel[3] =  Rm[4] &  Rm[3];

    assign rn_lo_sel[0] = ~Rn[2] & ~Rn[1] & ~Rn[0];
    assign rn_lo_sel[1] = ~Rn[2] & ~Rn[1] &  Rn[0];
    assign rn_lo_sel[2] = ~Rn[2] &  Rn[1] & ~Rn[0];
    assign rn_lo_sel[3] = ~Rn[2] &  Rn[1] &  Rn[0];
    assign rn_lo_sel[4] =  Rn[2] & ~Rn[1] & ~Rn[0];
    assign rn_lo_sel[5] =  Rn[2] & ~Rn[1] &  Rn[0];
    assign rn_lo_sel[6] =  Rn[2] &  Rn[1] & ~Rn[0];
    assign rn_lo_sel[7] =  Rn[2] &  Rn[1] &  Rn[0];

    assign rm_lo_sel[0] = ~Rm[2] & ~Rm[1] & ~Rm[0];
    assign rm_lo_sel[1] = ~Rm[2] & ~Rm[1] &  Rm[0];
    assign rm_lo_sel[2] = ~Rm[2] &  Rm[1] & ~Rm[0];
    assign rm_lo_sel[3] = ~Rm[2] &  Rm[1] &  Rm[0];
    assign rm_lo_sel[4] =  Rm[2] & ~Rm[1] & ~Rm[0];
    assign rm_lo_sel[5] =  Rm[2] & ~Rm[1] &  Rm[0];
    assign rm_lo_sel[6] =  Rm[2] &  Rm[1] & ~Rm[0];
    assign rm_lo_sel[7] =  Rm[2] &  Rm[1] &  Rm[0];

    wire [63:0] rn_masked [31:0];
    wire [63:0] rm_masked [31:0];

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : gen_read_decode
            localparam integer HI = (i >> 3);
            localparam integer LO = (i & 7);

            assign rn_sel[i] = rn_hi_sel[HI] & rn_lo_sel[LO];
            assign rm_sel[i] = rm_hi_sel[HI] & rm_lo_sel[LO];

            assign rn_masked[i] = registers[i] & {64{rn_sel[i]}};
            assign rm_masked[i] = registers[i] & {64{rm_sel[i]}};
        end
    endgenerate

    // Balanced 32:1 OR reduction for both read ports.
    wire [63:0] rn_or_l1 [15:0];
    wire [63:0] rn_or_l2 [7:0];
    wire [63:0] rn_or_l3 [3:0];
    wire [63:0] rn_or_l4 [1:0];

    wire [63:0] rm_or_l1 [15:0];
    wire [63:0] rm_or_l2 [7:0];
    wire [63:0] rm_or_l3 [3:0];
    wire [63:0] rm_or_l4 [1:0];

    generate
        for (i = 0; i < 16; i = i + 1) begin : gen_or_l1
            assign rn_or_l1[i] = rn_masked[2*i] | rn_masked[2*i+1];
            assign rm_or_l1[i] = rm_masked[2*i] | rm_masked[2*i+1];
        end
        for (i = 0; i < 8; i = i + 1) begin : gen_or_l2
            assign rn_or_l2[i] = rn_or_l1[2*i] | rn_or_l1[2*i+1];
            assign rm_or_l2[i] = rm_or_l1[2*i] | rm_or_l1[2*i+1];
        end
        for (i = 0; i < 4; i = i + 1) begin : gen_or_l3
            assign rn_or_l3[i] = rn_or_l2[2*i] | rn_or_l2[2*i+1];
            assign rm_or_l3[i] = rm_or_l2[2*i] | rm_or_l2[2*i+1];
        end
        for (i = 0; i < 2; i = i + 1) begin : gen_or_l4
            assign rn_or_l4[i] = rn_or_l3[2*i] | rn_or_l3[2*i+1];
            assign rm_or_l4[i] = rm_or_l3[2*i] | rm_or_l3[2*i+1];
        end
    endgenerate

    wire [63:0] readdata1_array;
    wire [63:0] readdata2_array;
    wire bypass_rn;
    wire bypass_rm;

    assign readdata1_array = rn_or_l4[0] | rn_or_l4[1];
    assign readdata2_array = rm_or_l4[0] | rm_or_l4[1];

    // Same-cycle WB -> ID bypass.  Without this, an ID/EX register sampling on
    // the same edge as a register-file write can capture the pre-write value.
    assign bypass_rn = Regwrite && (Rd != 5'd31) && (Rd == Rn);
    assign bypass_rm = Regwrite && (Rd != 5'd31) && (Rd == Rm);

    assign Readdata1 = (Rn == 5'd31) ? 64'd0 :
                       bypass_rn      ? Regwritedata : readdata1_array;
    assign Readdata2 = (Rm == 5'd31) ? 64'd0 :
                       bypass_rm      ? Regwritedata : readdata2_array;

    // ------------------------------------------------------------------------
    // Synchronous write port
    // ------------------------------------------------------------------------
    always @(posedge clk) begin
        if (Regwrite && (Rd != 5'd31))
            registers[Rd] <= Regwritedata;
    end

endmodule
