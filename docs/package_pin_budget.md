# 200-pin MQFP Package Pin Budget

## Project package assumption

- Process used for PD practice: Sky130
- Package model assumption: 200-pin MQFP
- Die-to-package connection: wire bonding
- `soc_top` remains the functional SoC integration top.
- A later `chip_top` will adapt internal wide interfaces to package-level pins.

## Why a separate chip_top is required

The current `soc_top` exposes wide verification-oriented interfaces:

| Interface | Pins |
|---|---:|
| clk + rst | 2 |
| External loader (`ext_valid`, `ext_target`, `ext_last`, `ext_addr[63:0]`, `ext_wdata[63:0]`, `ext_ready`) | 132 |
| GPIO (`gpio_in[63:0]`, `gpio_out[63:0]`) | 128 |
| UART byte-stream (`valid/data/ready` RX + TX) | 20 |
| `load_done` | 1 |
| **Current signal total** | **283** |

This already exceeds a 200-pin package before power and ground pins are counted.

## Package-level architecture

The package-facing `chip_top` should keep the internal SoC unchanged and reduce only the external interfaces:

```text
200-pin MQFP
     |
  chip_top
     |
     +-- clk / reset
     +-- serial boot interface
     +-- UART RX/TX pins
     +-- GPIO pins
     +-- status/test pins
     |
  soc_top
     +-- LEGv8 core
     +-- AHB-Lite
     +-- IMEM SRAM x1
     +-- DMEM SRAM x2
     +-- MMIO
```

## Initial 200-pin budget

This is a project-level engineering assumption, not a Sky130 package requirement.

### Power / ground: 32 pins

| Net class | Pins |
|---|---:|
| VCCD (core power) | 8 |
| VSSD (core ground) | 8 |
| VDDIO (I/O power) | 8 |
| VSSIO (I/O ground) | 8 |
| **Subtotal** | **32** |

### Functional signals: 137 pins

| Signal group | Pins | Note |
|---|---:|---|
| Clock | 1 | `clk` |
| Reset | 1 | package reset |
| Boot SPI | 4 | `boot_sclk`, `boot_cs_n`, `boot_mosi`, `boot_miso` |
| UART | 2 | bit-level `uart_rx`, `uart_tx` |
| GPIO input | 64 | preserves current MMIO GPIO input width |
| GPIO output | 64 | preserves current MMIO GPIO output width |
| Load status | 1 | `load_done` |
| **Subtotal** | **137** | |

### Reserved / test / future: 31 pins

200 - 32 - 137 = 31 pins remain for future test/debug signals, extra power pins, package constraints, or NC pins.

## Total

```text
Power / ground       32
Functional signals  137
Reserved / NC        31
-----------------------
Total               200
```

## Next implementation step

Do not expose the current 130-bit loader stream at package level.

Add a `chip_top` wrapper with:

1. SPI-like boot receiver / packet deserializer
   - converts package pins into the existing `ext_valid/ext_target/ext_last/ext_addr/ext_wdata/ext_ready` stream.
2. Bit-level UART PHY
   - converts `uart_rx/uart_tx` package pins into the existing internal UART byte-stream ready/valid interface.
3. Existing GPIO mapping
   - keeps `gpio_in[63:0]` and `gpio_out[63:0]` package-visible for now.

The AHB-Lite bus, SRAM buses, and wide internal data paths remain entirely inside the die and consume no package pins.
