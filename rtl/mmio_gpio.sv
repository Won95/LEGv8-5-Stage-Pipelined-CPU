module mmio_gpio (
    input  wire        clk,
    input  wire        rst,

    input  wire        valid,
    input  wire        write,
    input  wire [63:0] addr,
    input  wire [63:0] wdata,
    output wire        ready,
    output reg  [63:0] rdata,

    input  wire [63:0] gpio_in,
    output reg  [63:0] gpio_out
);

    localparam [63:0] GPIO_OUT_ADDR = 64'h0000_0000_0000_0100;
    localparam [63:0] GPIO_IN_ADDR  = 64'h0000_0000_0000_0108;

    // This peripheral is single-cycle from the bus point of view.
    assign ready = valid;

    always @(*) begin
        case (addr)
            GPIO_OUT_ADDR: rdata = gpio_out;
            GPIO_IN_ADDR : rdata = gpio_in;
            default      : rdata = 64'd0;
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            gpio_out <= 64'd0;
        end
        else if (valid && write && (addr == GPIO_OUT_ADDR)) begin
            gpio_out <= wdata;
        end
    end

endmodule
