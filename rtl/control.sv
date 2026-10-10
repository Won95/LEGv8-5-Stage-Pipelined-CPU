module Control (
    input  wire [31:0] instruction,
    output logic Reg2Loc,
    output logic Unconditionbranch,
    output logic Branch,
    output logic Memread,
    output logic MemtoReg,
    output logic [3:0] ALUop,
    output logic Memwrite,
    output logic ALUSrc,
    output logic Regwrite,
    output logic UseRn,
    output logic UseRm
);
    wire [10:0] opcode;
    wire is_b;
    wire is_cbz;

    assign opcode = instruction[31:21];
    assign is_b   = (instruction[31:26] == 6'b000101);
    assign is_cbz = (instruction[31:24] == 8'b10110100);

    always_comb begin : OP_Decode
        Reg2Loc          = 1'b0;
        Unconditionbranch = 1'b0;
        Branch           = 1'b0;
        Memread          = 1'b0;
        MemtoReg         = 1'b0;
        ALUop            = 4'b0000;
        Memwrite         = 1'b0;
        ALUSrc           = 1'b0;
        Regwrite         = 1'b0;
        UseRn            = 1'b0;
        UseRm            = 1'b0;

        if (is_b) begin
            Unconditionbranch = 1'b1;
        end
        else if (is_cbz) begin
            Reg2Loc = 1'b1;
            Branch  = 1'b1;
            ALUop   = 4'b0111;
            UseRm   = 1'b1;
        end
        else begin
            case (opcode)
                11'h458: begin // ADD
                    ALUop    = 4'b0010;
                    Regwrite = 1'b1;
                    UseRn    = 1'b1;
                    UseRm    = 1'b1;
                end

                11'h658: begin // SUB
                    ALUop    = 4'b0110;
                    Regwrite = 1'b1;
                    UseRn    = 1'b1;
                    UseRm    = 1'b1;
                end

                11'h7C2: begin // LDUR
                    Memread  = 1'b1;
                    MemtoReg = 1'b1;
                    ALUop    = 4'b0010;
                    ALUSrc   = 1'b1;
                    Regwrite = 1'b1;
                    UseRn    = 1'b1;
                end

                11'h7C0: begin // STUR
                    Reg2Loc  = 1'b1;
                    ALUop    = 4'b0010;
                    Memwrite = 1'b1;
                    ALUSrc   = 1'b1;
                    UseRn    = 1'b1;
                    UseRm    = 1'b1;
                end

                11'h450: begin // AND
                    ALUop    = 4'b0000;
                    Regwrite = 1'b1;
                    UseRn    = 1'b1;
                    UseRm    = 1'b1;
                end

                11'h550: begin // ORR
                    ALUop    = 4'b0001;
                    Regwrite = 1'b1;
                    UseRn    = 1'b1;
                    UseRm    = 1'b1;
                end

                11'h488: begin // ADDI
                    ALUop    = 4'b0010;
                    ALUSrc   = 1'b1;
                    Regwrite = 1'b1;
                    UseRn    = 1'b1;
                end

                11'h69B: begin // LSL
                    ALUop    = 4'b1110;
                    Regwrite = 1'b1;
                    UseRn    = 1'b1;
                end

                default: begin
                end
            endcase
        end
    end
endmodule
