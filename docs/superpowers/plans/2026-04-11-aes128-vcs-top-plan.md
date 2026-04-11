# AES128 VCS Top Verification Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a VCS environment in `1_vcs` that verifies `top_mcu_pll_sram_multiclk_soc` end-to-end with copied RTL, self-checking logs, and repeatable known-answer tests.

**Architecture:** The environment mirrors `2_synthesis` so the verification tree is easy to navigate. The testbench drives the top in `test_mode=1` so PLL outputs are bypassed by `ref_clk`, decodes `uart_txd`, and compares the 20-byte output stream against expected ciphertext and CRC32 values.

**Tech Stack:** Verilog, SystemVerilog, VCS, C-shell, SAED32 SRAM behavioral model

---

### Task 1: Create Local VCS Workspace And Copy Sources

**Files:**
- Create: `1_vcs/0_script/`
- Create: `1_vcs/1_input/model/`
- Create: `1_vcs/1_input/rtl/`
- Create: `1_vcs/1_input/tb/`
- Create: `1_vcs/2_output/`
- Create: `1_vcs/3_log/`
- Create: `1_vcs/4_report/`

- [ ] **Step 1: Create the directory structure**

Run:
```bash
mkdir -p /DATA/home/edu135/aes128_core/1_vcs/0_script /DATA/home/edu135/aes128_core/1_vcs/1_input/model /DATA/home/edu135/aes128_core/1_vcs/1_input/rtl /DATA/home/edu135/aes128_core/1_vcs/1_input/tb /DATA/home/edu135/aes128_core/1_vcs/2_output /DATA/home/edu135/aes128_core/1_vcs/3_log /DATA/home/edu135/aes128_core/1_vcs/4_report
```

Expected:
- all listed directories exist

- [ ] **Step 2: Copy the RTL snapshot into the VCS input tree**

Run:
```bash
cp /DATA/home/edu135/aes128_core/rtl/aes128_core.v /DATA/home/edu135/aes128_core/rtl/cdc_toggle_sync.v /DATA/home/edu135/aes128_core/rtl/clk_div2_toggle.v /DATA/home/edu135/aes128_core/rtl/crc32_byte.v /DATA/home/edu135/aes128_core/rtl/icg_latch.v /DATA/home/edu135/aes128_core/rtl/PLL_bb_for_syn.v /DATA/home/edu135/aes128_core/rtl/soc_ctrl_multiclk_soc.v /DATA/home/edu135/aes128_core/rtl/sram_wrap_1rw1024x8.v /DATA/home/edu135/aes128_core/rtl/top_mcu_pll_sram_multiclk_soc.v /DATA/home/edu135/aes128_core/rtl/uart_rx.v /DATA/home/edu135/aes128_core/rtl/uart_tx.v /DATA/home/edu135/aes128_core/1_vcs/1_input/rtl/
```

Expected:
- `1_vcs/1_input/rtl/` contains exactly the 11 copied RTL files above

- [ ] **Step 3: Copy the SRAM model used by the RTL**

Run:
```bash
cp /DATA/home/edu135/aes128_core/SAED32_EDK/lib/sram/verilog/saed32sram.v /DATA/home/edu135/aes128_core/1_vcs/1_input/model/saed32sram.v
```

Expected:
- `1_vcs/1_input/model/saed32sram.v` exists

- [ ] **Step 4: Verify the copied source set before scripting**

Run:
```bash
ls /DATA/home/edu135/aes128_core/1_vcs/1_input/rtl /DATA/home/edu135/aes128_core/1_vcs/1_input/model
```

Expected:
- local VCS input tree shows the copied RTL snapshot and SRAM model

- [ ] **Step 5: Commit**

```bash
git add 1_vcs
git commit -m "chore: create local VCS source snapshot"
```

### Task 2: Add VCS Compile Scripts And Filelist

**Files:**
- Create: `1_vcs/0_script/filelist.f`
- Create: `1_vcs/0_script/vcs_opts.f`
- Create: `1_vcs/0_script/run.csh`

- [ ] **Step 1: Write `filelist.f`**

```text
1_input/model/saed32sram.v
1_input/rtl/aes128_core.v
1_input/rtl/cdc_toggle_sync.v
1_input/rtl/clk_div2_toggle.v
1_input/rtl/crc32_byte.v
1_input/rtl/icg_latch.v
1_input/rtl/PLL_bb_for_syn.v
1_input/rtl/soc_ctrl_multiclk_soc.v
1_input/rtl/sram_wrap_1rw1024x8.v
1_input/rtl/top_mcu_pll_sram_multiclk_soc.v
1_input/rtl/uart_rx.v
1_input/rtl/uart_tx.v
1_input/tb/tb_top_mcu_pll_sram_multiclk_soc.sv
```

- [ ] **Step 2: Write `vcs_opts.f`**

```text
-full64
-sverilog
+v2k
-timescale=1ns/1ps
-debug_access+all
-kdb
-lca
+lint=TFIPC-L
+define+SIM_EXTVEC
```

- [ ] **Step 3: Write `run.csh`**

```csh
#!/bin/csh -f

set script_dir = `dirname $0`
set base_dir = `cd ${script_dir}/.. && pwd`
cd ${base_dir}

if (! $?ver) then
  setenv ver smoke
endif

if (! $?case_name) then
  setenv case_name default_nist
endif

mkdir -p ./2_output/${ver}
mkdir -p ./2_output/${ver}/wave
mkdir -p ./3_log
mkdir -p ./4_report/${ver}

vcs -f 0_script/vcs_opts.f -f 0_script/filelist.f \
  -top tb_top_mcu_pll_sram_multiclk_soc \
  -o ./2_output/${ver}/simv \
  -l ./3_log/${ver}_compile.log

if ($status != 0) then
  exit $status
endif

./2_output/${ver}/simv \
  +CASE=${case_name} \
  +SUMMARY=./4_report/${ver}/summary.log \
  -l ./3_log/${ver}_run.log

exit $status
```

- [ ] **Step 4: Make the run script executable**

Run:
```bash
chmod +x /DATA/home/edu135/aes128_core/1_vcs/0_script/run.csh
```

Expected:
- `run.csh` can be launched directly from `1_vcs`

- [ ] **Step 5: Dry-run the compile stage once**

Run:
```bash
env ver=compile_only case_name=default_nist /DATA/home/edu135/aes128_core/1_vcs/0_script/run.csh
```

Expected:
- `3_log/compile_only_compile.log` is created
- `4_report/compile_only/summary.log` is also created because `run.csh` performs compile and run together
- if compile fails, fix the TB or filelist before moving on

- [ ] **Step 6: Commit**

```bash
git add 1_vcs/0_script
git commit -m "build: add VCS compile and run scripts"
```

### Task 3: Write The Self-Checking Top-Level Testbench

**Files:**
- Create: `1_vcs/1_input/tb/tb_top_mcu_pll_sram_multiclk_soc.sv`

- [ ] **Step 1: Write the complete testbench**

```systemverilog
`timescale 1ns/1ps

module tb_top_mcu_pll_sram_multiclk_soc;

  localparam int REF_CLK_PERIOD_NS = 10;
  localparam int UART_BAUD         = 115200;
  localparam int UART_BIT_NS       = 8680;
  localparam int UART_BYTES        = 20;
  localparam int TIMEOUT_NS        = 5_000_000;

  reg         ref_clk;
  reg         rst_n;
  reg         start;
  reg         uart_rxd;
  reg [127:0] aes_key_ext;
  reg [127:0] aes_pt_ext;
  reg         aes_vec_valid;
  wire        uart_txd;
  wire        done;
  wire        pass;
  wire        clk_fast;
  wire        clk_div2;
  wire        clk_div4;
  wire        clk_div8;
  reg         test_mode;
  reg         scan_en;
  reg         scan_in;
  wire        scan_out;

  string case_name;
  string summary_path;
  integer summary_fd;
  integer i;
  integer rx_count;
  reg timeout_hit;

  reg [7:0] observed_bytes [0:UART_BYTES-1];
  reg [7:0] expected_bytes [0:UART_BYTES-1];
  reg [127:0] expected_ct;
  reg [31:0]  expected_crc;

  top_mcu_pll_sram_multiclk_soc dut (
    .ref_clk(ref_clk),
    .rst_n(rst_n),
    .start(start),
    .uart_rxd(uart_rxd),
    .aes_key_ext(aes_key_ext),
    .aes_pt_ext(aes_pt_ext),
    .aes_vec_valid(aes_vec_valid),
    .uart_txd(uart_txd),
    .done(done),
    .pass(pass),
    .clk_fast(clk_fast),
    .clk_div2(clk_div2),
    .clk_div4(clk_div4),
    .clk_div8(clk_div8),
    .test_mode(test_mode),
    .scan_en(scan_en),
    .scan_in(scan_in),
    .scan_out(scan_out)
  );

  always #(REF_CLK_PERIOD_NS/2) ref_clk = ~ref_clk;

  task automatic log_line(input string msg);
    begin
      $display("%s", msg);
      if (summary_fd != 0) $fdisplay(summary_fd, "%s", msg);
    end
  endtask

  task automatic fill_expected_bytes;
    begin
      expected_bytes[0]  = expected_ct[127:120];
      expected_bytes[1]  = expected_ct[119:112];
      expected_bytes[2]  = expected_ct[111:104];
      expected_bytes[3]  = expected_ct[103:96];
      expected_bytes[4]  = expected_ct[95:88];
      expected_bytes[5]  = expected_ct[87:80];
      expected_bytes[6]  = expected_ct[79:72];
      expected_bytes[7]  = expected_ct[71:64];
      expected_bytes[8]  = expected_ct[63:56];
      expected_bytes[9]  = expected_ct[55:48];
      expected_bytes[10] = expected_ct[47:40];
      expected_bytes[11] = expected_ct[39:32];
      expected_bytes[12] = expected_ct[31:24];
      expected_bytes[13] = expected_ct[23:16];
      expected_bytes[14] = expected_ct[15:8];
      expected_bytes[15] = expected_ct[7:0];
      expected_bytes[16] = expected_crc[31:24];
      expected_bytes[17] = expected_crc[23:16];
      expected_bytes[18] = expected_crc[15:8];
      expected_bytes[19] = expected_crc[7:0];
    end
  endtask

  task automatic load_case;
    begin
      aes_vec_valid = 1'b0;
      aes_key_ext   = 128'd0;
      aes_pt_ext    = 128'd0;

      if (case_name == "default_nist") begin
        expected_ct  = 128'h69C4E0D86A7B0430D8CDB78070B4C55A;
        expected_crc = 32'h3F6EA62F;
      end else if (case_name == "ext_zero") begin
        aes_vec_valid = 1'b1;
        aes_key_ext   = 128'h00000000000000000000000000000000;
        aes_pt_ext    = 128'h00000000000000000000000000000000;
        expected_ct   = 128'h66E94BD4EF8A2C3B884CFA59CA342B2E;
        expected_crc  = 32'hE7270EF5;
      end else if (case_name == "ext_ecb_nist") begin
        aes_vec_valid = 1'b1;
        aes_key_ext   = 128'h2B7E151628AED2A6ABF7158809CF4F3C;
        aes_pt_ext    = 128'h6BC1BEE22E409F96E93D7E117393172A;
        expected_ct   = 128'h3AD77BB40D7A3660A89ECAF32466EF97;
        expected_crc  = 32'h04647086;
      end else begin
        $fatal(1, "Unsupported CASE=%s", case_name);
      end

      fill_expected_bytes();
    end
  endtask

  task automatic collect_uart_stream;
    reg [7:0] byte_val;
    integer bit_idx;
    begin
      rx_count = 0;
      while (rx_count < UART_BYTES) begin
        @(negedge uart_txd);
        #(UART_BIT_NS + (UART_BIT_NS/2));
        for (bit_idx = 0; bit_idx < 8; bit_idx = bit_idx + 1) begin
          byte_val[bit_idx] = uart_txd;
          #(UART_BIT_NS);
        end
        if (uart_txd !== 1'b1) begin
          log_line($sformatf("[TB][FAIL] case=%s reason=UART_STOP_BIT idx=%0d time=%0t", case_name, rx_count, $time));
          $finish;
        end
        observed_bytes[rx_count] = byte_val;
        log_line($sformatf("[TB][INFO] case=%s uart_byte[%0d]=%02x", case_name, rx_count, byte_val));
        rx_count = rx_count + 1;
        #(UART_BIT_NS);
      end
    end
  endtask

  task automatic compare_results;
    reg mismatch;
    begin
      mismatch = 1'b0;
      if (!done) begin
        log_line($sformatf("[TB][FAIL] case=%s reason=DONE_LOW", case_name));
        mismatch = 1'b1;
      end
      if (!pass) begin
        log_line($sformatf("[TB][FAIL] case=%s reason=PASS_LOW", case_name));
        mismatch = 1'b1;
      end
      if (rx_count != UART_BYTES) begin
        log_line($sformatf("[TB][FAIL] case=%s reason=UART_LENGTH got=%0d exp=%0d", case_name, rx_count, UART_BYTES));
        mismatch = 1'b1;
      end
      for (i = 0; i < UART_BYTES; i = i + 1) begin
        if (observed_bytes[i] !== expected_bytes[i]) begin
          log_line($sformatf("[TB][FAIL] case=%s reason=UART_BYTE_MISMATCH idx=%0d exp=%02x got=%02x time=%0t", case_name, i, expected_bytes[i], observed_bytes[i], $time));
          mismatch = 1'b1;
        end
      end

      if (mismatch) begin
        log_line($sformatf("[TB][FAIL] case=%s exp_ct=%032h got_ct=%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x", case_name, expected_ct,
          observed_bytes[0], observed_bytes[1], observed_bytes[2], observed_bytes[3], observed_bytes[4], observed_bytes[5], observed_bytes[6], observed_bytes[7],
          observed_bytes[8], observed_bytes[9], observed_bytes[10], observed_bytes[11], observed_bytes[12], observed_bytes[13], observed_bytes[14], observed_bytes[15]));
        log_line($sformatf("[TB][FAIL] case=%s exp_crc=%08h got_crc=%02x%02x%02x%02x", case_name, expected_crc,
          observed_bytes[16], observed_bytes[17], observed_bytes[18], observed_bytes[19]));
        $finish;
      end

      log_line($sformatf("[TB][PASS] case=%s done=%0b pass=%0b", case_name, done, pass));
      log_line($sformatf("[TB][PASS] exp_ct=%032h", expected_ct));
      log_line($sformatf("[TB][PASS] exp_crc=%08h", expected_crc));
    end
  endtask

  initial begin
    ref_clk      = 1'b0;
    rst_n        = 1'b0;
    start        = 1'b0;
    uart_rxd     = 1'b1;
    aes_key_ext  = 128'd0;
    aes_pt_ext   = 128'd0;
    aes_vec_valid= 1'b0;
    test_mode    = 1'b1;
    scan_en      = 1'b0;
    scan_in      = 1'b0;
    timeout_hit  = 1'b0;
    rx_count     = 0;

    if (!$value$plusargs("CASE=%s", case_name))
      case_name = "default_nist";

    if (!$value$plusargs("SUMMARY=%s", summary_path))
      summary_path = "./summary.log";

    summary_fd = $fopen(summary_path, "w");
    if (summary_fd == 0)
      $fatal(1, "Cannot open summary file: %s", summary_path);

    load_case();
    repeat (10) @(posedge ref_clk);
    rst_n = 1'b1;
    repeat (20) @(posedge ref_clk);
    start = 1'b1;
    @(posedge ref_clk);
    start = 1'b0;

    fork
      begin
        collect_uart_stream();
      end
      begin
        #TIMEOUT_NS;
        timeout_hit = 1'b1;
      end
    join_none

    wait ((rx_count == UART_BYTES && done) || timeout_hit);

    if (timeout_hit) begin
      log_line($sformatf("[TB][FAIL] case=%s reason=TIMEOUT wait=%0dns", case_name, TIMEOUT_NS));
      $finish;
    end

    repeat (20) @(posedge ref_clk);
    compare_results();
    $fclose(summary_fd);
    $finish;
  end

endmodule
```

- [ ] **Step 2: Run the testbench once to verify the compile succeeds**

Run:
```bash
env ver=tb_compile case_name=default_nist /DATA/home/edu135/aes128_core/1_vcs/0_script/run.csh
```

Expected:
- compile completes cleanly enough to produce `2_output/tb_compile/simv`

- [ ] **Step 3: Fix any compile-time type or syntax issues immediately**

Run after each fix:
```bash
env ver=tb_compile case_name=default_nist /DATA/home/edu135/aes128_core/1_vcs/0_script/run.csh
```

Expected:
- no unresolved modules
- no fatal syntax errors

- [ ] **Step 4: Commit**

```bash
git add 1_vcs/1_input/tb
git commit -m "test: add self-checking VCS top-level testbench"
```

### Task 4: Run Smoke Test On The Built-In Vector

**Files:**
- Verify: `1_vcs/3_log/smoke_default_compile.log`
- Verify: `1_vcs/3_log/smoke_default_run.log`
- Verify: `1_vcs/4_report/smoke_default/summary.log`

- [ ] **Step 1: Run the default smoke case**

Run:
```bash
env ver=smoke_default case_name=default_nist /DATA/home/edu135/aes128_core/1_vcs/0_script/run.csh
```

Expected:
- summary contains:
```text
[TB][PASS] case=default_nist done=1 pass=1
[TB][PASS] exp_ct=69c4e0d86a7b0430d8cdb78070b4c55a
[TB][PASS] exp_crc=3f6ea62f
```

- [ ] **Step 2: Inspect the UART byte log if the smoke test fails**

Look for lines like:
```text
[TB][INFO] case=default_nist uart_byte[0]=69
[TB][INFO] case=default_nist uart_byte[19]=2f
```

Expected:
- exactly 20 byte logs exist

- [ ] **Step 3: If the smoke test fails, debug in this order**

Check:
```text
1. test_mode is held at 1
2. ref_clk period is 10ns
3. uart_txd decode timing uses 8680ns bit time
4. copied SRAM model is included before RTL wrapper
5. observed bytes match ciphertext-first, CRC-second ordering
```

- [ ] **Step 4: Commit**

```bash
git add 1_vcs/3_log 1_vcs/4_report
git commit -m "test: validate default top-level AES smoke case"
```

### Task 5: Run External-Vector Regression

**Files:**
- Verify: `1_vcs/3_log/ext_zero_run.log`
- Verify: `1_vcs/3_log/ext_ecb_nist_run.log`
- Verify: `1_vcs/4_report/ext_zero/summary.log`
- Verify: `1_vcs/4_report/ext_ecb_nist/summary.log`

- [ ] **Step 1: Run the all-zero external-vector case**

Run:
```bash
env ver=ext_zero case_name=ext_zero /DATA/home/edu135/aes128_core/1_vcs/0_script/run.csh
```

Expected:
- summary contains:
```text
[TB][PASS] case=ext_zero done=1 pass=1
[TB][PASS] exp_ct=66e94bd4ef8a2c3b884cfa59ca342b2e
[TB][PASS] exp_crc=e7270ef5
```

- [ ] **Step 2: Run the NIST external-vector case**

Run:
```bash
env ver=ext_ecb_nist case_name=ext_ecb_nist /DATA/home/edu135/aes128_core/1_vcs/0_script/run.csh
```

Expected:
- summary contains:
```text
[TB][PASS] case=ext_ecb_nist done=1 pass=1
[TB][PASS] exp_ct=3ad77bb40d7a3660a89ecaf32466ef97
[TB][PASS] exp_crc=04647086
```

- [ ] **Step 3: Verify regression coverage is still top-level only**

Check:
```text
- each test instantiates top_mcu_pll_sram_multiclk_soc
- no direct instantiation of soc_ctrl_multiclk_soc is added
- scoreboard verdict comes from UART stream comparison, not only DUT pass
```

- [ ] **Step 4: Commit**

```bash
git add 1_vcs/3_log 1_vcs/4_report
git commit -m "test: add top-level external-vector regression coverage"
```

### Task 6: Final Verification Sweep

**Files:**
- Verify: `1_vcs/3_log/*.log`
- Verify: `1_vcs/4_report/*/summary.log`

- [ ] **Step 1: Re-run all planned cases with fresh version tags**

Run:
```bash
env ver=final_default case_name=default_nist /DATA/home/edu135/aes128_core/1_vcs/0_script/run.csh
env ver=final_ext_zero case_name=ext_zero /DATA/home/edu135/aes128_core/1_vcs/0_script/run.csh
env ver=final_ext_ecb_nist case_name=ext_ecb_nist /DATA/home/edu135/aes128_core/1_vcs/0_script/run.csh
```

Expected:
- all three runs complete with pass summaries

- [ ] **Step 2: Confirm the final pass signatures**

Check for these lines:
```text
[TB][PASS] case=default_nist done=1 pass=1
[TB][PASS] case=ext_zero done=1 pass=1
[TB][PASS] case=ext_ecb_nist done=1 pass=1
```

- [ ] **Step 3: Record the final verification statement**

Use this exact summary text in the handoff note:
```text
Verified top_mcu_pll_sram_multiclk_soc in VCS using copied RTL, SAED SRAM model, test_mode-based PLL bypass, and a self-checking UART scoreboard across 3 known-answer cases.
```

- [ ] **Step 4: Commit**

```bash
git add 1_vcs
git commit -m "test: finalize top-level VCS verification environment"
```
