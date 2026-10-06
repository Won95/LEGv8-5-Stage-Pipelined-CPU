module programcounter (
    input wire clk,
    input wire rst,
    input wire [63:0] pc_next,
    input wire pchold,
    output reg [63:0] pc
);
    always @(posedge clk) begin 
        if (rst) begin
            pc <= 64'b0;
        end
        else begin
            if (pchold) begin
                pc <= pc;
            end else begin
                pc <= pc_next;                
            end
        end 
    end
    
endmodule