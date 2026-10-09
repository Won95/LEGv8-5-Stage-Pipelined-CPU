module uart_rx_phy #(
    parameter integer CLK_FREQ_HZ = 50_000_000,
    parameter integer BAUD        = 115200
) (
    input  wire       clk,
    input  wire       rst,
    input  wire       rx,

    output reg        out_valid,
    output reg  [7:0] out_data,
    input  wire       out_ready
);

    localparam integer CLKS_PER_BIT = CLK_FREQ_HZ / BAUD;
    localparam integer CTR_WIDTH = (CLKS_PER_BIT <= 1) ? 1 : $clog2(CLKS_PER_BIT);

    localparam [2:0] IDLE  = 3'd0;
    localparam [2:0] START = 3'd1;
    localparam [2:0] DATA  = 3'd2;
    localparam [2:0] STOP  = 3'd3;
    localparam [2:0] HOLD  = 3'd4;

    reg [2:0] state;
    reg [CTR_WIDTH-1:0] clk_count;
    reg [2:0] bit_index;
    reg [7:0] shift_reg;

    reg rx_meta;
    reg rx_sync;

    always @(posedge clk) begin
        if (rst) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end
        else begin
            rx_meta <= rx;
            rx_sync <= rx_meta;
        end
    end

    always @(posedge clk) begin
        if (rst) begin
            state      <= IDLE;
            clk_count  <= {CTR_WIDTH{1'b0}};
            bit_index  <= 3'd0;
            shift_reg  <= 8'd0;
            out_valid  <= 1'b0;
            out_data   <= 8'd0;
        end
        else begin
            if (out_valid && out_ready)
                out_valid <= 1'b0;

            case (state)
                IDLE: begin
                    clk_count <= {CTR_WIDTH{1'b0}};
                    bit_index <= 3'd0;
                    if (!rx_sync)
                        state <= START;
                end

                START: begin
                    if (clk_count == ((CLKS_PER_BIT / 2) - 1)) begin
                        clk_count <= {CTR_WIDTH{1'b0}};
                        if (!rx_sync)
                            state <= DATA;
                        else
                            state <= IDLE;
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                DATA: begin
                    if (clk_count == (CLKS_PER_BIT - 1)) begin
                        clk_count <= {CTR_WIDTH{1'b0}};
                        shift_reg[bit_index] <= rx_sync;
                        if (bit_index == 3'd7) begin
                            bit_index <= 3'd0;
                            state <= STOP;
                        end
                        else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                STOP: begin
                    if (clk_count == (CLKS_PER_BIT - 1)) begin
                        clk_count <= {CTR_WIDTH{1'b0}};
                        out_data  <= shift_reg;
                        out_valid <= 1'b1;
                        state     <= HOLD;
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                HOLD: begin
                    if (out_valid && out_ready)
                        state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
