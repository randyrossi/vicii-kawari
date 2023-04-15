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

module ntsc_col16x
(
    input         clk_in,
    output        clk_col16x,
    input         reset
);

wire [7:0]  status_int_unused;
wire clk_fb;
wire clk_x4;

// For x2
DCM_SP
    #(.CLKDV_DIVIDE          (2.000),
      .CLKFX_DIVIDE          (1),
      .CLKFX_MULTIPLY        (4),
      .CLKIN_DIVIDE_BY_2     ("FALSE"),
      .CLKIN_PERIOD          (69.84),
      .CLKOUT_PHASE_SHIFT    ("NONE"),
      .CLK_FEEDBACK          ("1X"),
      .DESKEW_ADJUST         ("SYSTEM_SYNCHRONOUS"),
      .PHASE_SHIFT           (0),
      .STARTUP_WAIT          ("FALSE"))
    dcm_sp_ntsc_inst
    // Input clock
    (.CLKIN                 (clk_in),
     .CLKFB                 (clk_fb),
     // Output clocks
     .CLK0                  (clk_fb),
     .CLK90                 (),
     .CLK180                (),
     .CLK270                (),
     .CLK2X                 (),
     .CLK2X180              (),
     .CLKFX                 (clk_x4),
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
     (.O (clk_col16x),
      .I (clk_x4));
      
endmodule
