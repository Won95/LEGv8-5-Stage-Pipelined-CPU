# LEGv8 5-Stage Pipelined CPU

LEGv8 기반 **5-stage pipelined CPU**를 직접 설계하고, **Sky130 SRAM hard macro**와 **AHB-Lite data bus**를 연결한 뒤 RTL-to-GDSII Physical Design을 진행하는 프로젝트입니다.

## CPU Design

- 5-stage pipeline: `IF / ID / EX / MEM / WB`
- Load-use hazard detection 및 pipeline stall
- EX/MEM, MEM/WB forwarding
- Conditional / unconditional branch 처리
- Taken branch flush
- Memory wait에 따른 pipeline hold

## SRAM Integration

Sky130 32-bit SRAM hard macro를 총 3개 사용합니다.

```text
Instruction Memory : 32-bit SRAM ×1
Data Memory        : 32-bit SRAM ×2 → logical 64-bit DMEM
```

Instruction memory는 CPU와 전용 request/response interface로 연결하고, data memory는 AHB-Lite를 통해 접근합니다.

## AHB-Lite

CPU의 load/store data path에 AHB-Lite Master/Fabric을 적용했습니다.

```text
CPU Load / Store
       ↓
AHB-Lite Master
       ↓
AHB-Lite Fabric
       ↓
      DMEM
```

현재 구현은 single-master / single-transfer 중심의 간단한 AHB-Lite 구조입니다.

## Verification

Directed regression을 통해 다음 항목을 확인했습니다.

- Pipeline hazard / stall
- Forwarding
- Branch / flush
- SRAM wrapper integration
- AHB-Lite DMEM access

AHB-Lite integration 기준 directed regression **40/40 PASS**를 확인했습니다.

## Physical Design

Sky130/OpenLane 환경에서 `core`와 `soc_top`을 대상으로 Physical Design을 진행합니다.

```text
RTL
 → Synthesis
 → Floorplan
 → SRAM Macro Placement
 → Placement
 → CTS
 → Routing
 → STA / Timing Closure
 → GDSII
```

주요 관심 항목은 SRAM macro placement, congestion, clock tree, setup/hold timing, critical path 및 RTL 구조와 physical implementation 결과의 관계입니다.

## Repository Structure

```text
rtl/                 RTL source
physical_design/core/
physical_design/soc_top/
physical_design/results/
tb/                  Testbench
```
