module uart_rx #(
  parameter integer CLK_HZ  = 200_000_000,
  parameter integer BAUD    = 115200
)(
  input        clk,
  input        rst_n,
  input        rxd,
  output reg   rx_valid,
  output reg [7:0] rx_data
);
  localparam integer DIV = (CLK_HZ/BAUD);
  localparam integer HALF = DIV/2;

  reg [31:0] divcnt;
  reg [3:0]  bitpos;
  reg        busy;
  reg [7:0]  data_shift;

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_valid <= 1'b0;
      rx_data  <= 8'd0;
      divcnt   <= 32'd0;
      bitpos   <= 4'd0;
      busy     <= 1'b0;
      data_shift <= 8'd0;
    end else begin
      rx_valid <= 1'b0;

      if (!busy) begin
        // detect start bit (low)
        if (rxd == 1'b0) begin
          busy   <= 1'b1;
          divcnt <= 32'd0;
          bitpos <= 4'd0;
        end
      end else begin
        // sample in middle of bit periods
        if (bitpos == 4'd0) begin
          if (divcnt == (HALF-1)) begin
            divcnt <= 32'd0;
            bitpos <= 4'd1; // move to data bits
          end else divcnt <= divcnt + 32'd1;
        end else if (bitpos >= 4'd1 && bitpos <= 4'd8) begin
          if (divcnt == (DIV-1)) begin
            divcnt <= 32'd0;
            data_shift <= {rxd, data_shift[7:1]}; // LSB first received
            bitpos <= bitpos + 4'd1;
          end else divcnt <= divcnt + 32'd1;
        end else begin
          // stop bit
          if (divcnt == (DIV-1)) begin
            divcnt <= 32'd0;
            busy <= 1'b0;
            rx_data <= data_shift;
            rx_valid <= 1'b1;
          end else divcnt <= divcnt + 32'd1;
        end
      end
    end
  end
endmodule
