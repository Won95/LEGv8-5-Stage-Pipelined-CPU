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
    output logic Regwrite
);
    wire [10:0] opcode;
    assign opcode = instruction[31:21]; // bit slice 위치 확인

    always_comb begin : OP_Decode
        Reg2Loc = 1'b0;
        Unconditionbranch = 1'b0;
        Branch = 1'b0;
        Memread = 1'b0;
        MemtoReg = 1'b0;
        ALUop = 4'b0000;
        Memwrite = 1'b0;
        ALUSrc = 1'b0;
        Regwrite = 1'b0;

        if(instruction[31:26] == 6'b000101)begin
            Reg2Loc = 1'b0;
            Unconditionbranch = 1'b1;
            Branch = 1'b0;
            Memread = 1'b0;
            MemtoReg = 1'b0;
            ALUop = 4'b0000;
            Memwrite = 1'b0;
            ALUSrc = 1'b0;
            Regwrite = 1'b0;
        end
        else if(instruction[31:24]==8'b10110100)begin
            Reg2Loc = 1'b1;         
            Unconditionbranch = 1'b0;
            Branch = 1'b1;           
            Memread = 1'b0;
            MemtoReg = 1'b0;
            ALUop = 4'b0111;         
            Memwrite = 1'b0;
            ALUSrc = 1'b0;
            Regwrite = 1'b0;
        end
        else begin
            case (opcode)
                11'h458: begin // ADD
                    Reg2Loc = 1'b0;
                    Unconditionbranch = 1'b0;
                    Branch = 1'b0;
                    Memread = 1'b0;
                    MemtoReg = 1'b0;
                    ALUop = 4'b0010;
                    Memwrite = 1'b0;
                    ALUSrc = 1'b0;
                    Regwrite = 1'b1;
                end

                11'h658: begin // SUB
                    Reg2Loc = 1'b0;
                    Unconditionbranch = 1'b0;
                    Branch = 1'b0;
                    Memread = 1'b0;
                    MemtoReg = 1'b0;
                    ALUop = 4'b0110;
                    Memwrite = 1'b0;
                    ALUSrc = 1'b0;
                    Regwrite = 1'b1;
                end

                11'h7C2: begin // LDUR
                    Reg2Loc = 1'b0;
                    Unconditionbranch = 1'b0;
                    Branch = 1'b0;
                    Memread = 1'b1;
                    MemtoReg = 1'b1;
                    ALUop = 4'b0010;
                    Memwrite = 1'b0;
                    ALUSrc = 1'b1;
                    Regwrite = 1'b1;
                end

                11'h7C0: begin // STUR
                    Reg2Loc = 1'b1;
                    Unconditionbranch = 1'b0;
                    Branch = 1'b0;
                    Memread = 1'b0;
                    MemtoReg = 1'b0;
                    ALUop = 4'b0010;
                    Memwrite = 1'b1;
                    ALUSrc = 1'b1;
                    Regwrite = 1'b0;
                end

                11'h450: begin // AND
                    Reg2Loc = 1'b0;
                    Unconditionbranch = 1'b0;
                    Branch = 1'b0;
                    Memread = 1'b0;
                    MemtoReg = 1'b0;
                    ALUop = 4'b0000;
                    Memwrite = 1'b0;
                    ALUSrc = 1'b0;
                    Regwrite = 1'b1;
                end

                11'h550: begin // ORR
                    Reg2Loc = 1'b0;
                    Unconditionbranch = 1'b0;
                    Branch = 1'b0;
                    Memread = 1'b0;
                    MemtoReg = 1'b0;   
                    ALUop = 4'b0001;
                    Memwrite = 1'b0;
                    ALUSrc = 1'b0;
                    Regwrite = 1'b1;
                end

                11'h488: begin // ADDI 
                    Reg2Loc = 1'b0;
                    Unconditionbranch = 1'b0;
                    Branch = 1'b0;
                    Memread = 1'b0;
                    MemtoReg = 1'b0;
                    ALUop = 4'b0010;
                    Memwrite = 1'b0;
                    ALUSrc = 1'b1;
                    Regwrite = 1'b1;
                end

                11'h69B: begin // LSL
                    Reg2Loc = 1'b0;
                    Unconditionbranch = 1'b0;
                    Branch = 1'b0;
                    Memread = 1'b0;
                    MemtoReg = 1'b0;
                    ALUop = 4'b1110;
                    Memwrite = 1'b0;
                    ALUSrc = 1'b0;     
                    Regwrite = 1'b1;
                end

                default: begin
                    Reg2Loc = 1'b0;
                    Unconditionbranch = 1'b0;
                    Branch = 1'b0;
                    Memread = 1'b0;
                    MemtoReg = 1'b0;
                    ALUop = 4'b0000;
                    Memwrite = 1'b0;
                    ALUSrc = 1'b0;
                    Regwrite = 1'b0;
                end
            endcase
        end
    end
endmodule