`timescale 1ns/1ps

`include "../common.vh"

// Top level module for the MojoV3 dev board.
//
// Only one clock configurations is supported that uses
// the on-board 50Mhz clock to produce a single dot4x
// clock.  No color clock is required since we don't
// support composite out in this module.
//
// The 4x dot clock is divided by 32 to generate the CPU phi clock.

module top(
           input sys_clock,
           input [1:0] chip,    // chip config from MCU
           input is_15khz,      // freq config pin from MCU
           input is_hide_raster_lines, // config pin from MCU
	   output tx,
	   input rx,
	   input cclk,
           output cpu_reset,    // reset for 6510 CPU
           output clk_phi,      // output phi clock for CPU
           output clk_dot4x_ext,    // pixel clock for external HDMI encoder
           output hsync,        // hsync signal for VGA/HDMI
           output vsync,        // vsync signal for VGA/HDMI
           output active,       // display active for HDMI
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
           //output ls245_addr_oe,   // OE for addr bus transceviers
           output ls245_addr_dir,  // DIR for addr bus transceivers
           output ls245_data_oe,   // OE for data bus transcevier
           output ls245_data_dir   // DIR for data bus transceiver
       );

`ifdef COMPOSITE_SUPPORT
// Should become an output if we ever support composite
wire csync;
// Should become an input if we ever support composite
wire is_composite;
`endif

wire rst;
wire clk_dot4x;
wire clk_25mhz;

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
clockgen mojo_clockgen(
             .sys_clock(sys_clock),
             .clk_dot4x(clk_dot4x),
				 .clk_25mhz(clk_25mhz),
             .rst(rst),
             .chip(chip));
`endif

// https://www.xilinx.com/support/answers/35032.html
ODDR2 oddr2(
          .D0(1'b1),
          .D1(1'b0),
          .C0(clk_dot4x),
          .C1(~clk_dot4x),
          .CE(1'b1),
          .R(1'b0),
          .S(1'b0),
          .Q(clk_dot4x_ext)
      );

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

wire[7:0] tx_data_4x;
wire tx_new_data_4x;
// Instantiate the vicii with our clocks and pins.
vicii vic_inst(
          .rst(rst),
          .chip(chip),
	  .tx_data_4x(tx_data_4x),
	  .tx_new_data_4x(tx_new_data_4x),
          .is_15khz(is_15khz),
          .is_hide_raster_lines(is_hide_raster_lines),
          .clk_dot4x(clk_dot4x),
          .clk_phi(clk_phi),
	  .active(active),
          .hsync(hsync),
          .vsync(vsync),
`ifdef COMPOSITE_SUPPORT
          .csync(csync),
          .is_composite(is_composite),
`endif
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

// Propagate tx from 4x domain to clk_25mhz domain
// When tx_new_data goes high, avr_interface will transmit
// the config byte to the MCU.
reg[7:0] tx_data_sys_pre;
reg tx_new_data_sys_pre;
reg[7:0] tx_data_sys;
reg tx_new_data_sys;

always @(posedge clk_25mhz) tx_data_sys_pre <= tx_data_4x;
always @(posedge clk_25mhz) tx_data_sys <= tx_data_sys_pre;

always @(posedge clk_25mhz) tx_new_data_sys_pre <= tx_new_data_4x;
always @(posedge clk_25mhz) tx_new_data_sys <= tx_new_data_sys_pre;

avr_interface mojo_avr_interface(
    .clk(clk_25mhz),
    .rst(rst),
    .cclk(cclk),
    .tx(tx),
    .rx(rx),
    .tx_data(tx_data_sys),
    .new_tx_data(tx_new_data_sys)
    // We don't ever receive from the MCU over serial (yet)
    //output [7:0] rx_data,
    //output new_rx_data
  );

endmodule : top
