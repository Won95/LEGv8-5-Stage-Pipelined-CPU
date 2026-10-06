module soc_top (
    input wire clk,
    input wire rst
);

    wire [63:0] imem_addr;
    wire [31:0] imem_rdata;

    wire [63:0] dmem_addr;
    wire [63:0] dmem_wdata;
    wire [63:0] dmem_rdata;
    wire        dmem_we;
    wire        dmem_re;


    core core(.clk(clk),
               .rst(rst),
               .imem_addr(imem_addr),
               .imem_rdata(imem_rdata),
               .dmem_addr(dmem_addr),
               .dmem_wdata(dmem_wdata),
               .dmem_we(dmem_we),
               .dmem_re(dmem_re),
               .dmem_rdata(dmem_rdata)
     );

    InstructionMem IM(.pc(imem_addr), 
                      .instruction(imem_rdata));

    dataMem DM(.clk(clk),
               .Address(dmem_addr),
               .Memwritedata(dmem_wdata),
               .Memwrite(dmem_we),
               .Memread(dmem_re),
               .Memreaddata(dmem_rdata));
    

endmodule