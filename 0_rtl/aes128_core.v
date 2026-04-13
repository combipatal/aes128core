module aes128_core (
  input          clk,
  input          rst_n,
  input          start,
  input  [127:0] key_in,
  input  [127:0] pt_in,
  output reg     busy,
  output reg     done,
  output reg [127:0] ct_out
);

  // round 0..10
  reg [3:0] round;
  reg [127:0] state;
  reg [1407:0] rkeys; // 11 * 128bit roundkeys packed

  // ----------------------------
  // helpers: get/set byte
  // ----------------------------
  function [7:0] getb;
    input [127:0] v;
    input integer idx;
    begin
      getb = v[127 - idx*8 -: 8];
    end
  endfunction

  function [127:0] setb;
    input [127:0] v;
    input integer idx;
    input [7:0] b;
    reg [127:0] t;
    begin
      t = v;
      t[127 - idx*8 -: 8] = b;
      setb = t;
    end
  endfunction

  // ----------------------------
  // AES S-box as function
  // ----------------------------
  function [7:0] sbox;
    input [7:0] a;
    begin
      case (a)
        8'h00: sbox=8'h63; 8'h01: sbox=8'h7c; 8'h02: sbox=8'h77; 8'h03: sbox=8'h7b;
        8'h04: sbox=8'hf2; 8'h05: sbox=8'h6b; 8'h06: sbox=8'h6f; 8'h07: sbox=8'hc5;
        8'h08: sbox=8'h30; 8'h09: sbox=8'h01; 8'h0a: sbox=8'h67; 8'h0b: sbox=8'h2b;
        8'h0c: sbox=8'hfe; 8'h0d: sbox=8'hd7; 8'h0e: sbox=8'hab; 8'h0f: sbox=8'h76;
        8'h10: sbox=8'hca; 8'h11: sbox=8'h82; 8'h12: sbox=8'hc9; 8'h13: sbox=8'h7d;
        8'h14: sbox=8'hfa; 8'h15: sbox=8'h59; 8'h16: sbox=8'h47; 8'h17: sbox=8'hf0;
        8'h18: sbox=8'had; 8'h19: sbox=8'hd4; 8'h1a: sbox=8'ha2; 8'h1b: sbox=8'haf;
        8'h1c: sbox=8'h9c; 8'h1d: sbox=8'ha4; 8'h1e: sbox=8'h72; 8'h1f: sbox=8'hc0;
        8'h20: sbox=8'hb7; 8'h21: sbox=8'hfd; 8'h22: sbox=8'h93; 8'h23: sbox=8'h26;
        8'h24: sbox=8'h36; 8'h25: sbox=8'h3f; 8'h26: sbox=8'hf7; 8'h27: sbox=8'hcc;
        8'h28: sbox=8'h34; 8'h29: sbox=8'ha5; 8'h2a: sbox=8'he5; 8'h2b: sbox=8'hf1;
        8'h2c: sbox=8'h71; 8'h2d: sbox=8'hd8; 8'h2e: sbox=8'h31; 8'h2f: sbox=8'h15;
        8'h30: sbox=8'h04; 8'h31: sbox=8'hc7; 8'h32: sbox=8'h23; 8'h33: sbox=8'hc3;
        8'h34: sbox=8'h18; 8'h35: sbox=8'h96; 8'h36: sbox=8'h05; 8'h37: sbox=8'h9a;
        8'h38: sbox=8'h07; 8'h39: sbox=8'h12; 8'h3a: sbox=8'h80; 8'h3b: sbox=8'he2;
        8'h3c: sbox=8'heb; 8'h3d: sbox=8'h27; 8'h3e: sbox=8'hb2; 8'h3f: sbox=8'h75;
        8'h40: sbox=8'h09; 8'h41: sbox=8'h83; 8'h42: sbox=8'h2c; 8'h43: sbox=8'h1a;
        8'h44: sbox=8'h1b; 8'h45: sbox=8'h6e; 8'h46: sbox=8'h5a; 8'h47: sbox=8'ha0;
        8'h48: sbox=8'h52; 8'h49: sbox=8'h3b; 8'h4a: sbox=8'hd6; 8'h4b: sbox=8'hb3;
        8'h4c: sbox=8'h29; 8'h4d: sbox=8'he3; 8'h4e: sbox=8'h2f; 8'h4f: sbox=8'h84;
        8'h50: sbox=8'h53; 8'h51: sbox=8'hd1; 8'h52: sbox=8'h00; 8'h53: sbox=8'hed;
        8'h54: sbox=8'h20; 8'h55: sbox=8'hfc; 8'h56: sbox=8'hb1; 8'h57: sbox=8'h5b;
        8'h58: sbox=8'h6a; 8'h59: sbox=8'hcb; 8'h5a: sbox=8'hbe; 8'h5b: sbox=8'h39;
        8'h5c: sbox=8'h4a; 8'h5d: sbox=8'h4c; 8'h5e: sbox=8'h58; 8'h5f: sbox=8'hcf;
        8'h60: sbox=8'hd0; 8'h61: sbox=8'hef; 8'h62: sbox=8'haa; 8'h63: sbox=8'hfb;
        8'h64: sbox=8'h43; 8'h65: sbox=8'h4d; 8'h66: sbox=8'h33; 8'h67: sbox=8'h85;
        8'h68: sbox=8'h45; 8'h69: sbox=8'hf9; 8'h6a: sbox=8'h02; 8'h6b: sbox=8'h7f;
        8'h6c: sbox=8'h50; 8'h6d: sbox=8'h3c; 8'h6e: sbox=8'h9f; 8'h6f: sbox=8'ha8;
        8'h70: sbox=8'h51; 8'h71: sbox=8'ha3; 8'h72: sbox=8'h40; 8'h73: sbox=8'h8f;
        8'h74: sbox=8'h92; 8'h75: sbox=8'h9d; 8'h76: sbox=8'h38; 8'h77: sbox=8'hf5;
        8'h78: sbox=8'hbc; 8'h79: sbox=8'hb6; 8'h7a: sbox=8'hda; 8'h7b: sbox=8'h21;
        8'h7c: sbox=8'h10; 8'h7d: sbox=8'hff; 8'h7e: sbox=8'hf3; 8'h7f: sbox=8'hd2;
        8'h80: sbox=8'hcd; 8'h81: sbox=8'h0c; 8'h82: sbox=8'h13; 8'h83: sbox=8'hec;
        8'h84: sbox=8'h5f; 8'h85: sbox=8'h97; 8'h86: sbox=8'h44; 8'h87: sbox=8'h17;
        8'h88: sbox=8'hc4; 8'h89: sbox=8'ha7; 8'h8a: sbox=8'h7e; 8'h8b: sbox=8'h3d;
        8'h8c: sbox=8'h64; 8'h8d: sbox=8'h5d; 8'h8e: sbox=8'h19; 8'h8f: sbox=8'h73;
        8'h90: sbox=8'h60; 8'h91: sbox=8'h81; 8'h92: sbox=8'h4f; 8'h93: sbox=8'hdc;
        8'h94: sbox=8'h22; 8'h95: sbox=8'h2a; 8'h96: sbox=8'h90; 8'h97: sbox=8'h88;
        8'h98: sbox=8'h46; 8'h99: sbox=8'hee; 8'h9a: sbox=8'hb8; 8'h9b: sbox=8'h14;
        8'h9c: sbox=8'hde; 8'h9d: sbox=8'h5e; 8'h9e: sbox=8'h0b; 8'h9f: sbox=8'hdb;
        8'ha0: sbox=8'he0; 8'ha1: sbox=8'h32; 8'ha2: sbox=8'h3a; 8'ha3: sbox=8'h0a;
        8'ha4: sbox=8'h49; 8'ha5: sbox=8'h06; 8'ha6: sbox=8'h24; 8'ha7: sbox=8'h5c;
        8'ha8: sbox=8'hc2; 8'ha9: sbox=8'hd3; 8'haa: sbox=8'hac; 8'hab: sbox=8'h62;
        8'hac: sbox=8'h91; 8'had: sbox=8'h95; 8'hae: sbox=8'he4; 8'haf: sbox=8'h79;
        8'hb0: sbox=8'he7; 8'hb1: sbox=8'hc8; 8'hb2: sbox=8'h37; 8'hb3: sbox=8'h6d;
        8'hb4: sbox=8'h8d; 8'hb5: sbox=8'hd5; 8'hb6: sbox=8'h4e; 8'hb7: sbox=8'ha9;
        8'hb8: sbox=8'h6c; 8'hb9: sbox=8'h56; 8'hba: sbox=8'hf4; 8'hbb: sbox=8'hea;
        8'hbc: sbox=8'h65; 8'hbd: sbox=8'h7a; 8'hbe: sbox=8'hae; 8'hbf: sbox=8'h08;
        8'hc0: sbox=8'hba; 8'hc1: sbox=8'h78; 8'hc2: sbox=8'h25; 8'hc3: sbox=8'h2e;
        8'hc4: sbox=8'h1c; 8'hc5: sbox=8'ha6; 8'hc6: sbox=8'hb4; 8'hc7: sbox=8'hc6;
        8'hc8: sbox=8'he8; 8'hc9: sbox=8'hdd; 8'hca: sbox=8'h74; 8'hcb: sbox=8'h1f;
        8'hcc: sbox=8'h4b; 8'hcd: sbox=8'hbd; 8'hce: sbox=8'h8b; 8'hcf: sbox=8'h8a;
        8'hd0: sbox=8'h70; 8'hd1: sbox=8'h3e; 8'hd2: sbox=8'hb5; 8'hd3: sbox=8'h66;
        8'hd4: sbox=8'h48; 8'hd5: sbox=8'h03; 8'hd6: sbox=8'hf6; 8'hd7: sbox=8'h0e;
        8'hd8: sbox=8'h61; 8'hd9: sbox=8'h35; 8'hda: sbox=8'h57; 8'hdb: sbox=8'hb9;
        8'hdc: sbox=8'h86; 8'hdd: sbox=8'hc1; 8'hde: sbox=8'h1d; 8'hdf: sbox=8'h9e;
        8'he0: sbox=8'he1; 8'he1: sbox=8'hf8; 8'he2: sbox=8'h98; 8'he3: sbox=8'h11;
        8'he4: sbox=8'h69; 8'he5: sbox=8'hd9; 8'he6: sbox=8'h8e; 8'he7: sbox=8'h94;
        8'he8: sbox=8'h9b; 8'he9: sbox=8'h1e; 8'hea: sbox=8'h87; 8'heb: sbox=8'he9;
        8'hec: sbox=8'hce; 8'hed: sbox=8'h55; 8'hee: sbox=8'h28; 8'hef: sbox=8'hdf;
        8'hf0: sbox=8'h8c; 8'hf1: sbox=8'ha1; 8'hf2: sbox=8'h89; 8'hf3: sbox=8'h0d;
        8'hf4: sbox=8'hbf; 8'hf5: sbox=8'he6; 8'hf6: sbox=8'h42; 8'hf7: sbox=8'h68;
        8'hf8: sbox=8'h41; 8'hf9: sbox=8'h99; 8'hfa: sbox=8'h2d; 8'hfb: sbox=8'h0f;
        8'hfc: sbox=8'hb0; 8'hfd: sbox=8'h54; 8'hfe: sbox=8'hbb; 8'hff: sbox=8'h16;
        default: sbox=8'h00;
      endcase
    end
  endfunction

  function [7:0] xtime;
    input [7:0] b;
    begin
      xtime = {b[6:0],1'b0} ^ (8'h1b & {8{b[7]}});
    end
  endfunction
  function [7:0] mul2; input [7:0] b; begin mul2 = xtime(b); end endfunction
  function [7:0] mul3; input [7:0] b; begin mul3 = xtime(b) ^ b; end endfunction

  function [127:0] subbytes_fn;
    input [127:0] st;
    integer k;
    reg [127:0] out;
    begin
      out = 128'd0;
      for (k=0;k<16;k=k+1)
        out = setb(out, k, sbox(getb(st,k)));
      subbytes_fn = out;
    end
  endfunction

  function [127:0] shiftrows_fn;
    input [127:0] st;
    reg [127:0] out;
    begin
      out = 128'd0;
      // column-major indices: idx = col*4 + row
      // row0: 0,4,8,12 no shift
      out = setb(out, 0,  getb(st,0));
      out = setb(out, 4,  getb(st,4));
      out = setb(out, 8,  getb(st,8));
      out = setb(out, 12, getb(st,12));
      // row1: 1,5,9,13 shift left 1 => (5,9,13,1)
      out = setb(out, 1,  getb(st,5));
      out = setb(out, 5,  getb(st,9));
      out = setb(out, 9,  getb(st,13));
      out = setb(out, 13, getb(st,1));
      // row2: 2,6,10,14 shift left 2 => (10,14,2,6)
      out = setb(out, 2,  getb(st,10));
      out = setb(out, 6,  getb(st,14));
      out = setb(out, 10, getb(st,2));
      out = setb(out, 14, getb(st,6));
      // row3: 3,7,11,15 shift left 3 => (15,3,7,11)
      out = setb(out, 3,  getb(st,15));
      out = setb(out, 7,  getb(st,3));
      out = setb(out, 11, getb(st,7));
      out = setb(out, 15, getb(st,11));
      shiftrows_fn = out;
    end
  endfunction

  function [127:0] mixcolumns_fn;
    input [127:0] st;
    integer c;
    reg [127:0] out;
    reg [7:0] a0,a1,a2,a3;
    reg [7:0] r0,r1,r2,r3;
    begin
      out = st;
      for (c=0;c<4;c=c+1) begin
        a0 = getb(st, c*4+0);
        a1 = getb(st, c*4+1);
        a2 = getb(st, c*4+2);
        a3 = getb(st, c*4+3);
        r0 = mul2(a0) ^ mul3(a1) ^ a2 ^ a3;
        r1 = a0 ^ mul2(a1) ^ mul3(a2) ^ a3;
        r2 = a0 ^ a1 ^ mul2(a2) ^ mul3(a3);
        r3 = mul3(a0) ^ a1 ^ a2 ^ mul2(a3);
        out = setb(out, c*4+0, r0);
        out = setb(out, c*4+1, r1);
        out = setb(out, c*4+2, r2);
        out = setb(out, c*4+3, r3);
      end
      mixcolumns_fn = out;
    end
  endfunction

  function [31:0] rotword;
    input [31:0] w;
    begin
      rotword = {w[23:0], w[31:24]};
    end
  endfunction

  function [31:0] subword;
    input [31:0] w;
    begin
      subword = {sbox(w[31:24]), sbox(w[23:16]), sbox(w[15:8]), sbox(w[7:0])};
    end
  endfunction

  function [31:0] rcon;
    input integer r;
    begin
      case (r)
        1: rcon=32'h01000000; 2: rcon=32'h02000000; 3: rcon=32'h04000000; 4: rcon=32'h08000000;
        5: rcon=32'h10000000; 6: rcon=32'h20000000; 7: rcon=32'h40000000; 8: rcon=32'h80000000;
        9: rcon=32'h1b000000; 10:rcon=32'h36000000;
        default: rcon=32'h00000000;
      endcase
    end
  endfunction

  function [1407:0] expand_key128;
    input [127:0] key;
    integer j;
    reg [31:0] w0,w1,w2,w3;
    reg [31:0] w[0:43];
    reg [31:0] tmp;
    reg [1407:0] out;
    integer r;
    begin
      w[0] = key[127:96];
      w[1] = key[95:64];
      w[2] = key[63:32];
      w[3] = key[31:0];
      for (j=4;j<44;j=j+1) begin
        tmp = w[j-1];
        if ((j % 4) == 0)
          tmp = subword(rotword(tmp)) ^ rcon(j/4);
        w[j] = w[j-4] ^ tmp;
      end

      out = 1408'd0;
      for (r=0;r<11;r=r+1) begin
        // pack rk[r] to out[1407 - r*128 -: 128]
        out[1407 - r*128 -: 128] = {w[r*4+0], w[r*4+1], w[r*4+2], w[r*4+3]};
      end
      expand_key128 = out;
    end
  endfunction

  function [127:0] get_rk;
    input [1407:0] allrk;
    input integer r;
    begin
      get_rk = allrk[1407 - r*128 -: 128];
    end
  endfunction

  // Reuse common combinational transforms so the same work is not rebuilt
  // multiple times in the sequential branch below.
  wire [1407:0] key_expanded_start = expand_key128(key_in);
  wire [127:0] start_state_next = pt_in ^ get_rk(key_expanded_start, 0);
  wire [127:0] state_sb_sr = shiftrows_fn(subbytes_fn(state));
  wire [127:0] state_round_next = mixcolumns_fn(state_sb_sr) ^ get_rk(rkeys, round);
  wire [127:0] state_final_next = state_sb_sr ^ get_rk(rkeys, 10);

  // ----------------------------
  // sequential
  // ----------------------------
  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      busy  <= 1'b0;
      done  <= 1'b0;
      round <= 4'd0;
      state <= 128'd0;
      rkeys <= 1408'd0;
      ct_out<= 128'd0;
    end else begin
      done <= 1'b0;

      if (start && !busy) begin
        /*
        rkeys <= expand_key128(key_in);
        state <= pt_in ^ get_rk(expand_key128(key_in), 0);
        */
        rkeys <= key_expanded_start;
        state <= start_state_next;
        round <= 4'd1;
        busy  <= 1'b1;
      end else if (busy) begin
        if (round <= 4'd9) begin
          /*
          state <= mixcolumns_fn(shiftrows_fn(subbytes_fn(state))) ^ get_rk(rkeys, round);
          */
          state <= state_round_next;
          round <= round + 4'd1;
        end else begin
          // final round (no mixcolumns)
          /*
          state <= shiftrows_fn(subbytes_fn(state)) ^ get_rk(rkeys, 10);
          ct_out<= shiftrows_fn(subbytes_fn(state)) ^ get_rk(rkeys, 10);
          */
          state <= state_final_next;
          ct_out<= state_final_next;
          busy  <= 1'b0;
          done  <= 1'b1;
        end
      end
    end
  end

endmodule
