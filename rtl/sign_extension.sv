module signextension (
    input  wire [31:0] instruction,
    output logic [63:0] SE_Dtaddr
);
    wire [10:0] opcode;
    assign opcode = instruction[31:21];

    always_comb begin : SE
        case (opcode)

            // LDUR / STUR : D-format, imm9 = [20:12]
            11'h7C2: begin
                SE_Dtaddr = {{55{instruction[20]}}, instruction[20:12]};
            end
            11'h7C0: begin
                SE_Dtaddr = {{55{instruction[20]}}, instruction[20:12]};
            end

            // B : imm26 = [25:0] 
            11'h0A0: begin
                SE_Dtaddr = {{38{instruction[25]}}, instruction[25:0]};
            end

            // CBZ : imm19 = [23:5]
            11'h5A0: begin
                SE_Dtaddr = {{45{instruction[23]}}, instruction[23:5]};
            end

            // ADDI : imm12 = [21:10]
            11'h488 : begin
                SE_Dtaddr = {{52{instruction[21]}}, instruction[21:10]};
            end

            default: begin
                SE_Dtaddr = 64'd0;
            end
        endcase
    end
endmodule