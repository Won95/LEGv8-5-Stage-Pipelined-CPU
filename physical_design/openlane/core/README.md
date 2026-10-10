# core_pd_top OpenLane configuration

This directory contains the standalone CPU-core physical-design setup used before hard SRAM and chip-level I/O integration.

## `config.json`

`config.json` is kept as valid JSON, so inline `//` or `#` comments are intentionally not used. The options are documented here instead.

### Design / PDK

- `DESIGN_NAME = core_pd_top`
  - Top module for the standalone core PD stage.
- `PDK = sky130A`
  - Selects the Sky130A PDK. OpenLane resolves the standard-cell library, Liberty timing data, LEF/GDS, timing corners, driving-cell defaults, output load, and related PDK data from this selection.

### RTL sources

- `VERILOG_FILES`
  - Explicit list of RTL files passed to Yosys.
  - This replaces the search-path-oriented style commonly used in Synopsys DC setups.

### Clock

- `CLOCK_PORT = clk`
  - Primary clock input.
- `CLOCK_PERIOD = 7`
  - 7 ns implementation target, approximately 142.9 MHz.
  - `top.con` uses the same period for OpenROAD/OpenSTA timing analysis.

### Synthesis

- `SYNTH_STRATEGY = AREA 0`
  - Area-oriented ABC technology-mapping strategy.
- `SYNTH_HIERARCHY_MODE = flatten`
  - Flattens the design hierarchy for synthesis.
- `SYNTH_SHARE_RESOURCES = true`
  - Allows Yosys to share equivalent/common resources where possible.
- `SYNTH_ABC_BUFFERING = false`
  - Disables extra ABC buffering during synthesis.
- `SYNTH_SIZING = false`
  - Disables synthesis-stage cell sizing; physical optimization is handled later by OpenROAD.
- `SYNTH_ABC_DFF = false`
  - Prevents ABC from remapping sequential cells.
- `SYNTH_DIRECT_WIRE_BUFFERING = true`
  - Enables direct-wire buffering handling in the synthesis flow.
- `SYNTH_SPLITNETS = true`
  - Splits multi-bit nets where required for downstream processing.
- `SYNTH_ADDER_TYPE = YOSYS`
  - Uses Yosys' native adder implementation.
- `SYNTH_MUL_BOOTH = false`
  - Does not use Booth multiplier transformation.
- `SYNTH_TIE_UNDEFINED = low`
  - Resolves undefined values to logic 0.
- `SYNTH_WRITE_NOATTR = true`
  - Writes the synthesized netlist without Yosys attributes.
- `USE_LIGHTER = false`
  - Uses the normal Yosys synthesis flow rather than Lighter.
- `USE_SYNLIG = false`
  - Uses the standard Yosys frontend rather than Synlig.
- `YOSYS_LOG_LEVEL = ALL`
  - Keeps detailed Yosys logs for synthesis/debugging.

### Timing constraints

- `PNR_SDC_FILE = dir::./top.con`
  - Used by OpenROAD/OpenSTA during pre-PnR and PnR timing analysis.
- `SIGNOFF_SDC_FILE = dir::./top.con`
  - Used for post-PnR/signoff timing analysis.

`top.con` is not sourced by stock `Yosys.Synthesis`; synthesis timing optimization is handled separately by OpenLane/Yosys/ABC.

## `top.con` policy

The current constraint file intentionally combines the IDEC reference assumptions with OpenLane/Sky130-specific timing environment values.

- Clock period: 7 ns
- Clock waveform: `{3.5 7.0}` for a 7 ns period
- External/source clock latency: max 2 ns
- Pre-CTS internal/network clock latency estimate: max 1 ns
- Post-CTS clock: propagated physical clock tree
- Clock uncertainty: `CLOCK_UNCERTAINTY_CONSTRAINT`
- Clock transition: `CLOCK_TRANSITION_CONSTRAINT`
- Max fanout / transition / capacitance: OpenLane environment values
- Input driving cell: `sky130_fd_sc_hd__buf_1/X` for synchronous `rst`
- Output load: OpenLane PDK `OUTPUT_CAP_LOAD`
- Timing derate: OpenLane `TIME_DERATING_CONSTRAINT`

### Provisional I/O timing budget

The current input/output delay values are derived from an intentionally loose internal-path target used for the first STA pass:

```text
input_delay(max)  = Tclk - uncertainty - Tmax(input port -> FF D)
output_delay(max) = Tclk - uncertainty - Tmax(FF Q -> output port)
```

For the first pass:

```text
Tmax(input port -> FF D) = 6.0 ns
Tmax(FF Q -> output port) = 6.0 ns
```

These 6 ns values are provisional. After `OpenROAD.STAPrePNR`, the actual worst input-to-register and register-to-output path delays should be inspected and the I/O budget should be tightened based on measured timing rather than treated as a final specification.

### Deliberately omitted constraints

- No generated clock: this standalone core currently has one clock only.
- No clock groups: there is no multi-clock relationship to constrain.
- No asynchronous-reset false path: `rst` is synchronous in this RTL.
- No multicycle/false-path exceptions are added unless justified by the RTL protocol/architecture.
- No explicit operating-condition names are copied from SAED32; Sky130 PVT/corner selection is handled by the OpenLane PDK configuration.
