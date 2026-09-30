module dataMem (
    input wire clk,
    input wire [63:0] Address,
    input wire [63:0] Memwritedata,
    input wire Memwrite,
    input wire Memread,
    output wire [63:0] Readmemdata
);
    reg [63:0] datamemory [31:0]; // 8byte 32개 256byte
    wire [4:0] addr;
    assign addr = Address[4:0];

    initial begin
        datamemory[0] = 64'd1; 
        datamemory[1] = 64'd2; 
        datamemory[2] = 64'd3; 
        datamemory[3] = 64'd4; 
        datamemory[4] = 64'd5; 
        datamemory[5] = 64'd6; 
        datamemory[6] = 64'd7;
        datamemory[7] = 64'd8;
        datamemory[8] = 64'd9;
        datamemory[9] = 64'd10;
        datamemory[10] = 64'd11; 
        datamemory[11] = 64'd12; 
        datamemory[12] = 64'd99; 
        datamemory[13] = 64'd14; 
        datamemory[14] = 64'd15; 
        datamemory[15] = 64'd16; 
        datamemory[16] = 64'd17;
        datamemory[17] = 64'd18;
        datamemory[18] = 64'd19;
        datamemory[19] = 64'd20;
        datamemory[20] = 64'd21; 
        datamemory[21] = 64'd22; 
        datamemory[22] = 64'd23; 
        datamemory[23] = 64'd24; 
        datamemory[24] = 64'd25; 
        datamemory[25] = 64'd26; 
        datamemory[26] = 64'd27;
        datamemory[27] = 64'd28;
        datamemory[28] = 64'd29;
        datamemory[29] = 64'd30;
        datamemory[30] = 64'd31;
        datamemory[31] = 64'd32;
    end

    assign Readmemdata = Memread ? datamemory[addr] : 64'd0;

    always @(posedge clk ) begin
        if(Memwrite)begin
            datamemory[addr] <= Memwritedata;    
        end
    end
endmodule