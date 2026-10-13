module sram_wrapper32b_pd (
`ifdef USE_POWER_PINS
    inout wire vccd1,
    inout wire vssd1,
`endif
    input  wire        clk,
    input  wire        rst,

    // CPU instruction request channel
    input  wire        req_valid,
    output wire        req_ready,
    input  wire [63:0] req_addr,

    // CPU instruction response channel
    output wire        rsp_valid,
    input  wire        rsp_ready,
    output wire [63:0] rsp_addr,
    output wire [31:0] rsp_data,

    // Taken branch: discard outstanding sequential fetches.
    input  wire        flush
);

    wire [31:0] unused_dout0;
    wire [31:0] dout1;

    // ------------------------------------------------------------------------
    // CPU pipelined read port
    // ------------------------------------------------------------------------
    // One request may be in the SRAM and up to two responses may be buffered.
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

    assign outstanding = {1'b0, rsp_count} + inflight_valid;
    assign req_ready    = !flush && (outstanding < 3'd2);
    assign req_fire     = req_valid && req_ready;
    assign arrival      = inflight_valid;

    always @(posedge clk) begin
        if (rst || flush) begin
            inflight_valid <= 1'b0;
            inflight_addr  <= 64'd0;
            rsp_count      <= 2'd0;
            rsp_addr0      <= 64'd0;
            rsp_addr1      <= 64'd0;
            rsp_data0      <= 32'd0;
            rsp_data1      <= 32'd0;
        end
        else begin
            inflight_valid <= req_fire;
            if (req_fire)
                inflight_addr <= req_addr;

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
                        2'b00: rsp_count <= 2'd1;
                        2'b01: begin
                            rsp_addr1 <= inflight_addr;
                            rsp_data1 <= dout1;
                            rsp_count <= 2'd2;
                        end
                        2'b10: rsp_count <= 2'd0;
                        2'b11: begin
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

    // PD target keeps only the CPU read path. Port0 is intentionally disabled;
    // external image loading remains in the verification-oriented soc_top.
    sky130_sram_1kbyte_1rw1r_32x256_8 SRAM_IMEM (
`ifdef USE_POWER_PINS
        .vccd1(vccd1),
        .vssd1(vssd1),
`endif
        .clk0   (clk),
        .csb0   (1'b1),
        .web0   (1'b1),
        .wmask0 (4'b0000),
        .addr0  (8'd0),
        .din0   (32'd0),
        .dout0  (unused_dout0),

        .clk1   (clk),
        .csb1   (~req_fire),
        .addr1  (req_addr[9:2]),
        .dout1  (dout1)
    );

endmodule
