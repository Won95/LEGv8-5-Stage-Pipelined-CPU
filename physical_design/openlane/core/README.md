# core_pd_top OpenLane configuration

This directory contains the standalone CPU-core physical-design setup used before hard SRAM and chip-level I/O integration.

## Configuration files

- `config.yaml`
  - Human-editable master configuration.
  - Run with `openlane --flow Classic config.yaml`.
- `config.json`
  - JSON mirror used when a pure JSON configuration is preferred.
- `top.con`
  - OpenROAD/OpenSTA timing constraints used for PnR and signoff STA.

Keep `config.yaml`, `config.json`, and `top.con` synchronized when changing the timing target.

## Design / PDK

- `DESIGN_NAME = core_pd_top`
  - Top module for the standalone core PD stage.
- `PDK = sky130A`
  - Selects the Sky130A PDK and its standard-cell timing/physical data.

## RTL sources

- `VERILOG_FILES`
  - Explicit list of RTL files passed to Yosys.
  - Includes `core_pd_top.sv` plus the LEGv8 core RTL modules.

## Current relaxed bring-up timing baseline

The current baseline is intentionally loose. Its purpose is to establish a clean PnR/STA reference before tightening the clock target.

- `CLOCK_PORT = clk`
- `CLOCK_PERIOD = 15 ns`
  - Approximately 66.7 MHz.
- External/source clock latency: 2 ns
- Pre-CTS internal clock-network latency estimate: 1 ns
- Post-CTS clock: propagated physical clock tree
- Setup uncertainty: 1 ns
- Clock transition: 1 ns
- Input delay: min 2 ns / max 3 ns
- Output delay: min 0 ns / max 3 ns
- Input driving cell: `sky130_fd_sc_hd__buf_2/X`
- Output load: 0.2 pF
- Timing derate: OpenLane `TIME_DERATING_CONSTRAINT`

The I/O delays are provisional block-level assumptions, not chip/package signoff specifications. They are intentionally relaxed so that standalone core analysis emphasizes internal register-to-register timing, clock-tree behavior, routing, and electrical quality.

## Synthesis

- `SYNTH_STRATEGY = AREA 0`
  - Area-oriented ABC technology-mapping strategy.
- `SYNTH_HIERARCHY_MODE = flatten`
  - Flattens the design hierarchy for synthesis.
- `SYNTH_SHARE_RESOURCES = true`
  - Allows Yosys to share equivalent/common resources where possible.
- `SYNTH_ABC_BUFFERING = true`
  - Allows ABC buffering during technology mapping.
- `SYNTH_SIZING = false`
  - Leaves physical sizing primarily to OpenROAD.
- `SYNTH_ABC_DFF = false`
  - Prevents ABC from remapping sequential cells.
- `SYNTH_DIRECT_WIRE_BUFFERING = true`
- `SYNTH_SPLITNETS = true`
- `SYNTH_ADDER_TYPE = YOSYS`
- `SYNTH_MUL_BOOTH = false`
- `SYNTH_TIE_UNDEFINED = low`
- `SYNTH_WRITE_NOATTR = true`
- `USE_LIGHTER = false`
- `USE_SYNLIG = false`
- `YOSYS_LOG_LEVEL = ALL`

## Physical implementation baseline

- `FP_SIZING = relative`
- `FP_ASPECT_RATIO = 1.0`
- `FP_CORE_UTIL = 35`
- `PL_TARGET_DENSITY_PCT = 45`
- Timing-driven placement enabled
- Routability-driven placement enabled
- CTS enabled
- Post-CTS timing resizer enabled
- Global routing antenna repair enabled
- Detailed routing enabled
- Multi-corner post-PnR STA enabled
- SPEF extraction enabled

The design relies on Liberty/PDK limits for slew and capacitance checks. No extra global `set_max_fanout` constraint is imposed in `top.con` for the relaxed baseline.

## Timing-closure workflow

Use 15 ns as the initial reference point. After a clean run, reduce the period step-by-step, for example:

```text
15 ns -> 12 ns -> 10 ns -> 8 ns -> 7 ns
```

At each step, check:

1. Overall setup/hold WNS and TNS.
2. Register-to-register setup and hold slack separately from I/O-boundary paths.
3. Max slew and max capacitance violations.
4. The worst setup path at the first period that fails.

Do not change the clock period merely to hide slew/capacitance problems. Electrical violations should be analyzed independently from architectural or combinational-path timing limits.

## Deliberately omitted constraints

- No generated clock: this standalone core currently has one clock only.
- No clock groups: there is no multi-clock relationship to constrain.
- No asynchronous-reset false path: `rst` is synchronous in this RTL.
- No multicycle/false-path exceptions are added unless justified by the RTL protocol/architecture.
- No explicit SAED-style operating-condition names are copied into this Sky130/OpenLane flow.
