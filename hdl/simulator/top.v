// This file is part of the vicii-kawari distribution
// (https://github.com/randyrossi/vicii-kawari)
// Copyright (c) 2022 Randy Rossi.
// 
// This program is free software: you can redistribute it and/or modify  
// it under the terms of the GNU General Public License as published by  
// the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful, but 
// WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License 
// along with this program. If not, see <http://www.gnu.org/licenses/>.

`timescale 1ns/1ps

`include "common.vh"

// Top level module for the simulator.
//
`ifndef SIMULATOR_BOARD
ERROR_NEED_SIMULATOR_BOARD_DEFINED See common.vh
`endif

module top(
           input clk_col4x,     // driven by sim
           input clk_col16x,    // driven by sim

           output cpu_reset,    // reset for 6510 CPU
`ifdef HIRES_RESET
           input cpu_reset_i,
`endif
           input[1:0] sim_chip, // only used by sim to pass in cmd line chip
           input standard_sw,   // video standard toggle switch
           output clk_phi,      // output phi clock for CPU
           output clk_dot4x,    // pixel clock
`ifdef WITH_DVI
           input clk_dvi,       // pixel clock
`endif
`ifdef GEN_RGB
           output reg clk_rgb,      // pixel clock for analog RGB
           output active,
           output hsync,        // hsync signal for analog RGB
           output vsync,        // vsync signal for analog RGB
           output [5:0] red,    // red out for analog RGB
           output [5:0] green,  // green out for analog RGB
           output [5:0] blue,   // blue out for analog RGB
`endif

           // If we are generating luma/chroma, add outputs
`ifdef GEN_LUMA_CHROMA
           output luma_sink,    // luma current sink
           output [5:0] luma,    // luma out
           output [5:0] chroma,  // chroma out
`endif

`ifdef WITH_EXTENSIONS
           input cfg1,
           input cfg2,
           input cfg3,
`ifdef HAVE_FLASH
           output flash_s,
`endif
`ifdef WITH_SPI
           output spi_d,
           input  spi_q,
           output spi_c,
`endif
`ifdef HAVE_EEPROM
           input cfg_reset,
           output eeprom_s,
`endif
`endif // WITH_EXTENSIONS

           // Verilog doesn't support inout/tri so this section is
           // slightly different than non-sim top
           input [5:0] adl,  // address (lower 6 bits)
           output [5:0] adh, // address (upper 6 bits)
           input [7:0] dbl,  // data bus lines (ram/rom)
           input [3:0] dbh,  // data bus lines (color)
           output [7:0] dbo_sim,  // for our simulator
           output [11:0] ado_sim, // for our simulator
           // End diff

           input ce,            // chip enable (LOW=enable, HIGH=disabled)
           input rw,            // read/write (LOW=write, HIGH=read)
           output rw_ctl,
           output irq,          // irq
           input lp,            // light pen
           output aec,          // aec
           output ba,           // ba
           output cas,          // column address strobe
           output ras,          // row address strobe
           output ls245_data_dir,  // DIR for data bus transceiver
           output ls245_addr_dir   // DIR for addr bus transceiver
`ifdef WITH_DVI
           ,
           output tmds_data_r, // from generic DVI encoder
           output tmds_data_g, // from generic DVI encoder
           output tmds_data_b, // from generic DVI encoder
           output tmds_clock // from generic DVI encoder
`endif
           );

wire rst;
wire [1:0] chip;
`ifdef GEN_LUMA_CHROMA
wire ntsc_50;
//wire pal_60;
`endif

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

// This is a reset line for the CPU which would have to be
// connected with a jumper.  It holds the CPU in reset
// before the clock is locked.  TODO: Find out if this is
// actually required.
`ifdef OUTPUT_DOT_CLOCK
reg[3:0] dot_clock_shift = 4'b1100;
always @(posedge clk_dot4x) dot_clock_shift <= {dot_clock_shift[2:0], dot_clock_shift[3]};
assign cpu_reset = dot_clock_shift[3];
`else
assign cpu_reset = rst;
`endif

`ifdef EFINIX
`ifdef WITH_DVI
reg rst_dvi_1;
reg rst_dvi;
always @ (posedge clk_dvi) rst_dvi_1 <= rst;
always @ (posedge clk_dvi) rst_dvi <= rst_dvi_1;
`endif
`endif

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
`ifdef HIRES_RESET
          .cpu_reset_i(cpu_reset_i),
`endif
          .sim_chip(sim_chip),
          .standard_sw(standard_sw),
          .clk_dot4x(clk_dot4x),
`ifdef EFINIX
`ifdef WITH_DVI
          .clk_dvi(clk_dvi),
          .rst_dvi(rst_dvi),
`endif
`endif
          .clk_phi(clk_phi),
          .clk_col16x(clk_col16x),
`ifdef EFINIX
          .clk_col16x_4tm(clk_col16x),
`endif
`ifdef NEED_RGB
          .active(active),
          .hsync(hsync),
          .vsync(vsync),
          .red(red),
          .green(green),
          .blue(blue),
`endif
`ifdef GEN_LUMA_CHROMA
          .luma_sink(luma_sink),
          .luma(luma),
          .chroma(chroma),
          .ntsc_50(ntsc_50),
          //.pal_60(pal_60),
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
          .ba_d2(ba),
          .cas(cas),
          .ras(ras),
          .ls245_data_dir(ls245_data_dir),
          .ls245_addr_dir(ls245_addr_dir),
          .vic_write_db(vic_write_db),
          .vic_write_ab(vic_write_ab),
`ifdef WITH_EXTENSIONS
`ifdef HAVE_EEPROM
          .cfg_reset(cfg_reset),
          .eeprom_s(eeprom_s),
`endif
          .spi_lock(cfg1),
          .extensions_lock(cfg2),
          .persistence_lock(cfg3),
`ifdef HAVE_FLASH
          .flash_s(flash_s),
`endif
`ifdef WITH_SPI
          .spi_d(spi_d),
          .spi_q(spi_q),
          .spi_c(spi_c),
`endif
`endif // WITH_EXTENSIONS
          .rw_ctl(rw_ctl),
          .chip(chip)
      );

// Diff for Verilator, no tri state so use _sim regs
assign ado_sim = ado;
assign dbo_sim = dbo;
// End diff

`ifdef WITH_DVI
wire[31:0] red_scaled;
wire[31:0] green_scaled;
wire[31:0] blue_scaled;
assign red_scaled = red * 255 / 63;
assign green_scaled = green * 255 / 63;
assign blue_scaled = blue * 255 / 63;

// Fake a clock and 10x clock. Won't be
// aligned to dot4x but we can look at
// rgb data load and encoding issues.
reg c1 = 1;
reg [3:0] ctr;
reg c2;
always @(posedge clk_dot4x)
begin
    c1 = ~c1;
    ctr = ctr +1;
    if (ctr == 10) begin
       ctr = 0;
       c2 = ~c2;
    end
end

dvi dvi_tx0 (
   .clk_pixel    (c2),
   .clk_pixel_x10(c1),
   .reset        (rst),
   .rgb          ({red_scaled[7:0], green_scaled[7:0], blue_scaled[7:0]}),
   .hsync        (hsync),
   .vsync        (vsync),
   .de           (active),
   .tmds         ({tmds_data_r, tmds_data_g, tmds_data_b}),
   .tmds_clock   (tmds_clock));
`endif

endmodule
