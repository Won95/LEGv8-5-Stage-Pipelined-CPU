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
    // IMEM address는 CPU PC와 동일한 byte address를 사용한다.
    reg [129:0] image [0:19];
    reg         active;
    reg [4:0]   index;

    initial begin
        // Instruction image
        image[0]  = {1'b0, 1'b0, 64'd0,  64'h00000000_8B020023};
        image[1]  = {1'b0, 1'b0, 64'd4,  64'h00000000_CB010064};
        image[2]  = {1'b0, 1'b0, 64'd8,  64'h00000000_8A030085};
        image[3]  = {1'b0, 1'b0, 64'd12, 64'h00000000_AA0400A6};
        image[4]  = {1'b0, 1'b0, 64'd16, 64'h00000000_F8401149};
        image[5]  = {1'b0, 1'b0, 64'd20, 64'h00000000_8B01012C};
        image[6]  = {1'b0, 1'b0, 64'd24, 64'h00000000_CB02018D};
        image[7]  = {1'b0, 1'b0, 64'd28, 64'h00000000_CB01002E};
        image[8]  = {1'b0, 1'b0, 64'd32, 64'h00000000_B400004E};
        image[9]  = {1'b0, 1'b0, 64'd36, 64'h00000000_91000694};
        image[10] = {1'b0, 1'b0, 64'd40, 64'h00000000_910006B5};
        image[11] = {1'b0, 1'b0, 64'd44, 64'h00000000_910005EF};
        image[12] = {1'b0, 1'b0, 64'd48, 64'h00000000_B400004F};
        image[13] = {1'b0, 1'b0, 64'd52, 64'h00000000_910006D6};
        image[14] = {1'b0, 1'b0, 64'd56, 64'h00000000_CB020050};
        image[15] = {1'b0, 1'b0, 64'd60, 64'h00000000_B4000050};
        image[16] = {1'b0, 1'b0, 64'd64, 64'h00000000_910006F7};
        image[17] = {1'b0, 1'b0, 64'd68, 64'h00000000_91000718};
        image[18] = {1'b0, 1'b0, 64'd72, 64'h00000000_14000000};

        // Initial data image
        image[19] = {1'b1, 1'b1, 64'd12, 64'd99};
    end

    assign stream_valid = active;
    assign {stream_last, stream_target, stream_addr, stream_wdata} = image[index];

    always @(posedge clk) begin
        if (rst) begin
            index  <= 5'd0;
            active <= 1'b1;
        end
        else if (stream_valid && stream_ready) begin
            if (stream_last)
                active <= 1'b0;
            else
                index <= index + 5'd1;
        end
    end

endmodule
