# n2n FM `scan_out` 처리 메모

## 1. 무엇을 확인했는가

`5_FM/4_report/n2n_4_12_7p3ns/`의 baseline n2n FM 결과를 확인했다.

핵심 결과는 다음과 같았다.

- `unmatched_points_post_matching.rpt`: unmatched point 없음
- `unverified_points.rpt`: unverified point 없음
- `aborted_points.rpt`: aborted point 없음
- `failing_points.rpt`: `scan_out` 1개만 fail

즉, **구조 매칭은 정상이고 전체 기능이 무너진 것이 아니라 `scan_out` compare point 하나만 실패한 상태**였다.

## 2. 어떻게 확인했는가

### failing point 확인

`5_FM/4_report/n2n_4_12_7p3ns/failing_points.rpt:10-13`

- failing compare point 수: `1`
- failing point:
  - `r:/WORK/top_mcu_pll_sram_multiclk_soc/scan_out`
  - `i:/WORK/top_mcu_pll_sram_multiclk_soc/scan_out`

### functional mode constant 확인

`5_FM/4_report/n2n_4_12_7p3ns/constants.rpt:13-18`

- `scan_en = 0`
- `scan_in = 0`
- `test_mode = 0`

ref / impl 양쪽 모두 동일하게 적용되어 있었다.

### 기존 dont_verify 상태 확인

`5_FM/4_report/n2n_4_12_7p3ns/dont_verify_points.rpt:10`

- `Don't verify points: None`

즉, baseline 실행에서는 `scan_out`가 compare 대상에서 제외되지 않았다.

## 3. 왜 그렇게 판단했는가

### pre-DFT mapped gate에서의 `scan_out`

`2_synthesis/2_output/4_12_7p3ns/mapped/soc_gate.v:18808`

```verilog
INVX0_RVT U8 ( .A(1'b1), .Y(scan_out) );
```

pre-DFT gate에서는 `scan_out`가 사실상 상수로 정리되어 있다.

### post-DFT netlist에서의 `scan_out`

`3_DFT/2_output/4_12_7p3ns/aes_128_internal.v:18971`

```verilog
NBUFFX2_RVT DFTC_8 ( .A(uart_txd), .Y(scan_out) );
```

post-DFT netlist에서는 `scan_out`가 더 이상 상수 포트가 아니라, 어떤 내부 신호 cone에 의해 실제로 구동된다.

다만 **이 한 줄만 보고 `scan_out`가 곧바로 scan chain의 마지막 노드라고 단정할 수는 없다.**
이 줄이 직접 말해주는 것은 다음 두 가지다.

1. pre-DFT의 `scan_out`와 post-DFT의 `scan_out` 구현 cone이 달라졌다.
2. post-DFT에서는 `scan_out`가 더 이상 tie-off 포트가 아니다.

즉, netlist 한 줄은 **cone 변화의 증거**이고, `scan_out`의 test 역할 자체는 아래 DFT 리포트들이 보강한다.

### DFT 리포트에서의 `scan_out` 역할 확인

#### DFT signal 분류

`3_DFT/4_report/4_12_7p3ns/dft_signals_internal.rpt:16-21`

- `scan_en            ScanEnable`
- `scan_out           ScanDataOut`
- `scan_in            ScanDataIn`

즉 DFT tool이 `scan_out`를 **공식적으로 ScanDataOut 포트**로 인식하고 있다.

#### 실제 built scan chain 확인

`3_DFT/4_report/4_12_7p3ns/scan_chains_internal.rpt:25`

- `I chain0     1532  scan_in     scan_out    scan_en     ref_clk     -`

즉 insert_dft 결과에서 실제 scan chain의 입구는 `scan_in`, 출구는 `scan_out`로 구성되었다.

#### preview 단계에서도 동일한 방향 확인

`3_DFT/4_report/4_12_7p3ns/preview_dft.rpt:16-24`

- `Number of chains: 1`
- `Scan methodology: full_scan`
- `S chain0   scan_in -->  scan_out               1532`

즉 preview 단계에서도 tool이 `scan_in -> scan_out` 구조로 scan chain을 만들 계획이었고, 실제 built 결과와 일치한다.

#### dedicated scan output 포트 생성 여부

`3_DFT/4_report/4_12_7p3ns/scan_config_internal.rpt:26`

- `Create dedicated scan out ports: False`

즉 tool이 전용 새 scan output 포트를 따로 만들지 않고, **기존 `scan_out` 포트를 scan output 용도로 재사용**했음을 알 수 있다.

### 해석

이 프로젝트에서 `scan_out` 포트는 RTL에 미리 존재하지만, **기능 RTL에서는 사실상 비활성/미구동 포트에 가깝고**, DFT 삽입 이후에는 리포트상 명시적으로 `ScanDataOut` 역할을 가진다.

따라서 이 문서에서의 판단 근거는 다음 조합이다.

1. pre-DFT gate에서는 `scan_out`가 상수로 정리됨
2. post-DFT gate에서는 `scan_out`가 실제 cone을 가짐
3. DFT 리포트에서 `scan_out`가 `ScanDataOut`으로 분류됨
4. scan chain 리포트에서 `scan_in -> scan_out` 체인이 실제로 보고됨
5. dedicated scan-out 포트를 따로 만들지 않았으므로 기존 `scan_out` 포트가 test output으로 재사용됨

따라서 post-DFT n2n FM에서:

- reference 쪽 `scan_out` cone
- implementation 쪽 `scan_out` cone

이 달라지는 것은 자연스러운 현상이며, **functional equivalence 확인 목적이라면 `scan_out`를 직접 compare하지 않는 것이 타당**하다고 판단했다.

## 4. 무엇을 변경했는가

`5_FM/0_script/n2n/FM_n2n_script.tcl:78-80`

```tcl
# scan_out는 post-DFT에서 scan chain용 test output 성격이 강하므로 functional n2n 비교에서 제외한다.
set_dont_verify_point r:/WORK/${TOP_MODULE}/scan_out
set_dont_verify_point i:/WORK/${TOP_MODULE}/scan_out
```

즉, post-DFT functional n2n FM에서는 `scan_out`를 dont verify point로 처리하도록 수정했다.

## 5. 왜 이렇게 변경했는가

이번 n2n FM의 목적은 **scan chain 자체의 test 동작 검증이 아니라, DFT 삽입 이후에도 functional logic equivalence가 유지되는지 확인하는 것**이다.

이 기준에서는 `scan_out`는 다음 이유로 compare 제외가 합리적이다.

1. DFT 리포트 기준으로 `scan_out`는 `ScanDataOut`이며 test 포트 역할이 명확하다.
2. pre-DFT와 post-DFT에서 `scan_out`의 cone이 의도적으로 달라졌다.
3. `Create dedicated scan out ports: False` 설정 때문에 기존 포트 재사용이 일어났다.
4. baseline 결과에서도 나머지 compare point는 모두 통과했고, `scan_out`만 단독 실패였다.

## 6. 결과는 무엇이었는가

### baseline 결과

- n2n FM은 `scan_out` 1개 때문에 fail
- 그 외 point는 모두 pass

### 수정 후 재실행 상태

수정 후 `run_n2n.csh` 재실행을 시도했지만 현재 세션에서는 아래 이유로 완료하지 못했다.

```text
License Failure (-15) - Not authorized for feature Formality.
```

따라서 **수정 후 최종 clean pass 여부는 라이선스가 가능한 환경에서 재실행해 다시 확인해야 한다.**

## 7. 다음 확인 항목

라이선스가 가능한 환경에서 아래 순서로 다시 확인한다.

1. `csh run_n2n.csh`
2. `dont_verify_points.rpt`에 `scan_out`가 기록되는지 확인
3. `failing_points.rpt`가 비어 있는지 확인
4. 최종적으로 `Verification PASSED`가 나오는지 확인

## 8. 한 줄 결론

이번 이슈는 **기능 로직 오류라기보다, DFT 리포트상 `ScanDataOut`으로 재사용된 `scan_out`를 functional n2n compare에 그대로 포함해서 발생한 fail**로 정리할 수 있다.
