`timescale 1ns / 1ps

module prefix_addsub64 (
    input  wire [63:0] a,
    input  wire [63:0] b,
    input  wire        sub,
    output wire [63:0] sum
);
    // Shared adder/subtractor:
    //   ADD: a + b      => b_eff=b,  cin=0
    //   SUB: a + ~b + 1 => b_eff=~b, cin=1
    //
    // Keep each prefix level as a separately named vector.  The previous
    // unpacked p[0:6]/g[0:6] arrays were logically acyclic, but Verilator
    // tracked the whole array as one dependency object and reported UNOPTFLAT
    // circular-combinational warnings.  These explicit stages describe the
    // same six-level parallel-prefix network without that false dependency.
    wire [63:0] b_eff;
    wire [63:0] p0, p1, p2, p3, p4, p5, p6;
    wire [63:0] g0, g1, g2, g3, g4, g5, g6;
    wire [63:0] carry_in;

    assign b_eff = b ^ {64{sub}};
    assign p0    = a ^ b_eff;
    assign g0    = a & b_eff;

    genvar i;
    generate
        for (i = 0; i < 64; i = i + 1) begin : gen_prefix_bit
            if (i >= 1) begin : stage1_combine
                assign g1[i] = g0[i] | (p0[i] & g0[i-1]);
                assign p1[i] = p0[i] & p0[i-1];
            end else begin : stage1_pass
                assign g1[i] = g0[i];
                assign p1[i] = p0[i];
            end

            if (i >= 2) begin : stage2_combine
                assign g2[i] = g1[i] | (p1[i] & g1[i-2]);
                assign p2[i] = p1[i] & p1[i-2];
            end else begin : stage2_pass
                assign g2[i] = g1[i];
                assign p2[i] = p1[i];
            end

            if (i >= 4) begin : stage3_combine
                assign g3[i] = g2[i] | (p2[i] & g2[i-4]);
                assign p3[i] = p2[i] & p2[i-4];
            end else begin : stage3_pass
                assign g3[i] = g2[i];
                assign p3[i] = p2[i];
            end

            if (i >= 8) begin : stage4_combine
                assign g4[i] = g3[i] | (p3[i] & g3[i-8]);
                assign p4[i] = p3[i] & p3[i-8];
            end else begin : stage4_pass
                assign g4[i] = g3[i];
                assign p4[i] = p3[i];
            end

            if (i >= 16) begin : stage5_combine
                assign g5[i] = g4[i] | (p4[i] & g4[i-16]);
                assign p5[i] = p4[i] & p4[i-16];
            end else begin : stage5_pass
                assign g5[i] = g4[i];
                assign p5[i] = p4[i];
            end

            if (i >= 32) begin : stage6_combine
                assign g6[i] = g5[i] | (p5[i] & g5[i-32]);
                assign p6[i] = p5[i] & p5[i-32];
            end else begin : stage6_pass
                assign g6[i] = g5[i];
                assign p6[i] = p5[i];
            end
        end
    endgenerate

    // carry_in[i] is the carry entering sum bit i.  The carry out of bit 63
    // is intentionally not built because the ALU does not consume it.
    assign carry_in[0] = sub;

    genvar k;
    generate
        for (k = 1; k < 64; k = k + 1) begin : gen_carry_in
            assign carry_in[k] = g6[k-1] | (p6[k-1] & sub);
        end
    endgenerate

    assign sum = p0 ^ carry_in;
endmodule


module ALU (
    input  wire [3:0]  ALUop,
    input  wire [63:0] Readdata1,
    input  wire [63:0] Readdata2,
    input  wire [5:0]  shamt,
    output logic [63:0] result
);
    wire is_sub;
    wire [63:0] arithmetic_result;

    assign is_sub = (ALUop == 4'b0110);

    // ADD and SUB share one physical arithmetic datapath.  This avoids
    // synthesizing two independent 64-bit arithmetic cones followed by a mux.
    prefix_addsub64 u_prefix_addsub (
        .a   (Readdata1),
        .b   (Readdata2),
        .sub (is_sub),
        .sum (arithmetic_result)
    );

    always_comb begin : ALU_Decoder
        case (ALUop)
            4'b0000: result = Readdata1 & Readdata2;       // AND
            4'b0001: result = Readdata1 | Readdata2;       // ORR
            4'b0010: result = arithmetic_result;           // ADD
            4'b0110: result = arithmetic_result;           // SUB
            4'b0111: result = Readdata2;                   // pass B
            4'b1100: result = ~(Readdata1 | Readdata2);    // NOR
            4'b1110: result = Readdata1 << shamt;           // LSL
            default: result = 64'd0;
        endcase
    end
endmodule
