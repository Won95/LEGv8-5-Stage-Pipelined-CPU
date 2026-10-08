module external_memory_model (
    input  wire        clk,
    input  wire        rst,

    output wire        stream_valid,
    output wire        stream_target,
    output wire        stream_last,
    output wire [63:0] stream_addr,
    output wire [63:0] stream_wdata,
    input  wire        stream_ready
);

    // packet = {last, target, addr, data}
    // target: 0=IMEM, 1=DMEM
    reg [129:0] image [0:0];
    reg         active;
    reg         index;

    initial begin
        // 현재 directed test에서 필요한 초기 data.
        // 이후 IMEM program image도 같은 배열에 추가한다.
        image[0] = {1'b1, 1'b1, 64'd12, 64'd99};
    end

    assign stream_valid = active;
    assign {stream_last, stream_target, stream_addr, stream_wdata} = image[index];

    always @(posedge clk) begin
        if (rst) begin
            index  <= 1'b0;
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
