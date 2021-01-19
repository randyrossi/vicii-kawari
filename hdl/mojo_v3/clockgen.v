`timescale 1ns/1ps

`include "../common.vh"

// NOTE: Clock pins must be declared in constr.xdc to match
// selected configuration here.

// Chose one:
`define USE_INTCLOCK_PAL      // use on-board clock
//`define USE_INTCLOCK_NTSC     // use on-board clock

// For the MojoV3 board.
// This module:
//     1) generates a 4x dot clock
//     2) selects the chip
//     3) generates the reset signal and holds for approx 150ms at startup
module clockgen(
           input sys_clock,
           output clk_dot4x,
           output clk_dot8x,
           output rst,
           output [1:0] chip
       );

// 22 = ~150ms
// 27 = ~4s for testing
reg [22:0] rstcntr = 0;
wire internal_rst = !rstcntr[22];

always @(posedge clk_dot4x)
    if (internal_rst)
        rstcntr <= rstcntr + 4'd1;

// TODO: Use dynamic clock config module to select the clock
// mult/divide params based on an 'is_pal' input. Also set
// chip based on that.  At the moment, the type still has to
// be hard coded in the bitstream..

`ifdef USE_INTCLOCK_PAL

assign chip = `CHIP6569;

// Generate the 4x dot clock. See vicii.v for values.
dot4x_50_pal_clockgen dot4x_50_pal_clockgen(
                          .clk_in50mhz(sys_clock),    // board 50 Mhz clock
                          .reset(1'b0),
                          .clk_dot4x(clk_dot4x),      // generated 4x dot clock
                          .clk_dot8x(clk_dot8x),      // generated 8x dot clock
                          .locked(locked)
                      );
`endif

`ifdef USE_INTCLOCK_NTSC

assign chip = `CHIP6567R8;

// Generate the 4x dot clock. See vicii.v for values.
dot4x_50_ntsc_clockgen dot4x_50_ntsc_clockgen(
                           .clk_in50mhz(sys_clock),    // external 50 Mhz clock
                           .reset(1'b0),
                           .clk_dot4x(clk_dot4x),      // generated 4x dot clock
                           .clk_dot8x(clk_dot8x),      // generated 8x dot clock
                           .locked(locked)
                       );
`endif

wire running;

// If we are locked and internal reset timer has been reached, then
// we are running.
assign running = locked & internal_rst;

// Synchronize reset to clock
RisingEdge_DFlipFlop_SyncReset ff1(1'b0, clk_dot4x, running, ff1_q);
RisingEdge_DFlipFlop_SyncReset ff2(ff1_q, clk_dot4x, running, rst);

endmodule : clockgen
