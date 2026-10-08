module ahb_lite_fabric (
    input  wire        clk,
    input  wire        rst,
    input  wire        boot_mode,

    // AHB-Lite bus
    input  wire [63:0] HADDR,
    input  wire [1:0]  HTRANS,
    input  wire        HWRITE,
    input  wire [2:0]  HSIZE,
    input  wire [2:0]  HBURST,
    input  wire [3:0]  HPROT,
    input  wire        HMASTLOCK,
    input  wire [63:0] HWDATA,
    output wire [63:0] HRDATA,
    output wire        HREADY,
    output wire        HRESP,

    // DMEM backend
    output wire        dmem_valid,
    output wire        dmem_write,
    output wire [63:0] dmem_addr,
    output wire [63:0] dmem_wdata,
    input  wire        dmem_ready,
    input  wire [63:0] dmem_rdata,

    // MMIO backend
    output wire        mmio_valid,
    output wire        mmio_write,
    output wire [63:0] mmio_addr,
    output wire [63:0] mmio_wdata,
    input  wire        mmio_ready,
    input  wire [63:0] mmio_rdata
);

    // The SoC only issues SINGLE/NONSEQ transfers. Address/control are captured
    // in the AHB address phase; the selected backend then completes the data
    // phase, potentially inserting wait states through HREADY.
    reg        pending;
    reg        select_dmem_q;
    reg        select_mmio_q;
    reg        write_q;
    reg [63:0] addr_q;

    wire address_phase_valid;
    wire select_dmem_now;
    wire select_mmio_now;

    assign address_phase_valid = HTRANS[1]; // NONSEQ/SEQ are active transfers

    // Runtime map:
    //   0x0000 ~ 0x00FF : DMEM
    //   0x0100 ~ 0x01FF : MMIO
    // During external loading, every loader data-bus transaction targets DMEM.
    assign select_dmem_now = boot_mode || (HADDR[63:8] == 56'd0);
    assign select_mmio_now = !boot_mode && (HADDR[63:8] == 56'd1);

    assign dmem_valid = pending && select_dmem_q;
    assign dmem_write = write_q;
    assign dmem_addr  = addr_q;
    assign dmem_wdata = HWDATA;

    assign mmio_valid = pending && select_mmio_q;
    assign mmio_write = write_q;
    assign mmio_addr  = addr_q;
    assign mmio_wdata = HWDATA;

    // No transfer pending means the bus is ready for a new address phase.
    // Unmapped transfers complete as OKAY with zero read data.
    assign HREADY = !pending       ? 1'b1       :
                    select_dmem_q  ? dmem_ready :
                    select_mmio_q  ? mmio_ready :
                                     1'b1;

    assign HRDATA = select_dmem_q ? dmem_rdata :
                    select_mmio_q ? mmio_rdata :
                                    64'd0;

    assign HRESP = 1'b0; // OKAY

    always @(posedge clk) begin
        if (rst) begin
            pending       <= 1'b0;
            select_dmem_q <= 1'b0;
            select_mmio_q <= 1'b0;
            write_q       <= 1'b0;
            addr_q        <= 64'd0;
        end
        else begin
            if (pending) begin
                if (HREADY) begin
                    pending       <= 1'b0;
                    select_dmem_q <= 1'b0;
                    select_mmio_q <= 1'b0;
                end
            end
            else if (address_phase_valid && HREADY) begin
                pending       <= 1'b1;
                select_dmem_q <= select_dmem_now;
                select_mmio_q <= select_mmio_now;
                write_q       <= HWRITE;
                addr_q        <= HADDR;
            end
        end
    end

    // These AHB-Lite attributes are fixed by the current single-transfer master.
    // Keep them visible here so future width/burst/protection checks can be added.
    wire [2:0] unused_hsize = HSIZE;
    wire [2:0] unused_hburst = HBURST;
    wire [3:0] unused_hprot = HPROT;
    wire       unused_hmastlock = HMASTLOCK;

endmodule
