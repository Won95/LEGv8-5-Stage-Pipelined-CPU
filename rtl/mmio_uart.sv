module mmio_uart (
    input  wire        clk,
    input  wire        rst,

    input  wire        valid,
    input  wire        write,
    input  wire [63:0] addr,
    input  wire [63:0] wdata,
    output wire        ready,
    output reg  [63:0] rdata,

    // External RX byte stream -> RX FIFO
    input  wire        rx_valid,
    input  wire [7:0]  rx_data,
    output wire        rx_ready,

    // TX FIFO -> external TX byte stream
    output wire        tx_valid,
    output wire [7:0]  tx_data,
    input  wire        tx_ready
);

    localparam [63:0] UART_RXDATA_ADDR = 64'h0000_0000_0000_0120;
    localparam [63:0] UART_TXDATA_ADDR = 64'h0000_0000_0000_0128;
    localparam [63:0] UART_STATUS_ADDR = 64'h0000_0000_0000_0130;

    /*==============================
      RX FIFO
      ==============================*/
    wire       rx_fifo_valid;
    wire [7:0] rx_fifo_data;
    wire       rx_fifo_pop;

    simple_fifo #(
        .WIDTH(8),
        .DEPTH(4)
    ) rx_fifo (
        .clk      (clk),
        .rst      (rst),
        .wr_valid (rx_valid),
        .wr_data  (rx_data),
        .wr_ready (rx_ready),
        .rd_valid (rx_fifo_valid),
        .rd_data  (rx_fifo_data),
        .rd_ready (rx_fifo_pop)
    );

    /*==============================
      TX FIFO
      ==============================*/
    wire       tx_fifo_wr_ready;
    wire       tx_fifo_push;

    simple_fifo #(
        .WIDTH(8),
        .DEPTH(4)
    ) tx_fifo (
        .clk      (clk),
        .rst      (rst),
        .wr_valid (tx_fifo_push),
        .wr_data  (wdata[7:0]),
        .wr_ready (tx_fifo_wr_ready),
        .rd_valid (tx_valid),
        .rd_data  (tx_data),
        .rd_ready (tx_ready)
    );

    wire access_rxdata;
    wire access_txdata;

    assign access_rxdata = valid && !write && (addr == UART_RXDATA_ADDR);
    assign access_txdata = valid &&  write && (addr == UART_TXDATA_ADDR);

    // RXDATA read blocks while the RX FIFO is empty.
    // TXDATA write blocks while the TX FIFO is full.
    // STATUS and unsupported UART-register accesses complete immediately.
    assign ready = access_rxdata ? rx_fifo_valid :
                   access_txdata ? tx_fifo_wr_ready :
                                   valid;

    assign rx_fifo_pop  = access_rxdata && ready;
    assign tx_fifo_push = access_txdata && ready;

    always @(*) begin
        case (addr)
            UART_RXDATA_ADDR: rdata = {56'd0, rx_fifo_data};
            UART_STATUS_ADDR: rdata = {62'd0, tx_fifo_wr_ready, rx_fifo_valid};
            default         : rdata = 64'd0;
        endcase
    end

endmodule
