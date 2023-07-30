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

`include "../common.vh"

module top(
       input clk_col4x_ntsc, // from pin
       input clk_col4x_pal, // from pin

       input clk_col16x_ntsc, // from pll
       input clk_dot4x_ntsc, // from pll
       input clk_col16x_pal, // from pll
       input clk_dot4x_pal, // from pll

       // If we are generating luma/chroma, add outputs
`ifdef GEN_LUMA_CHROMA
           output luma_sink,     // luma current sink
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

           output cpu_reset,    // for pulling 6510 reset LOW
`ifdef HIRES_RESET
           input cpu_reset_i,   // for listening to 6510 reset
`endif
           input standard_sw,   // video standard toggle switch
           output clk_phi,      // output phi clock for CPU
`ifdef OUTPUT_DOT_CLOCK
           output clk_dot_ext,  // pixel clock
`endif

           input [5:0] adl_IN, // address (lower 6 bits input)
           output [5:0] adl_OUT, // address (lower 6 bits output)
           output [5:0] adl_OE, // address enable (lower 6 bits)

           output [5:0] adh,     // address (high 6 bits)

           input [7:0] dbl_IN, // data bus lines in (ram/rom)
           output [7:0] dbl_OUT, // data bus ines out (ram/rom)
           output [7:0] dbl_OE,  // data bus enable

           input [3:0] dbh,     // data bus lines (color)

           input ce,            // chip enable (LOW=enable, HIGH=disabled)
           input rw,            // read/write (LOW=write, HIGH=read)
           output rw_ctl,
           output irq,          // irq
           input lp,            // light pen
           output aec,          // aec
           output ba,           // ba
           output cas,          // column address strobe
           output ras,          // row address strobe
           output ls245_addr_dir,  // DIR for addr bus transceivers
           output ls245_data_dir,  // DIR for data bus transceiver
           output ls245_addr_oe,   // OE for addr bus transceivers
           output ls245_data_oe    // OE for data bus transceiver
);

`ifdef OUTPUT_DOT_CLOCK

`define HAVE_DOT_CLOCK_REGS 1
reg[3:0] dot_clock_shift = 4'b1100;
always @(posedge clk_dot4x) begin
   dot_clock_shift <= {dot_clock_shift[2:0], dot_clock_shift[3]};
end
assign clk_dot_ext = dot_clock_shift[3];
`endif

wire rst;
`ifdef DOT_CLOCK_ON_74LS05
// NOTE: Hack to get the dot clock on Pin 3 of the 74LS05
// instead of the reset signal.
// A wire must be soldered and a 33 ohm resistor added
// before plugging into the motherboard.
// For boards that have it, the 8701 clock ICs must be
// removed. i.e. 250425 250466
// For other boards, the clock circuit must be disabled.
// This will NOT currently work on short board motherboards
// The unit with this hack should NEVER be plugged into a
// motherboard without the clock circuit being disabled.
`ifndef HAVE_DOT_CLOCK_REGS
reg[3:0] dot_clock_shift = 4'b1100;
always @(posedge clk_dot4x) begin
   dot_clock_shift <= {dot_clock_shift[2:0], dot_clock_shift[3]};
end
`endif
assign cpu_reset = dot_clock_shift[3];
`else
assign cpu_reset = rst;
`endif

wire clk_dot4x;
// Put the muxed clock onto the clock tree
EFX_GBUFCE mux1(
    .CE(1'b1),
    .I(chip[0] ? clk_dot4x_pal : clk_dot4x_ntsc),
    .O(clk_dot4x)
    );

wire clk_col16x;
`ifdef GEN_LUMA_CHROMA
wire color_sel = chip[0] ? (~ntsc_50) : 1'b0; //was (pal_60)
`else
wire color_sel = chip[0];
`endif

// Put the muxed clock onto the clock tree
EFX_GBUFCE mux2(
    .CE(1'b1),
    .I(color_sel ? clk_col16x_pal : clk_col16x_ntsc),
    .O(clk_col16x)
    );

wire clk_col16x_4tm;
EFX_GBUFCE mux2b(
    .CE(1'b1),
    .I(chip[0] ? clk_col16x_pal : clk_col16x_ntsc),
    .O(clk_col16x_4tm)
    );

(* syn_preserve = "true" *) reg ntsc_dot;// throw away signal for mux hack
(* syn_preserve = "true" *) reg pal_dot; // throw away signal for mux hack
(* syn_preserve = "true" *) reg ntsc_col; // throw away signal for mux hack
(* syn_preserve = "true" *) reg pal_col; // throw away signal for mux hack

// This is a bit of a hack.  The Efinity toolchain does
// not like us using  our generated clocks only in the
// bit of combinatorial logic above (mux). It wants
// to drive at least one flipflop. So, we will burn
// 6 pins, one for each of our generated clocks. Is
// there a better way?
always @(posedge clk_dot4x_ntsc)
begin
    ntsc_dot <= ~ntsc_dot;
end

always @(posedge clk_dot4x_pal)
begin
    pal_dot <= ~pal_dot;
end

always @(posedge clk_col16x_ntsc)
begin
    ntsc_col <= ~ntsc_col;
end

always @(posedge clk_col16x_pal)
begin
    pal_col <= ~pal_col;
end

wire [7:0] dbo;
wire [11:0] ado;

wire vic_write_ab;
wire vic_write_db;

wire [1:0] chip;
`ifdef GEN_LUMA_CHROMA
wire ntsc_50;
//wire pal_60;
`endif

// Instantiate the vicii with our clocks and pins.
vicii vic_inst(
          .rst(rst),
          .chip(chip),
          .rw_ctl(rw_ctl),
`ifdef HIRES_RESET
          .cpu_reset_i(cpu_reset_i),
`endif
          .standard_sw(standard_sw),
`ifdef WITH_EXTENSIONS
          .spi_lock(cfg1),
          .extensions_lock(cfg2),
          .persistence_lock(cfg3),
`ifdef HAVE_FLASH
          .flash_s(flash_s),
`endif
`ifdef HAVE_EEPROM
          .cfg_reset(cfg_reset),
          .eeprom_s(eeprom_s),
`endif
`ifdef WITH_SPI
          .spi_d(spi_d),
          .spi_q(spi_q),
          .spi_c(spi_c),
`endif
`endif // WITH_EXTENSIONS
          .clk_dot4x(clk_dot4x),
          .clk_phi(clk_phi),
          .clk_col16x(clk_col16x),
          .clk_col16x_4tm(clk_col16x_4tm),
`ifdef GEN_LUMA_CHROMA
          .luma_sink(luma_sink),
          .luma(luma),
          .chroma(chroma),
          .ntsc_50(ntsc_50),
          //.pal_60(pal_60),
`endif
          .adi(adl_IN),
          .ado(ado),
          .dbi({dbh,dbl_IN}),
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
          //.ls245_data_oe(ls245_data_oe),
          //.ls245_addr_oe(ls245_addr_oe),
          .vic_write_db(vic_write_db),
          .vic_write_ab(vic_write_ab)
      );

      
// Write to bus condition, else tri state.
assign dbl_OUT[7:0] = dbo; // CPU reading
assign dbl_OE = {vic_write_db,vic_write_db,vic_write_db,vic_write_db,vic_write_db,vic_write_db,vic_write_db,vic_write_db};

assign adl_OUT = ado[5:0]; // vic or stollen cycle
assign adl_OE = {vic_write_ab,vic_write_ab,vic_write_ab,vic_write_ab,vic_write_ab,vic_write_ab};
assign adh = ado[11:6];

// Set LOW unless we need otherwise.
assign ls245_addr_oe = 1'b0;
assign ls245_data_oe = 1'b0;

endmodule
