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

// Generate clk_dot4x from a 14.318181 Mhz input clock
// Also generate a clk_col16x clock.
//
// clk_dot    = 14.318181 * 8 / 14
// clk_dot4x  = 14.318181 * 64 / 28
// clk_col16x = 14.318181 * 64 / 16 (=*4)

module dot4x_14_ntsc_clockgen
       (output wire clk_dot4x,
        output wire clk_col16x,
        input wire reset,
        input wire clk_in14mhz,
        output locked
       );

wire clk_dot4x_clk_wiz_0;
wire clk_col16x_clk_wiz_0;

wire [15:0] do_unused;
wire drdy_unused;
wire psdone_unused;
wire clkfbout_clk_wiz_0;
wire clkfbout_buf_clk_wiz_0;
wire clkfboutb_unused;
wire clkfbstopped_unused;
wire clkinstopped_unused;
wire reset_high;

MMCME2_ADV
    #(.BANDWIDTH("HIGH"),
      .CLKOUT4_CASCADE("FALSE"),
      .COMPENSATION("ZHOLD"),
      .STARTUP_WAIT("FALSE"),
      .DIVCLK_DIVIDE(1),
      .CLKFBOUT_MULT_F(64.000),
      .CLKFBOUT_PHASE(0.000),
      .CLKFBOUT_USE_FINE_PS("FALSE"),
      .CLKOUT0_DIVIDE_F(16.000),
      .CLKOUT0_PHASE(0.000),
      .CLKOUT0_DUTY_CYCLE(0.500),
      .CLKOUT0_USE_FINE_PS("FALSE"),
      .CLKOUT1_DIVIDE(28.000),
      .CLKOUT1_PHASE(0.000),
      .CLKOUT1_DUTY_CYCLE(0.500),
      .CLKOUT1_USE_FINE_PS("FALSE"),
      .CLKIN1_PERIOD(69.841))
    mmcm_adv_inst
    // Output clocks
    (
        .CLKFBOUT(clkfbout_clk_wiz_0),
        .CLKFBOUTB(clkfboutb_unused),
        .CLKOUT0(clk_col16x_clk_wiz_0),
        .CLKOUT0B(clkout0b_unused),
        .CLKOUT1(clk_dot4x_clk_wiz_0),
        .CLKOUT1B(clkout1b_unused),
        .CLKOUT2(clkout2_unused),
        .CLKOUT2B(clkout2b_unused),
        .CLKOUT3(clkout3_unused),
        .CLKOUT3B(clkout3b_unused),
        .CLKOUT4(clkout4_unused),
        .CLKOUT5(clkout5_unused),
        .CLKOUT6(clkout6_unused),
        // Input clock control
        .CLKFBIN(clkfbout_buf_clk_wiz_0),
        .CLKIN1(clk_in14mhz), // was clk_dot4x_clk_wiz_0
        .CLKIN2(1'b0),
        // Tied to always select the primary input clock
        .CLKINSEL(1'b1),
        // Ports for dynamic reconfiguration
        .DADDR(7'h0),
        .DCLK(1'b0),
        .DEN(1'b0),
        .DI(16'h0),
        .DO(do_unused),
        .DRDY(drdy_unused),
        .DWE(1'b0),
        // Ports for dynamic phase shift
        .PSCLK(1'b0),
        .PSEN(1'b0),
        .PSINCDEC(1'b0),
        .PSDONE(psdone_unused),
        // Other control and status signals
        .LOCKED(locked),
        .CLKINSTOPPED(clkinstopped_unused),
        .CLKFBSTOPPED(clkfbstopped_unused),
        .PWRDWN(1'b0),
        .RST(reset_high));
assign reset_high = reset;

BUFG clkf_buf
     (.O(clkfbout_buf_clk_wiz_0),
      .I(clkfbout_clk_wiz_0));

BUFG clkout1_buf
     (.O(clk_col16x),
      .I(clk_col16x_clk_wiz_0));

BUFG clkout2_buf
     (.O(clk_dot4x),
      .I(clk_dot4x_clk_wiz_0));

endmodule
