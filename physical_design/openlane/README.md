# OpenLane PD stages

This directory is split by integration level so the physical-design work can be compared stage by stage.

```
openlane/
├── core/       # CPU core + behavioral IMEM/DMEM
├── soc_top/    # core + AHB/MMIO/loader + hard SRAM macros
└── chip_top/   # soc_top + Sky130 package I/O / padframe
```

## 1. core

`core_pd_top` wraps the CPU core with the project's behavioral `InstructionMem` and `dataMem` models.  This stage is intended to study synthesis, floorplanning, placement, CTS, routing, and timing of the CPU logic before hard SRAM and I/O integration are added.

## 2. soc_top

`soc_top` is the SoC-level flow.  IMEM and DMEM are implemented with three `sky130_sram_1kbyte_1rw1r_32x256_8` hard macros, and the AHB-Lite fabric, loader, MMIO GPIO, and UART byte-stream logic are present.

## 3. chip_top

`chip_top` adds Sky130 signal pads and package power/ground pads around `soc_top`.  The accompanying `padframe.cfg` documents the first 2.0 mm x 2.0 mm pad-ring arrangement.  Padframe filler/connect/corner cells are a physical-integration concern and are kept separate from the CPU/SoC RTL.

The three flows deliberately keep separate `config.json` files so constraints, macro placement, reports, and run directories do not get mixed together.
