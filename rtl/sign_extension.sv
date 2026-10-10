module signextension (
    input  wire [31:0] instruction,
    output logic [63:0] SE_Dtaddr
);
    wire [10:0] opcode;
    wire is_b;
    wire is_cbz;

    assign opcode = instruction[31:21];
    assign is_b   = (instruction[31:26] == 6'b000101);
    assign is_cbz = (instruction[31:24] == 8'b10110100);

    always_comb begin : SE
        if (is_b) begin
            // B: signed imm26, scaled by 4 later in the datapath.
            SE_Dtaddr = {{38{instruction[25]}}, instruction[25:0]};
        end
        else if (is_cbz) begin
            // CBZ: signed imm19, scaled by 4 later in the datapath.
            SE_Dtaddr = {{45{instruction[23]}}, instruction[23:5]};
        end
        else begin
            case (opcode)
                // LDUR / STUR: signed imm9.
                11'h7C2,
                11'h7C0: SE_Dtaddr = {{55{instruction[20]}}, instruction[20:12]};

                // ADDI: unsigned imm12 in the supported subset.
                11'h488: SE_Dtaddr = {52'd0, instruction[21:10]};

                default: SE_Dtaddr = 64'd0;
            endcase
        end
    end
endmodule
