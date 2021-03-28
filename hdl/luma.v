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
// 499 1k 2k 4k 8k 16k
module luma(
           input [3:0] index,
           output reg [5:0] luma);
    always @*
        case (index)
        `BLACK:       luma = 6'b010011; // 0
        `WHITE:       luma = 6'b111011; // 8
        `RED:         luma = 6'b011111; // 2
        `CYAN:        luma = 6'b101100; // 6
        `PURPLE:      luma = 6'b100010; // 3
        `GREEN:       luma = 6'b100111; // 5
        `BLUE:        luma = 6'b011100; // 1
        `YELLOW:      luma = 6'b110010; // 7
        `ORANGE:      luma = 6'b100010; // 3
        `BROWN:       luma = 6'b011100; // 1
        `PINK:        luma = 6'b100111; // 5
        `DARK_GREY:   luma = 6'b011111; // 2
        `GREY:        luma = 6'b100110; // 4
        `LIGHT_GREEN: luma = 6'b110010; // 7
        `LIGHT_BLUE:  luma = 6'b100110; // 4
        `LIGHT_GREY:  luma = 6'b101100; // 6
      endcase
endmodule: luma

// Given a color index, set amplitude
// 000 = highest, 110 = lowest, 111 = no modulation
module amplitude(
           input [3:0] index,
           output reg [2:0] amplitude);
    always @*
        case (index)
        `BLACK:       amplitude = 3'b111; // no modulation
        `WHITE:       amplitude = 3'b111; // no modulation
        `RED:         amplitude = 3'b010;
        `CYAN:        amplitude = 3'b010;
        `PURPLE:      amplitude = 3'b001;
        `GREEN:       amplitude = 3'b001;
        `BLUE:        amplitude = 3'b010;
        `YELLOW:      amplitude = 3'b000;
        `ORANGE:      amplitude = 3'b000;
        `BROWN:       amplitude = 3'b010;
        `PINK:        amplitude = 3'b010;
        `DARK_GREY:   amplitude = 3'b111; // no modulation
        `GREY:        amplitude = 3'b111; // no modulation
        `LIGHT_GREEN: amplitude = 3'b010;
        `LIGHT_BLUE:  amplitude = 3'b010;
        `LIGHT_GREY:  amplitude = 3'b111; // no modulation
      endcase
endmodule: amplitude

// Given a color index, set phase offset
module phase(
           input [3:0] index,
           output reg [7:0] phase,
			  input oddline);
    always @*
       case (oddline)
       1'b0:
         case (index)
          `BLACK:       phase = 8'd0;  // unmodulated
          `WHITE:       phase = 8'd0;  // unmodulated
          `RED:         phase = 8'd80; // 112.5 deg
          `CYAN:        phase = 8'd208; // 292.5 deg
          `PURPLE:      phase = 8'd32; // 45 deg
          `GREEN:       phase = 8'd160; // 225 deg
          `BLUE:        phase = 8'd0; // 0 deg
          `YELLOW:      phase = 8'd128; // 180 deg
          `ORANGE:      phase = 8'd96; // 135 deg
          `BROWN:       phase = 8'd112; // 157.5 deg
          `PINK:        phase = 8'd80; // 112.5 deg
          `DARK_GREY:   phase = 8'd0;  // unmodulated
          `GREY:        phase = 8'd0;  // unmodulated
          `LIGHT_GREEN: phase = 8'd160; // 225 deg
          `LIGHT_BLUE:  phase = 8'd0; // 0 deg
          `LIGHT_GREY:  phase = 8'd0;  // unmodulated
          endcase
       1'b1:
         case (index)
          `BLACK:       phase = 8'd0;  // unmodulated
          `WHITE:       phase = 8'd0;  // unmodulated
          `RED:         phase = 8'd176; // 247.5 deg
          `CYAN:        phase = 8'd48; // 67.5 deg
          `PURPLE:      phase = 8'd224; // 315 deg
          `GREEN:       phase = 8'd96; // 135 deg
          `BLUE:        phase = 8'd0; // 0 deg
          `YELLOW:      phase = 8'd128; // 180 deg
          `ORANGE:      phase = 8'd160; // 225 deg
          `BROWN:       phase = 8'd144; // 202.5 deg
          `PINK:        phase = 8'd176; // 247.5 deg
          `DARK_GREY:   phase = 8'd0;  // unmodulated
          `GREY:        phase = 8'd0;  // unmodulated
          `LIGHT_GREEN: phase = 8'd96; // 135 deg
          `LIGHT_BLUE:  phase = 8'd0; // 0 deg
          `LIGHT_GREY:  phase = 8'd0;  // unmodulated
          endcase
       endcase
endmodule: phase
