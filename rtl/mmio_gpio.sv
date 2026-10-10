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
    output reg  [63:0] gpio_out,
    output reg  [63:0] gpio_oe
);

    localparam [7:0] GPIO_OUT_OFF = 8'h00;
    localparam [7:0] GPIO_IN_OFF  = 8'h08;
    localparam [7:0] GPIO_OE_OFF  = 8'h10;

    assign ready = valid;

    always_comb begin
        case (addr[7:0])
            GPIO_OUT_OFF: rdata = gpio_out;
            GPIO_IN_OFF : rdata = gpio_in;
            GPIO_OE_OFF : rdata = gpio_oe;
            default     : rdata = 64'd0;
        endcase
    end

    always @(posedge clk) begin
        if (rst) begin
            gpio_out <= 64'd0;
            gpio_oe  <= 64'd0;
        end
        else if (valid && write) begin
            case (addr[7:0])
                GPIO_OUT_OFF: gpio_out <= wdata;
                GPIO_OE_OFF : gpio_oe  <= wdata;
                default     : begin end
            endcase
        end
    end

endmodule
