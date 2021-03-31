`timescale 1ns/1ps

`include "common.vh"

// Luma        NTSC-Voltage    PAL-Voltage
// 0           1.38            TBD
// 1           2.10            TBD
// 2           2.28            TBD
// 3           2.46            TBD
// 4           2.76            TBD
// 5           2.86            TBD
// 6           3.24            TBD
// 7           3.66            TBD
// 8           4.28            TBD

// Given an indexed color, set luma
// 499(1%) 1k 2k 4k 8k 16k
module luma(
           input [3:0] index,
`ifdef CONFIGURABLE_LUMAS
			  input [95:0] lumareg_o,
`endif
           output reg [5:0] luma
			  );

`ifdef CONFIGURABLE_LUMAS
wire [5:0] lumareg[15:0];
// Handle un-flattening here
assign lumareg[0] = lumareg_o[95:90];
assign lumareg[1] = lumareg_o[89:84];
assign lumareg[2] = lumareg_o[83:78];
assign lumareg[3] = lumareg_o[77:72];
assign lumareg[4] = lumareg_o[71:66];
assign lumareg[5] = lumareg_o[65:60];
assign lumareg[6] = lumareg_o[59:54];
assign lumareg[7] = lumareg_o[53:48];
assign lumareg[8] = lumareg_o[47:42];
assign lumareg[9] = lumareg_o[41:36];
assign lumareg[10] = lumareg_o[35:30];
assign lumareg[11] = lumareg_o[29:24];
assign lumareg[12] = lumareg_o[23:18];
assign lumareg[13] = lumareg_o[17:12];
assign lumareg[14] = lumareg_o[11:6];
assign lumareg[15] = lumareg_o[5:0];

`endif

    always @*
        case (index)
`ifdef CONFIGURABLE_LUMAS
        `BLACK:       luma <= lumareg[0];
        `WHITE:       luma <= lumareg[1];
        `RED:         luma <= lumareg[2];
        `CYAN:        luma <= lumareg[3];
        `PURPLE:      luma <= lumareg[4];
        `GREEN:       luma <= lumareg[5];
        `BLUE:        luma <= lumareg[6];
        `YELLOW:      luma <= lumareg[7];
        `ORANGE:      luma <= lumareg[8];
        `BROWN:       luma <= lumareg[9];
        `PINK:        luma <= lumareg[10];
        `DARK_GREY:   luma <= lumareg[11];
        `GREY:        luma <= lumareg[12];
        `LIGHT_GREEN: luma <= lumareg[13];
        `LIGHT_BLUE:  luma <= lumareg[14];
        `LIGHT_GREY:  luma <= lumareg[15];
`else
        `BLACK:       luma <= 6'b010011; // 0
        `WHITE:       luma <= 6'b111011; // 8
        `RED:         luma <= 6'b011111; // 2
        `CYAN:        luma <= 6'b101100; // 6
        `PURPLE:      luma <= 6'b100010; // 3
        `GREEN:       luma <= 6'b100111; // 5
        `BLUE:        luma <= 6'b011100; // 1
        `YELLOW:      luma <= 6'b110010; // 7
        `ORANGE:      luma <= 6'b100010; // 3
        `BROWN:       luma <= 6'b011100; // 1
        `PINK:        luma <= 6'b100111; // 5
        `DARK_GREY:   luma <= 6'b011111; // 2
        `GREY:        luma <= 6'b100110; // 4
        `LIGHT_GREEN: luma <= 6'b110010; // 7
        `LIGHT_BLUE:  luma <= 6'b100110; // 4
        `LIGHT_GREY:  luma <= 6'b101100; // 6
`endif
      endcase

endmodule: luma

// Given a color index, set amplitude
// 000 = highest, 110 = lowest, 111 = no modulation
module amplitude(
           input [3:0] index,
`ifdef CONFIGURABLE_LUMAS
			  input [47:0] amplitudereg_o,
`endif
           output reg [2:0] amplitude);

`ifdef CONFIGURABLE_LUMAS
wire [2:0] amplitudereg[15:0];
assign amplitudereg[0] = amplitudereg_o[47:45];
assign amplitudereg[1] = amplitudereg_o[44:42];
assign amplitudereg[2] = amplitudereg_o[41:39];
assign amplitudereg[3] = amplitudereg_o[37:36];
assign amplitudereg[4] = amplitudereg_o[35:33];
assign amplitudereg[5] = amplitudereg_o[32:30];
assign amplitudereg[6] = amplitudereg_o[29:27];
assign amplitudereg[7] = amplitudereg_o[26:24];
assign amplitudereg[8] = amplitudereg_o[23:21];
assign amplitudereg[9] = amplitudereg_o[20:18];
assign amplitudereg[10] = amplitudereg_o[17:15];
assign amplitudereg[11] = amplitudereg_o[14:12];
assign amplitudereg[12] = amplitudereg_o[11:9];
assign amplitudereg[13] = amplitudereg_o[8:6];
assign amplitudereg[14] = amplitudereg_o[5:3];
assign amplitudereg[15] = amplitudereg_o[2:0];
`endif
 
   always @*
        case (index)
`ifdef CONFIGURABLE_LUMAS
        `BLACK:       amplitude <= amplitudereg[0];
        `WHITE:       amplitude <= amplitudereg[1];
        `RED:         amplitude <= amplitudereg[2];
        `CYAN:        amplitude <= amplitudereg[3];
        `PURPLE:      amplitude <= amplitudereg[4];
        `GREEN:       amplitude <= amplitudereg[5];
        `BLUE:        amplitude <= amplitudereg[6];
        `YELLOW:      amplitude <= amplitudereg[7];
        `ORANGE:      amplitude <= amplitudereg[8];
        `BROWN:       amplitude <= amplitudereg[9];
        `PINK:        amplitude <= amplitudereg[10];
        `DARK_GREY:   amplitude <= amplitudereg[11];
        `GREY:        amplitude <= amplitudereg[12];
        `LIGHT_GREEN: amplitude <= amplitudereg[13];
        `LIGHT_BLUE:  amplitude <= amplitudereg[14];
        `LIGHT_GREY:  amplitude <= amplitudereg[15];
`else
        `BLACK:       amplitude <= 3'b111; // no modulation
        `WHITE:       amplitude <= 3'b111; // no modulation
        `RED:         amplitude <= 3'b010;
        `CYAN:        amplitude <= 3'b010;
        `PURPLE:      amplitude <= 3'b001;
        `GREEN:       amplitude <= 3'b001;
        `BLUE:        amplitude <= 3'b010;
        `YELLOW:      amplitude <= 3'b000;
        `ORANGE:      amplitude <= 3'b000;
        `BROWN:       amplitude <= 3'b010;
        `PINK:        amplitude <= 3'b010;
        `DARK_GREY:   amplitude <= 3'b111; // no modulation
        `GREY:        amplitude <= 3'b111; // no modulation
        `LIGHT_GREEN: amplitude <= 3'b010;
        `LIGHT_BLUE:  amplitude <= 3'b010;
        `LIGHT_GREY:  amplitude <= 3'b111; // no modulation
`endif 
     endcase
endmodule: amplitude

// Given a color index, set phase offset
module phase(
           input [3:0] index,
`ifdef CONFIGURABLE_LUMAS
			  input [127:0] phasereg_o,
`endif
           output reg [7:0] phase,
			  input oddline);

`ifdef CONFIGURABLE_LUMAS
wire [7:0] phasereg[15:0];
assign phasereg[0] = phasereg_o[127:120];
assign phasereg[1] = phasereg_o[119:112];
assign phasereg[2] = phasereg_o[111:104];
assign phasereg[3] = phasereg_o[103:96];
assign phasereg[4] = phasereg_o[95:88];
assign phasereg[5] = phasereg_o[87:80];
assign phasereg[6] = phasereg_o[79:72];
assign phasereg[7] = phasereg_o[71:64];
assign phasereg[8] = phasereg_o[63:56];
assign phasereg[9] = phasereg_o[55:48];
assign phasereg[10] = phasereg_o[47:40];
assign phasereg[11] = phasereg_o[39:32];
assign phasereg[12] = phasereg_o[31:24];
assign phasereg[13] = phasereg_o[23:16];
assign phasereg[14] = phasereg_o[15:8];
assign phasereg[15] = phasereg_o[7:0];
`endif

    always @*
       case (oddline)
       1'b0:
         case (index)
`ifdef CONFIGURABLE_LUMAS
          `BLACK:       phase <= phasereg[0];
          `WHITE:       phase <= phasereg[1];
          `RED:         phase <= phasereg[2];
          `CYAN:        phase <= phasereg[3];
          `PURPLE:      phase <= phasereg[4];
          `GREEN:       phase <= phasereg[5];
          `BLUE:        phase <= phasereg[6];
          `YELLOW:      phase <= phasereg[7];
          `ORANGE:      phase <= phasereg[8];
          `BROWN:       phase <= phasereg[9];
          `PINK:        phase <= phasereg[10];
          `DARK_GREY:   phase <= phasereg[11];
          `GREY:        phase <= phasereg[12];
          `LIGHT_GREEN: phase <= phasereg[13];
          `LIGHT_BLUE:  phase <= phasereg[14];
          `LIGHT_GREY:  phase <= phasereg[15];
`else
          `BLACK:       phase <= 8'd0;  // unmodulated
          `WHITE:       phase <= 8'd0;  // unmodulated
          `RED:         phase <= 8'd80; // 112.5 deg
          `CYAN:        phase <= 8'd208; // 292.5 deg
          `PURPLE:      phase <= 8'd32; // 45 deg
          `GREEN:       phase <= 8'd160; // 225 deg
          `BLUE:        phase <= 8'd0; // 0 deg
          `YELLOW:      phase <= 8'd128; // 180 deg
          `ORANGE:      phase <= 8'd96; // 135 deg
          `BROWN:       phase <= 8'd112; // 157.5 deg
          `PINK:        phase <= 8'd80; // 112.5 deg
          `DARK_GREY:   phase <= 8'd0;  // unmodulated
          `GREY:        phase <= 8'd0;  // unmodulated
          `LIGHT_GREEN: phase <= 8'd160; // 225 deg
          `LIGHT_BLUE:  phase <= 8'd0; // 0 deg
          `LIGHT_GREY:  phase <= 8'd0;  // unmodulated
`endif
          endcase
       1'b1:
         case (index)
`ifdef CONFIGURABLE_LUMAS
          `BLACK:       phase <= 8'd256 - phasereg[0];
          `WHITE:       phase <= 8'd256 - phasereg[1];
          `RED:         phase <= 8'd256 - phasereg[2];
          `CYAN:        phase <= 8'd256 - phasereg[3];
          `PURPLE:      phase <= 8'd256 - phasereg[4];
          `GREEN:       phase <= 8'd256 - phasereg[5];
          `BLUE:        phase <= 8'd256 - phasereg[6];
          `YELLOW:      phase <= 8'd256 - phasereg[7];
          `ORANGE:      phase <= 8'd256 - phasereg[8];
          `BROWN:       phase <= 8'd256 - phasereg[9];
          `PINK:        phase <= 8'd256 - phasereg[10];
          `DARK_GREY:   phase <= 8'd256 - phasereg[11];
          `GREY:        phase <= 8'd256 - phasereg[12];
          `LIGHT_GREEN: phase <= 8'd256 - phasereg[13];
          `LIGHT_BLUE:  phase <= 8'd256 - phasereg[14];
          `LIGHT_GREY:  phase <= 8'd256 - phasereg[15];
`else
          `BLACK:       phase <= 8'd0;  // unmodulated
          `WHITE:       phase <= 8'd0;  // unmodulated
          `RED:         phase <= 8'd176; // 247.5 deg
          `CYAN:        phase <= 8'd48; // 67.5 deg
          `PURPLE:      phase <= 8'd224; // 315 deg
          `GREEN:       phase <= 8'd96; // 135 deg
          `BLUE:        phase <= 8'd0; // 0 deg
          `YELLOW:      phase <= 8'd128; // 180 deg
          `ORANGE:      phase <= 8'd160; // 225 deg
          `BROWN:       phase <= 8'd144; // 202.5 deg
          `PINK:        phase <= 8'd176; // 247.5 deg
          `DARK_GREY:   phase <= 8'd0;  // unmodulated
          `GREY:        phase <= 8'd0;  // unmodulated
          `LIGHT_GREEN: phase <= 8'd96; // 135 deg
          `LIGHT_BLUE:  phase <= 8'd0; // 0 deg
          `LIGHT_GREY:  phase <= 8'd0;  // unmodulated
`endif
          endcase
       endcase
endmodule: phase
