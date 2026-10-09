module uart_tx_phy #(
    parameter integer CLK_FREQ_HZ = 50_000_000,
    parameter integer BAUD        = 115200
) (
    input  wire       clk,
    input  wire       rst,

    input  wire       in_valid,
    input  wire [7:0] in_data,
    output wire       in_ready,

    output reg        tx
);

    localparam integer CLKS_PER_BIT = CLK_FREQ_HZ / BAUD;
    localparam integer CTR_WIDTH = (CLKS_PER_BIT <= 1) ? 1 : $clog2(CLKS_PER_BIT);

    localparam [1:0] IDLE  = 2'd0;
    localparam [1:0] START = 2'd1;
    localparam [1:0] DATA  = 2'd2;
    localparam [1:0] STOP  = 2'd3;

    reg [1:0] state;
    reg [CTR_WIDTH-1:0] clk_count;
    reg [2:0] bit_index;
    reg [7:0] shift_reg;

    assign in_ready = (state == IDLE);

    always @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            clk_count <= {CTR_WIDTH{1'b0}};
            bit_index <= 3'd0;
            shift_reg <= 8'd0;
            tx        <= 1'b1;
        end
        else begin
            case (state)
                IDLE: begin
                    tx        <= 1'b1;
                    clk_count <= {CTR_WIDTH{1'b0}};
                    bit_index <= 3'd0;
                    if (in_valid) begin
                        shift_reg <= in_data;
                        tx        <= 1'b0;
                        state     <= START;
                    end
                end

                START: begin
                    if (clk_count == (CLKS_PER_BIT - 1)) begin
                        clk_count <= {CTR_WIDTH{1'b0}};
                        tx        <= shift_reg[0];
                        state     <= DATA;
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                DATA: begin
                    if (clk_count == (CLKS_PER_BIT - 1)) begin
                        clk_count <= {CTR_WIDTH{1'b0}};
                        if (bit_index == 3'd7) begin
                            bit_index <= 3'd0;
                            tx        <= 1'b1;
                            state     <= STOP;
                        end
                        else begin
                            bit_index <= bit_index + 1'b1;
                            tx        <= shift_reg[bit_index + 1'b1];
                        end
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                STOP: begin
                    tx <= 1'b1;
                    if (clk_count == (CLKS_PER_BIT - 1)) begin
                        clk_count <= {CTR_WIDTH{1'b0}};
                        state     <= IDLE;
                    end
                    else begin
                        clk_count <= clk_count + 1'b1;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
