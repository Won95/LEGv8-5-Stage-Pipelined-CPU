module hazarddetectionunit (
    input  wire [4:0] Rd_ex,
    input  wire       Memread_ex,
    input  wire [4:0] Rn_id,
    input  wire [4:0] Rm_id,
    input  wire       UseRn_id,
    input  wire       UseRm_id,
    output wire       hazardmux_id,
    output wire       idhold,
    output wire       pchold
);

    wire rn_dep;
    wire rm_dep;
    wire load_use_hazard;

    assign rn_dep = UseRn_id && (Rn_id == Rd_ex);
    assign rm_dep = UseRm_id && (Rm_id == Rd_ex);

    // Branches are resolved in EX, so they use the same one-cycle load-use
    // interlock as every other consumer.  The older ID-stage branch-specific
    // dependency chain is intentionally removed from the PC critical path.
    assign load_use_hazard =
        Memread_ex &&
        (Rd_ex != 5'd31) &&
        (rn_dep || rm_dep);

    assign hazardmux_id = load_use_hazard;
    assign idhold       = load_use_hazard;
    assign pchold       = load_use_hazard;

endmodule
