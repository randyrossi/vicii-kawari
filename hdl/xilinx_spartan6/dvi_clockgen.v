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

`include "../common.vh"

`ifdef WITH_DVI
    // A clock gen module for our DVI module.  Accepts a
    // pixel clock as input and generates the necessary
    // 2x, 10x and serdes strobe signals for the dvi
    // encoder.
    module dvi_clockgen (
        input    clkin,
        output   tx0_pclkx10,
        output   tx0_pclkx2,
        output   tx0_serdesstrobe
    );

wire tx0_clkfbout, tx0_clkfbin, tx0_plllckd;
wire tx0_pllclk0, tx0_pllclk2;

PLL_BASE # (
             // CLKIN_PERIOD is used for timing analysis. This is the value for PAL but
             // should be okay for NTSC too.  The tool complains this value does not
             // match the period constraint! (NgdBuild:1440) WHY???
             .CLKIN_PERIOD(31.724138),
             .CLKFBOUT_MULT(20),   // 10x CLKIN
             .CLKOUT0_DIVIDE(2),   // 10x
             .CLKOUT1_DIVIDE(20),  // 1x
             .CLKOUT2_DIVIDE(10),  // 2x
             .COMPENSATION("SOURCE_SYNCHRONOUS")
         ) PLL_OSERDES_0 (
             .CLKFBOUT(tx0_clkfbout),
             .CLKOUT0(tx0_pllclk0),
             .CLKOUT1(),
             .CLKOUT2(tx0_pllclk2),
             .CLKOUT3(),
             .CLKOUT4(),
             .CLKOUT5(),
             .LOCKED(tx0_plllckd),
             .CLKFBIN(tx0_clkfbin),
             .CLKIN(clkin),     // Pixel clock
             .RST(tx0_pll_reset)
         );

BUFG tx0_clkfb_buf (.I(tx0_clkfbout), .O(tx0_clkfbin));
BUFG tx0_pclkx2_buf (.I(tx0_pllclk2), .O(tx0_pclkx2));

wire tx0_bufpll_lock;
BUFPLL #(.DIVIDE(5)) tx0_ioclk_buf (.PLLIN(tx0_pllclk0), .GCLK(tx0_pclkx2), .LOCKED(tx0_plllckd),
                                    .IOCLK(tx0_pclkx10), .SERDESSTROBE(tx0_serdesstrobe), .LOCK(tx0_bufpll_lock));

endmodule
`endif
