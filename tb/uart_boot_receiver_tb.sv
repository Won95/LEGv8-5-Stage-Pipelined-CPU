`timescale 1ns / 1ps

module uart_boot_receiver_tb;

    reg clk;
    reg rst;

    reg        byte_valid;
    reg [7:0]  byte_data;
    wire       byte_ready;

    wire        ext_valid;
    wire        ext_target;
    wire        ext_last;
    wire [63:0] ext_addr;
    wire [63:0] ext_wdata;
    reg         ext_ready;

    integer errors;

    uart_boot_receiver dut (
        .clk        (clk),
        .rst        (rst),
        .byte_valid (byte_valid),
        .byte_data  (byte_data),
        .byte_ready (byte_ready),
        .ext_valid  (ext_valid),
        .ext_target (ext_target),
        .ext_last   (ext_last),
        .ext_addr   (ext_addr),
        .ext_wdata  (ext_wdata),
        .ext_ready  (ext_ready)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task send_byte;
        input [7:0] value;
        begin
            while (byte_ready !== 1'b1)
                @(posedge clk);
            @(negedge clk);
            byte_data  = value;
            byte_valid = 1'b1;
            @(posedge clk);
            @(negedge clk);
            byte_valid = 1'b0;
        end
    endtask

    initial begin
        errors     = 0;
        byte_valid = 1'b0;
        byte_data  = 8'd0;
        ext_ready  = 1'b0;

        rst = 1'b1;
        repeat (2) @(posedge clk);
        rst = 1'b0;

        // control: last=1, target=1
        send_byte(8'h03);

        // address 0x1122334455667788, little-endian
        send_byte(8'h88);
        send_byte(8'h77);
        send_byte(8'h66);
        send_byte(8'h55);
        send_byte(8'h44);
        send_byte(8'h33);
        send_byte(8'h22);
        send_byte(8'h11);

        // data 0xAABBCCDDEEFF0011, little-endian
        send_byte(8'h11);
        send_byte(8'h00);
        send_byte(8'hFF);
        send_byte(8'hEE);
        send_byte(8'hDD);
        send_byte(8'hCC);
        send_byte(8'hBB);
        send_byte(8'hAA);

        @(posedge clk);

        if (ext_valid !== 1'b1) begin
            $display("[FAIL] ext_valid not asserted");
            errors = errors + 1;
        end
        if (ext_target !== 1'b1) begin
            $display("[FAIL] target expected 1 actual=%b", ext_target);
            errors = errors + 1;
        end
        if (ext_last !== 1'b1) begin
            $display("[FAIL] last expected 1 actual=%b", ext_last);
            errors = errors + 1;
        end
        if (ext_addr !== 64'h1122_3344_5566_7788) begin
            $display("[FAIL] addr expected=1122334455667788 actual=%h", ext_addr);
            errors = errors + 1;
        end
        if (ext_wdata !== 64'hAABB_CCDD_EEFF_0011) begin
            $display("[FAIL] data expected=AABBCCDDEEFF0011 actual=%h", ext_wdata);
            errors = errors + 1;
        end

        ext_ready = 1'b1;
        @(posedge clk);
        @(negedge clk);
        ext_ready = 1'b0;

        if (ext_valid !== 1'b0) begin
            $display("[FAIL] ext_valid did not clear after handshake");
            errors = errors + 1;
        end

        if (errors == 0) begin
            $display("UART BOOT RECEIVER TEST PASSED");
            $finish;
        end
        else begin
            $display("UART BOOT RECEIVER TEST FAILED: %0d error(s)", errors);
            $fatal(1, "UART boot receiver regression failed");
        end
    end

endmodule
