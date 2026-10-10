module sram_wrapper64b (
`ifdef USE_POWER_PINS
    inout wire         vccd1,
    inout wire         vssd1,
`endif

    input  wire        clk,
    input  wire        rst,

    input  wire [63:0] addr,
    input  wire [63:0] wdata,
    input  wire        we,
    input  wire        re,

    output wire        ready,
    output wire [63:0] rdata
);

    localparam IDLE = 1'b0;
    localparam WAIT = 1'b1;

    reg state;

    wire request;
    wire request_fire;
    wire [31:0] dout_low;
    wire [31:0] dout_high;

    // CPU는 re/we를 ready가 돌아올 때까지 유지한다.
    assign request      = re | we;
    assign request_fire = (state == IDLE) && request;

    // WAIT 상태 동안 SRAM access가 끝났다고 CPU에 알린다.
    // SRAM read data는 다음 posedge에서 CPU가 샘플링한다.
    assign ready = (state == WAIT);
    assign rdata = {dout_high, dout_low};

    // SRAM control은 active low.
    // request를 처음 접수하는 한 cycle에만 macro를 enable한다.
    wire csb0;
    wire web0;
    assign csb0 = ~request_fire;
    assign web0 = ~we;

    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
        end
        else begin
            case (state)
                IDLE: begin
                    if (request)
                        state <= WAIT;
                end

                WAIT: begin
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

    // lower 32-bit
    sky130_sram_1kbyte_1rw1r_32x256_8 SRAM_LOW (
	`ifdef USE_POWER_PINS
    	.vccd1(vccd1),
    	.vssd1(vssd1),
	`endif
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
        `ifdef USE_POWER_PINS
    	.vccd1(vccd1),
    	.vssd1(vssd1),
	`endif
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
