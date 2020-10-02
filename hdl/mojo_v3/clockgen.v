`timescale 1ns/1ps

`include "../common.vh"

// NOTE: Clock pins must be declared in constr.xdc to match
// selected configuration here.

// Chose one:
`define USE_INTCLOCK_PAL      // use on-board clock
//`define USE_INTCLOCK_NTSC     // use on-board clock
//`define USE_EXTCLOCK_PAL      // use external clock
//`define USE_EXTCLOCK_NTSC    // use external clock


// For the CMod A35t PDIP board.
// This module:
//     1) generates the 4x dot and 4x color clocks
//     2) selects the chip
//     3) generates the reset signal and holds for approx 150ms at startup
module clockgen(
           input sys_clock,
           output clk_dot4x,
           output clk_col4x,
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
                          .clk_col4x(clk_col4x),     // generated 4x col clock
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
                           .clk_col4x(clk_col4x)     // generated 4x col clock
                           .locked(locked)
                       );
`endif

// Use an external clock for pal.
`ifdef USE_EXTCLOCK_PAL

assign chip = `CHIP6569;

dot4x_17_pal_clockgen dot4x_17_pal_clockgen(
                          .clk_in17mhz(sys_clock),
                          .reset(1'b0),
                          .clk_col4x(clk_col4x),
                          .clk_dot4x(clk_dot4x),
                          .locked(locked)
                      );
`endif

// Use an external clock for ntsc.
`ifdef USE_EXTCLOCK_NTSC

assign chip = `CHIP6567R8;

dot4x_14_ntsc_clockgen dot4x_14_ntsc_clockgen(
                           .clk_in14mhz(sys_clock),
                           .reset(1'b0),
                           .clk_col4x(clk_col4x),
                           .clk_dot4x(clk_dot4x),
                           .locked(locked)
                       );
`endif

// Synchronize reset to clock using locked output
wire hold;
assign hold = !locked & !internal_rst; 
RisingEdge_DFlipFlop_SyncReset ff1(1'b0, clk_dot4x, hold, ff1_q);
RisingEdge_DFlipFlop_SyncReset ff2(ff1_q, clk_dot4x, hold, rst);

endmodule : clockgen
