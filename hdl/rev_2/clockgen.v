`timescale 1ns/1ps

`include "../common.vh"

// For the MojoV3 board.
// This module:
//     1) generates a 4x dot clock for both ntsc and pal clocks
//     2) uses the lower bit of chip to select ntsc/pal clocks
//     3) generates the reset signal and holds for approx 150ms at startup
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
