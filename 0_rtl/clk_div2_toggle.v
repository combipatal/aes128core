module clk_div2_toggle (
  input  clk_in,
  input  rst_n,
  output reg clk_out
);
  always @(posedge clk_in or negedge rst_n) begin
    if (!rst_n) clk_out <= 1'b0;
    else        clk_out <= ~clk_out;
  end
endmodule
