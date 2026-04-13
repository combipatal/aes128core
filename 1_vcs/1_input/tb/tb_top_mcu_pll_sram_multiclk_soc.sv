`timescale 1ns/1ps

module tb_top_mcu_pll_sram_multiclk_soc;

  localparam integer REF_CLK_PERIOD_NS = 10;
  localparam integer UART_BIT_NS       = 8680;
  localparam integer UART_BYTES        = 20;
  localparam integer TIMEOUT_NS        = 5_000_000;

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
  string wave_path;
  integer summary_fd;
  integer i;
  integer rx_count;
  reg timeout_hit;

  reg [7:0] observed_bytes [0:UART_BYTES-1];
  reg [7:0] expected_bytes [0:UART_BYTES-1];
  reg [127:0] expected_ct;
  reg [31:0]  expected_crc;

  top_mcu_pll_sram_multiclk_soc_tbwrap dut (
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

  task automatic log_line;
    input string msg;
    begin
      $display("%s", msg);
      if (summary_fd != 0)
        $fdisplay(summary_fd, "%s", msg);
    end
  endtask

  task automatic clear_observed_bytes;
    begin
      for (i = 0; i < UART_BYTES; i = i + 1)
        observed_bytes[i] = 8'h00;
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
      clear_observed_bytes();

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
        log_line($sformatf("[TB][FAIL] case=%s exp_ct=%032h got_ct=%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
          case_name, expected_ct,
          observed_bytes[0], observed_bytes[1], observed_bytes[2], observed_bytes[3],
          observed_bytes[4], observed_bytes[5], observed_bytes[6], observed_bytes[7],
          observed_bytes[8], observed_bytes[9], observed_bytes[10], observed_bytes[11],
          observed_bytes[12], observed_bytes[13], observed_bytes[14], observed_bytes[15]));
        log_line($sformatf("[TB][FAIL] case=%s exp_crc=%08h got_crc=%02x%02x%02x%02x",
          case_name, expected_crc,
          observed_bytes[16], observed_bytes[17], observed_bytes[18], observed_bytes[19]));
        $finish;
      end

      log_line($sformatf("[TB][PASS] case=%s done=%0b pass=%0b", case_name, done, pass));
      log_line($sformatf("[TB][PASS] exp_ct=%032h", expected_ct));
      log_line($sformatf("[TB][PASS] exp_crc=%08h", expected_crc));
    end
  endtask

  initial begin
    ref_clk       = 1'b0;
    rst_n         = 1'b0;
    start         = 1'b0;
    uart_rxd      = 1'b1;
    aes_key_ext   = 128'd0;
    aes_pt_ext    = 128'd0;
    aes_vec_valid = 1'b0;
    test_mode     = 1'b1;
    scan_en       = 1'b0;
    scan_in       = 1'b0;
    timeout_hit   = 1'b0;
    rx_count      = 0;
    summary_fd    = 0;

    if (!$value$plusargs("CASE=%s", case_name))
      case_name = "default_nist";

    if (!$value$plusargs("SUMMARY=%s", summary_path))
      summary_path = "./summary.log";

    if ($value$plusargs("WAVE=%s", wave_path)) begin
      $dumpfile(wave_path);
      $dumpvars(0, tb_top_mcu_pll_sram_multiclk_soc);
    end

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
      $fclose(summary_fd);
      $finish;
    end

    repeat (20) @(posedge ref_clk);
    compare_results();
    $fclose(summary_fd);
    $finish;
  end

endmodule
