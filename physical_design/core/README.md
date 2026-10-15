# core_pd_top OpenLane configuration

This directory contains the standalone CPU-core physical-design setup used before hard SRAM integration.

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

The I/O delays are provisional block-level assumptions, not package signoff specifications. They are intentionally relaxed so that standalone core analysis emphasizes internal register-to-register timing, clock-tree behavior, routing, and electrical quality.

## Synthesis

- `SYNTH_STRATEGY = AREA 0`
- `SYNTH_HIERARCHY_MODE = flatten`
- `SYNTH_SHARE_RESOURCES = true`
- `SYNTH_ABC_BUFFERING = true`
- `SYNTH_SIZING = false`
- `SYNTH_ABC_DFF = false`
- `SYNTH_DIRECT_WIRE_BUFFERING = true`
- `SYNTH_SPLITNETS = true`
- `SYNTH_ADDER_TYPE = YOSYS`

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

## Timing-closure workflow

Use 15 ns as the initial reference point. After a clean run, reduce the period step-by-step, for example:

```text
15 ns -> 12 ns -> 10 ns -> 8 ns -> 7 ns
```

At each step, check setup/hold WNS/TNS, register-to-register paths, slew/capacitance violations, and the worst setup path.
