module crc32_byte (
  input        clk,
  input        rst_n,
  input        start,
  input        data_valid,
  input  [7:0] data_byte,
  input        finish,
  output reg   done,
  output reg [31:0] crc_out
);
  // CRC-32 (IEEE 802.3) poly 0x04C11DB7, MSB-first
  reg [31:0] crc;
  integer i;
  reg [31:0] c;

  function [31:0] next_crc;
    input [31:0] crc_in;
    input [7:0]  d;
    integer k;
    reg [31:0] x;
    begin
      x = crc_in ^ ( {d,24'h0} );
      for (k=0;k<8;k=k+1) begin
        if (x[31]) x = (x<<1) ^ 32'h04C11DB7;
        else      x = (x<<1);
      end
      next_crc = x;
    end
  endfunction

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      crc <= 32'hFFFF_FFFF;
      crc_out <= 32'd0;
      done <= 1'b0;
    end else begin
      done <= 1'b0;
      if (start) begin
        crc <= 32'hFFFF_FFFF;
      end else if (data_valid) begin
        crc <= next_crc(crc, data_byte);
      end else if (finish) begin
        crc_out <= ~crc;
        done <= 1'b1;
      end
    end
  end
endmodule
