`timescale 1ns / 1ps

module soc_top_tb;

    reg clk;
    reg rst;

    reg         boot_mode;
    reg         boot_valid;
    reg         boot_target;
    reg  [63:0] boot_addr;
    reg  [63:0] boot_wdata;
    wire        boot_ready;

    integer pass_count;
    integer fail_count;
    integer assertion_fail_count;

    reg prev_stall;
    reg [63:0] prev_pc_if;

    reg saw_stall;
    reg saw_fwd_a_mem;
    reg saw_fwd_a_wb;
    reg saw_fwd_b_mem;
    reg saw_fwd_b_wb;
    reg saw_cbz_taken;
    reg saw_cbz_not_taken;
    reg saw_uncond_branch;

    integer stall_count;
    integer fwd_a_mem_count;
    integer fwd_a_wb_count;
    integer fwd_b_mem_count;
    integer fwd_b_wb_count;

    reg saw_stall_pc20;
    reg saw_stall_pc32;
    reg saw_stall_pc48;
    reg saw_stall_pc60;

    reg saw_cbz_pc32_taken;
    reg saw_cbz_pc48_not_taken;
    reg saw_cbz_pc60_taken;
    reg saw_b_pc72_taken;

    soc_top dut(
        .clk(clk),
        .rst(rst),
        .boot_mode(boot_mode),
        .boot_valid(boot_valid),
        .boot_target(boot_target),
        .boot_addr(boot_addr),
        .boot_wdata(boot_wdata),
        .boot_ready(boot_ready)
    );

    task check_reg;
        input integer reg_num;
        input [63:0] expected;
        begin
            if (dut.core.datapath.REG.registers[reg_num] === expected) begin
                $display("[PASS] x%0d = %0d", reg_num,
                         dut.core.datapath.REG.registers[reg_num]);
                pass_count = pass_count + 1;
            end
            else begin
                $display("[FAIL] x%0d expected=%0d actual=%0d",
                         reg_num,
                         expected,
                         dut.core.datapath.REG.registers[reg_num]);
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

    // External loader model: future FIFO/IO logic will drive the same transaction.
    task boot_write_dmem;
        input [63:0] addr;
        input [63:0] data;
        begin
            @(negedge clk);
            boot_target = 1'b1; // DMEM
            boot_addr   = addr;
            boot_wdata  = data;
            boot_valid  = 1'b1;

            while (boot_ready !== 1'b1)
                @(negedge clk);

            boot_valid = 1'b0;
            @(negedge clk);
        end
    endtask

    initial clk = 1'b0;
    always #5 clk = ~clk;

    initial begin
        pass_count = 0;
        fail_count = 0;
        assertion_fail_count = 0;

        prev_stall = 1'b0;
        prev_pc_if = 64'd0;

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

        boot_mode   = 1'b1;
        boot_valid  = 1'b0;
        boot_target = 1'b1;
        boot_addr   = 64'd0;
        boot_wdata  = 64'd0;

        rst = 1'b1;
        #12;
        rst = 1'b0;

        // No SRAM backdoor preload: write through the external boot interface.
        boot_write_dmem(64'd12, 64'd99);
        $display("BOOT DMEM WRITE COMPLETE: addr=12 data=99");

        // Loader releases ownership; CPU starts from reset state on next posedge.
        boot_mode = 1'b0;

        #500;

        $display("========== FINAL PIPELINE STATE ==========");
        $display("pc_if            = %0d", dut.core.datapath.pc_if);
        $display("instruction_if   = %h", dut.core.datapath.instruction_if);
        $display("instruction_id   = %h", dut.core.instruction_id);
        $display("PCSrc_id         = %b", dut.core.datapath.PCSrc_id);
        $display("pchold_id        = %b", dut.core.pchold_id);
        $display("idhold_id        = %b", dut.core.idhold_id);
        $display("hazardmux_id     = %b", dut.core.hazardmux_id);
        $display("fwdmuxa_ex       = %b", dut.core.fwdmuxa_ex);
        $display("fwdmuxb_ex       = %b", dut.core.fwdmuxb_ex);
        $display("Rd_ex            = %0d", dut.core.Rd_ex);
        $display("Rd_mem           = %0d", dut.core.Rd_mem);
        $display("Rd_wb            = %0d", dut.core.Rd_wb);
        $display("result_ex        = %0d", dut.core.datapath.result_ex);
        $display("result_mem       = %0d", dut.core.datapath.result_mem);
        $display("Regwritedata_wb  = %0d", dut.core.datapath.Regwritedata_wb);

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

        $display("=========== ASSERTION SUMMARY ===========");
        if (assertion_fail_count == 0) begin
            $display("[PASS] runtime assertions: no failures");
            pass_count = pass_count + 1;
        end
        else begin
            $display("[FAIL] runtime assertions: %0d failure(s)",
                     assertion_fail_count);
            fail_count = fail_count + 1;
        end

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

    always @(posedge clk) begin
        if (!dut.core_rst) begin
            assert (({dut.core.pchold_id, dut.core.idhold_id, dut.core.hazardmux_id} == 3'b000) ||
                    ({dut.core.pchold_id, dut.core.idhold_id, dut.core.hazardmux_id} == 3'b111))
            else begin
                $error("ASSERT: inconsistent stall controls at t=%0t: pchold=%b idhold=%b hazardmux=%b",
                       $time, dut.core.pchold_id, dut.core.idhold_id, dut.core.hazardmux_id);
                assertion_fail_count = assertion_fail_count + 1;
            end

            assert (((dut.core.fwdmuxa_ex == 2'b00) ||
                     (dut.core.fwdmuxa_ex == 2'b01) ||
                     (dut.core.fwdmuxa_ex == 2'b10)) &&
                    ((dut.core.fwdmuxb_ex == 2'b00) ||
                     (dut.core.fwdmuxb_ex == 2'b01) ||
                     (dut.core.fwdmuxb_ex == 2'b10)))
            else begin
                $error("ASSERT: illegal forwarding select at t=%0t: fwdA=%b fwdB=%b",
                       $time, dut.core.fwdmuxa_ex, dut.core.fwdmuxb_ex);
                assertion_fail_count = assertion_fail_count + 1;
            end

            if (prev_stall) begin
                assert (dut.core.datapath.pc_if == prev_pc_if)
                else begin
                    $error("ASSERT: PC changed during stall at t=%0t: previous=%0d current=%0d",
                           $time, prev_pc_if, dut.core.datapath.pc_if);
                    assertion_fail_count = assertion_fail_count + 1;
                end
            end

            if (dut.core.pchold_id && dut.core.idhold_id && dut.core.hazardmux_id) begin
                saw_stall <= 1'b1;
                stall_count <= stall_count + 1;

                case (dut.core.datapath.pc_id)
                    64'd20: saw_stall_pc20 <= 1'b1;
                    64'd32: saw_stall_pc32 <= 1'b1;
                    64'd48: saw_stall_pc48 <= 1'b1;
                    64'd60: saw_stall_pc60 <= 1'b1;
                    default: ;
                endcase
            end

            // mem_wait 동안 EX state가 hold되므로 동일 forwarding 상태를 중복 count하지 않는다.
            if (!dut.core.datapath.mem_wait && dut.core.fwdmuxa_ex == 2'b10) begin
                saw_fwd_a_mem <= 1'b1;
                fwd_a_mem_count <= fwd_a_mem_count + 1;
            end
            if (!dut.core.datapath.mem_wait && dut.core.fwdmuxa_ex == 2'b01) begin
                saw_fwd_a_wb <= 1'b1;
                fwd_a_wb_count <= fwd_a_wb_count + 1;
            end
            if (!dut.core.datapath.mem_wait && dut.core.fwdmuxb_ex == 2'b10) begin
                saw_fwd_b_mem <= 1'b1;
                fwd_b_mem_count <= fwd_b_mem_count + 1;
            end
            if (!dut.core.datapath.mem_wait && dut.core.fwdmuxb_ex == 2'b01) begin
                saw_fwd_b_wb <= 1'b1;
                fwd_b_wb_count <= fwd_b_wb_count + 1;
            end

            if (dut.core.Branch_id && !dut.core.idhold_id) begin
                if (dut.core.datapath.PCSrc_id) begin
                    saw_cbz_taken <= 1'b1;
                    if (dut.core.datapath.pc_id == 64'd32)
                        saw_cbz_pc32_taken <= 1'b1;
                    if (dut.core.datapath.pc_id == 64'd60)
                        saw_cbz_pc60_taken <= 1'b1;
                end
                else begin
                    saw_cbz_not_taken <= 1'b1;
                    if (dut.core.datapath.pc_id == 64'd48)
                        saw_cbz_pc48_not_taken <= 1'b1;
                end
            end

            if (dut.core.Unconditionbranch_id && dut.core.datapath.PCSrc_id) begin
                saw_uncond_branch <= 1'b1;
                if (dut.core.datapath.pc_id == 64'd72)
                    saw_b_pc72_taken <= 1'b1;
            end

            prev_stall <= dut.core.pchold_id && dut.core.idhold_id && dut.core.hazardmux_id;
            prev_pc_if <= dut.core.datapath.pc_if;
        end
        else begin
            prev_stall <= 1'b0;
            prev_pc_if <= 64'd0;
        end

        $display(
            "t=%0t | pc_if=%0d | pc_id=%0d | if=%h | id=%h | hold(pcid/hz)=%b%b%b | PCSrc=%b | fwdA=%b fwdB=%b | Rm_id=%0d Rn_id=%0d Rd_id=%0d | Rd_ex=%0d Rd_mem=%0d Rd_wb=%0d | MemR_ex=%b Mem2R_mem=%b RegW(mem/wb)=%b%b | result_ex=%0d result_mem=%0d wbdata=%0d",
            $time,
            dut.core.datapath.pc_if,
            dut.core.datapath.pc_id,
            dut.core.datapath.instruction_if,
            dut.core.instruction_id,
            dut.core.pchold_id,
            dut.core.idhold_id,
            dut.core.hazardmux_id,
            dut.core.datapath.PCSrc_id,
            dut.core.fwdmuxa_ex,
            dut.core.fwdmuxb_ex,
            dut.core.Rm_id,
            dut.core.Rn_id,
            dut.core.datapath.Rd_id,
            dut.core.Rd_ex,
            dut.core.Rd_mem,
            dut.core.Rd_wb,
            dut.core.Memread_ex,
            dut.core.MemtoReg_mem,
            dut.core.Regwrite_mem,
            dut.core.Regwrite_wb,
            dut.core.datapath.result_ex,
            dut.core.datapath.result_mem,
            dut.core.datapath.Regwritedata_wb
        );
    end

endmodule
