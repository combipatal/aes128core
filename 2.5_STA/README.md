# 2.5_STA

`2.5_STA` is a focused STA workspace for SS/FF comparison on versioned netlists.

## Purpose

- compare `4_13_7p3ns` and `4_13_7p3ns_ff`
- run both `ss0p95v125c` and `ff1p16v125c`
- keep outputs versioned and separate from the existing `4_STA` workspace

## Defaults

- default scenario: `func`
- default net source: `synth`
- default netlist:
  - `../2_synthesis/2_output/${ver}/mapped/soc_gate.v`
- default SDC:
  - `../2_synthesis/2_output/${ver}/mapped/soc_func.sdc`

## Optional net source

- `net_source=synth`
  - use synthesis mapped netlist directly
- `net_source=dft`
  - use `../3_DFT/2_output/${ver}/aes_128_internal.v`

## Example commands

```bash
cd /DATA/home/edu135/aes128_core/2.5_STA
env ver=4_13_7p3ns corner=ss0p95v125c sta_scenario=func net_source=synth csh run.csh
env ver=4_13_7p3ns corner=ff1p16v125c sta_scenario=func net_source=synth csh run.csh
env ver=4_13_7p3ns_ff corner=ss0p95v125c sta_scenario=func net_source=synth csh run.csh
env ver=4_13_7p3ns_ff corner=ff1p16v125c sta_scenario=func net_source=synth csh run.csh
```

## External terminal execution

For long runs, use a separate `tmux` session:

```bash
tmux new-session -d -s sta_7p3_ss 'cd /DATA/home/edu135/aes128_core/2.5_STA && env ver=4_13_7p3ns corner=ss0p95v125c sta_scenario=func net_source=synth csh run.csh'
```

Logs are written to:

```text
3_log/${ver}_${net_source}_${sta_scenario}_${mode}_${corner}_sta.log
```

Reports are written under:

```text
4_report/${ver}/${net_source}/${scenario}/...
```
