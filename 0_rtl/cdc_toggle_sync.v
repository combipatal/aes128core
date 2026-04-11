module cdc_toggle_sync (
  input  clk_src,
  input  rst_n_src,
  input  pulse_src,
  output busy_src,

  input  clk_dst,
  input  rst_n_dst,
  input  ready_dst,
  output reg pulse_dst
);

  // src toggle
  reg req_tog_src;

  // dst ack toggle
  reg ack_tog_dst;

  // sync ack into src
  reg ack_ff1, ack_ff2;

  // sync req into dst
  reg req_ff1, req_ff2;
  reg seen_dst;

  // ---------------- SRC ----------------
  always @(posedge clk_src or negedge rst_n_src) begin
    if (!rst_n_src) begin
      req_tog_src <= 1'b0;
      ack_ff1     <= 1'b0;
      ack_ff2     <= 1'b0;
    end else begin
      ack_ff1 <= ack_tog_dst;
      ack_ff2 <= ack_ff1;

      if (pulse_src && (req_tog_src == ack_ff2))
        req_tog_src <= ~req_tog_src;   // idle일 때만 토글
    end
  end

  assign busy_src = (req_tog_src != ack_ff2);

  // ---------------- DST ----------------
  always @(posedge clk_dst or negedge rst_n_dst) begin
    if (!rst_n_dst) begin
      req_ff1     <= 1'b0;
      req_ff2     <= 1'b0;
      seen_dst    <= 1'b0;
      ack_tog_dst <= 1'b0;
      pulse_dst   <= 1'b0;
    end else begin
      pulse_dst <= 1'b0;

      req_ff1 <= req_tog_src;
      req_ff2 <= req_ff1;

      // pending 있고 ready일 때만 소비 + ack + 1cycle pulse
      if ((req_ff2 != seen_dst) && ready_dst) begin
        seen_dst    <= req_ff2;
        ack_tog_dst <= req_ff2;
        pulse_dst   <= 1'b1;
      end
    end
  end

endmodule

