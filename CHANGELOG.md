# 수정 기록

## 현재까지 수정한 내용

- 기존 `core` 내부 구조 정리
- `datapath`, `control`, `hazard detection`, `forwarding` 연결 정리
- testbench를 `core` 기준으로 수정
- register 결과 자동 비교 추가
- stall / forwarding / branch 발생 여부 확인 추가
- stall 및 forwarding 발생 횟수 확인 추가
- 특정 PC에서 stall / branch가 발생하는지 확인 추가
- 간단한 runtime assertion 추가
  - stall control signal 확인
  - forwarding mux 값 확인
  - stall 발생 시 PC hold 확인
- 현재 directed test 기준 `40/40 PASS`

## 다음에 수정할 내용

- `InstructionMem`을 `datapath` 외부로 분리
- `dataMem`을 `datapath` 외부로 분리
- `top`에서 `core`, `InstructionMem`, `dataMem` 연결
- 구조 변경 후 기존 testbench를 다시 실행해서 동일 동작 확인
- 이후 UART + FIFO 연결 진행
