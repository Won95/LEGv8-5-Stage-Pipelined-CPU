module simple_bus (
    input  wire        loader_select,

    // Loader master
    input  wire        loader_valid,
    input  wire        loader_write,
    input  wire [63:0] loader_addr,
    input  wire [63:0] loader_wdata,
    output wire        loader_ready,

    // CPU master
    input  wire        cpu_valid,
    input  wire        cpu_write,
    input  wire [63:0] cpu_addr,
    input  wire [63:0] cpu_wdata,
    output wire        cpu_ready,
    output wire [63:0] cpu_rdata,

    // Single slave side
    output wire        slave_valid,
    output wire        slave_write,
    output wire [63:0] slave_addr,
    output wire [63:0] slave_wdata,
    input  wire        slave_ready,
    input  wire [63:0] slave_rdata
);

    assign slave_valid = loader_select ? loader_valid : cpu_valid;
    assign slave_write = loader_select ? loader_write : cpu_write;
    assign slave_addr  = loader_select ? loader_addr  : cpu_addr;
    assign slave_wdata = loader_select ? loader_wdata : cpu_wdata;

    assign loader_ready = loader_select  ? slave_ready : 1'b0;
    assign cpu_ready    = !loader_select ? slave_ready : 1'b0;
    assign cpu_rdata    = slave_rdata;

endmodule
