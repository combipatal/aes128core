// ------------------------------------------------------------
// Simple latch-based Integrated Clock Gating (ICG) model
// - Synthesis-friendly (latch + AND)
// - Keeps clock ON during test/scan via test_en
//
// NOTE:
// In real SoC flows this is typically replaced/mapped to a
// technology ICG cell (e.g. CGL*/ICG*/CLKGATE*).
// ------------------------------------------------------------
module icg_latch (
  input  wire clk,
  input  wire en,
  input  wire test_en,
  output wire gclk
);
  reg en_lat;

  // Level-sensitive latch transparent when clk is LOW
  always @ (clk or en or test_en) begin
    if (!clk) en_lat = (en | test_en);
  end

  assign gclk = clk & en_lat;
endmodule
