`timescale 1ns/1ps

`include "../common.vh"

// Top level module for the cmod-a35t for testing.
// This is just for testing RGB or luma/chroma or
// EEPROM stuff.  There aren't enough pins on the
// cmod-a35t to have all signals so this is
// stripped down a bit.
module top(
           input sys_clock,
           input [1:0] btn,
           output [1:0] led,
           output [5:0] luma,    // luma out
           output [5:0] chroma,  // chroma out
           //output cpu_reset,    // reset for 6510 CPU
           output clk_phi,      // output phi clock for CPU
`ifdef GEN_RGB
           output clk_dot4x,    // pixel clock for VGA/DVI
           output hsync,        // hsync signal for VGA/DVI
           output vsync,        // vsync signal for VGA/DVI
           output [5:0] red,    // red out for VGA/DVI or Composite Encoder
           output [5:0] green,  // green out for VGA/DVI or Composite Encoder
           output [5:0] blue,   // blue out for VGA/DVI or Composite Encoder
`endif
`ifdef HAVE_EEPROM
        output D,
        input  Q,
        output C,
        output S,
`endif
           inout tri [5:0] adl, // address (lower 6 bits)
           output tri [5:0] adh,// address (high 6 bits)
           inout tri [7:0] dbl, // data bus lines (ram/rom)
           input [3:0] dbh,     // data bus lines (color)

           input ce,            // chip enable (LOW=enable, HIGH=disabled)
           input rw,            // read/write (LOW=write, HIGH=read)
           output irq,          // irq
           input lp,            // light pen
           output aec,          // aec
           output ba,           // ba
           output cas,          // column address strobe
           output ras,          // row address strobe
           output ls245_addr_dir,  // DIR for addr bus transceivers
           output ls245_data_dir   // DIR for data bus transceiver
       );
wire active;

wire rst;
wire clk_dot4x;

wire [1:0] chip;
assign chip = `CHIP6567R8;

`ifndef GEN_RGB
// When we're not exporting these signals, we still need
// them defined as wires (for DVI for example).
`ifdef NEED_RGB
wire hsync;
wire vsync;
wire active;
wire [5:0] red;
wire [5:0] green;
wire [5:0] blue;
`endif
`endif

wire clk_col16x;

// dot4x clock generator
// sys_clock could be 12mhz on board clock or an external
// clock from an oscillator. See clockgen.v
clockgen a35t_clockgen(
             .src_clock(sys_clock),
             .clk_dot4x(clk_dot4x),
             .clk_col16x(clk_col16x),
             .chip(chip)
        );

// This is a reset line for the CPU which would have to be
// connected with a jumper.  It holds the CPU in reset
// before the clock is locked.  TODO: Find out if this is
// actually required.
//assign cpu_reset = rst;

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
          .btn(btn),
          .led(led),
          .clk_dot4x(clk_dot4x),
          .clk_phi(clk_phi),
`ifdef NEED_RGB
          .active(active),
          .hsync(hsync),
          .vsync(vsync),
          .red(red),
          .green(green),
          .blue(blue),
`endif
`ifdef HAVE_EEPROM
            .D(D),
            .Q(Q),
            .C(C),
            .S(S),
`endif
          .clk_col16x(clk_col16x),
          .luma(luma),
          .chroma(chroma),
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
          .ls245_addr_dir(ls245_addr_dir),
          .vic_write_db(vic_write_db),
          .vic_write_ab(vic_write_ab)
      );

// Write to bus condition, else tri state.
assign dbl[7:0] = vic_write_db ? dbo : 8'bz; // CPU reading
assign adl = vic_write_ab ? ado[5:0] : 6'bz; // vic or stollen cycle
assign adh = vic_write_ab ? ado[11:6] : 6'bz;

endmodule : top
