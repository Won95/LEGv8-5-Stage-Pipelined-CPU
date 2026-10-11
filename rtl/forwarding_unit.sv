`timescale 1ns / 1ps

module forwardingunit (
    input  wire [4:0] Rm_id,
    input  wire [4:0] Rn_id,
    input  wire       UseRm_id,
    input  wire       UseRn_id,

    // Producers as seen while the consumer is still in ID.
    // The current EX instruction will be in MEM when the consumer reaches EX;
    // the current MEM instruction will be in WB.
    input  wire [4:0] Rd_ex,
    input  wire [4:0] Rd_mem,
    input  wire       Regwrite_ex,
    input  wire       Memread_ex,
    input  wire       Regwrite_mem,

    output logic [1:0] muxa_id,
    output logic [1:0] muxb_id
);

    wire ex_can_forward_next;
    wire mem_can_forward_next;

    // A load currently in EX cannot provide its data from next cycle's MEM
    // result path.  load-use hazard detection stalls the dependent consumer;
    // after that stall the load is in MEM and is selected as next cycle's WB
    // forwarding source instead.
    assign ex_can_forward_next =
        Regwrite_ex && !Memread_ex && (Rd_ex != 5'd31);

    assign mem_can_forward_next =
        Regwrite_mem && (Rd_mem != 5'd31);

    always_comb begin
        muxa_id = 2'b00;
        if (UseRn_id && ex_can_forward_next && (Rd_ex == Rn_id))
            muxa_id = 2'b10; // current EX -> future MEM
        else if (UseRn_id && mem_can_forward_next && (Rd_mem == Rn_id))
            muxa_id = 2'b01; // current MEM -> future WB

        muxb_id = 2'b00;
        if (UseRm_id && ex_can_forward_next && (Rd_ex == Rm_id))
            muxb_id = 2'b10; // current EX -> future MEM
        else if (UseRm_id && mem_can_forward_next && (Rd_mem == Rm_id))
            muxb_id = 2'b01; // current MEM -> future WB
    end

endmodule
