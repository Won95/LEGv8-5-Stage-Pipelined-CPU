# OpenLane Physical Design 단계

이 디렉터리는 Physical Design 작업을 통합 수준별로 분리하여 각 단계의 결과를 비교할 수 있도록 구성하였습니다.

```text
openlane/
├── core/       # CPU Core + Behavioral IMEM/DMEM
└── soc_top/    # Core + AHB/MMIO/Loader + Hard SRAM Macro
```

## 1. core

`core_pd_top`은 CPU Core와 프로젝트의 Behavioral `InstructionMem`, `dataMem` 모델을 하나의 Top Module로 구성한 단계.

Hard SRAM과 I/O Integration을 추가하기 전에 CPU Logic을 대상으로 Synthesis, Floorplan, Placement, CTS, Routing, Timing을 확인하기 위한 단계.

## 2. soc_top

`soc_top`은 SoC 수준의 Physical Design 단계.

IMEM과 DMEM은 3개의 `sky130_sram_1kbyte_1rw1r_32x256_8` Hard SRAM Macro로 구현하며, AHB-Lite Fabric, Loader, MMIO GPIO, UART Byte-Stream Logic을 함께 포함합니다.

### Physical Design 결과

`soc_top`에 Sky130 SRAM Hard Macro 3개를 통합한 뒤 Placement, CTS, Routing을 수행하여 생성한 최종 Layout입니다.
<img width="2169" height="1252" alt="c" src="https://github.com/user-attachments/assets/de416b4a-2cf9-4a11-9eb6-5644c44fd200" />
