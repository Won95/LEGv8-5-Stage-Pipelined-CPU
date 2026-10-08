module data_bus_decoder (
    input  wire        boot_mode,

    input  wire        bus_valid,
    input  wire        bus_write,
    input  wire [63:0] bus_addr,
    input  wire [63:0] bus_wdata,
    output wire        bus_ready,
    output wire [63:0] bus_rdata,

    // DMEM slave
    output wire        dmem_valid,
    output wire        dmem_write,
    output wire [63:0] dmem_addr,
    output wire [63:0] dmem_wdata,
    input  wire        dmem_ready,
    input  wire [63:0] dmem_rdata,

    // MMIO slave
    output wire        mmio_valid,
    output wire        mmio_write,
    output wire [63:0] mmio_addr,
    output wire [63:0] mmio_wdata,
    input  wire        mmio_ready,
    input  wire [63:0] mmio_rdata
);

    // Runtime address map
    //   0x0000 ~ 0x00FF : DMEM
    //   0x0100 ~ 0x01FF : MMIO
    // During external loading, target=DMEM packets must always reach DMEM.
    wire select_dmem;
    wire select_mmio;
    wire select_unmapped;

    assign select_dmem     = boot_mode || (bus_addr[63:8] == 56'd0);
    assign select_mmio     = !boot_mode && (bus_addr[63:8] == 56'd1);
    assign select_unmapped = !select_dmem && !select_mmio;

    assign dmem_valid = bus_valid && select_dmem;
    assign dmem_write = bus_write;
    assign dmem_addr  = bus_addr;
    assign dmem_wdata = bus_wdata;

    assign mmio_valid = bus_valid && select_mmio;
    assign mmio_write = bus_write;
    assign mmio_addr  = bus_addr;
    assign mmio_wdata = bus_wdata;

    // Unmapped access completes immediately with zero so the CPU cannot deadlock.
    assign bus_ready = select_dmem     ? dmem_ready :
                       select_mmio     ? mmio_ready :
                       select_unmapped ? bus_valid  : 1'b0;

    assign bus_rdata = select_dmem ? dmem_rdata :
                       select_mmio ? mmio_rdata :
                                     64'd0;

endmodule
