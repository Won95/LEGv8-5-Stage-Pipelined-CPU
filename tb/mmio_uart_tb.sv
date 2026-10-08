`timescale 1ns / 1ps

module mmio_uart_tb;

    reg clk;
    reg rst;

    reg         valid;
    reg         write;
    reg  [63:0] addr;
    reg  [63:0] wdata;
    wire        ready;
    wire [63:0] rdata;

    reg         rx_valid;
    reg  [7:0]  rx_data;
    wire        rx_ready;

    wire        tx_valid;
    wire [7:0]  tx_data;
    reg         tx_ready;

    integer errors;

    localparam [63:0] UART_RXDATA_ADDR = 64'h0000_0000_0000_0120;
    localparam [63:0] UART_TXDATA_ADDR = 64'h0000_0000_0000_0128;
    localparam [63:0] UART_STATUS_ADDR = 64'h0000_0000_0000_0130;

    mmio_uart dut (
        .clk      (clk),
        .rst      (rst),

        .valid    (valid),
        .write    (write),
        .addr     (addr),
        .wdata    (wdata),
        .ready    (ready),
        .rdata    (rdata),

        .rx_valid (rx_valid),
        .rx_data  (rx_data),
        .rx_ready (rx_ready),

        .tx_valid (tx_valid),
        .tx_data  (tx_data),
        .tx_ready (tx_ready)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task check;
        input condition;
        input [8*80-1:0] name;
        begin
            if (condition) begin
                $display("[PASS] %0s", name);
            end
            else begin
                $display("[FAIL] %0s", name);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors   = 0;
        valid    = 1'b0;
        write    = 1'b0;
        addr     = 64'd0;
        wdata    = 64'd0;
        rx_valid = 1'b0;
        rx_data  = 8'd0;
        tx_ready = 1'b0;

        rst = 1'b1;
        repeat (2) @(posedge clk);
        rst = 1'b0;
        @(negedge clk);

        // Initial status: RX empty, TX has space.
        valid = 1'b1;
        write = 1'b0;
        addr  = UART_STATUS_ADDR;
        #1;
        check(ready === 1'b1, "STATUS read completes immediately");
        check(rdata[0] === 1'b0, "RX valid is clear after reset");
        check(rdata[1] === 1'b1, "TX ready is set after reset");
        @(negedge clk);
        valid = 1'b0;

        // RXDATA read must block while RX FIFO is empty.
        @(negedge clk);
        valid = 1'b1;
        write = 1'b0;
        addr  = UART_RXDATA_ADDR;
        #1;
        check(ready === 1'b0, "RXDATA read stalls while RX FIFO is empty");

        // External side supplies one byte while CPU-side read is waiting.
        rx_data  = 8'h5A;
        rx_valid = 1'b1;
        @(posedge clk);
        @(negedge clk);
        rx_valid = 1'b0;
        #1;
        check(ready === 1'b1, "waiting RXDATA read completes after byte arrival");
        check(rdata[7:0] === 8'h5A, "RXDATA returns received byte 0x5A");

        // Complete/pop the MMIO read.
        @(posedge clk);
        @(negedge clk);
        valid = 1'b0;
        #1;
        check(dut.rx_fifo_valid === 1'b0, "RX FIFO pops after successful RXDATA read");

        // CPU-side TX write pushes one byte into TX FIFO.
        @(negedge clk);
        valid = 1'b1;
        write = 1'b1;
        addr  = UART_TXDATA_ADDR;
        wdata = 64'hA5;
        #1;
        check(ready === 1'b1, "TXDATA write accepted when TX FIFO has space");
        @(posedge clk);
        @(negedge clk);
        valid = 1'b0;
        write = 1'b0;
        #1;
        check(tx_valid === 1'b1, "TX FIFO presents a valid byte");
        check(tx_data === 8'hA5, "TX FIFO presents byte 0xA5");

        // External transmitter consumes the byte only when ready is asserted.
        tx_ready = 1'b1;
        @(posedge clk);
        @(negedge clk);
        tx_ready = 1'b0;
        #1;
        check(tx_valid === 1'b0, "TX FIFO pops after external ready handshake");

        if (errors == 0) begin
            $display("MMIO UART TEST PASSED");
            $finish;
        end
        else begin
            $display("MMIO UART TEST FAILED: %0d error(s)", errors);
            $fatal(1, "MMIO UART regression failed");
        end
    end

endmodule
