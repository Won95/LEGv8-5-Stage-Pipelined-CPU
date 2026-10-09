module InstructionMem (
    input wire [63:0] pc,
    output wire[31:0] instruction
);
    
    (* rom_style = "block" *)
    reg [31:0] instructionmemory [31:0]; //4byte 32개 = 32byte, 32개 명령어 저장가능
    wire [4:0] imaddr; // insturcution memory 접근 변수
    assign imaddr = pc[6:2]; // pc는 4씩 증가하므로 bit slice로 index화 하여 IM에 접근 0 : 0 -> 4 : 1 -> 8 : 2  ...

    initial begin
        instructionmemory[0]  = 32'b1000_1011_0000_0010_0000_0000_0010_0011; // 8B020023 ADD  x3,  x1,  x2   -> x3  = 5
        instructionmemory[1]  = 32'b1100_1011_0000_0001_0000_0000_0110_0100; // CB010064 SUB  x4,  x3,  x1   -> x4  = 3   (EX forwarding)
        instructionmemory[2]  = 32'b1000_1010_0000_0011_0000_0000_1000_0101; // 8A030085 AND  x5,  x4,  x3   -> x5  = 1   (forwarding)
        instructionmemory[3]  = 32'b1010_1010_0000_0100_0000_0000_1010_0110; // AA0400A6 ORR  x6,  x5,  x4   -> x6  = 3   (forwarding)

        instructionmemory[4]  = 32'b1111_1000_0100_0000_0001_0001_0100_1001; // F8401149 LDUR x9,  [x10,#1]  -> x9  = mem[12] = 99
        instructionmemory[5]  = 32'b1000_1011_0000_0001_0000_0001_0010_1100; // 8B01012C ADD  x12, x9,  x1   -> x12 = 101 (load-use hazard)
        instructionmemory[6]  = 32'b1100_1011_0000_0010_0000_0001_1000_1101; // CB02018D SUB  x13, x12, x2   -> x13 = 98  (forwarding after stall)

        instructionmemory[7]  = 32'b1100_1011_0000_0001_0000_0000_0010_1110; // CB01002E SUB  x14, x1,  x1   -> x14 = 0
        instructionmemory[8]  = 32'b1011_0100_0000_0000_0000_0000_0100_1110; // B400004E CBZ  x14, #2        -> taken, branch_dep_ex stall + flush
        instructionmemory[9]  = 32'b1001_0001_0000_0000_0000_0110_1001_0100; // 91000694 ADDI x20, x20, #1   -> flush 되어야 함
        instructionmemory[10] = 32'b1001_0001_0000_0000_0000_0110_1011_0101; // 910006B5 ADDI x21, x21, #1   -> 실행되어야 함

        instructionmemory[11] = 32'b1001_0001_0000_0000_0000_0101_1110_1111; // 910005EF ADDI x15, x15, #1   -> x15 = 17
        instructionmemory[12] = 32'b1011_0100_0000_0000_0000_0000_0100_1111; // B400004F CBZ  x15, #2        -> not taken
        instructionmemory[13] = 32'b1001_0001_0000_0000_0000_0110_1101_0110; // 910006D6 ADDI x22, x22, #1   -> 실행되어야 함

        instructionmemory[14] = 32'b1100_1011_0000_0010_0000_0000_0101_0000; // CB020050 SUB  x16, x2,  x2   -> x16 = 0
        instructionmemory[15] = 32'b1011_0100_0000_0000_0000_0000_0101_0000; // B4000050 CBZ  x16, #2        -> taken
        instructionmemory[16] = 32'b1001_0001_0000_0000_0000_0110_1111_0111; // 910006F7 ADDI x23, x23, #1   -> flush 되어야 함
        instructionmemory[17] = 32'b1001_0001_0000_0000_0000_0111_0001_1000; // 91000718 ADDI x24, x24, #1   -> 실행되어야 함

        instructionmemory[18] = 32'b0001_0100_0000_0000_0000_0000_0000_0000; // 14000000 B    #0             -> self loop halt
    end

    assign instruction = instructionmemory[imaddr]; 
endmodule
