module top_mcu_pll_sram_multiclk_soc (
  input  ref_clk,
  input  rst_n,
  input  start,          // optional external start
  input  uart_rxd,
  input  [127:0] aes_key_ext,
  input  [127:0] aes_pt_ext,
  input          aes_vec_valid,
  output uart_txd,
  output done,
  output pass,

  // observe clocks (do not create_clock on output ports)
  output clk_fast,
  output clk_div2,
  output clk_div4,
  output clk_div8,

  // DFT passthrough
  input  test_mode,
  input  scan_en,
  input  scan_in,
  output scan_out
);

  // tie power/analog pins for sim
  //wire DVDD;
  //wire VSS;
  //wire AVDD;

  wire FB_CLK = 1'b0;
  wire FB_MODE = 1'b0;
  wire PLL_BYPASS = 1'b0;
  // ---------------------------------------------------------
  // DFT: test_mode 시 내부 클록을 ref_clk로 우회시키기 위한 내부 net
  // ---------------------------------------------------------
  wire pll_clk_fast;
  wire pll_clk_div2;
  wire pll_clk_div4;

  wire clk_fast_int;
  wire clk_div2_int;
  wire clk_div4_int;

  // div8은 divider 출력 + test bypass mux
  wire clk_div8_func;
  wire clk_div8_int;
  wire test_mode_int;
`ifdef SIM
    assign test_mode_int = 1'b0;
`else
    assign test_mode_int = test_mode;
`endif

  // test_mode=1이면 ATE가 주는 ref_clk로 모든 내부 클록을 구동
  assign clk_fast_int = (test_mode_int) ? ref_clk : pll_clk_fast;
  assign clk_div2_int = (test_mode_int) ? ref_clk : pll_clk_div2;
  assign clk_div4_int = (test_mode_int) ? ref_clk : pll_clk_div4;
  assign clk_div8_int = (test_mode_int) ? ref_clk : clk_div8_func;

  // 출력 포트는 "실제로 내부에서 쓰는 클록"을 보여주도록 연결
  assign clk_fast = clk_fast_int;
  assign clk_div2 = clk_div2_int;
  assign clk_div4 = clk_div4_int;
  assign clk_div8 = clk_div8_int;

`ifdef SIM
  PLL u_pll (
    //.DVDD (DVDD),
    //.VSS (VSS),
    //.AVDD (AVDD),
    .REF_CLK(ref_clk),
    .FB_CLK(FB_CLK),
    .FB_MODE(FB_MODE),
    .PLL_BYPASS(PLL_BYPASS),
    .CLK_4X(pll_clk_fast),
    .CLK_2X(pll_clk_div2),
    .CLK_1X(pll_clk_div4)
  );
`else
  PLL u_pll (
    //.DVDD (DVDD),
    //.VSS (VSS),
    //.AVDD (AVDD),
    .REF_CLK(ref_clk),
    .FB_CLK(FB_CLK),
    .FB_MODE(FB_MODE),
    .PLL_BYPASS(PLL_BYPASS),
    .CLK_4X(pll_clk_fast),
    .CLK_2X(pll_clk_div2),
    .CLK_1X(pll_clk_div4)
  );
`endif

  // div8 from div4
  clk_div2_toggle u_div8 (
    .clk_in (clk_div4_int),
    .rst_n  (rst_n),
    .clk_out(clk_div8_func)
  );

  // SRAM wrapper (clocked on clk_div2)
  wire        mem_cs, mem_we, mem_oe;
  wire [9:0]  mem_addr;
  wire [7:0]  mem_wdata;
  wire [7:0]  mem_rdata;
  //wire VDD ;

  sram_wrap_1rw1024x8 u_mem (
    .clk   (clk_div2_int),
    //.VDD   (VDD),
    //.VSS   (VSS),
    .cs    (mem_cs),
    .we    (mem_we),
    .oe    (mem_oe),
    .addr  (mem_addr),
    .wdata (mem_wdata),
    .rdata (mem_rdata)
  );

  soc_ctrl_multiclk_soc u_ctrl (
    .clk_fast (clk_fast_int),
    .clk_div2 (clk_div2_int),
    .clk_div4 (clk_div4_int),
    .clk_div8 (clk_div8_int),
    .rst_n    (rst_n),
    .start_ext(start),
    .uart_rxd (uart_rxd),
    .aes_key_ext(aes_key_ext),
    .aes_pt_ext (aes_pt_ext),
    .aes_vec_valid(aes_vec_valid),
    .uart_txd (uart_txd),
    .done     (done),
    .pass     (pass),

    .mem_cs   (mem_cs),
    .mem_we   (mem_we),
    .mem_oe   (mem_oe),
    .mem_addr (mem_addr),
    .mem_wdata(mem_wdata),
    .mem_rdata(mem_rdata),

    .test_mode(test_mode),
    .scan_en  (scan_en),
    .scan_in  (scan_in),
    .scan_out (scan_out)
  );

endmodule
