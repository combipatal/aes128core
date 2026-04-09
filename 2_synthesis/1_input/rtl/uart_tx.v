module uart_tx #(
  parameter integer CLK_HZ  = 200_000_000, // adjust per clk_div4 frequency
  parameter integer BAUD    = 115200
)(
  input        clk,
  input        rst_n,
  input        tx_start,
  input  [7:0] tx_data,
  output reg   txd,
  output reg   tx_busy
);
  localparam integer DIV = (CLK_HZ/BAUD);
  reg [31:0] divcnt;
  reg [3:0]  bitpos;
  reg [9:0]  shifter;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      txd     <= 1'b1;
      tx_busy <= 1'b0;
      divcnt  <= 32'd0;
      bitpos  <= 4'd0;
      shifter <= 10'h3FF;
    end else begin
      if (!tx_busy) begin
        if (tx_start) begin
          // start(0) + data[7:0] LSB first + stop(1)
          shifter <= {1'b1, tx_data, 1'b0};
          tx_busy <= 1'b1;
          bitpos  <= 4'd0;
          divcnt  <= 32'd0;
        end
      end else begin
        if (divcnt == (DIV-1)) begin
          divcnt <= 32'd0;
          txd    <= shifter[0];
          shifter<= {1'b1, shifter[9:1]};
          if (bitpos == 4'd9) begin
            tx_busy <= 1'b0;
            txd     <= 1'b1;
          end else begin
            bitpos <= bitpos + 4'd1;
          end
        end else begin
          divcnt <= divcnt + 32'd1;
        end
      end
    end
  end
endmodule
