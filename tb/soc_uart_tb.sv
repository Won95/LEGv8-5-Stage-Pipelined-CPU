`timescale 1ns / 1ps

module soc_uart_tb;

    reg clk;
    reg rst;

    wire        ext_valid;
    wire        ext_target;
    wire        ext_last;
    wire [63:0] ext_addr;
    wire [63:0] ext_wdata;
    wire        ext_ready;
    wire        load_done;

    reg  [63:0] gpio_in;
    wire [63:0] gpio_out;

    reg         uart_rx_valid;
    reg  [7:0]  uart_rx_data;
    wire        uart_rx_ready;

    wire        uart_tx_valid;
    wire [7:0]  uart_tx_data;
    reg         uart_tx_ready;

    integer cycles;
    integer errors;

    uart_external_memory_model EXT_MEM (
        .clk           (clk),
        .rst           (rst),
        .stream_valid  (ext_valid),
        .stream_target (ext_target),
        .stream_last   (ext_last),
        .stream_addr   (ext_addr),
        .stream_wdata  (ext_wdata),
        .stream_ready  (ext_ready)
    );

    soc_top dut (
        .clk           (clk),
        .rst           (rst),

        .ext_valid     (ext_valid),
        .ext_target    (ext_target),
        .ext_last      (ext_last),
        .ext_addr      (ext_addr),
        .ext_wdata     (ext_wdata),
        .ext_ready     (ext_ready),

        .gpio_in       (gpio_in),
        .gpio_out      (gpio_out),

        .uart_rx_valid (uart_rx_valid),
        .uart_rx_data  (uart_rx_data),
        .uart_rx_ready (uart_rx_ready),

        .uart_tx_valid (uart_tx_valid),
        .uart_tx_data  (uart_tx_data),
        .uart_tx_ready (uart_tx_ready),

        .load_done     (load_done)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        errors        = 0;
        gpio_in       = 64'd0;
        uart_rx_valid = 1'b0;
        uart_rx_data  = 8'd0;
        uart_tx_ready = 1'b0; // Hold TX byte until the TB observes it.

        rst = 1'b1;
        repeat (2) @(posedge clk);
        rst = 1'b0;

        wait (load_done === 1'b1);
        $display("UART TEST IMAGE LOAD COMPLETE");

        // Let the CPU reach LDUR UART_RXDATA. It should block while RX FIFO is empty.
        repeat (8) @(posedge clk);

        // External UART-side source sends one byte through ready/valid.
        @(negedge clk);
        uart_rx_data  = 8'h5A;
        uart_rx_valid = 1'b1;

        while (uart_rx_ready !== 1'b1)
            @(negedge clk);

        @(posedge clk);
        @(negedge clk);
        uart_rx_valid = 1'b0;

        // CPU should read 0x5A from RXDATA and write it to TXDATA.
        cycles = 0;
        while ((uart_tx_valid !== 1'b1) && (cycles < 100)) begin
            @(posedge clk);
            cycles = cycles + 1;
        end

        if (uart_tx_valid !== 1'b1) begin
            $display("[FAIL] UART TX byte was not produced");
            errors = errors + 1;
        end
        else begin
            $display("[PASS] UART TX valid observed");
        end

        if (uart_tx_data !== 8'h5A) begin
            $display("[FAIL] UART TX expected=5A actual=%h", uart_tx_data);
            errors = errors + 1;
        end
        else begin
            $display("[PASS] UART TX data = 5A");
        end

        if (dut.core.datapath.REG.registers[1] !== 64'h5A) begin
            $display("[FAIL] CPU x1 expected=5A actual=%h",
                     dut.core.datapath.REG.registers[1]);
            errors = errors + 1;
        end
        else begin
            $display("[PASS] CPU loaded UART RX byte into x1");
        end

        // External transmitter consumes the queued TX byte.
        uart_tx_ready = 1'b1;
        @(posedge clk);
        @(negedge clk);
        uart_tx_ready = 1'b0;

        if (uart_tx_valid !== 1'b0) begin
            $display("[FAIL] UART TX FIFO did not pop after ready handshake");
            errors = errors + 1;
        end
        else begin
            $display("[PASS] UART TX FIFO pop observed");
        end

        if (errors == 0) begin
            $display("SOC UART END-TO-END TEST PASSED");
            $finish;
        end
        else begin
            $display("SOC UART END-TO-END TEST FAILED: %0d error(s)", errors);
            $fatal(1, "SoC UART end-to-end regression failed");
        end
    end

endmodule
