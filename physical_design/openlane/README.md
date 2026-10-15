# OpenLane Physical Design 단계

이 디렉터리는 Physical Design 작업을 통합 수준별로 분리하여 각 단계의 결과를 비교할 수 있도록 구성하였다.

```text
openlane/
├── core/       # CPU Core + Behavioral IMEM/DMEM
├── soc_top/    # Core + AHB/MMIO/Loader + Hard SRAM Macro
└── chip_top/   # soc_top + Sky130 Package I/O / Padframe
```

## 1. core

`core_pd_top`은 CPU Core와 프로젝트의 Behavioral `InstructionMem`, `dataMem` 모델을 하나의 Top Module로 구성한 단계이다.

Hard SRAM과 I/O Integration을 추가하기 전에 CPU Logic을 대상으로 Synthesis, Floorplan, Placement, CTS, Routing, Timing을 확인하기 위한 단계이다.

## 2. soc_top

`soc_top`은 SoC 수준의 Physical Design 단계이다.

IMEM과 DMEM은 3개의 `sky130_sram_1kbyte_1rw1r_32x256_8` Hard SRAM Macro로 구현하며, AHB-Lite Fabric, Loader, MMIO GPIO, UART Byte-Stream Logic을 함께 포함한다.

### Physical Design 결과

`soc_top`에 Sky130 SRAM Hard Macro 3개를 통합한 뒤 Placement, CTS, Routing을 수행하여 생성한 최종 Layout이다.

![soc_top Final Layout](./results/soc_top_final_layout.jpg)

## 3. chip_top

`chip_top`은 `soc_top`의 상위 단계로, Sky130 Signal Pad와 Package Power/Ground Pad를 추가한 Chip-Level Integration 단계이다.

`padframe.cfg`에는 최초의 2.0 mm × 2.0 mm Pad-Ring 구성이 정의되어 있다. Padframe의 Filler/Connect/Corner Cell은 CPU/SoC RTL과 분리된 Physical Integration 영역에서 관리한다.

세 단계는 각각 독립된 설정 파일을 사용하여 Constraint, Macro Placement, Report, Run Directory가 서로 섞이지 않도록 관리한다.
