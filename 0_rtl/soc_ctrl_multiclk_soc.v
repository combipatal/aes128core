module soc_ctrl_multiclk_soc (
  input  clk_fast,
  input  clk_div2,
  input  clk_div4,
  input  clk_div8,
  input  rst_n,
  input  start_ext,
  input  uart_rxd,
  input  [127:0] aes_key_ext,
  input  [127:0] aes_pt_ext,
  input          aes_vec_valid,
  output uart_txd,
  output reg done,
  output reg pass,

  output reg        mem_cs,
  output reg        mem_we,
  output reg        mem_oe,
  output reg [9:0]  mem_addr,
  output reg [7:0]  mem_wdata,
  input      [7:0]  mem_rdata,

  input  test_mode,
  input  scan_en,
  input  scan_in,
  output scan_out
);

  // ------------------------------------------------------------
  // Test/scan override for clock gating
  // ------------------------------------------------------------
  wire test_or_scan = test_mode | scan_en;

  // ------------------------------------------------------------
  // clk_div8 heartbeat/timer (ensures clk_div8 is used)
  // ------------------------------------------------------------
  reg [15:0] tmr8;
  always @(posedge clk_div8 or negedge rst_n) begin
    if (!rst_n) tmr8 <= 16'd0;
    else        tmr8 <= tmr8 + 16'd1;
  end

  // ------------------------------------------------------------
  // UART RX/TX on clk_div4
  // - Receive 0xA5 to start (optional)
  // - Transmit ciphertext (16 bytes) + CRC32 (4 bytes)
  // ------------------------------------------------------------
  // NOTE: CLK_HZ is an estimate; adjust to your PLL ratio if needed.
  // For synthesis, this only affects divider constants in logic.
  localparam integer UART_CLK_HZ = 100_000_000;
  localparam integer UART_BAUD   = 115200;

  wire rx_valid;
  wire [7:0] rx_data;
  uart_rx #(.CLK_HZ(UART_CLK_HZ), .BAUD(UART_BAUD)) u_rx (
    .clk(clk_div4), .rst_n(rst_n), .rxd(uart_rxd),
    .rx_valid(rx_valid), .rx_data(rx_data)
  );

  reg start_uart_cmd;
  reg done_div4_ff1, done_div4_ff2;
  wire done_div4 = done_div4_ff2;
  always @(posedge clk_div4 or negedge rst_n) begin
    if (!rst_n) begin
      done_div4_ff1 <= 1'b0;
      done_div4_ff2 <= 1'b0;
    end else begin
      done_div4_ff1 <= done;
      done_div4_ff2 <= done_div4_ff1;
    end
  end

  always @(posedge clk_div4 or negedge rst_n) begin
    if (!rst_n) start_uart_cmd <= 1'b0;
    else if (rx_valid && (rx_data == 8'hA5)) start_uart_cmd <= 1'b1;
    else if (done_div4) start_uart_cmd <= 1'b0;
  end

  // TX
  reg tx_start;
  reg [7:0] tx_data;
  wire tx_busy;
  reg        tx_buf_valid;
  reg [7:0]  tx_buf_data;
  uart_tx #(.CLK_HZ(UART_CLK_HZ), .BAUD(UART_BAUD)) u_tx (
    .clk(clk_div4), .rst_n(rst_n),
    .tx_start(tx_start), .tx_data(tx_data),
    .txd(uart_txd), .tx_busy(tx_busy)
  );

  // ------------------------------------------------------------
  // AES on clk_fast
  // ------------------------------------------------------------
  reg aes_start;
  wire aes_busy, aes_done;
  reg [127:0] aes_key, aes_pt;
  wire [127:0] aes_ct;

  // Fixed vectors (can be replaced by UART load as an extension)
  // NIST known test vector:
  // key = 000102030405060708090a0b0c0d0e0f
  // pt  = 00112233445566778899aabbccddeeff
  // ct  = 69c4e0d86a7b0430d8cdb78070b4c55a  // Fixed vectors (default; SIM_EXTVEC can override key/PT at start)
  localparam [127:0] AES_KEY_DFLT = 128'h000102030405060708090A0B0C0D0E0F;
  localparam [127:0] AES_PT_DFLT  = 128'h00112233445566778899AABBCCDDEEFF;
  reg use_ext_vec_active;
  // ------------------------------------------------------------
  // Optional: clock gate the AES core clock using a latch-based ICG
  // - Functional enable: aes_clk_req (asserted while AES is active)
  // - Test/scan override: keep clock running when test_mode/scan_en is high
  // ------------------------------------------------------------
  reg aes_done_ff1;
  wire clk_fast_aes;
  reg  aes_clk_req;
  wire aes_done_pulse = aes_done & ~aes_done_ff1;

  // Hold AES clock enable from start until AES done
  always @(posedge clk_fast or negedge rst_n) begin
    if (!rst_n) aes_clk_req <= 1'b0;
    else begin
      if (aes_start)          aes_clk_req <= 1'b1;
      else if (aes_done_pulse) aes_clk_req <= 1'b0;
    end
  end

  icg_latch u_icg_aes (
    .clk     (clk_fast),
    .en      (aes_clk_req),
    .test_en (test_or_scan),
    .gclk    (clk_fast_aes)
  );

  aes128_core_rewrite u_aes (
    .clk(clk_fast_aes), .rst_n(rst_n),
    .start(aes_start),
    .key_in(aes_key),
    .pt_in(aes_pt),
    .busy(aes_busy),
    .done(aes_done),
    .ct_out(aes_ct)
  );

  // AES done pulse -> transfer ciphertext to clk_div2 domain via CDC toggle
  always @(posedge clk_fast or negedge rst_n) begin
    if (!rst_n) aes_done_ff1 <= 1'b0;
    else        aes_done_ff1 <= aes_done;
  end

  /*
  reg [127:0] ct_hold_fast;
  always @(posedge clk_fast or negedge rst_n) begin
    if (!rst_n) ct_hold_fast <= 128'd0;
    else if (aes_done_pulse) ct_hold그럼 _fast <= aes_ct;
  end
  */

  // aes_ct is already a fast-domain register output from u_aes and remains
  // stable after done until the next transaction, so a second 128-bit shadow
  // capture is unnecessary and creates a large aes_done_pulse-driven fanout.
  wire [127:0] ct_fast_bus = aes_ct;

  // CDC handshake: fast -> div2
  wire ct_xfer_pulse_div2;
  reg ct_req_pulse_fast;
  wire ct_busy_fast;
  reg [2:0] sst;
  localparam [2:0] S_IDLE=0, S_LOAD=1, S_W=2, S_R=3, S_RWAIT=4, S_CHK=5, S_FIN=6, S_DONE=7;
  wire ct_ready_div2 = (sst == S_IDLE);
  always @(posedge clk_fast or negedge rst_n) begin
    if (!rst_n) ct_req_pulse_fast <= 1'b0;
    else        ct_req_pulse_fast <= aes_done_pulse;
  end

  cdc_toggle_sync u_ct_cdc (
    .clk_src(clk_fast),
    .rst_n_src(rst_n),
    .pulse_src(ct_req_pulse_fast),
    .busy_src(ct_busy_fast),
    .clk_dst(clk_div2),
    .rst_n_dst(rst_n),
    .ready_dst(ct_ready_div2),
    .pulse_dst(ct_xfer_pulse_div2)
  );

  // ------------------------------------------------------------
  // clk_div2 domain: SRAM write ciphertext + CRC32 over ciphertext bytes
  // ------------------------------------------------------------
  reg [127:0] ct_hold_div2;

  // CRC engine
  reg crc_start, crc_finish, crc_dv;
  reg [7:0] crc_byte;
  wire crc_done;
  wire [31:0] crc_out;

  crc32_byte u_crc (
    .clk(clk_div2), .rst_n(rst_n),
    .start(crc_start),
    .data_valid(crc_dv),
    .data_byte(crc_byte),
    .finish(crc_finish),
    .done(crc_done),
    .crc_out(crc_out)
  );

  // SRAM state machine on clk_div2
  // Keep the one-shot 128-bit landing register for CDC ownership, but stop
  // re-slicing it repeatedly in the active write/read/TX cones.
  /* reg [4:0] byte_idx; */
  reg [3:0] wr_idx;
  reg [3:0] rd_idx;
  reg [3:0] load_idx;
  reg fail;
  reg [7:0] wr_byte_cur;
  reg [7:0] rd_byte_exp;
  reg [7:0] tx_ct_byte_cur;
  /* wire byte_idx_last = (byte_idx == 5'd15); */
  /* wire [9:0] mem_addr_cur = {5'd0, byte_idx}; */
  /* wire [7:0] ct_byte_cur = ct_hold_div2[127 - byte_idx*8 -: 8]; */
  wire load_idx_last = (load_idx == 4'd15);
  wire wr_idx_last = (wr_idx == 4'd15);
  wire rd_idx_last = (rd_idx == 4'd15);
  wire [9:0] mem_addr_w = {6'd0, wr_idx};
  wire [9:0] mem_addr_r = {6'd0, rd_idx};
  wire sst_is_idle = (sst == S_IDLE);
  wire sst_is_done = (sst == S_DONE);
  wire ct_byte_mismatch = (mem_rdata !== rd_byte_exp);

  function [7:0] select_ct_byte;
    input [127:0] ct_bus;
    input [3:0] idx;
    begin
      case (idx)
        4'd0:  select_ct_byte = ct_bus[127:120];
        4'd1:  select_ct_byte = ct_bus[119:112];
        4'd2:  select_ct_byte = ct_bus[111:104];
        4'd3:  select_ct_byte = ct_bus[103:96];
        4'd4:  select_ct_byte = ct_bus[95:88];
        4'd5:  select_ct_byte = ct_bus[87:80];
        4'd6:  select_ct_byte = ct_bus[79:72];
        4'd7:  select_ct_byte = ct_bus[71:64];
        4'd8:  select_ct_byte = ct_bus[63:56];
        4'd9:  select_ct_byte = ct_bus[55:48];
        4'd10: select_ct_byte = ct_bus[47:40];
        4'd11: select_ct_byte = ct_bus[39:32];
        4'd12: select_ct_byte = ct_bus[31:24];
        4'd13: select_ct_byte = ct_bus[23:16];
        4'd14: select_ct_byte = ct_bus[15:8];
        4'd15: select_ct_byte = ct_bus[7:0];
        default: select_ct_byte = 8'h00;
      endcase
    end
  endfunction

  // We'll store ciphertext bytes at SRAM addresses 0..15
  // Then read back 0..15 to verify, feeding CRC.
  always @(posedge clk_div2 or negedge rst_n) begin
    if (!rst_n) begin
      sst <= S_IDLE;
      ct_hold_div2 <= 128'd0;
      load_idx <= 4'd0;
      wr_idx <= 4'd0;
      rd_idx <= 4'd0;
      mem_cs <= 1'b0; mem_we <= 1'b0; mem_oe <= 1'b0;
      mem_addr <= 10'd0; mem_wdata <= 8'd0;
      fail <= 1'b0;
      wr_byte_cur <= 8'd0;
      rd_byte_exp <= 8'd0;
      crc_start <= 1'b0; crc_finish <= 1'b0; crc_dv <= 1'b0; crc_byte <= 8'd0;
    end else begin
      crc_start <= 1'b0;
      crc_finish <= 1'b0;
      crc_dv <= 1'b0;

      case (sst)
        S_IDLE: begin
          mem_cs <= 1'b0; mem_we <= 1'b0; mem_oe <= 1'b0;
          load_idx <= 4'd0;
          wr_idx <= 4'd0;
          rd_idx <= 4'd0;
          fail <= 1'b0;
          if (ct_xfer_pulse_div2) begin
            sst <= S_LOAD;
          end
        end

        S_LOAD: begin
          ct_hold_div2[127 - load_idx*8 -: 8] <= select_ct_byte(ct_fast_bus, load_idx);
          if (load_idx_last) begin
            wr_idx <= 4'd0;
            rd_idx <= 4'd0;
            wr_byte_cur <= ct_fast_bus[127:120];
            crc_start <= 1'b1;
            sst <= S_W;
          end else begin
            load_idx <= load_idx + 4'd1;
          end
        end

        S_W: begin
          mem_cs <= 1'b1;
          mem_we <= 1'b1;
          mem_oe <= 1'b0;
          /*
          mem_addr <= {5'd0, byte_idx}; // 0..15
          mem_wdata <= ct_hold_div2[127 - byte_idx*8 -: 8];
          if (byte_idx == 5'd15) begin
          */
          mem_addr <= mem_addr_w; // 0..15
          mem_wdata <= wr_byte_cur;
          if (wr_idx_last) begin
            rd_idx <= 4'd0;
            rd_byte_exp <= ct_hold_div2[127:120];
            sst <= S_R;
          end else begin
            wr_idx <= wr_idx + 4'd1;
            wr_byte_cur <= select_ct_byte(ct_hold_div2, wr_idx + 4'd1);
          end
        end

        S_R: begin
          mem_cs <= 1'b1;
          mem_we <= 1'b0;
          mem_oe <= 1'b1;
          /* mem_addr <= {5'd0, byte_idx}; */
          mem_addr <= mem_addr_r;
          sst <= S_RWAIT;
        end
	S_RWAIT: begin
		  mem_cs <= 1'b1;
		  mem_we <= 1'b0;
		  mem_oe <= 1'b1;
		  /* mem_addr <= {5'd0, byte_idx}; */
		  mem_addr <= mem_addr_r;
		  sst <= S_CHK;
		end

	        S_CHK: begin
	          // compare
	          /* if (mem_rdata !== ct_hold_div2[127 - byte_idx*8 -: 8]) fail <= 1'b1; */
	          if (ct_byte_mismatch) fail <= 1'b1;

	          // feed CRC with read-back byte (meaningful CRC over SRAM-read data)
	          crc_dv <= 1'b1;
	          crc_byte <= mem_rdata;

		  /* if (byte_idx == 5'd15) begin */
		  if (rd_idx_last) begin
		    sst <= S_FIN;
		  end else begin
		    rd_idx <= rd_idx + 4'd1;
		    rd_byte_exp <= select_ct_byte(ct_hold_div2, rd_idx + 4'd1);
		    sst <= S_R;
		  end
	end
	S_FIN: begin
  	  mem_cs <= 1'b0; mem_we <= 1'b0; mem_oe <= 1'b0;
	  crc_finish <= 1'b1;
	  sst <= S_DONE;
	end

        S_DONE: begin
          mem_cs <= 1'b0; mem_we <= 1'b0; mem_oe <= 1'b0;
          // wait crc_done then allow UART transmit
          if (crc_done) begin
            sst <= S_DONE; // hold
          end
        end

        default: sst <= S_IDLE;
      endcase
    end
  end

  // ------------------------------------------------------------
  // div2 -> div4 byte-stream handshake for UART TX
  // - Send 16 ciphertext bytes (from ct_hold_div2) then 4 CRC bytes (MSB first)
  // ------------------------------------------------------------
  // We'll implement a simple "request next byte" handshake using a toggle.
  reg send_go_div2;
  reg send_busy_div2;
  wire send_pulse_div4;
  reg stream_ready_div2;
  reg stream_sent_div2;   // 20바이트 전송 요청(=send_go_div2) 완료 표시
  wire allow_send_div2 = stream_ready_div2 && !send_busy_div2 && !stream_sent_div2;
  reg  allow_send_div2_d;

   cdc_toggle_sync u_send_cdc (
     .clk_src(clk_div2), .rst_n_src(rst_n),
     .pulse_src(send_go_div2),
     .busy_src(send_busy_div2),
     .clk_dst(clk_div4), .rst_n_dst(rst_n),
     .ready_dst(~tx_buf_valid),          // ★ UART가 놀 때만 다음 바이트 요청을 “소비”
     .pulse_dst(send_pulse_div4)
   );

  reg [4:0] tx_idx_div2; // 0..19
  reg [7:0] tx_byte_div2;
  wire tx_idx_is_ct = (tx_idx_div2 < 5'd16);
  wire tx_idx_last = (tx_idx_div2 == 5'd19);
  /* wire [7:0] tx_ct_byte = ct_hold_div2[127 - tx_idx_div2*8 -: 8]; */


always @(posedge clk_div2 or negedge rst_n) begin
  if (!rst_n) begin
    tx_idx_div2       <= 5'd0;
    tx_byte_div2      <= 8'd0;
    tx_ct_byte_cur    <= 8'd0;
    send_go_div2      <= 1'b0;
    stream_ready_div2 <= 1'b0;
    stream_sent_div2  <= 1'b0;
    allow_send_div2_d <= 1'b0;

  end else begin
    send_go_div2 <= 1'b0;
    allow_send_div2_d <= allow_send_div2;

	    // 새 트랜잭션 시작(CT 넘어옴) 시 스트림 상태 리셋
	    if (ct_xfer_pulse_div2 && sst_is_idle) begin
	      tx_idx_div2       <= 5'd0;
          tx_ct_byte_cur    <= 8'd0;
	      stream_ready_div2 <= 1'b0;
	      stream_sent_div2  <= 1'b0;
	    end
		
	    // ready는 "CRC 끝 + SRAM verify 끝(S_DONE)" AND 아직 한 번도 20바이트 전송요청 안했을 때
	    if (sst_is_done && crc_done && !stream_sent_div2) begin
	      stream_ready_div2 <= 1'b1;
          if (tx_idx_div2 == 5'd0)
            tx_ct_byte_cur <= ct_hold_div2[127:120];
	    end
		
	    // 20바이트만 전송 요청하고 멈춤
	    if (allow_send_div2 && !allow_send_div2_d) begin
	      /*
	      if (tx_idx_div2 < 5'd16) begin
	        tx_byte_div2 <= ct_hold_div2[127 - tx_idx_div2*8 -: 8];
	      */
	      if (tx_idx_is_ct) begin
	        tx_byte_div2 <= tx_ct_byte_cur;
	      end else begin
	        case (tx_idx_div2)
	          5'd16: tx_byte_div2 <= crc_out[31:24];
	          5'd17: tx_byte_div2 <= crc_out[23:16];
          5'd18: tx_byte_div2 <= crc_out[15:8];
          5'd19: tx_byte_div2 <= crc_out[7:0];
          default: tx_byte_div2 <= 8'h00;
        endcase
      end

	      send_go_div2 <= 1'b1; // div4로 "1바이트 보내라" 요청
	
	      /* if (tx_idx_div2 == 5'd19) begin */
	      if (tx_idx_last) begin
	        // 마지막 바이트 요청 완료 → 더 이상 보내지 않음
	        stream_sent_div2  <= 1'b1;
	        stream_ready_div2 <= 1'b0;
	        tx_idx_div2       <= 5'd0;
	      end else begin
	        tx_idx_div2 <= tx_idx_div2 + 5'd1;
            if (tx_idx_div2 < 5'd15)
              tx_ct_byte_cur <= select_ct_byte(ct_hold_div2, tx_idx_div2[3:0] + 4'd1);
	      end
	    end
	  end
	end

  // div4: on send_pulse_div4, push tx_byte_div2 into UART TX (one at a time)
  // Need to safely sample tx_byte_div2 in div4 domain: since clocks synchronous and handshake toggles, we can sample directly.
  // For robustness, double-register it.
  reg [7:0] tx_byte_ff1, tx_byte_ff2;
  always @(posedge clk_div4 or negedge rst_n) begin
    if (!rst_n) begin
      tx_byte_ff1 <= 8'd0;
      tx_byte_ff2 <= 8'd0;
    end else begin
      tx_byte_ff1 <= tx_byte_div2;
      tx_byte_ff2 <= tx_byte_ff1;
    end
  end
  reg [4:0] tx_cnt_div4;
  reg tx_all_started_div4;
  reg tx_done_div4;
  reg tx_busy_d;
  reg tx_active_div4;


// UART TX control (1-byte buffer)
// send_pulse_div4는 CDC에서 ready_dst(~tx_busy)일 때만 나오므로
// 여기서는 send_pulse_div4만 보면 됨.
always @(posedge clk_div4 or negedge rst_n) begin
  if (!rst_n) begin
    tx_start     <= 1'b0;
    tx_data      <= 8'd0;
    tx_buf_valid <= 1'b0;
    tx_buf_data  <= 8'd0;
  end else begin
    tx_start <= 1'b0;

    // (1) div2 요청 수신: 버퍼에 저장
    // ready_dst=~tx_buf_valid 이므로, send_pulse_div4는 버퍼가 비었을 때만 들어와야 정상
    if (send_pulse_div4) begin
      tx_buf_data  <= tx_byte_ff2;
      tx_buf_valid <= 1'b1;
    end

    // (2) UART가 idle이면 버퍼를 꺼내 실제 tx_start 발생
    if (!tx_busy && tx_buf_valid) begin
      tx_data      <= tx_buf_data;
      tx_start     <= 1'b1;
      tx_buf_valid <= 1'b0;
    end
  end
end

always @(posedge clk_div4 or negedge rst_n) begin
  if (!rst_n) begin
    tx_cnt_div4         <= 5'd0;
    tx_all_started_div4 <= 1'b0;
    tx_done_div4        <= 1'b0;
    tx_busy_d           <= 1'b0;
    tx_active_div4      <= 1'b0;
  end else begin
    tx_busy_d <= tx_busy;

    // 새 스트림 시작은 "첫 tx_start 관측"으로 정의 (CDC 없이 div4 내부 이벤트만 사용)
    // 새 스트림 시작은 "첫 tx_start 관측"으로 정의
    if (!tx_active_div4 && tx_start) begin
      tx_active_div4      <= 1'b1;
      tx_cnt_div4         <= 5'd1;   // ★ 첫 바이트 시작을 1로 카운트
      tx_all_started_div4 <= 1'b0;
      tx_done_div4        <= 1'b0;

    end else if (tx_active_div4 && tx_start) begin
      // 바이트 시작 카운트 (총 20개면 마지막은 20)
      if (tx_cnt_div4 == 5'd19) begin
        tx_cnt_div4         <= 5'd20;
        tx_all_started_div4 <= 1'b1;  // ★ 20번째 바이트 시작됨
      end else begin
        tx_cnt_div4 <= tx_cnt_div4 + 5'd1;
      end
    end

    // 마지막 바이트 시작된 이후, tx_busy가 1->0으로 떨어지면 전송 완료
    if (tx_active_div4 && tx_all_started_div4 && tx_busy_d && !tx_busy) begin
      tx_done_div4   <= 1'b1;   // 레벨로 유지
      tx_active_div4 <= 1'b0;   // 스트림 종료
    end
  end
end

  // ------------------------------------------------------------
  // Start condition: external start OR UART command
  // - We trigger AES start on clk_fast
  // ------------------------------------------------------------
  // ------------------------------------------------------------
  // sync start_uart_cmd into clk_fast
  reg su_ff1, su_ff2;
  always @(posedge clk_fast or negedge rst_n) begin
    if (!rst_n) begin
      su_ff1 <= 1'b0;
      su_ff2 <= 1'b0;
    end else begin
      su_ff1 <= start_uart_cmd;
      su_ff2 <= su_ff1;
    end
  end

  wire start_fast = start_ext | su_ff2;

  // ------------------------------------------------------------
  // aes_start generation (stretch until AES core goes busy)
  reg start_seen;

  always @(posedge clk_fast or negedge rst_n) begin
    if (!rst_n) begin
      aes_start  <= 1'b0;
      start_seen <= 1'b0;
      aes_key    <= AES_KEY_DFLT;
      aes_pt     <= AES_PT_DFLT;
`ifdef SIM_EXTVEC
      use_ext_vec_active <= 1'b0;
`endif
    end else begin

      // issue start (and keep it high) until AES core reports busy
      if (start_fast && !start_seen && !aes_busy) begin
        aes_start <= 1'b1;

`ifdef SIM_EXTVEC
        if (aes_vec_valid) begin
          aes_key <= aes_key_ext;
          aes_pt  <= aes_pt_ext;
          use_ext_vec_active <= 1'b1;
        end else begin
          aes_key <= AES_KEY_DFLT;
          aes_pt  <= AES_PT_DFLT;
          use_ext_vec_active <= 1'b0;
        end
`endif
        start_seen <= 1'b1;

      end else if (aes_start && aes_busy) begin
        // AES core has accepted start
        aes_start <= 1'b0;
      end

      // allow next transaction after done and start has deasserted
      if (done && !start_fast)
        start_seen <= 1'b0;
    end
  end
   // ------------------------------------------------------------
  // Final done/pass (generated on clk_fast)
  // Pass criteria:
  // - AES produced known ciphertext for test vector (optional check)
  // - SRAM readback matched (fail==0)
  // ------------------------------------------------------------
  // We check ciphertext match on fast domain using known expected.
  

reg txdone_ff1, txdone_ff2;

always @(posedge clk_fast or negedge rst_n) begin
  if (!rst_n) begin
    txdone_ff1 <= 1'b0;
    txdone_ff2 <= 1'b0;
  end else begin
    txdone_ff1 <= tx_done_div4;
    txdone_ff2 <= txdone_ff1;
  end
end

  reg ct_ok;
  always @(posedge clk_fast or negedge rst_n) begin
    if (!rst_n) ct_ok <= 1'b0;
    else if (aes_done_pulse) begin
`ifdef SIM_EXTVEC
      if (use_ext_vec_active) ct_ok <= 1'b1;
      else                    ct_ok <= (aes_ct == 128'h69C4E0D86A7B0430D8CDB78070B4C55A);
`else
      ct_ok <= (aes_ct == 128'h69C4E0D86A7B0430D8CDB78070B4C55A);
`endif
    end
  end

  // bring fail/crc_done to fast domain
  reg fail_ff1, fail_ff2, crc_ff1, crc_ff2;
  reg crc_done_hold;
  always @(posedge clk_fast or negedge rst_n) begin
    if (!rst_n) begin
      fail_ff1 <= 1'b0; fail_ff2 <= 1'b0;
      crc_ff1  <= 1'b0; crc_ff2  <= 1'b0;
      crc_done_hold <= 1'b0;
    end else begin
      fail_ff1 <= fail;
      fail_ff2 <= fail_ff1;

      crc_ff1 <= crc_done;
      crc_ff2 <= crc_ff1;

      // 새 트랜잭션 시작 시 hold 클리어 (start_fast가 처음 들어오는 순간)
      if (start_fast && !start_seen && !aes_busy)
        crc_done_hold <= 1'b0;
      else if (crc_ff2)
        crc_done_hold <= 1'b1;
    end
  end

  // done asserted when CRC done and we've started streaming (or at least ready)
always @(posedge clk_fast or negedge rst_n) begin
  if (!rst_n) begin
    done <= 1'b0;
    pass <= 1'b0;
  end else begin
    // 새 트랜잭션 시작 시 clear (원하면 조건 더 타이트하게)
    if (start_fast && !start_seen && !aes_busy) begin
      done <= 1'b0;
      pass <= 1'b0;
    end

    // 완료 조건 만족 시 1번만 set 후 유지
    if (!done && txdone_ff2 && crc_done_hold && ct_ok) begin
      done <= 1'b1;
      pass <= ~fail_ff2;
    end
  end
end
endmodule
