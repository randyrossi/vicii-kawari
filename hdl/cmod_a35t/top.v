`timescale 1ns/1ps

`include "common.vh"

// Top level module for the CMod A35t PDIP board.
//
// Two clock configurations are supported:
//     1) using the on-board 12Mhz clock
//     2) using external 14.318181 and/or 17.734475 Mhz clocks
//
// System clock:
//     This config uses the on-board 12Mhz clock and uses two MMCMs
//     to generate both the 4x dot and 4x color clocks.
// 
// External Clocks:
//     This config takes in a 4x color clock signal and uses an MMCM
//     to generate the 4x dot clock.
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
           input is_composite,  // 1=composite, 0=vga/hdmi
           output cpu_reset,    // reset for 6510 CPU
           output clk_colref,   // output color ref clock for CXA1545P
           output clk_phi,      // output phi clock for CPU
           output clk_dot4x,    // pixel clock for external HDMI encoder
           output csync,        // composite sync signal for CXA1545P
           output hsync,        // hsync signal for VGA/HDMI
           output vsync,        // vsync signal for VGA/HDMI
           output active,
           output [2:0] red,    // red out for CXA1545P
           output [2:0] green,  // green out for CXA1545P
           output [2:0] blue,   // blue out for CXA1545P
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
           output ls245_data_dir   // DIR for data bus transceiver
       );

wire rst;
wire [1:0] chip;
wire clk_col4x;

`ifndef IS_SIMULATOR
// Clock generators and chip selection
clockgen cmod_clockgen(
         .sys_clock(sys_clock),
         .clk_dot4x(clk_dot4x),
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

reg [9:0] raster_x;
reg [9:0] xpos_d;
reg [8:0] raster_line;
vic_color pixel_color3;

reg [9:0] hs_sta;
reg [9:0] hs_end;
reg [9:0] ha_sta;
reg [9:0] vs_sta;
reg [9:0] vs_end;
reg [9:0] va_end;
reg [9:0] hoffset;
reg [9:0] voffset;

// Instantiate the vicii with our clocks and pins.
vicii vic_inst(
          .rst(rst),
          .chip(chip),
          .clk_dot4x(clk_dot4x),
          .clk_phi(clk_phi),
          .raster_x(raster_x),
          .xpos_d(xpos_d),
          .raster_line(raster_line),
          .pixel_color3(pixel_color3),
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
          .vic_write_db(vic_write_db),
          .vic_write_ab(vic_write_ab)
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

// ----------------------------------------------------
// Composite output - csync and color_ref
// ----------------------------------------------------
vic_color pixel_color4_composite;
comp_sync vic_comp_sync(
         .rst(rst),
         .clk_dot4x(clk_dot4x),
         .clk_col4x(clk_col4x),
         .chip(chip),
         .raster_x(xpos_d),
         .raster_y(raster_line),
         .pixel_color3(pixel_color3),
         .csync(csync),
         .clk_colref(clk_colref),
         .pixel_color4(pixel_color4_composite)
     );

// ----------------------------------------------------
// VGA/HDMI output - hsync/vsync
// ----------------------------------------------------
vic_color pixel_color4_vga;
vga_sync vic_vga_sync(
    .rst(rst),
    .clk_dot4x(clk_dot4x),
    .raster_x(raster_x),
    .raster_y(raster_line),
    .chip(chip),
    .pixel_color3(pixel_color3),
    .hsync(hsync),
    .vsync(vsync),
    .active(active),
    .pixel_color4(pixel_color4_vga)
);

// FINAL OUTPUT RGB values from stage 4 indexed value.
// The source pixel depends on video type (composite/vga)

// NOTE: It would be possible to output both HDMI/VGA and
// Composite simultaneously if we had dedicated rgb lines for
// each.

// Translate pixel_color3 (indexed) to RGB values
color vic_colors(
     .out_pixel(is_composite ? pixel_color4_composite : pixel_color4_vga),
     .red(red),
     .green(green),
     .blue(blue)
);

endmodule : top
