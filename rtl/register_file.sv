module register (
    input wire clk,
    input wire [4:0] Rm,
    input wire [4:0] Rn,
    input wire [4:0] Rd,
    input wire Regwrite,
    input wire [63:0] Regwritedata,
    output wire [63:0] Readdata1,
    output wire [63:0] Readdata2
);
    reg [63:0] registers [31:0];

    initial begin
        registers[0]  = 64'd1;  // X0
        registers[1]  = 64'd2;  // X1
        registers[2]  = 64'd3;  // X2
        registers[3]  = 64'd4;  // X3
        registers[4]  = 64'd5;  // X4
        registers[5]  = 64'd6;  // X5
        registers[6]  = 64'd7;  // X6
        registers[7]  = 64'd8;  // X7
        registers[8]  = 64'd9;  // X8
        registers[9]  = 64'd10; // X9
        registers[10] = 64'd11; // X10
        registers[11] = 64'd0;  // X11
        registers[12] = 64'd13; // X12
        registers[13] = 64'd14; // X13
        registers[14] = 64'd15; // X14
        registers[15] = 64'd16; // X15
        registers[16] = 64'd17; // X16
        registers[17] = 64'd18; // X17
        registers[18] = 64'd19; // X18
        registers[19] = 64'd20; // X19
        registers[20] = 64'd21; // X20
        registers[21] = 64'd22; // X21
        registers[22] = 64'd23; // X22
        registers[23] = 64'd24; // X23
        registers[24] = 64'd25; // X24
        registers[25] = 64'd26; // X25
        registers[26] = 64'd27; // X26
        registers[27] = 64'd28; // X27
        registers[28] = 64'd29; // X28
        registers[29] = 64'd30; // X29
        registers[30] = 64'd31; // X30
        registers[31] = 64'd0;  // XZR (X31)
    end

    // ------------------------------------------------------------------------
    // Asynchronous read ports
    // ------------------------------------------------------------------------
    // Do not infer a direct 32:1 mux from "registers[address]".  The previous
    // implementation caused each address bit (for example Rm[0]) to become a
    // very high-fanout mux-select net after standard-cell mapping.
    //
    // Decode each 5-bit read address once to one-hot, then use the one-hot
    // selects to gate the 32 register words.  The final 64-bit result is formed
    // with a balanced OR tree.  Functionally this is still a 2R1W register file
    // with combinational/asynchronous reads; only the implementation structure
    // is changed for synthesis/physical-design experiments.
    (* keep = "true" *) wire [31:0] rn_sel;
    (* keep = "true" *) wire [31:0] rm_sel;

    wire [63:0] rn_masked [31:0];
    wire [63:0] rm_masked [31:0];

    genvar i;
    generate
        for (i = 0; i < 32; i = i + 1) begin : gen_read_decode
            localparam [4:0] INDEX = i;
            assign rn_sel[i] = (Rn == INDEX);
            assign rm_sel[i] = (Rm == INDEX);

            assign rn_masked[i] = registers[i] & {64{rn_sel[i]}};
            assign rm_masked[i] = registers[i] & {64{rm_sel[i]}};
        end
    endgenerate

    // Balanced 32-to-1 OR reduction for read port 1.
    wire [63:0] rn_or_l1 [15:0];
    wire [63:0] rn_or_l2 [7:0];
    wire [63:0] rn_or_l3 [3:0];
    wire [63:0] rn_or_l4 [1:0];

    // Balanced 32-to-1 OR reduction for read port 2.
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

    assign Readdata1 = rn_or_l4[0] | rn_or_l4[1];
    assign Readdata2 = rm_or_l4[0] | rm_or_l4[1];

    // ------------------------------------------------------------------------
    // Synchronous write port
    // ------------------------------------------------------------------------
    // X31 is the architectural zero register and is never written.
    always @(posedge clk) begin
        if (Regwrite && (Rd != 5'd31)) begin
            registers[Rd] <= Regwritedata;
        end
    end

endmodule
