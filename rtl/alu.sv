module ALU (
    input wire [3:0] ALUop,
    input wire [63:0] Readdata1,
    input wire [63:0] Readdata2,
    input wire [5:0] shamt,
    output logic [63:0] result
);
    always_comb begin : ALU_Decoder
        case (ALUop)
            4'b0000 : begin //and 연산
                result = Readdata1 & Readdata2;
            end 
            4'b0001 : begin //or 연산
                result = Readdata1 | Readdata2;

            end
            4'b0010 : begin //add 연산 
                result = Readdata1 + Readdata2;
            end
            4'b0110 : begin //sub 연산
                result = Readdata1 - Readdata2;
            end
            4'b0111 : begin //pass input Readdata2
                result = Readdata2;
            end
            4'b1100 : begin //nor 연산
                result = ~(Readdata1 | Readdata2); //!은 1bit 반전
            end
            4'b1110 : begin //lsl 연산
                result = (Readdata1<<shamt);
            end
            default: begin
                result = 64'b0;
            end
        endcase
    end
endmodule
