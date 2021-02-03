`timescale 1ns/1ps

`include "../common.vh"

// For the MojoV3 board.
// This module:
//     1) generates a 4x dot clock for both ntsc and pal clocks
//     2) uses the lower bit of chip to select ntsc/pal clocks
//     3) generates the reset signal and holds for approx 150ms at startup
module clockgen(
           input sys_clock,
           input [1:0] chip,
           output clk_dot4x,
           output clk_25mhz,
           output rst
       ); 

// 22 = ~150ms
// 27 = ~4s for testing
reg [22:0] rstcntr = 0;
wire internal_rst = !rstcntr[22];

always @(posedge clk_dot4x)
    if (internal_rst)
        rstcntr <= rstcntr + 4'd1;

wire clk_dot4x_pal;
wire clk_dot4x_ntsc;

// Generate the 4x dot clock for both standards. See vicii.v for values.
dot4x_50_clockgen dot4x_50_clockgen(
                          .clk_in50mhz(sys_clock),    // board 50 Mhz clock
                          .reset(1'b0),
                          .clk_dot4x_pal(clk_dot4x_pal), // generated pal dot
                          .clk_dot4x_ntsc(clk_dot4x_ntsc), // generated ntsc dot
                          .clk_25mhz(clk_25mhz), // used for serial
                          .locked(locked)
                      );

// Use a BUGFMUX to select either pal or ntsc clocks.  It might
// be possible to switch this on the fly and although that would
// be interesting, it might mess up the cycle state machine so let's
// not do it.
BUFGMUX clkmux(.S(chip[0]),
	       .I0(clk_dot4x_ntsc),
	       .I1(clk_dot4x_pal),
	       .O(clk_dot4x));

wire running;

// If we are locked and internal reset timer has been reached, then
// we are running.
assign running = locked & internal_rst;

// Synchronize reset to clock
RisingEdge_DFlipFlop_SyncReset ff1(1'b0, clk_dot4x, running, ff1_q);
RisingEdge_DFlipFlop_SyncReset ff2(ff1_q, clk_dot4x, running, rst);

endmodule : clockgen
