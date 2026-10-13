module ahb_lite_fabric_pd (
    input  wire        clk,
    input  wire        rst,

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

    output wire        dmem_valid,
    output wire        dmem_write,
    output wire [63:0] dmem_addr,
    output wire [63:0] dmem_wdata,
    input  wire        dmem_ready,
    input  wire [63:0] dmem_rdata,

    output wire        gpio_valid,
    output wire        gpio_write,
    output wire [63:0] gpio_addr,
    output wire [63:0] gpio_wdata,
    input  wire        gpio_ready,
    input  wire [63:0] gpio_rdata
);

    reg        pending;
    reg        select_dmem_q;
    reg        select_gpio_q;
    reg        write_q;
    reg [63:0] addr_q;

    wire address_phase_valid;
    wire upper_window_zero;
    wire select_dmem_now;
    wire select_gpio_now;

    assign address_phase_valid = HTRANS[1];

    // Runtime memory map:
    //   0x0000~0x00ff : DMEM
    //   0x0100~0x011f : GPIO MMIO
    // Other addresses complete as unmapped OKAY/zero-data accesses.
    assign upper_window_zero = ~(|HADDR[63:9]);
    assign select_dmem_now   = upper_window_zero && !HADDR[8];
    assign select_gpio_now   = upper_window_zero && HADDR[8] &&
                               (HADDR[7:5] == 3'b000);

    assign dmem_valid = pending && select_dmem_q;
    assign dmem_write = write_q;
    assign dmem_addr  = addr_q;
    assign dmem_wdata = HWDATA;

    assign gpio_valid = pending && select_gpio_q;
    assign gpio_write = write_q;
    assign gpio_addr  = addr_q;
    assign gpio_wdata = HWDATA;

    assign HREADY = !pending      ? 1'b1       :
                    select_dmem_q ? dmem_ready :
                    select_gpio_q ? gpio_ready :
                                    1'b1;

    assign HRDATA = select_dmem_q ? dmem_rdata :
                    select_gpio_q ? gpio_rdata :
                                    64'd0;

    assign HRESP = 1'b0;

    always @(posedge clk) begin
        if (rst) begin
            pending       <= 1'b0;
            select_dmem_q <= 1'b0;
            select_gpio_q <= 1'b0;
            write_q       <= 1'b0;
            addr_q        <= 64'd0;
        end
        else if (pending) begin
            if (HREADY) begin
                pending       <= 1'b0;
                select_dmem_q <= 1'b0;
                select_gpio_q <= 1'b0;
            end
        end
        else if (address_phase_valid) begin
            pending       <= 1'b1;
            select_dmem_q <= select_dmem_now;
            select_gpio_q <= select_gpio_now;
            write_q       <= HWRITE;
            addr_q        <= HADDR;
        end
    end

    wire [2:0] unused_hsize     = HSIZE;
    wire [2:0] unused_hburst    = HBURST;
    wire [3:0] unused_hprot     = HPROT;
    wire       unused_hmastlock = HMASTLOCK;

endmodule
