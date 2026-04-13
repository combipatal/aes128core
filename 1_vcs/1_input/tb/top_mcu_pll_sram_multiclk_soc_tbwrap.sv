`timescale 1ns/1ps

// Simulation-only wrapper that preserves the old external AES vector ingress
// after the production top drops those ports.
module top_mcu_pll_sram_multiclk_soc_tbwrap (
  input  wire         ref_clk,
  input  wire         rst_n,
  input  wire         start,
  input  wire         uart_rxd,
  input  wire [127:0] aes_key_ext,
  input  wire [127:0] aes_pt_ext,
  input  wire         aes_vec_valid,
  output wire         uart_txd,
  output wire         done,
  output wire         pass,
  output wire         clk_fast,
  output wire         clk_div2,
  output wire         clk_div4,
  output wire         clk_div8,
  input  wire         test_mode,
  input  wire         scan_en,
  input  wire         scan_in,
  output wire         scan_out
);

  wire FB_CLK = 1'b0;
  wire FB_MODE = 1'b0;
  wire PLL_BYPASS = 1'b0;

  wire pll_clk_fast;
  wire pll_clk_div2;
  wire pll_clk_div4;

  wire clk_fast_int;
  wire clk_div2_int;
  wire clk_div4_int;
  wire clk_div8_func;
  wire clk_div8_int;
  wire test_mode_int;

`ifdef SIM
  assign test_mode_int = 1'b0;
`else
  assign test_mode_int = test_mode;
`endif

  assign clk_fast_int = (test_mode_int) ? ref_clk : pll_clk_fast;
  assign clk_div2_int = (test_mode_int) ? ref_clk : pll_clk_div2;
  assign clk_div4_int = (test_mode_int) ? ref_clk : pll_clk_div4;
  assign clk_div8_int = (test_mode_int) ? ref_clk : clk_div8_func;

  assign clk_fast = clk_fast_int;
  assign clk_div2 = clk_div2_int;
  assign clk_div4 = clk_div4_int;
  assign clk_div8 = clk_div8_int;

  PLL u_pll (
    .REF_CLK(ref_clk),
    .FB_CLK(FB_CLK),
    .FB_MODE(FB_MODE),
    .PLL_BYPASS(PLL_BYPASS),
    .CLK_4X(pll_clk_fast),
    .CLK_2X(pll_clk_div2),
    .CLK_1X(pll_clk_div4)
  );

  clk_div2_toggle u_div8 (
    .clk_in (clk_div4_int),
    .rst_n  (rst_n),
    .clk_out(clk_div8_func)
  );

  wire        mem_cs;
  wire        mem_we;
  wire        mem_oe;
  wire [9:0]  mem_addr;
  wire [7:0]  mem_wdata;
  wire [7:0]  mem_rdata;

  sram_wrap_1rw1024x8 u_mem (
    .clk   (clk_div2_int),
    .cs    (mem_cs),
    .we    (mem_we),
    .oe    (mem_oe),
    .addr  (mem_addr),
    .wdata (mem_wdata),
    .rdata (mem_rdata)
  );

  soc_ctrl_multiclk_soc u_ctrl (
    .clk_fast     (clk_fast_int),
    .clk_div2     (clk_div2_int),
    .clk_div4     (clk_div4_int),
    .clk_div8     (clk_div8_int),
    .rst_n        (rst_n),
    .start_ext    (start),
    .uart_rxd     (uart_rxd),
    .aes_key_ext  (aes_key_ext),
    .aes_pt_ext   (aes_pt_ext),
    .aes_vec_valid(aes_vec_valid),
    .uart_txd     (uart_txd),
    .done         (done),
    .pass         (pass),
    .mem_cs       (mem_cs),
    .mem_we       (mem_we),
    .mem_oe       (mem_oe),
    .mem_addr     (mem_addr),
    .mem_wdata    (mem_wdata),
    .mem_rdata    (mem_rdata),
    .test_mode    (test_mode),
    .scan_en      (scan_en),
    .scan_in      (scan_in),
    .scan_out     (scan_out)
  );

endmodule
