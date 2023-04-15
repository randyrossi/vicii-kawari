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

// A clock gen module that takes an 8x color clock and
// produces 4x dot clocks.  The input 8x color clock will
// either be NTSC or PAL timing.  The PLL is configured
// to output both clocks and the correct one should be
// selected based on the chip model.
module dot4x_cc_clockgen
(
     input    RST,
     input    CLKIN,
     output   SRDY,
     output   CLK0OUT,
     output   CLK1OUT,
     output   LOCKED
);

wire           clkfb_bufgout;
wire           clkfb_bufgin;

wire           clk0_bufgin;
wire           clk1_bufgin;

BUFG BUFG_FB (
         .O(clkfb_bufgout),
         .I(clkfb_bufgin)
     );

BUFG BUFG_CLK0 (
         .O(CLK0OUT),
         .I(clk0_bufgin)
     );

BUFG BUFG_CLK1 (
         .O(CLK1OUT),
         .I(clk1_bufgin)
     );

// Default config is for PAL timing
//
// FROM COL_8X
//    35.468950 / 18 * 16 = 31.527955
//
// Second config is for NTSC timing
// FROM COL_8X
//    28.636362 / 14 * 16 = 32.72727
PLL_ADV #(
            .SIM_DEVICE("SPARTAN6"),
            .DIVCLK_DIVIDE(1), // 1 to 52
            .BANDWIDTH("LOW"), // "HIGH", "LOW" or "OPTIMIZED"

            // CLKFBOUT stuff
            .CLKFBOUT_MULT(8),
            .CLKFBOUT_PHASE(0.0),

            // Set the clock period (ns) of input clocks and reference jitter
            .REF_JITTER(0.100),
            .CLKIN1_PERIOD(14.09), // Period of PAL 16x color (NTSC would be 17.46)

            .CLKOUT0_DIVIDE(14),
            .CLKOUT0_DUTY_CYCLE(0.5),
            .CLKOUT0_PHASE(0.0),

            .CLKOUT1_DIVIDE(18),
            .CLKOUT1_DUTY_CYCLE(0.5),
            .CLKOUT1_PHASE(0.0),

            // Set the compensation
            .COMPENSATION("DCM2PLL"),

            // PMCD stuff (not used)
            .EN_REL("FALSE"),
            .PLL_PMCD_MODE("FALSE"),
            .RST_DEASSERT_CLK("CLKIN1")
        ) PLL_ADV_inst (
            .CLKFBDCM(),
            .CLKFBOUT(clkfb_bufgin),

            // CLK outputs
            .CLKOUT0(clk0_bufgin),
            .CLKOUT1(clk1_bufgin),
            .CLKOUT2(clk2_unused),
            .CLKOUT3(clk3_unused),
            .CLKOUT4(clk4_unused),
            .CLKOUT5(clk5_unused),

            // CLKOUTS to DCM
            .CLKOUTDCM0(),
            .CLKOUTDCM1(),
            .CLKOUTDCM2(),
            .CLKOUTDCM3(),
            .CLKOUTDCM4(),
            .CLKOUTDCM5(),

            .LOCKED(LOCKED),
            .CLKFBIN(clkfb_bufgout),

            // Clock inputs
            .CLKIN1(CLKIN),
            .CLKIN2(),
            .CLKINSEL(1'b1),

            .REL(1'b0),
            .RST(RST)
        );

endmodule
