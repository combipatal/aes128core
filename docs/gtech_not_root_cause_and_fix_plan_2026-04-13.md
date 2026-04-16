# `u_mem` `dont_touch`로 인한 `GTECH_NOT` 잔존 이슈 정리

> [!WARNING]
> Deprecated plan document.
> This file is kept as an archive of the 2026-04-13 root-cause note.
> Use [aes128_core_portfolio_summary.md](aes128_core_portfolio_summary.md) and current stage README files for the latest baseline.

## 목적

이 문서는 `aes128_core`의 baseline synthesis 결과에서 `GTECH_NOT`가 남는 원인과, 이를 어떻게 수정하는 것이 맞는지 정리한다.

대상 baseline:

- synthesis version: `4_12_7p3ns`
- mapped netlist: `2_synthesis/2_output/4_12_7p3ns/mapped/soc_gate.v:1`

## 결론 요약

현재 `GTECH_NOT`가 남는 직접 원인은 **SRAM macro 자체 때문이 아니라 SRAM wrapper 인스턴스 `u_mem` 전체를 `dont_touch`한 것**이다.

즉:

1. 실제 macro는 `u_mem` 내부의 `u_sram`
2. `u_mem` wrapper에는 `cs/we/oe`를 active-low pin으로 뒤집는 간단한 inverter logic가 있음
3. synthesis script가 wrapper 전체 `u_mem`을 `dont_touch`해서
4. 이 inverter logic가 standard cell inverter로 mapping되지 못하고 generic `GTECH_NOT` 상태로 남음

따라서 수정 방향은:

- `u_mem` 전체 `dont_touch`를 제거하고
- 필요 시 실제 macro instance인 `u_mem/u_sram`만 보호하는 것이다.

## 확인 근거

### 1. synthesis script에서 wrapper 전체를 `dont_touch`하고 있음

`2_synthesis/0_script/synthesis_script.tcl:47`

```tcl
# block box 
set_dont_touch [get_cells u_mem]
set_dont_touch [get_cells u_pll]
```

여기서 `u_mem`은 SRAM macro가 아니라 wrapper instance다.

### 2. top RTL에서 `u_mem`은 wrapper instance임

`0_rtl/top_mcu_pll_sram_multiclk_soc.v:109`

```verilog
sram_wrap_1rw1024x8 u_mem (
  .clk   (clk_div2_int),
  .cs    (mem_cs),
  .we    (mem_we),
  .oe    (mem_oe),
  .addr  (mem_addr),
  .wdata (mem_wdata),
  .rdata (mem_rdata)
);
```

즉 `u_mem`은 macro가 아니라 `sram_wrap_1rw1024x8` wrapper다.

### 3. wrapper 내부에는 polarity conversion logic가 있음

`0_rtl/sram_wrap_1rw1024x8.v:11`

```verilog
wire CSB = ~cs;
wire WEB = ~we;
wire OEB = ~oe;

SRAM1RW1024x8 u_sram (
  .A   (addr),
  .CE  (clk),
  .WEB (WEB),
  .OEB (OEB),
  .CSB (CSB),
  .I   (wdata),
  .O   (rdata)
);
```

이 RTL은 wrapper 수준에서 `~cs`, `~we`, `~oe`를 만들어 macro의 active-low pin에 연결한다.

따라서 wrapper 전체를 `dont_touch`하면, 이 세 개의 inversion logic도 mapping 대상에서 사실상 고정된다.

### 4. 실제 mapped netlist에 `GTECH_NOT` 3개가 남아 있음

`2_synthesis/2_output/4_12_7p3ns/mapped/soc_gate.v:15`

```verilog
SRAM1RW1024x8 u_sram ( .I(wdata), .O(rdata), .A(addr), .CE(clk), .CSB(CSB),
      .WEB(WEB), .OEB(OEB) );
GTECH_NOT I_0 ( .A(cs), .Z(CSB) );
GTECH_NOT I_1 ( .A(we), .Z(WEB) );
GTECH_NOT I_2 ( .A(oe), .Z(OEB) );
```

즉 문제는 정확히 wrapper 내부의 세 개 polarity conversion이다.

### 5. 이 generic 잔존은 뒤 단계에도 영향을 준다

합성 리포트:

- `2_synthesis/4_report/4_12_7p3ns/area.rpt:34`

```text
Information: This design contains unmapped logic. (RPT-7)
```

STA 리포트:

- `4_STA/4_report/4_12_7p3ns/shift/check_timing/scan_shift_pre_ss0p95v125c_check_timing.rpt:13`

```text
Information: There are 3 generic cells in the design.
```

또한 PrimeTime script도 이를 살리기 위해 `gtech.db`를 link path에 포함하고 있다:

- `4_STA/0_script/STA_script.tcl:49`

```tcl
set_app_var link_path "* $target_library $TARGET_LIBRARY_FILES_MEM gtech.db"
```

즉 현재 흐름은 문제를 해결한 것이 아니라, **generic cell이 남아도 PT가 읽을 수 있게 우회한 상태**다.

## 왜 이게 문제인가

학습용 실험에서는 tool이 돌아가기만 해도 넘어갈 수 있지만, 실무형 흐름에서는 아래 이유로 좋지 않다.

1. mapped netlist가 library-clean하지 않다.
2. STA/FM가 generic cell을 이해하도록 추가 우회 설정에 의존한다.
3. signoff 관점에서 “합성 완료”와 “technology mapping 완료”가 분리되어 버린다.
4. 나중에 다른 툴이나 다른 corner flow로 갈 때 재현성이 약해진다.

핵심은 **macro black-box를 보호해야 하는 것과 wrapper combinational logic까지 보호하는 것은 다르다**는 점이다.

## 정확한 원인 정리

이 이슈의 root cause는 아래 한 줄로 정리할 수 있다.

> `u_mem`은 macro가 아니라 wrapper인데, synthesis script에서 wrapper 전체를 `dont_touch`해서 wrapper 내부 inversion logic가 technology mapping되지 못하고 `GTECH_NOT`로 남았다.

즉:

- 잘못된 가정: `u_mem == macro`
- 실제 구조: `u_mem == wrapper`, `u_mem/u_sram == macro`

## 수정 방법

### 권장 수정안

현재:

```tcl
set_dont_touch [get_cells u_mem]
set_dont_touch [get_cells u_pll]
```

권장:

```tcl
# wrapper 전체를 보호하지 않는다.
# 실제 macro 인스턴스만 보호한다.
set_dont_touch [get_cells u_mem/u_sram]
set_dont_touch [get_cells u_pll]
```

또는 macro library link만 충분하고 wrapper logic 변경이 문제없다면 `u_mem/u_sram`에 대한 명시적 `dont_touch`도 생략 가능하다. 다만 현재 프로젝트에서는 macro intent를 명확히 하기 위해 `u_mem/u_sram`만 보호하는 쪽이 더 읽기 쉽다.

### 수정 후 기대 결과

수정 후에는 wrapper 내부의 다음 logic가:

- `GTECH_NOT`

가 아니라:

- `INVX*_RVT` 또는 등가 standard cell inverter

로 매핑되어야 한다.

즉 mapped netlist 상단에서 아래 같은 generic cell이 사라져야 한다.

```verilog
GTECH_NOT I_0
GTECH_NOT I_1
GTECH_NOT I_2
```

## 수정 후 검증 체크리스트

수정 후에는 아래 순서로 반드시 확인한다.

### 1. synthesis 재실행

- `2_synthesis/run.csh`

### 2. mapped netlist에서 generic cell 제거 확인

예:

```bash
rg "GTECH_" ./2_synthesis/2_output/<ver>/mapped/soc_gate.v
```

기대값:

- 출력 없음

### 3. 합성 리포트 확인

확인 파일:

- `2_synthesis/4_report/<ver>/area.rpt`
- `2_synthesis/4_report/<ver>/aes_chk_design.rpt`

기대값:

- `This design contains unmapped logic` 문구 제거 또는 최소한 wrapper inversion 때문에 뜨던 항목 해소

### 4. STA 재확인

확인 파일:

- `4_STA/4_report/<ver>/func/...`
- `4_STA/4_report/<ver>/shift/check_timing/...`

기대값:

- `There are 3 generic cells in the design.` 제거

### 5. FM 재확인

확인 파일:

- `5_FM/3_log/r2n_<ver>.log`
- `5_FM/3_log/n2n_<ver>.log`

기대값:

- 기존 PASS 유지

## 부작용/주의점

이 수정은 원칙적으로 안전하다. 이유는:

- wrapper 내부 로직은 단순 inverter 3개뿐이고
- macro interface polarity만 바꾸는 역할이라
- technology mapping되어도 기능 의미가 바뀌지 않는다.

다만 아래는 같이 확인해야 한다.

1. synthesis 후 hold/setup 숫자가 미세하게 변할 수 있음
2. DFT/STA 리포트 path 이름이 일부 변할 수 있음
3. FM 매칭 경로가 약간 달라질 수 있으므로 r2n/n2n 재검증 필요

## 최종 판단

이 항목은 PPA 개선 이전에 먼저 처리하는 것이 맞다.

이유는 이 문제가 단순 timing margin 문제가 아니라:

- stage handoff 품질
- technology mapping completeness
- STA/FM 재현성

에 직접 연결되기 때문이다.

즉 1번 작업의 목표는 단순히 `GTECH_NOT` 3개를 없애는 것이 아니라,

> synthesis -> DFT -> STA -> FM으로 이어지는 netlist handoff를 library-clean 상태로 만드는 것

으로 보는 것이 맞다.
