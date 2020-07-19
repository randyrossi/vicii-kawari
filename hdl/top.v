`timescale 1ns/1ps

`include "common.vh"

// Top level module for the CMod A35t PDIP board.
module top(
           input sys_clock,
           input is_composite,  // 1=composite, 0=vga
           output cpu_reset,    // reset for 6510 CPU
           output clk_colref,   // output color ref clock for CXA1545P
           output clk_phi,      // output phi clock for CPU
           output csync,        // composite sync signal for CXA1545P
           output hsync,        // hsync signal for VGA
           output vsync,        // vsync signal for VGA
           output [2:0] red,    // red out for CXA1545P
           output [2:0] green,  // green out for CXA1545P
           output [2:0] blue,   // blue out for CXA1545P
           inout tri [5:0] adl, // address (lower 6 bits)
           output tri [5:0] adh,// address (high 6 bits)
           inout tri [7:0] dbl, // data bus lines
           input [3:0] dbh,      // data bus lines
           input ce,            // chip enable (LOW=enable, HIGH=disabled)
           input rw,            // read/write (LOW=write, HIGH=read)
           output irq,          // irq
           input lp,            // light pen
           output aec,          // aec
           output ba,           // ba
           output cas,          // column address strobe
           output ras,          // row address strobe
           output ls245_dir     // DIR for bus transceiver
       );

wire rst;
wire [1:0] chip;
wire clk_dot4x;
wire clk_col4x;

// Vendor specific clock generators and chip selection
cmod cmod(
         .sys_clock(sys_clock),
         .clk_dot4x(clk_dot4x),
         .clk_col4x(clk_col4x),
         .rst(rst),
         .chip(chip));

// This is a reset line for the CPU which would have to be
// connected with a jumper.  It holds the CPU in reset
// before the clock is locked.
assign cpu_reset = rst;

// Divides the color4x clock by 4 to get color reference clock
clk_div4 clk_colorgen (
          .clk_in(clk_col4x),     // from 4x color clock
          .reset(rst),
          .clk_out(clk_colref));  // create color ref clock

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
          .chip(chip),
          .is_composite(is_composite),
          .clk_dot4x(clk_dot4x),
          .clk_phi(clk_phi),
          .red(red),
          .green(green),
          .blue(blue),
          .rst(rst),
          .csync(csync),
          .hsync(hsync),
          .vsync(vsync),
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
          .ls245_dir(ls245_dir),
          .vic_write_db(vic_write_db),
          .vic_write_ab(vic_write_ab)
      );

// Write to bus condition, else tri state.
assign dbl[7:0] = vic_write_db ? dbo : 8'bz; // CPU reading
assign adl = vic_write_ab ? ado[5:0] : 6'bz; // vic or stollen cycle
assign adh = vic_write_ab ? ado[11:6] : 6'bz;

endmodule : top
