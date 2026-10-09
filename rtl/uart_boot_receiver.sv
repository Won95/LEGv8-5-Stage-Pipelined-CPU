module uart_boot_receiver (
    input  wire        clk,
    input  wire        rst,

    input  wire        byte_valid,
    input  wire [7:0]  byte_data,
    output wire        byte_ready,

    output reg         ext_valid,
    output reg         ext_target,
    output reg         ext_last,
    output reg  [63:0] ext_addr,
    output reg  [63:0] ext_wdata,
    input  wire        ext_ready
);

    // UART boot packet: 17 bytes, little-endian fields.
    //   byte 0    : control [1]=last, [0]=target (0=IMEM, 1=DMEM)
    //   byte 1~8  : 64-bit address
    //   byte 9~16 : 64-bit data
    reg [4:0] byte_count;

    assign byte_ready = !ext_valid;

    always @(posedge clk) begin
        if (rst) begin
            byte_count <= 5'd0;
            ext_valid  <= 1'b0;
            ext_target <= 1'b0;
            ext_last   <= 1'b0;
            ext_addr   <= 64'd0;
            ext_wdata  <= 64'd0;
        end
        else begin
            if (ext_valid && ext_ready) begin
                ext_valid  <= 1'b0;
                byte_count <= 5'd0;
            end

            if (byte_valid && byte_ready) begin
                case (byte_count)
                    5'd0: begin
                        ext_target <= byte_data[0];
                        ext_last   <= byte_data[1];
                        ext_addr   <= 64'd0;
                        ext_wdata  <= 64'd0;
                        byte_count <= 5'd1;
                    end
                    5'd1: begin ext_addr[7:0]    <= byte_data; byte_count <= 5'd2;  end
                    5'd2: begin ext_addr[15:8]   <= byte_data; byte_count <= 5'd3;  end
                    5'd3: begin ext_addr[23:16]  <= byte_data; byte_count <= 5'd4;  end
                    5'd4: begin ext_addr[31:24]  <= byte_data; byte_count <= 5'd5;  end
                    5'd5: begin ext_addr[39:32]  <= byte_data; byte_count <= 5'd6;  end
                    5'd6: begin ext_addr[47:40]  <= byte_data; byte_count <= 5'd7;  end
                    5'd7: begin ext_addr[55:48]  <= byte_data; byte_count <= 5'd8;  end
                    5'd8: begin ext_addr[63:56]  <= byte_data; byte_count <= 5'd9;  end
                    5'd9: begin ext_wdata[7:0]   <= byte_data; byte_count <= 5'd10; end
                    5'd10: begin ext_wdata[15:8] <= byte_data; byte_count <= 5'd11; end
                    5'd11: begin ext_wdata[23:16] <= byte_data; byte_count <= 5'd12; end
                    5'd12: begin ext_wdata[31:24] <= byte_data; byte_count <= 5'd13; end
                    5'd13: begin ext_wdata[39:32] <= byte_data; byte_count <= 5'd14; end
                    5'd14: begin ext_wdata[47:40] <= byte_data; byte_count <= 5'd15; end
                    5'd15: begin ext_wdata[55:48] <= byte_data; byte_count <= 5'd16; end
                    5'd16: begin
                        ext_wdata[63:56] <= byte_data;
                        ext_valid <= 1'b1;
                        byte_count <= 5'd16;
                    end
                    default: byte_count <= 5'd0;
                endcase
            end
        end
    end

endmodule
