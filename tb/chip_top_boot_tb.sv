`timescale 1ns / 1ps

module chip_top_boot_tb;

    localparam integer CLK_FREQ_HZ = 10_000_000;
    localparam integer UART_BAUD   = 1_000_000;
    localparam integer CLKS_PER_BIT = CLK_FREQ_HZ / UART_BAUD;

    reg clk;
    reg rst;
    reg uart_rx;
    wire uart_tx;
    tri [31:0] gpio;
    wire load_done;

    integer errors;
    integer timeout_cycles;
    integer i;

    chip_top #(
        .CLK_FREQ_HZ (CLK_FREQ_HZ),
        .UART_BAUD   (UART_BAUD)
    ) dut (
        .clk       (clk),
        .rst       (rst),
        .uart_rx   (uart_rx),
        .uart_tx   (uart_tx),
        .gpio      (gpio),
        .load_done (load_done)
    );

    initial clk = 1'b0;
    always #50 clk = ~clk; // 10 MHz

    task uart_send_byte;
        input [7:0] value;
        integer bit_idx;
        begin
            @(negedge clk);
            uart_rx = 1'b0; // start bit
            repeat (CLKS_PER_BIT) @(posedge clk);

            for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
                @(negedge clk);
                uart_rx = value[bit_idx];
                repeat (CLKS_PER_BIT) @(posedge clk);
            end

            @(negedge clk);
            uart_rx = 1'b1; // stop bit
            repeat (CLKS_PER_BIT) @(posedge clk);
        end
    endtask

    task uart_send_u64_le;
        input [63:0] value;
        integer byte_idx;
        begin
            for (byte_idx = 0; byte_idx < 8; byte_idx = byte_idx + 1)
                uart_send_byte(value[byte_idx*8 +: 8]);
        end
    endtask

    task boot_packet;
        input        last;
        input        target;
        input [63:0] addr;
        input [63:0] data;
        begin
            uart_send_byte({6'd0, last, target});
            uart_send_u64_le(addr);
            uart_send_u64_le(data);
        end
    endtask

    task check_reg;
        input integer idx;
        input [63:0] expected;
        begin
            if (dut.soc.core.datapath.REG.registers[idx] !== expected) begin
                $display("[FAIL] x%0d expected=%0d actual=%0d",
                         idx, expected, dut.soc.core.datapath.REG.registers[idx]);
                errors = errors + 1;
            end
            else begin
                $display("[PASS] x%0d = %0d", idx, expected);
            end
        end
    endtask

    initial begin
        errors  = 0;
        uart_rx = 1'b1;
        rst     = 1'b1;

        repeat (4) @(posedge clk);
        rst = 1'b0;
        repeat (4) @(posedge clk);

        // Directed LEGv8 program -> IMEM. target=0, last=0.
        boot_packet(1'b0, 1'b0, 64'd0,  64'h0000_0000_8B02_0023);
        boot_packet(1'b0, 1'b0, 64'd4,  64'h0000_0000_CB01_0064);
        boot_packet(1'b0, 1'b0, 64'd8,  64'h0000_0000_8A03_0085);
        boot_packet(1'b0, 1'b0, 64'd12, 64'h0000_0000_AA04_00A6);
        boot_packet(1'b0, 1'b0, 64'd16, 64'h0000_0000_F840_1149);
        boot_packet(1'b0, 1'b0, 64'd20, 64'h0000_0000_8B01_012C);
        boot_packet(1'b0, 1'b0, 64'd24, 64'h0000_0000_CB02_018D);
        boot_packet(1'b0, 1'b0, 64'd28, 64'h0000_0000_CB01_002E);
        boot_packet(1'b0, 1'b0, 64'd32, 64'h0000_0000_B400_004E);
        boot_packet(1'b0, 1'b0, 64'd36, 64'h0000_0000_9100_0694);
        boot_packet(1'b0, 1'b0, 64'd40, 64'h0000_0000_9100_06B5);
        boot_packet(1'b0, 1'b0, 64'd44, 64'h0000_0000_9100_05EF);
        boot_packet(1'b0, 1'b0, 64'd48, 64'h0000_0000_B400_004F);
        boot_packet(1'b0, 1'b0, 64'd52, 64'h0000_0000_9100_06D6);
        boot_packet(1'b0, 1'b0, 64'd56, 64'h0000_0000_CB02_0050);
        boot_packet(1'b0, 1'b0, 64'd60, 64'h0000_0000_B400_0050);
        boot_packet(1'b0, 1'b0, 64'd64, 64'h0000_0000_9100_06F7);
        boot_packet(1'b0, 1'b0, 64'd68, 64'h0000_0000_9100_0718);
        boot_packet(1'b0, 1'b0, 64'd72, 64'h0000_0000_1400_0000);

        // Initial DMEM[12] = 99. Final record releases CPU after write completes.
        boot_packet(1'b1, 1'b1, 64'd12, 64'd99);

        timeout_cycles = 0;
        while ((load_done !== 1'b1) && (timeout_cycles < 1000)) begin
            @(posedge clk);
            timeout_cycles = timeout_cycles + 1;
        end

        if (load_done !== 1'b1) begin
            $display("[FAIL] UART boot did not reach load_done");
            $fatal(1, "chip_top UART boot timeout");
        end
        else begin
            $display("[PASS] UART boot load_done observed");
        end

        // Allow the program to execute and settle into the final B #0 loop.
        repeat (140) @(posedge clk);

        check_reg(1,  64'd2);
        check_reg(3,  64'd5);
        check_reg(9,  64'd99);
        check_reg(13, 64'd98);
        check_reg(22, 64'd24);
        check_reg(24, 64'd26);

        if (errors == 0) begin
            $display("CHIP TOP UART BOOT TEST PASSED");
            $finish;
        end
        else begin
            $display("CHIP TOP UART BOOT TEST FAILED: %0d error(s)", errors);
            $fatal(1, "chip_top UART boot regression failed");
        end
    end

endmodule
