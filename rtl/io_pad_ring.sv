module io_pad_ring (
`ifdef USE_POWER_PINS
    // Internal core / I/O power-domain rails.
    inout wire        vccd1,
    inout wire        vssd1,
    inout wire        vddio,
    inout wire        vssio,
    inout wire        vdda,
    inout wire        vssa,
    inout wire        vswitch,
    inout wire        vcchib,
    inout wire        vddio_q,
    inout wire        vssio_q,
`endif

    // Physical package-facing power pads.
    inout wire        pad_vccd,
    inout wire        pad_vssd,
    inout wire        pad_vddio,
    inout wire        pad_vssio,
    inout wire        pad_vdda,
    inout wire        pad_vssa,

    // Physical package-facing signal pads.
    inout wire        pad_clk,
    inout wire        pad_rst,
    inout wire [15:0] pad_gpio,

    // Core-facing signals.
    output wire        core_clk,
    output wire        core_rst,
    input  wire [15:0] gpio_out,
    input  wire [15:0] gpio_oe,
    output wire [15:0] gpio_in
);

    // The analog mux buses are unused by this digital-only project, but the
    // pad macros share them physically around the I/O ring.
    wire amuxbus_a;
    wire amuxbus_b;

`ifdef USE_POWER_PINS
    /*======================================================================
      Package power / ground pads

      The clamped pads provide the package-facing bond pads and the padframe
      ESD structures.  The logical rails remain explicit because OpenLane PDN
      and the SRAM macros currently use vccd1/vssd1 directly.

      Padframe physical integration must additionally include the Sky130
      connect/filler slices so the abutment rails are continuous around the
      ring.  In particular, the physical connect slice joins VCCHIB<->VCCD
      and VSWITCH<->VDDIO.
      ======================================================================*/

    sky130_ef_io__vccd_lvc_clamped_pad u_vccd_pad (
        .AMUXBUS_A (amuxbus_a),
        .AMUXBUS_B (amuxbus_b),
        .VSSA      (vssa),
        .VDDA      (vdda),
        .VSWITCH   (vswitch),
        .VDDIO_Q   (vddio_q),
        .VCCHIB    (vcchib),
        .VDDIO     (vddio),
        .VCCD      (vccd1),
        .VCCD_PAD  (pad_vccd),
        .VSSIO     (vssio),
        .VSSD      (vssd1),
        .VSSIO_Q   (vssio_q)
    );

    sky130_ef_io__vssd_lvc_clamped_pad u_vssd_pad (
        .AMUXBUS_A (amuxbus_a),
        .AMUXBUS_B (amuxbus_b),
        .VSSA      (vssa),
        .VDDA      (vdda),
        .VSWITCH   (vswitch),
        .VDDIO_Q   (vddio_q),
        .VCCHIB    (vcchib),
        .VDDIO     (vddio),
        .VCCD      (vccd1),
        .VSSIO     (vssio),
        .VSSD      (vssd1),
        .VSSD_PAD  (pad_vssd),
        .VSSIO_Q   (vssio_q)
    );

    sky130_ef_io__vddio_hvc_clamped_pad u_vddio_pad (
        .AMUXBUS_A (amuxbus_a),
        .AMUXBUS_B (amuxbus_b),
        .VSSA      (vssa),
        .VDDA      (vdda),
        .VSWITCH   (vswitch),
        .VDDIO_Q   (vddio_q),
        .VCCHIB    (vcchib),
        .VDDIO     (vddio),
        .VDDIO_PAD (pad_vddio),
        .VCCD      (vccd1),
        .VSSIO     (vssio),
        .VSSD      (vssd1),
        .VSSIO_Q   (vssio_q)
    );

    sky130_ef_io__vssio_hvc_clamped_pad u_vssio_pad (
        .AMUXBUS_A (amuxbus_a),
        .AMUXBUS_B (amuxbus_b),
        .VSSA      (vssa),
        .VDDA      (vdda),
        .VSWITCH   (vswitch),
        .VDDIO_Q   (vddio_q),
        .VCCHIB    (vcchib),
        .VDDIO     (vddio),
        .VCCD      (vccd1),
        .VSSIO     (vssio),
        .VSSIO_PAD (pad_vssio),
        .VSSD      (vssd1),
        .VSSIO_Q   (vssio_q)
    );

    sky130_ef_io__vdda_hvc_clamped_pad u_vdda_pad (
        .AMUXBUS_A (amuxbus_a),
        .AMUXBUS_B (amuxbus_b),
        .VSSA      (vssa),
        .VDDA      (vdda),
        .VDDA_PAD  (pad_vdda),
        .VSWITCH   (vswitch),
        .VDDIO_Q   (vddio_q),
        .VCCHIB    (vcchib),
        .VDDIO     (vddio),
        .VCCD      (vccd1),
        .VSSIO     (vssio),
        .VSSD      (vssd1),
        .VSSIO_Q   (vssio_q)
    );

    sky130_ef_io__vssa_hvc_clamped_pad u_vssa_pad (
        .AMUXBUS_A (amuxbus_a),
        .AMUXBUS_B (amuxbus_b),
        .VSSA      (vssa),
        .VSSA_PAD  (pad_vssa),
        .VDDA      (vdda),
        .VSWITCH   (vswitch),
        .VDDIO_Q   (vddio_q),
        .VCCHIB    (vcchib),
        .VDDIO     (vddio),
        .VCCD      (vccd1),
        .VSSIO     (vssio),
        .VSSD      (vssd1),
        .VSSIO_Q   (vssio_q)
    );
`endif

    /*======================================================================
      Clock input pad

      DM=001 and OE_N=1 disable the output driver.  INP_DIS=0 keeps the
      digital input path enabled, so PAD -> IN becomes the internal clock.
      ======================================================================*/
    sky130_ef_io__gpiov2_pad u_clk_pad (
        .IN_H           (),
        .PAD_A_NOESD_H  (),
        .PAD_A_ESD_0_H  (),
        .PAD_A_ESD_1_H  (),
        .PAD             (pad_clk),
        .DM              (3'b001),
        .HLD_H_N         (1'b1),
        .IN              (core_clk),
        .INP_DIS         (1'b0),
        .IB_MODE_SEL     (1'b0),
        .ENABLE_H        (1'b1),
        .ENABLE_VDDA_H   (1'b1),
        .ENABLE_INP_H    (1'b1),
        .OE_N            (1'b1),
        .TIE_HI_ESD      (),
        .TIE_LO_ESD      (),
        .SLOW            (1'b0),
        .VTRIP_SEL       (1'b0),
        .HLD_OVR         (1'b0),
        .ANALOG_EN       (1'b0),
        .ANALOG_SEL      (1'b0),
        .ENABLE_VDDIO    (1'b1),
        .ENABLE_VSWITCH_H(1'b1),
        .ANALOG_POL      (1'b0),
        .OUT             (1'b0),
        .AMUXBUS_A       (amuxbus_a),
        .AMUXBUS_B       (amuxbus_b),
`ifdef USE_POWER_PINS
        .VSSA            (vssa),
        .VDDA            (vdda),
        .VSWITCH         (vswitch),
        .VDDIO_Q         (vddio_q),
        .VCCHIB          (vcchib),
        .VDDIO           (vddio),
        .VCCD            (vccd1),
        .VSSIO           (vssio),
        .VSSD            (vssd1),
        .VSSIO_Q         (vssio_q)
`else
        .VSSA            (),
        .VDDA            (),
        .VSWITCH         (),
        .VDDIO_Q         (),
        .VCCHIB          (),
        .VDDIO           (),
        .VCCD            (),
        .VSSIO           (),
        .VSSD            (),
        .VSSIO_Q         ()
`endif
    );

    /*======================================================================
      Reset input pad

      The project uses an active-high reset, so the pad input is connected
      directly to core_rst.  A dedicated XRES pad can replace this cell later
      without changing soc_top.
      ======================================================================*/
    sky130_ef_io__gpiov2_pad u_rst_pad (
        .IN_H           (),
        .PAD_A_NOESD_H  (),
        .PAD_A_ESD_0_H  (),
        .PAD_A_ESD_1_H  (),
        .PAD             (pad_rst),
        .DM              (3'b001),
        .HLD_H_N         (1'b1),
        .IN              (core_rst),
        .INP_DIS         (1'b0),
        .IB_MODE_SEL     (1'b0),
        .ENABLE_H        (1'b1),
        .ENABLE_VDDA_H   (1'b1),
        .ENABLE_INP_H    (1'b1),
        .OE_N            (1'b1),
        .TIE_HI_ESD      (),
        .TIE_LO_ESD      (),
        .SLOW            (1'b0),
        .VTRIP_SEL       (1'b0),
        .HLD_OVR         (1'b0),
        .ANALOG_EN       (1'b0),
        .ANALOG_SEL      (1'b0),
        .ENABLE_VDDIO    (1'b1),
        .ENABLE_VSWITCH_H(1'b1),
        .ANALOG_POL      (1'b0),
        .OUT             (1'b0),
        .AMUXBUS_A       (amuxbus_a),
        .AMUXBUS_B       (amuxbus_b),
`ifdef USE_POWER_PINS
        .VSSA            (vssa),
        .VDDA            (vdda),
        .VSWITCH         (vswitch),
        .VDDIO_Q         (vddio_q),
        .VCCHIB          (vcchib),
        .VDDIO           (vddio),
        .VCCD            (vccd1),
        .VSSIO           (vssio),
        .VSSD            (vssd1),
        .VSSIO_Q         (vssio_q)
`else
        .VSSA            (),
        .VDDA            (),
        .VSWITCH         (),
        .VDDIO_Q         (),
        .VCCHIB          (),
        .VDDIO           (),
        .VCCD            (),
        .VSSIO           (),
        .VSSD            (),
        .VSSIO_Q         ()
`endif
    );

    /*======================================================================
      16 bidirectional GPIO pads

      DM=110 selects strong push-pull drive when OE_N is low.  OE_N is the
      active-low form of the MMIO GPIO_OE bit.  The input buffer remains
      enabled so software can also read back the physical pad state.
      ======================================================================*/
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : GPIO_PADS
            sky130_ef_io__gpiov2_pad u_gpio_pad (
                .IN_H           (),
                .PAD_A_NOESD_H  (),
                .PAD_A_ESD_0_H  (),
                .PAD_A_ESD_1_H  (),
                .PAD             (pad_gpio[i]),
                .DM              (3'b110),
                .HLD_H_N         (1'b1),
                .IN              (gpio_in[i]),
                .INP_DIS         (1'b0),
                .IB_MODE_SEL     (1'b0),
                .ENABLE_H        (1'b1),
                .ENABLE_VDDA_H   (1'b1),
                .ENABLE_INP_H    (1'b1),
                .OE_N            (~gpio_oe[i]),
                .TIE_HI_ESD      (),
                .TIE_LO_ESD      (),
                .SLOW            (1'b0),
                .VTRIP_SEL       (1'b0),
                .HLD_OVR         (1'b0),
                .ANALOG_EN       (1'b0),
                .ANALOG_SEL      (1'b0),
                .ENABLE_VDDIO    (1'b1),
                .ENABLE_VSWITCH_H(1'b1),
                .ANALOG_POL      (1'b0),
                .OUT             (gpio_out[i]),
                .AMUXBUS_A       (amuxbus_a),
                .AMUXBUS_B       (amuxbus_b),
`ifdef USE_POWER_PINS
                .VSSA            (vssa),
                .VDDA            (vdda),
                .VSWITCH         (vswitch),
                .VDDIO_Q         (vddio_q),
                .VCCHIB          (vcchib),
                .VDDIO           (vddio),
                .VCCD            (vccd1),
                .VSSIO           (vssio),
                .VSSD            (vssd1),
                .VSSIO_Q         (vssio_q)
`else
                .VSSA            (),
                .VDDA            (),
                .VSWITCH         (),
                .VDDIO_Q         (),
                .VCCHIB          (),
                .VDDIO           (),
                .VCCD            (),
                .VSSIO           (),
                .VSSD            (),
                .VSSIO_Q         ()
`endif
            );
        end
    endgenerate

endmodule
