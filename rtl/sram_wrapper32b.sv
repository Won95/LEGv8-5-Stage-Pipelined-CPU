module sram_wrapper32b (
    input  wire        clk,
    input  wire        rst,

    // Loader write path (byte address)
    input  wire        prog_valid,
    input  wire [63:0] prog_addr,
    input  wire [31:0] prog_wdata,
    output wire        prog_ready,

    // CPU instruction fetch path (byte address)
    input  wire        cpu_re,
    input  wire [63:0] cpu_addr,
    output wire        cpu_rvalid,
    output wire [63:0] cpu_raddr,
    output wire [31:0] cpu_rdata
);

    localparam IDLE = 1'b0;
    localparam WAIT = 1'b1;

    reg prog_state;

    wire prog_fire;
    wire [31:0] unused_dout0;
    wire [31:0] dout1;

    // Loader write request는 한 번만 SRAM port0에 넣고,
    // 다음 cycle에 완료 응답을 돌려준다.
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

    // Port1은 pipelined instruction read port로 사용한다.
    // address를 받은 다음 cycle에 rvalid/raddr/rdata가 한 세트로 유효하다.
    reg        cpu_re_d;
    reg [63:0] cpu_addr_d;

    always @(posedge clk) begin
        if (rst) begin
            cpu_re_d   <= 1'b0;
            cpu_addr_d <= 64'd0;
        end
        else begin
            cpu_re_d <= cpu_re;
            if (cpu_re)
                cpu_addr_d <= cpu_addr;
        end
    end

    assign cpu_rvalid = cpu_re_d;
    assign cpu_raddr  = cpu_addr_d;
    assign cpu_rdata  = dout1;

    sky130_sram_1kbyte_1rw1r_32x256_8 SRAM_IMEM (
        // Port0: loader write
        .clk0   (clk),
        .csb0   (~prog_fire),
        .web0   (1'b0),
        .wmask0 (4'b1111),
        .addr0  (prog_addr[9:2]),
        .din0   (prog_wdata),
        .dout0  (unused_dout0),

        // Port1: CPU instruction read
        .clk1   (clk),
        .csb1   (~cpu_re),
        .addr1  (cpu_addr[9:2]),
        .dout1  (dout1)
    );

endmodule
