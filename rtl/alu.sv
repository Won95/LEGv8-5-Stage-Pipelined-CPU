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
    // A six-level parallel-prefix network replaces the long carry chain that
    // the generic '+'/'-' operators can map into.  The prefix network builds
    // group generate/propagate terms in log2(64)=6 stages.
    wire [63:0] b_eff;
    wire [63:0] p [0:6];
    wire [63:0] g [0:6];
    wire [64:0] carry;

    assign b_eff = b ^ {64{sub}};
    assign p[0]  = a ^ b_eff;
    assign g[0]  = a & b_eff;

    genvar s;
    genvar i;
    generate
        for (s = 0; s < 6; s = s + 1) begin : gen_prefix_stage
            for (i = 0; i < 64; i = i + 1) begin : gen_prefix_bit
                if (i >= (1 << s)) begin : gen_combine
                    assign g[s+1][i] = g[s][i] |
                                         (p[s][i] & g[s][i-(1 << s)]);
                    assign p[s+1][i] = p[s][i] &
                                         p[s][i-(1 << s)];
                end
                else begin : gen_pass
                    assign g[s+1][i] = g[s][i];
                    assign p[s+1][i] = p[s][i];
                end
            end
        end
    endgenerate

    assign carry[0] = sub;

    generate
        for (i = 0; i < 64; i = i + 1) begin : gen_carry
            assign carry[i+1] = g[6][i] | (p[6][i] & sub);
        end
    endgenerate

    assign sum = p[0] ^ carry[63:0];
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
            4'b1110: result = Readdata1 << shamt;          // LSL
            default: result = 64'd0;
        endcase
    end
endmodule
