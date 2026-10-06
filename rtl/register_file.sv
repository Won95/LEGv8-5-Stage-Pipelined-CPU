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
        registers[0] = 64'd1;  // X0
        registers[1] = 64'd2;  // X1
        registers[2] = 64'd3;  // X2
        registers[3] = 64'd4;  // X3 
        registers[4] = 64'd5;  // X4 
        registers[5] = 64'd6;  // X5 
        registers[6] = 64'd7;  // X6
        registers[7] = 64'd8;  // X7
        registers[8] = 64'd9;  // X8
        registers[9] = 64'd10; // X9
        registers[10] = 64'd11;// X10 
        registers[11] = 64'd0; // X11
        registers[12] = 64'd13;// X12
        registers[13] = 64'd14;// X13
        registers[14] = 64'd15;// X14
        registers[15] = 64'd16;// X15
        registers[16] = 64'd17;// X16
        registers[17] = 64'd18;// X17
        registers[18] = 64'd19;// X18
        registers[19] = 64'd20;// X19
        registers[20] = 64'd21;// X20
        registers[21] = 64'd22;// X21 
        registers[22] = 64'd23;// X22 
        registers[23] = 64'd24;// X23 
        registers[24] = 64'd25;// X24 
        registers[25] = 64'd26;// X25 
        registers[26] = 64'd27;// X26
        registers[27] = 64'd28;// X27
        registers[28] = 64'd29;// X28
        registers[29] = 64'd30;// X29
        registers[30] = 64'd31;// X30
        registers[31] = 64'd0; // XZR(X31)
    end

    assign Readdata1 = registers[Rn];
    assign Readdata2 = registers[Rm];

    always @(posedge clk ) begin
        if (Regwrite && (Rd != 5'd31)) begin
            registers[Rd] <= Regwritedata;
        end
    end


endmodule