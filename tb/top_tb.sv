`timescale 1ns / 1ps

module top_tb;

    reg clk;
    reg rst;

    integer pass_count;
    integer fail_count;

    core dut(
        .clk(clk),
        .rst(rst)
    );

    task check_reg;
        input integer reg_num;
        input [63:0] expected;
        begin
            if (dut.datapath.REG.registers[reg_num] === expected) begin
                $display("[PASS] x%0d = %0d", reg_num,
                         dut.datapath.REG.registers[reg_num]);
                pass_count = pass_count + 1;
            end
            else begin
                $display("[FAIL] x%0d expected=%0d actual=%0d",
                         reg_num,
                         expected,
                         dut.datapath.REG.registers[reg_num]);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial clk = 1'b0;
    always #5 clk = ~clk;   // 10ns period

    initial begin
        pass_count = 0;
        fail_count = 0;

        rst = 1'b1;
        #12;
        rst = 1'b0;

        // 충분히 길게 돌려야 instructionmemory[18]의 B #0 까지 감
        #500;

        $display("========== FINAL PIPELINE STATE ==========");
        $display("pc_if            = %0d", dut.datapath.pc_if);
        $display("instruction_if   = %h", dut.datapath.instruction_if);
        $display("instruction_id   = %h", dut.instruction_id);
        $display("PCSrc_id         = %b", dut.datapath.PCSrc_id);
        $display("pchold_id        = %b", dut.pchold_id);
        $display("idhold_id        = %b", dut.idhold_id);
        $display("hazardmux_id     = %b", dut.hazardmux_id);
        $display("fwdmuxa_ex       = %b", dut.fwdmuxa_ex);
        $display("fwdmuxb_ex       = %b", dut.fwdmuxb_ex);
        $display("Rd_ex            = %0d", dut.Rd_ex);
        $display("Rd_mem           = %0d", dut.Rd_mem);
        $display("Rd_wb            = %0d", dut.Rd_wb);
        $display("result_ex        = %0d", dut.datapath.result_ex);
        $display("result_mem       = %0d", dut.datapath.result_mem);
        $display("Regwritedata_wb  = %0d", dut.datapath.Regwritedata_wb);

        $display("=========== REGISTER CHECK =============");
        check_reg(1,  64'd2);
        check_reg(2,  64'd3);

        check_reg(3,  64'd5);
        check_reg(4,  64'd3);
        check_reg(5,  64'd1);
        check_reg(6,  64'd3);

        check_reg(9,  64'd99);
        check_reg(10, 64'd11);

        check_reg(12, 64'd101);
        check_reg(13, 64'd98);

        check_reg(14, 64'd0);
        check_reg(15, 64'd17);
        check_reg(16, 64'd0);

        check_reg(20, 64'd21);
        check_reg(21, 64'd23);
        check_reg(22, 64'd24);
        check_reg(23, 64'd24);
        check_reg(24, 64'd26);

        $display("=======================================");

        if (fail_count == 0) begin
            $display("ALL TESTS PASSED (%0d/%0d)", pass_count, pass_count);
            $finish;
        end
        else begin
            $display("TEST FAILED: %0d passed, %0d failed",
                     pass_count, fail_count);
            $fatal(1, "Register regression failed");
        end
    end

    // clk 상승엣지 기준으로 한 줄씩 출력
    always @(posedge clk) begin
        $display(
            "t=%0t | pc_if=%0d | if=%h | id=%h | hold(pcid/hz)=%b%b%b | PCSrc=%b | fwdA=%b fwdB=%b | Rm_id=%0d Rn_id=%0d Rd_id=%0d | Rd_ex=%0d Rd_mem=%0d Rd_wb=%0d | MemR_ex=%b Mem2R_mem=%b RegW(mem/wb)=%b%b | result_ex=%0d result_mem=%0d wbdata=%0d",
            $time,
            dut.datapath.pc_if,
            dut.datapath.instruction_if,
            dut.instruction_id,
            dut.pchold_id,
            dut.idhold_id,
            dut.hazardmux_id,
            dut.datapath.PCSrc_id,
            dut.fwdmuxa_ex,
            dut.fwdmuxb_ex,
            dut.Rm_id,
            dut.Rn_id,
            dut.datapath.Rd_id,
            dut.Rd_ex,
            dut.Rd_mem,
            dut.Rd_wb,
            dut.Memread_ex,
            dut.MemtoReg_mem,
            dut.Regwrite_mem,
            dut.Regwrite_wb,
            dut.datapath.result_ex,
            dut.datapath.result_mem,
            dut.datapath.Regwritedata_wb
        );
    end

endmodule
