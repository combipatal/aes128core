module sram_wrap_1rw1024x8 (
  input        clk,     // mapped to CE in macro model
  input        cs,      // 1=select
  input        we,      // 1=write
  input        oe,      // 1=output enable
  input  [9:0] addr,
  input  [7:0] wdata,
  output [7:0] rdata
 // inout VDD, VSS
);
  wire CSB = ~cs;
  wire WEB = ~we;
  wire OEB = ~oe;

  SRAM1RW1024x8 u_sram (
    .A   (addr),
    .CE  (clk),
    .WEB (WEB),
    .OEB (OEB),
    .CSB (CSB),
    .I   (wdata),
    .O   (rdata)
  //  .VDD (VDD),
   // .VSS (VSS)
  );
endmodule
