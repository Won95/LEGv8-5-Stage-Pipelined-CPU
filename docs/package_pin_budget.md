# 200-pin MQFP Package Pin Budget

## Project package assumption

- Process used for PD practice: Sky130
- Package model assumption: 200-pin MQFP
- Die-to-package connection: wire bonding
- `soc_top` is the internal SoC integration top.
- `chip_top` is the package-facing top.

The 200-pin MQFP assumption is a project packaging model, not a requirement imposed by Sky130.

## Why chip_top is separate

`soc_top` intentionally exposes wide internal/verification interfaces. If those signals were treated as package pins, the count would be excessive:

| Internal interface | Signals |
|---|---:|
| clk + rst | 2 |
| External loader stream | 132 |
| GPIO in/out/output-enable | 192 |
| UART byte-stream ready/valid interfaces | 20 |
| `load_done` | 1 |
| **Total** | **347** |

These are not intended to be physical package pins.

## Final package-level architecture

```text
                200-pin MQFP
                     |
                  chip_top
                     |
        +------------+------------+
        |            |            |
     clk/reset    UART RX/TX    GPIO[31:0]
                     |
        +------------+------------+
                     |
                  soc_top
        +------------+------------+
        |            |            |
      LEGv8       AHB-Lite       MMIO
        |                         |
   IMEM / DMEM                 GPIO/UART
     SRAM x3
```

The same physical UART pins are reused for two phases:

1. Boot phase (`load_done=0`)
   - UART RX -> UART PHY -> boot packet receiver -> FIFO -> Loader -> IMEM/DMEM
   - CPU remains in reset.
2. Runtime phase (`load_done=1`)
   - UART RX/TX -> UART PHY -> MMIO UART FIFOs -> CPU through AHB-Lite.

No external working memory bus is exposed. IMEM and DMEM stay on-die as SRAM hard macros.

## UART boot packet format

Each memory-write record is 17 bytes:

```text
byte 0     : control
             bit[1] = last
             bit[0] = target (0=IMEM, 1=DMEM)
byte 1~8   : 64-bit address, little-endian
byte 9~16  : 64-bit data, little-endian
```

For IMEM writes the loader uses `data[31:0]`. For DMEM writes the full 64-bit data field is used.

The final record sets `last=1`. After that write completes, `load_done` is asserted and the CPU leaves reset.

## Initial 200-pin budget

### Power / ground: 32 pins

This is an initial project allocation and can be changed when a concrete padframe is built.

| Net class | Pins |
|---|---:|
| VCCD (core power) | 8 |
| VSSD (core ground) | 8 |
| VDDIO (I/O power) | 8 |
| VSSIO (I/O ground) | 8 |
| **Subtotal** | **32** |

### Functional signals: 37 pins

| Signal group | Pins | Note |
|---|---:|---|
| Clock | 1 | `clk` |
| Reset | 1 | active-high `rst` |
| UART | 2 | `uart_rx`, `uart_tx`; shared by boot and runtime |
| GPIO | 32 | bidirectional `gpio[31:0]` |
| Load status | 1 | `load_done` |
| **Subtotal** | **37** | |

### Reserved / test / NC: 131 pins

```text
200 - 32 - 37 = 131
```

Unused package leads may remain NC or later be allocated to JTAG/debug, additional GPIO, test access, clocking, extra supply/ground, or other interfaces.

## Total

```text
Power / ground       32
Functional signals   37
Reserved / test / NC 131
------------------------
Total                200
```

## PD boundary

```text
On die:
LEGv8 + AHB-Lite + FIFO/Loader + MMIO + SRAM hard macros + I/O cells

Die boundary:
I/O pads

Off die:
bonding wire -> MQFP lead frame -> PCB
```

AHB-Lite, SRAM data/address buses, and the 130-bit loader packet remain internal to the die and therefore consume no package pins.
