module sram_wrapper (
    input  wire        clk,

    input  wire [63:0] addr,
    input  wire [63:0] wdata,
    input  wire        we,
    input  wire        re,

    output wire [63:0] rdata
);

    wire [31:0] dout_low;
    wire [31:0] dout_high;

    // SRAM control은 active low
    wire csb0;
    wire web0;

    assign csb0 = ~(re | we);
    assign web0 = ~we;

    assign rdata = {dout_high, dout_low};


    // lower 32-bit
    sky130_sram_1kbyte_1rw1r_32x256_8 SRAM_LOW (
        .clk0   (clk),
        .csb0   (csb0),
        .web0   (web0),
        .wmask0 (4'b1111),
        .addr0  (addr[7:0]),
        .din0   (wdata[31:0]),
        .dout0  (dout_low),

        .clk1   (clk),
        .csb1   (1'b1),
        .addr1  (8'd0),
        .dout1  ()
    );


    // upper 32-bit
    sky130_sram_1kbyte_1rw1r_32x256_8 SRAM_HIGH (
        .clk0   (clk),
        .csb0   (csb0),
        .web0   (web0),
        .wmask0 (4'b1111),
        .addr0  (addr[7:0]),
        .din0   (wdata[63:32]),
        .dout0  (dout_high),

        .clk1   (clk),
        .csb1   (1'b1),
        .addr1  (8'd0),
        .dout1  ()
    );

endmodule