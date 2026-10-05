`timescale 1ns / 1ps

module top_tb;

    reg clk;
    reg rst;

    core dut(
        .clk(clk),
        .rst(rst)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;   // 10ns period

    initial begin
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

        $display("=========== REGISTER RESULT ===========");
        $display("x1  = %0d  (expected: 2)",   dut.datapath.REG.registers[1]);
        $display("x2  = %0d  (expected: 3)",   dut.datapath.REG.registers[2]);

        $display("x3  = %0d  (expected: 5)",   dut.datapath.REG.registers[3]);
        $display("x4  = %0d  (expected: 3)",   dut.datapath.REG.registers[4]);
        $display("x5  = %0d  (expected: 1)",   dut.datapath.REG.registers[5]);
        $display("x6  = %0d  (expected: 3)",   dut.datapath.REG.registers[6]);

        $display("x9  = %0d  (expected: 99)",  dut.datapath.REG.registers[9]);
        $display("x10 = %0d  (expected: 11)",  dut.datapath.REG.registers[10]);

        $display("x12 = %0d  (expected: 101)", dut.datapath.REG.registers[12]);
        $display("x13 = %0d  (expected: 98)",  dut.datapath.REG.registers[13]);

        $display("x14 = %0d  (expected: 0)",   dut.datapath.REG.registers[14]);
        $display("x15 = %0d  (expected: 17)",  dut.datapath.REG.registers[15]);
        $display("x16 = %0d  (expected: 0)",   dut.datapath.REG.registers[16]);

        $display("x20 = %0d  (expected: 21)",  dut.datapath.REG.registers[20]);
        $display("x21 = %0d  (expected: 23)",  dut.datapath.REG.registers[21]);
        $display("x22 = %0d  (expected: 24)",  dut.datapath.REG.registers[22]);
        $display("x23 = %0d  (expected: 24)",  dut.datapath.REG.registers[23]);
        $display("x24 = %0d  (expected: 26)",  dut.datapath.REG.registers[24]);

        $display("=======================================");

        $finish;
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
