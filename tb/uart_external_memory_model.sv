module uart_external_memory_model (
    input  wire        clk,
    input  wire        rst,

    output wire        stream_valid,
    output wire        stream_target,
    output wire        stream_last,
    output wire [63:0] stream_addr,
    output wire [63:0] stream_wdata,
    input  wire        stream_ready
);

    // CPU MMIO UART echo program:
    //   ADDI x10, x31, #0x120   ; UART_RXDATA
    //   LDUR x1, [x10,#0]
    //   ADDI x11, x31, #0x128   ; UART_TXDATA
    //   STUR x1, [x11,#0]
    //   B #0
    reg [129:0] image [0:4];
    reg [2:0]   index;
    reg         active;

    initial begin
        image[0] = {1'b0, 1'b0, 64'd0,  32'h00000000_910483EA};
        image[1] = {1'b0, 1'b0, 64'd4,  32'h00000000_F8400141};
        image[2] = {1'b0, 1'b0, 64'd8,  32'h00000000_9104A3EB};
        image[3] = {1'b0, 1'b0, 64'd12, 32'h00000000_F8000161};
        image[4] = {1'b1, 1'b0, 64'd16, 32'h00000000_14000000};
    end

    assign stream_valid = active;
    assign {stream_last, stream_target, stream_addr, stream_wdata} = image[index];

    always @(posedge clk) begin
        if (rst) begin
            index  <= 3'd0;
            active <= 1'b1;
        end
        else if (stream_valid && stream_ready) begin
            if (stream_last)
                active <= 1'b0;
            else
                index <= index + 1'b1;
        end
    end

endmodule
