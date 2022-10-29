// This file is part of the vicii-kawari distribution
// (https://github.com/randyrossi/vicii-kawari)
// Copyright (c) 2022 Randy Rossi.
// 
// This program is free software: you can redistribute it and/or modify  
// it under the terms of the GNU General Public License as published by  
// the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful, but 
// WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License 
// along with this program. If not, see <http://www.gnu.org/licenses/>.

`timescale 1ns/1ps

`include "../common.vh"

// Wrapper around dot4x_cc_clockgen that optionally
// includes dvi_clockgen
module clockgen(
           input src_clock,
           input [1:0] chip,
           output clk_dot4x
`ifdef WITH_DVI
           ,
           output tx0_pclkx10,
           output tx0_pclkx2,
           output tx0_serdesstrobe
`endif
       );

// We use the dot4x_cc clock gen module to generate dot4x clocks
// for ntsc and pal. Only one of these clocks will be correct depending
// on what src_clock we were given.
dot4x_cc_clockgen dot4x_cc_clockgen(
                      .CLKIN(src_clock),    // 8x color clock
                      .RST(1'b0),
                      .CLK0OUT(clk_dot4x_ntsc),
                      .CLK1OUT(clk_dot4x_pal),
                      .LOCKED(locked)
                  );

// Now we must pick the correct clock based on the chip model.
BUFGMUX colmux2(
            .I0(clk_dot4x_ntsc),
            .I1(clk_dot4x_pal),
            .O(clk_dot4x),
            .S(chip[0]));

`ifdef WITH_DVI
// This is the clock gen for our DVI encoder.  It takes in the pixel clock
// prodices 2x and 10x clocks as well as the ser/des strobe.
dvi_clockgen dvi_clockgen(
                 .clkin(clk_dot4x),
                 .tx0_pclkx10(tx0_pclkx10),
                 .tx0_pclkx2(tx0_pclkx2),
                 .tx0_serdesstrobe(tx0_serdesstrobe)
             );
`endif

endmodule
