# LEGv8 5-Stage Pipelined CPU SoC

LEGv8 기반 5-stage pipelined CPU에 **Sky130 SRAM hard macro, AHB-Lite, MMIO**를 결합한 소형 SoC 프로젝트입니다.

목표는 CPU 기능 확장보다 직접 구성한 RTL을 대상으로 **RTL-to-GDSII / Physical Design / STA**를 수행하고 timing, placement, routing 결과를 분석하는 것입니다.

## Architecture

`soc_top`의 주요 구성은 다음과 같습니다.

```text
soc_top
├─ LEGv8 5-stage Core
├─ Instruction SRAM : 32-bit macro ×1
├─ AHB-Lite Master / Fabric
├─ Data SRAM        : 32-bit macro ×2 → logical 64-bit DMEM
├─ MMIO             : GPIO / UART FIFO
└─ External Loader  : simulation image loading
```

- **Instruction side**: CPU ↔ IMEM 전용 request/response path
- **Data side**: CPU Load/Store → AHB-Lite → DMEM / MMIO
- **SRAM hard macro**: 총 3개 (`IMEM ×1 + DMEM ×2`)
- **Pipeline**: `IF / ID / EX / MEM / WB`
- Hazard detection, forwarding, branch flush 지원

External Loader는 프로그램과 초기 데이터를 SRAM에 적재하기 위한 **verification infrastructure**이며 runtime instruction-fetch path는 아닙니다.

## Memory Map

| Address | Block |
|---|---|
| `0x0000 ~ 0x00FF` | DMEM |
| `0x0100` | GPIO_OUT |
| `0x0108` | GPIO_IN |
| `0x0110` | GPIO_OE |
| `0x0120` | UART_RXDATA |
| `0x0128` | UART_TXDATA |
| `0x0130` | UART_STATUS |

UART는 현재 **MMIO + FIFO + byte-stream interface**까지 구현되어 있으며 bit-level UART PHY는 포함하지 않습니다.

## Verification

Directed regression에서 다음 항목을 확인했습니다.

- Load-use hazard / pipeline stall
- EX/MEM, MEM/WB forwarding
- Conditional / unconditional branch
- SRAM wrapper integration
- AHB-Lite DMEM access

AHB-Lite integration 기준 directed regression **40/40 PASS**를 확인했습니다.

## Physical Design

Physical Design은 `core`와 `soc_top`을 대상으로 진행합니다.

```text
RTL → Synthesis → Floorplan → Macro Placement → Placement
    → CTS → Routing → STA / Timing Closure → GDSII
```

주요 분석 대상:

- SRAM macro placement / halo / routing channel
- Standard-cell utilization / congestion
- Setup / Hold, WNS / TNS
- Critical path와 RTL 구조의 관계
- Sky130/OpenLane 기반 RTL-to-GDSII

## Repository

```text
rtl/                 RTL source
physical_design/     core / soc_top OpenLane flow
physical_design/results/
docs/                architecture diagram
```
