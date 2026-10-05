`timescale 1ns / 1ps

module top_tb;

    reg clk;
    reg rst;

    integer pass_count;
    integer fail_count;

    // Pipeline event coverage flags
    reg saw_stall;
    reg saw_fwd_a_mem;
    reg saw_fwd_a_wb;
    reg saw_fwd_b_mem;
    reg saw_fwd_b_wb;
    reg saw_cbz_taken;
    reg saw_cbz_not_taken;
    reg saw_uncond_branch;

    // Exact event counters for the current directed program
    integer stall_count;
    integer fwd_a_mem_count;
    integer fwd_a_wb_count;
    integer fwd_b_mem_count;
    integer fwd_b_wb_count;

    // PC-specific microarchitecture checks
    reg saw_stall_pc20;
    reg saw_stall_pc32;
    reg saw_stall_pc48;
    reg saw_stall_pc60;

    reg saw_cbz_pc32_taken;
    reg saw_cbz_pc48_not_taken;
    reg saw_cbz_pc60_taken;
    reg saw_b_pc72_taken;

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

    task check_event;
        input [8*40-1:0] event_name;
        input observed;
        begin
            if (observed === 1'b1) begin
                $display("[PASS] %0s observed", event_name);
                pass_count = pass_count + 1;
            end
            else begin
                $display("[FAIL] %0s was not observed", event_name);
                fail_count = fail_count + 1;
            end
        end
    endtask

    task check_count;
        input [8*40-1:0] event_name;
        input integer actual;
        input integer expected;
        begin
            if (actual == expected) begin
                $display("[PASS] %0s count = %0d", event_name, actual);
                pass_count = pass_count + 1;
            end
            else begin
                $display("[FAIL] %0s count expected=%0d actual=%0d",
                         event_name, expected, actual);
                fail_count = fail_count + 1;
            end
        end
    endtask

    initial clk = 1'b0;
    always #5 clk = ~clk;   // 10ns period

    initial begin
        pass_count = 0;
        fail_count = 0;

        saw_stall = 1'b0;
        saw_fwd_a_mem = 1'b0;
        saw_fwd_a_wb = 1'b0;
        saw_fwd_b_mem = 1'b0;
        saw_fwd_b_wb = 1'b0;
        saw_cbz_taken = 1'b0;
        saw_cbz_not_taken = 1'b0;
        saw_uncond_branch = 1'b0;

        stall_count = 0;
        fwd_a_mem_count = 0;
        fwd_a_wb_count = 0;
        fwd_b_mem_count = 0;
        fwd_b_wb_count = 0;

        saw_stall_pc20 = 1'b0;
        saw_stall_pc32 = 1'b0;
        saw_stall_pc48 = 1'b0;
        saw_stall_pc60 = 1'b0;

        saw_cbz_pc32_taken = 1'b0;
        saw_cbz_pc48_not_taken = 1'b0;
        saw_cbz_pc60_taken = 1'b0;
        saw_b_pc72_taken = 1'b0;

        rst = 1'b1;
        #12;
        rst = 1'b0;

        // Run long enough to reach instructionmemory[18] and observe B #0.
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

        $display("=========== PIPELINE EVENT CHECK ========");
        check_event("stall",                saw_stall);
        check_event("forward A from MEM",   saw_fwd_a_mem);
        check_event("forward A from WB",    saw_fwd_a_wb);
        check_event("forward B from MEM",   saw_fwd_b_mem);
        check_event("forward B from WB",    saw_fwd_b_wb);
        check_event("CBZ taken",            saw_cbz_taken);
        check_event("CBZ not taken",        saw_cbz_not_taken);
        check_event("unconditional branch", saw_uncond_branch);

        $display("=========== STRICT EVENT CHECK ========== ");
        check_count("stall",              stall_count,     4);
        check_count("forward A from MEM", fwd_a_mem_count, 5);
        check_count("forward A from WB",  fwd_a_wb_count,  1);
        check_count("forward B from MEM", fwd_b_mem_count, 3);
        check_count("forward B from WB",  fwd_b_wb_count,  5);

        check_event("stall at ID PC=20",   saw_stall_pc20);
        check_event("stall at ID PC=32",   saw_stall_pc32);
        check_event("stall at ID PC=48",   saw_stall_pc48);
        check_event("stall at ID PC=60",   saw_stall_pc60);

        check_event("CBZ taken at PC=32",      saw_cbz_pc32_taken);
        check_event("CBZ not taken at PC=48",  saw_cbz_pc48_not_taken);
        check_event("CBZ taken at PC=60",      saw_cbz_pc60_taken);
        check_event("B taken at PC=72",        saw_b_pc72_taken);

        $display("=======================================");

        if (fail_count == 0) begin
            $display("ALL TESTS PASSED (%0d/%0d)",
                     pass_count, pass_count + fail_count);
            $finish;
        end
        else begin
            $display("TEST FAILED: %0d passed, %0d failed",
                     pass_count, fail_count);
            $fatal(1, "CPU regression failed");
        end
    end

    // Observe pipeline events during execution.
    always @(posedge clk) begin
        if (!rst) begin
            // Stall: freeze PC/ID and inject a bubble through the control mux.
            if (dut.pchold_id && dut.idhold_id && dut.hazardmux_id) begin
                saw_stall <= 1'b1;
                stall_count <= stall_count + 1;

                case (dut.datapath.pc_id)
                    64'd20: saw_stall_pc20 <= 1'b1;
                    64'd32: saw_stall_pc32 <= 1'b1;
                    64'd48: saw_stall_pc48 <= 1'b1;
                    64'd60: saw_stall_pc60 <= 1'b1;
                    default: ;
                endcase
            end

            // Forwarding mux encoding: 01 = WB, 10 = MEM.
            if (dut.fwdmuxa_ex == 2'b10) begin
                saw_fwd_a_mem <= 1'b1;
                fwd_a_mem_count <= fwd_a_mem_count + 1;
            end
            if (dut.fwdmuxa_ex == 2'b01) begin
                saw_fwd_a_wb <= 1'b1;
                fwd_a_wb_count <= fwd_a_wb_count + 1;
            end
            if (dut.fwdmuxb_ex == 2'b10) begin
                saw_fwd_b_mem <= 1'b1;
                fwd_b_mem_count <= fwd_b_mem_count + 1;
            end
            if (dut.fwdmuxb_ex == 2'b01) begin
                saw_fwd_b_wb <= 1'b1;
                fwd_b_wb_count <= fwd_b_wb_count + 1;
            end

            // Branch checks at the exact ID-stage PC of the directed program.
            if (dut.Branch_id && !dut.idhold_id) begin
                if (dut.datapath.PCSrc_id) begin
                    saw_cbz_taken <= 1'b1;
                    if (dut.datapath.pc_id == 64'd32)
                        saw_cbz_pc32_taken <= 1'b1;
                    if (dut.datapath.pc_id == 64'd60)
                        saw_cbz_pc60_taken <= 1'b1;
                end
                else begin
                    saw_cbz_not_taken <= 1'b1;
                    if (dut.datapath.pc_id == 64'd48)
                        saw_cbz_pc48_not_taken <= 1'b1;
                end
            end

            if (dut.Unconditionbranch_id && dut.datapath.PCSrc_id) begin
                saw_uncond_branch <= 1'b1;
                if (dut.datapath.pc_id == 64'd72)
                    saw_b_pc72_taken <= 1'b1;
            end
        end

        $display(
            "t=%0t | pc_if=%0d | pc_id=%0d | if=%h | id=%h | hold(pcid/hz)=%b%b%b | PCSrc=%b | fwdA=%b fwdB=%b | Rm_id=%0d Rn_id=%0d Rd_id=%0d | Rd_ex=%0d Rd_mem=%0d Rd_wb=%0d | MemR_ex=%b Mem2R_mem=%b RegW(mem/wb)=%b%b | result_ex=%0d result_mem=%0d wbdata=%0d",
            $time,
            dut.datapath.pc_if,
            dut.datapath.pc_id,
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
