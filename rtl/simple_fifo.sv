module simple_fifo #(
    parameter WIDTH = 130,
    parameter DEPTH = 4
)(
    input  wire             clk,
    input  wire             rst,
    input  wire             wr_valid,
    input  wire [WIDTH-1:0] wr_data,
    output wire             wr_ready,
    output wire             rd_valid,
    output wire [WIDTH-1:0] rd_data,
    input  wire             rd_ready
);

    localparam PTR_WIDTH = $clog2(DEPTH);

    reg [WIDTH-1:0] mem [0:DEPTH-1];
    reg [PTR_WIDTH-1:0] wr_ptr;
    reg [PTR_WIDTH-1:0] rd_ptr;
    reg [PTR_WIDTH:0]   count;

    wire wr_fire = wr_valid && wr_ready;
    wire rd_fire = rd_valid && rd_ready;

    assign wr_ready = (count < DEPTH);
    assign rd_valid = (count != 0);
    assign rd_data  = mem[rd_ptr];

    always @(posedge clk) begin
        if (rst) begin
            wr_ptr <= {PTR_WIDTH{1'b0}};
            rd_ptr <= {PTR_WIDTH{1'b0}};
            count  <= {(PTR_WIDTH+1){1'b0}};
        end
        else begin
            if (wr_fire) begin
                mem[wr_ptr] <= wr_data;
                wr_ptr <= wr_ptr + 1'b1;
            end

            if (rd_fire)
                rd_ptr <= rd_ptr + 1'b1;

            case ({wr_fire, rd_fire})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end

endmodule
