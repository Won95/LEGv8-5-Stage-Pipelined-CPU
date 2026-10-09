# 200-pin MQFP Package / I/O Scope

## Project assumption

- Process used for PD practice: Sky130
- Package model assumption: 200-pin MQFP
- Die-to-package connection: wire bonding
- `soc_top` remains the functional SoC integration and verification top.
- `chip_top` is a PD-oriented chip wrapper used to model the die I/O boundary.

The 200-pin MQFP assumption is a project packaging model, not a requirement imposed by Sky130.

## Scope decision

This project is primarily a Physical Design / EDA project. The following blocks are kept in the main design scope:

```text
LEGv8 5-stage CPU
+ AHB-Lite
+ IMEM SRAM hard macro x1
+ DMEM SRAM hard macro x2
+ MMIO GPIO
+ MMIO UART byte-stream FIFO
+ chip-level I/O boundary
```

The following are deliberately outside the implementation scope:

```text
bit-level UART RX/TX PHY
UART baud-rate generator
UART boot protocol / packet parser
external Flash controller
full package-specific boot subsystem
```

Program and initial-data loading remain part of the verification infrastructure at `soc_top`:

```text
external_memory_model -> FIFO -> Loader -> IMEM / DMEM
```

This keeps boot-image loading testable without turning the project into a large RTL peripheral project.

## chip_top

`chip_top` does not expose the wide external loader stream as package pins. It contains a minimal internal startup abstraction only so the CPU can leave its loader hold state during chip-level synthesis/PD.

The current wrapper bonds out 16 bidirectional GPIO signals:

```text
MMIO GPIO_OUT / GPIO_IN / GPIO_OE
              |
          chip_top
              |
         gpio[15:0]
              |
           I/O pads
```

The UART block is retained at its existing byte-stream ready/valid boundary. A real two-pin asynchronous serial PHY is intentionally left outside the project scope. Therefore `chip_top` is a PD-oriented digital wrapper, not a fabrication-ready package netlist.

## Package concept

The intended physical hierarchy is:

```text
LEGv8 / AHB-Lite / SRAM / MMIO
              |
           chip_top
              |
           I/O cells
              |
          die pads
              |
        bonding wires
              |
       200-pin MQFP
              |
             PCB
```

IMEM and DMEM remain on-die. No external working-memory bus is required.

## 200-pin budget

At this stage the exact power-pad count and final signal allocation are not fixed. A provisional budget is sufficient for floorplanning:

| Category | Provisional pins |
|---|---:|
| Core / I/O power and ground | 32 |
| Clock + reset | 2 |
| GPIO | 16 |
| UART package reservation | 2 |
| Debug / test reservation | 8 |
| Reserved / NC / additional supply | 140 |
| **Total** | **200** |

The two UART package pins are a future physical-interface reservation only; the bit-level UART PHY is not implemented in the current RTL.

## PD boundary

For the PD portfolio, the important implementation work is:

1. integrate the three Sky130 SRAM hard macros;
2. floorplan CPU, bus logic, SRAM macros, and MMIO logic;
3. add macro halos / routing blockages;
4. build the PDN and connect macro power;
5. perform placement, CTS, routing, extraction, and STA;
6. add or model the chip-level I/O ring;
7. analyze timing and congestion around the SRAM macros and I/O boundary.

Package R/L/C and bonding-wire parasitics can be added later as an optional extension. They are not required for the initial RTL-to-GDSII flow.
