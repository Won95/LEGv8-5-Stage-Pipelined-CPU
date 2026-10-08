module memory_loader (
    input  wire         clk,
    input  wire         rst,

    input  wire         fifo_valid,
    input  wire [129:0] fifo_data,
    output wire         fifo_ready,

    output wire         bus_valid,
    output wire         bus_write,
    output wire [63:0]  bus_addr,
    output wire [63:0]  bus_wdata,
    input  wire         bus_ready,

    output reg          load_done
);

    localparam IDLE  = 1'b0;
    localparam ISSUE = 1'b1;

    reg state;

    reg        pkt_last;
    reg        pkt_target;
    reg [63:0] pkt_addr;
    reg [63:0] pkt_wdata;

    assign fifo_ready = (state == IDLE) && !load_done;

    // 현재 단계에서는 target=1(DMEM)만 bus transaction으로 처리한다.
    // target=0(IMEM)은 instruction SRAM 연결 단계에서 추가한다.
    assign bus_valid = (state == ISSUE) && pkt_target;
    assign bus_write = 1'b1;
    assign bus_addr  = pkt_addr;
    assign bus_wdata = pkt_wdata;

    always @(posedge clk) begin
        if (rst) begin
            state      <= IDLE;
            pkt_last   <= 1'b0;
            pkt_target <= 1'b0;
            pkt_addr   <= 64'd0;
            pkt_wdata  <= 64'd0;
            load_done  <= 1'b0;
        end
        else begin
            case (state)
                IDLE: begin
                    if (fifo_valid && fifo_ready) begin
                        {pkt_last, pkt_target, pkt_addr, pkt_wdata} <= fifo_data;
                        state <= ISSUE;
                    end
                end

                ISSUE: begin
                    if (pkt_target) begin
                        if (bus_ready) begin
                            if (pkt_last)
                                load_done <= 1'b1;
                            state <= IDLE;
                        end
                    end
                    else begin
                        // IMEM target은 아직 미연결. 현재 image에는 사용하지 않는다.
                        if (pkt_last)
                            load_done <= 1'b1;
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
