module ahb_lite_master (
    input  wire        clk,
    input  wire        rst,

    // During external image loading the loader owns the AHB master.
    input  wire        loader_select,

    input  wire        loader_valid,
    input  wire        loader_write,
    input  wire [63:0] loader_addr,
    input  wire [63:0] loader_wdata,
    output wire        loader_ready,

    input  wire        cpu_valid,
    input  wire        cpu_write,
    input  wire [63:0] cpu_addr,
    input  wire [63:0] cpu_wdata,
    output wire        cpu_ready,
    output wire [63:0] cpu_rdata,

    // AHB-Lite master signals
    output reg  [63:0] HADDR,
    output reg  [1:0]  HTRANS,
    output reg         HWRITE,
    output reg  [2:0]  HSIZE,
    output reg  [2:0]  HBURST,
    output reg  [3:0]  HPROT,
    output reg         HMASTLOCK,
    output reg  [63:0] HWDATA,
    input  wire [63:0] HRDATA,
    input  wire        HREADY,
    input  wire        HRESP
);

    localparam IDLE = 1'b0;
    localparam DATA = 1'b1;

    localparam [1:0] HTRANS_IDLE   = 2'b00;
    localparam [1:0] HTRANS_NONSEQ = 2'b10;

    reg state;
    reg active_loader;
    reg [63:0] wdata_q;

    wire selected_valid;
    wire selected_write;
    wire [63:0] selected_addr;
    wire [63:0] selected_wdata;

    assign selected_valid = loader_select ? loader_valid : cpu_valid;
    assign selected_write = loader_select ? loader_write : cpu_write;
    assign selected_addr  = loader_select ? loader_addr  : cpu_addr;
    assign selected_wdata = loader_select ? loader_wdata : cpu_wdata;

    // The request-side interface is blocking: completion is reported only
    // when the AHB data phase completes.
    assign loader_ready = (state == DATA) &&  active_loader && HREADY;
    assign cpu_ready    = (state == DATA) && !active_loader && HREADY;
    assign cpu_rdata    = HRDATA;

    always @(*) begin
        HADDR     = 64'd0;
        HTRANS    = HTRANS_IDLE;
        HWRITE    = 1'b0;
        HSIZE     = 3'b011;  // 8-byte transfer for the 64-bit LEGv8 data path
        HBURST    = 3'b000;  // SINGLE
        HPROT     = 4'b0011; // data, privileged, non-bufferable, non-cacheable
        HMASTLOCK = 1'b0;
        HWDATA    = wdata_q;

        if (state == IDLE && selected_valid) begin
            // Address/control phase.
            HADDR  = selected_addr;
            HTRANS = HTRANS_NONSEQ;
            HWRITE = selected_write;
        end
        else if (state == DATA) begin
            // Data phase. No next transfer is issued, so HTRANS is IDLE.
            HTRANS = HTRANS_IDLE;
            HWDATA = wdata_q;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            state         <= IDLE;
            active_loader <= 1'b0;
            wdata_q       <= 64'd0;
        end
        else begin
            case (state)
                IDLE: begin
                    // With no previous transfer, HREADY is normally high.
                    // If it is low, keep address/control stable until accepted.
                    if (selected_valid && HREADY) begin
                        state         <= DATA;
                        active_loader <= loader_select;
                        wdata_q       <= selected_wdata;
                    end
                end

                DATA: begin
                    // Slave wait states extend the AHB data phase.
                    if (HREADY)
                        state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

    // HRESP is currently always OKAY in this SoC. It is kept on the master
    // interface so the bus remains AHB-Lite shaped when error support is added.
    wire unused_hresp = HRESP;

endmodule
