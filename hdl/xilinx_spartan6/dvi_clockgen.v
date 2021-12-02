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

endmodule`endif

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

// These signals are used for the BUFG's necessary for the design.
wire           clkin_bufgout;

wire           clkfb_bufgout;
wire           clkfb_bufgin;

wire           clk0_bufgin;

BUFG BUFG_CLKIN (
         .O(clkin_bufgout),
         .I(CLKIN)
     );

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
            .CLKFBOUT_MULT(16),
            .CLKFBOUT_PHASE(0.0),

            // Set the clock period (ns) of input clocks and reference jitter
            .REF_JITTER(0.100),
            .CLKIN1_PERIOD(28.190), // period for 35.468950Mhz (pal color x 8)

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
