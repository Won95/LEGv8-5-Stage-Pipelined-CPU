module programcounter (
    input  wire        clk,
    input  wire        rst,
    input  wire [63:0] pc_next,
    input  wire        pchold,
    output reg  [63:0] pc
);

    // Clock-enable style coding avoids an explicit self-feedback mux branch.
    always @(posedge clk) begin
        if (rst)
            pc <= 64'd0;
        else if (!pchold)
            pc <= pc_next;
    end

endmodule
