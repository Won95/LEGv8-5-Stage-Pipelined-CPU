module sram_wrapper32b (
    `ifdef USE_POWER_PINS
    inout wire vccd1,
    inout wire vssd1,
    
    `endif
    input  wire        clk,
    input  wire        rst,

    // Loader write path (byte address)
    input  wire        prog_valid,
    input  wire [63:0] prog_addr,
    input  wire [31:0] prog_wdata,
    output wire        prog_ready,

    // CPU instruction request channel
    input  wire        req_valid,
    output wire        req_ready,
    input  wire [63:0] req_addr,

    // CPU instruction response channel
    output wire        rsp_valid,
    input  wire        rsp_ready,
    output wire [63:0] rsp_addr,
    output wire [31:0] rsp_data,

    // Taken branch: discard all outstanding sequential fetches.
    input  wire        flush
);

    localparam IDLE = 1'b0;
    localparam WAIT = 1'b1;

    reg prog_state;

    wire prog_fire;
    wire [31:0] unused_dout0;
    wire [31:0] dout1;

    /*==============================
      Loader write port
      ==============================*/
    assign prog_fire  = (prog_state == IDLE) && prog_valid;
    assign prog_ready = (prog_state == WAIT);

    always @(posedge clk) begin
        if (rst) begin
            prog_state <= IDLE;
        end
        else begin
            case (prog_state)
                IDLE: begin
                    if (prog_valid)
                        prog_state <= WAIT;
                end

                WAIT: begin
                    prog_state <= IDLE;
                end

                default: prog_state <= IDLE;
            endcase
        end
    end

    /*==============================
      CPU pipelined read port

      SRAM read latency가 1 cycle이므로 accepted request는 먼저
      inflight slot에 들어간다. CPU가 갑자기 backpressure를 걸어도
      이미 SRAM에 들어간 response를 잃지 않도록 response queue는
      2-entry(response + skid)로 둔다.
      ==============================*/
    reg        inflight_valid;
    reg [63:0] inflight_addr;

    reg [1:0]  rsp_count;
    reg [63:0] rsp_addr0, rsp_addr1;
    reg [31:0] rsp_data0, rsp_data1;

    wire rsp_fire;
    wire req_fire;
    wire arrival;
    wire [2:0] outstanding;

    assign rsp_valid = (rsp_count != 2'd0);
    assign rsp_addr  = rsp_addr0;
    assign rsp_data  = rsp_data0;
    assign rsp_fire  = rsp_valid && rsp_ready;

    // queue에 저장된 response + SRAM에서 돌아올 inflight response를 합쳐
    // 최대 2개까지만 outstanding으로 허용한다.
    assign outstanding = {1'b0, rsp_count} + inflight_valid;

    // 현재 response를 같은 cycle에 consume한다면 그 자리까지 고려해
    // 다음 request를 받을 수 있다.
    assign req_ready = !flush && ((outstanding < 3'd2) || rsp_fire);
    assign req_fire  = req_valid && req_ready;

    // 이전 cycle에 SRAM으로 넣은 request의 data가 현재 cycle에 유효하다.
    assign arrival = inflight_valid;

    always @(posedge clk) begin
        if (rst || flush) begin
            inflight_valid <= 1'b0;
            inflight_addr  <= 64'd0;

            rsp_count <= 2'd0;
            rsp_addr0 <= 64'd0;
            rsp_addr1 <= 64'd0;
            rsp_data0 <= 32'd0;
            rsp_data1 <= 32'd0;
        end
        else begin
            // Current accepted request becomes next cycle's inflight response.
            inflight_valid <= req_fire;
            if (req_fire)
                inflight_addr <= req_addr;

            // Response queue update. dout1 corresponds to inflight_addr.
            case (rsp_count)
                2'd0: begin
                    if (arrival) begin
                        rsp_addr0 <= inflight_addr;
                        rsp_data0 <= dout1;
                        rsp_count <= 2'd1;
                    end
                end

                2'd1: begin
                    case ({rsp_fire, arrival})
                        2'b00: begin
                            rsp_count <= 2'd1;
                        end

                        2'b01: begin
                            rsp_addr1 <= inflight_addr;
                            rsp_data1 <= dout1;
                            rsp_count <= 2'd2;
                        end

                        2'b10: begin
                            rsp_count <= 2'd0;
                        end

                        2'b11: begin
                            // Head is consumed while the inflight response
                            // replaces it in the same cycle.
                            rsp_addr0 <= inflight_addr;
                            rsp_data0 <= dout1;
                            rsp_count <= 2'd1;
                        end
                    endcase
                end

                2'd2: begin
                    if (rsp_fire) begin
                        rsp_addr0 <= rsp_addr1;
                        rsp_data0 <= rsp_data1;

                        if (arrival) begin
                            rsp_addr1 <= inflight_addr;
                            rsp_data1 <= dout1;
                            rsp_count <= 2'd2;
                        end
                        else begin
                            rsp_count <= 2'd1;
                        end
                    end
                end

                default: rsp_count <= 2'd0;
            endcase
        end
    end

    sky130_sram_1kbyte_1rw1r_32x256_8 SRAM_IMEM (
	`ifdef USE_POWER_PINS
    	.vccd1(vccd1),
    	.vssd1(vssd1),
	`endif
    	// Port0: loader write
        .clk0   (clk),
        .csb0   (~prog_fire),
        .web0   (1'b0),
        .wmask0 (4'b1111),
        .addr0  (prog_addr[9:2]),
        .din0   (prog_wdata),
        .dout0  (unused_dout0),

        // Port1: CPU instruction read. Only accepted requests hit the macro.
        .clk1   (clk),
        .csb1   (~req_fire),
        .addr1  (req_addr[9:2]),
        .dout1  (dout1)
    );

endmodule
