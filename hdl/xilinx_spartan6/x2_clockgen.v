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

`timescale 1ps/1ps

// This module multiplies the clk_in by x2 and x4.  The color clock on input
// is already 4x color.  But we need a color_x8 clock to meet the minimum frequency
// of the PLL downstream.  We also need a color x16 clock for our chroma signal
// generator.

// WORKAROUND for intermittent black and white image on PAL boot.
// This used to use just one DCM_SP instance and provided both x2 and x4 clocks but
// that resulted in the x4 clock sometimes not generated correctly causing our chroma
// generator to mess up (black and white picture or 'hatched' pattern from messed up
// chroma signal).  Now we have separate DCM_SP instances in a cascaded config so we
// can keep the x4 under reset until after the chip has been selected.  This seems to
// prevent the clk_col16x issue from happening.
module x2_clockgen
(
    input         clk_in,          // color clock
    output        clk_out_x2,      // color clock x2 = color 8x used to obtain dot clock
    output        clk_out_x4,      // color clock x4 = color 16x used to generate chroma
    input         reset            // only usedfor clk_out_x4 gen under reset, not x2
);

wire [7:0]  status_int_unused;
wire [7:0]  status_int2_unused;

wire clkfb;
wire clkfb2;

// For x2
DCM_SP
    #(.CLKDV_DIVIDE          (2.000),
      .CLKFX_DIVIDE          (1),
      .CLKFX_MULTIPLY        (4),
      .CLKIN_DIVIDE_BY_2     ("FALSE"),
      .CLKIN_PERIOD          (56.387), // pal 4x color clock
      .CLKOUT_PHASE_SHIFT    ("NONE"),
      .CLK_FEEDBACK          ("1X"),
      .DESKEW_ADJUST         ("SYSTEM_SYNCHRONOUS"),
      .PHASE_SHIFT           (0),
      .STARTUP_WAIT          ("TRUE"))
    dcm_sp_inst
    // Input clock
    (.CLKIN                 (clk_in),
     .CLKFB                 (clk_fb),
     // Output clocks
     .CLK0                  (clk_fb),
     .CLK90                 (),
     .CLK180                (),
     .CLK270                (),
     .CLK2X                 (clk_x2),  // CLKIN x 2
     .CLK2X180              (),
     .CLKFX                 (),
     .CLKFX180              (),
     .CLKDV                 (),
     // Ports for dynamic phase shift
     .PSCLK                 (1'b0),
     .PSEN                  (1'b0),
     .PSINCDEC              (1'b0),
     .PSDONE                (),
     // Other control and status signals
     .STATUS                (status_int1_unused),

     .RST                   (1'b0), // never pass reset to this DCM_SP
     // Unused pin- tie low
     .DSSEN                 (1'b0));

BUFG clkf_buf2
     (.O (clk_out_x2),
      .I (clk_x2));
      
// For x4
DCM_SP
    #(.CLKDV_DIVIDE          (2.000),
      .CLKFX_DIVIDE          (1),
      .CLKFX_MULTIPLY        (4),
      .CLKIN_DIVIDE_BY_2     ("FALSE"),
      .CLKIN_PERIOD          (28.19), // pal 8x color clock
      .CLKOUT_PHASE_SHIFT    ("NONE"),
      .CLK_FEEDBACK          ("1X"),
      .DESKEW_ADJUST         ("SYSTEM_SYNCHRONOUS"),
      .PHASE_SHIFT           (0),
      .STARTUP_WAIT          ("TRUE"))
    dcm_sp_inst2
    // Input clock
    (.CLKIN                 (clk_out_x2),
     .CLKFB                 (clk_fb2),
     // Output clocks
     .CLK0                  (clk_fb2),
     .CLK90                 (),
     .CLK180                (),
     .CLK270                (),
     .CLK2X                 (clk_x4),
     .CLK2X180              (),
     .CLKFX                 (),
     .CLKFX180              (),
     .CLKDV                 (),
     // Ports for dynamic phase shift
     .PSCLK                 (1'b0),
     .PSEN                  (1'b0),
     .PSINCDEC              (1'b0),
     .PSDONE                (),
     // Other control and status signals
     .STATUS                (status_int2_unused),

     .RST                   (reset),
     // Unused pin- tie low
     .DSSEN                 (1'b0));
  
BUFG clkf_buf4
     (.O (clk_out_x4),
      .I (clk_x4));

endmodule
