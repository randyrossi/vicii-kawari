`timescale 1ns/1ps

`include "common.vh"

// Top level module for the CMod A35t PDIP board.
//
// Two clock configurations are supported:
//     1) using the on-board 12Mhz clock
//     2) using external 14.318181 and/or 17.734475 Mhz clocks
//
// System clock:
//     This config uses the on-board 12Mhz clock and uses an MMCM
//     to generate both the 4x dot and 4x color clocks.
//
// External Clocks:
//     This config takes in a 4x color clock signal and uses an MMCM
//     to generate the 4x dot clock and pass through the 4x color
//     clock.
//
// In either case, the 4x color clock is divided by 4 to produce a
// color ref clock for an external composite encoder.  The 4x dot clock
// is divided by 32 to generate the CPU phi clock.
//
// NOTE: The system clock configuration does not produce a suitable
// color clock for PAL composite video.  This is due to there being
// no mult/div possible from a 12Mhz clock to get an accurate color
// clock.  Consequently, colors will 'shimmer'.  For a stable PAL
// composite signal, an external clock must be used. HDMI or VGA
// output options don't require a color clock so the clock gens
// could be modified to accept a 4x dot clock and phi could then
// be derived from that clock.

module top(
           input sys_clock,
	   input [1:0] chip,    // chip config pin from MCU
	   input is_15khz,      // freq config pin from MCU
	   input is_hide_raster_lines, // config pin from MCU
           output cpu_reset,    // reset for 6510 CPU
           output clk_colref,   // output color ref clock for CXA1545P
           output clk_phi,      // output phi clock for CPU
           output clk_dot8x,    // pixel clock for external HDMI encoder
           output active,       // display active for HDMI
           output hsync,        // hsync signal for VGA/HDMI
           output vsync,        // vsync signal for VGA/HDMI
           output [3:0] red,    // red out for CXA1545P
           output [3:0] green,  // green out for CXA1545P
           output [3:0] blue,   // blue out for CXA1545P
`ifndef IS_SIMULATOR    
           inout tri [5:0] adl, // address (lower 6 bits)
           output tri [5:0] adh,// address (high 6 bits)
           inout tri [7:0] dbl, // data bus lines (ram/rom)
           input [3:0] dbh,     // data bus lines (color)
`else
           input [5:0] adl,
           output [5:0] adh,
           input [7:0] dbl,
           input [3:0] dbh,
           output [7:0] dbo_sim,
           output [11:0] ado_sim,
`endif
           input ce,            // chip enable (LOW=enable, HIGH=disabled)
           input rw,            // read/write (LOW=write, HIGH=read)
           output irq,          // irq
           input lp,            // light pen
           output aec,          // aec
           output ba,           // ba
           output cas,          // column address strobe
           output ras,          // row address strobe
           output ls245_data_dir  // DIR for data bus transceiver
           //output ls245_data_oe,   // OE for data bus transceiver
           //output ls245_addr_dir,  // DIR for addr bus transceiver
           //output ls245_addr_oe    // OE for addr bus transceiver
       );

// Should become an output if we ever support composite.
wire csync;

wire rst;
wire clk_col4x;
wire clk_dot4x;

wire ls245_data_oe; // not enough pins on cmod_a7, just ground it
wire ls245_addr_dir;  // not enough pins on cmod_a7, use aec
//wire ls245_addr_oe;  // not enough pins on cmod_a7, just ground it

// TODO : If we ever support composite, we need clk_col4x to
// be an input on a clock capable pin.  We then will divide it
// by 4 to get the color carrier.  Also, this would be the input
// to our clock gen that would produce clk_dot4x.  For now, we
// are using the dev board's 50Mhz clock as the source and we
// don't need a color clock for HDMI.
// Divides the color4x clock by 4 to get color reference clock
//clk_div4 clk_colorgen (
//             .clk_in(clk_col4x),     // from 4x color clock
//             .reset(rst),
//             .clk_out(clk_colref));  // create color ref clock

`ifndef IS_SIMULATOR
// Clock generators and chip selection
clockgen cmod_clockgen(
             .sys_clock(sys_clock),
             .clk_dot4x(clk_dot4x),
             .clk_dot8x(clk_dot8x), // THIS IS NOT GENERATED! NEED TO FIX GEN!
             .clk_col4x(clk_col4x),
             .rst(rst),
             .chip(chip));
`endif

// This is a reset line for the CPU which would have to be
// connected with a jumper.  It holds the CPU in reset
// before the clock is locked.  TODO: Find out if this is
// actually required.
assign cpu_reset = rst;

wire [7:0] dbo;
wire [11:0] ado;

// When these are true, the VIC is writing to the data
// or address bus so ab/db will be assigned from
// ado/dbo respectively.  Otherwise, we tri-state
// those lines and VIC can read from adi/dbi.
// NOTE: The VIC only ever reads the lower 6 bits from
// the address lines. This is the reason for the adl/adh
// split below.
wire vic_write_ab;
wire vic_write_db;

// Instantiate the vicii with our clocks and pins.
vicii vic_inst(
          .rst(rst),
          .chip(chip),
	  .is_15khz(is_15khz),
	  .is_hide_raster_lines(is_hide_raster_lines),
          .clk_dot4x(clk_dot4x),
          .clk_dot8x(clk_dot8x),
          .clk_phi(clk_phi),
	  .active(active),
	  .hsync(hsync),
	  .vsync(vsync),
	  .csync(csync),
          .adi(adl[5:0]),
          .ado(ado),
          .dbi({dbh,dbl}),
          .dbo(dbo),
          .ce(ce),
          .rw(rw),
          .aec(aec),
          .irq(irq),
          .lp(lp),
          .ba(ba),
          .cas(cas),
          .ras(ras),
          .ls245_data_dir(ls245_data_dir),
          .ls245_data_oe(ls245_data_oe),
          .ls245_addr_dir(ls245_addr_dir),
          //.ls245_addr_oe(ls245_addr_oe),
          .vic_write_db(vic_write_db),
          .vic_write_ab(vic_write_ab),
	  .red(red),
	  .green(green),
	  .blue(blue)
      );

`ifndef IS_SIMULATOR
// Write to bus condition, else tri state.
assign dbl[7:0] = vic_write_db ? dbo : 8'bz; // CPU reading
assign adl = vic_write_ab ? ado[5:0] : 6'bz; // vic or stollen cycle
assign adh = vic_write_ab ? ado[11:6] : 6'bz;
`else
assign ado_sim = ado;
assign dbo_sim = dbo;
`endif

endmodule : top
