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

// Top level module for the Rev_4L board.
module top(
           input clk_col4x_pal,
           input clk_col4x_ntsc,

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
           output flash_d1,
           output flash_d2,
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
           output clk_dot_ext,  // dot clock
`ifdef GEN_RGB
           output hsync,        // hsync signal for analog RGB
           output vsync,        // vsync signal for analog RGB
           output [5:0] red,    // red out for analog RGB
           output [5:0] green,  // green out for analog RGB
           output [5:0] blue,   // blue out for analog RGB
`endif

           inout tri [5:0] adl, // address (lower 6 bits)
           output tri [5:0] adh,// address (high 6 bits)
           inout tri [7:0] dbl, // data bus lines (ram/rom)
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
`ifdef WITH_DVI
           ,
           output wire [3:0] TX0_TMDS,
           output wire [3:0] TX0_TMDSB
`endif
       );
wire active;

wire rst;
wire clk_dot4x;
wire [1:0] chip;

`ifdef OUTPUT_DOT_CLOCK
// NOTE: This hack will only work breadbins that use
// 8701 clock ICs and that IC MUST be removed.
// i.e. 250425 250466
// This will NOT currently work on short board motherboards
// The unit with this hack should NEVER be plugged into a
// motherboard without the clock circuit being disabled.
reg[3:0] dot_clock_shift = 4'b1100;
always @(posedge clk_dot4x) dot_clock_shift <= {dot_clock_shift[2:0], dot_clock_shift[3]};
assign clk_dot_ext = dot_clock_shift[3];
`else
assign clk_dot_ext = 1'b0;
`endif

`ifdef WITH_SPI
assign flash_d1 = 1'b1;
assign flash_d2 = 1'b1;
`endif

`ifndef GEN_RGB
// When we're not exporting these signals, we still need
// them defined as wires (for DVI for example).
`ifdef NEED_RGB
wire hsync;
wire vsync;
wire [5:0] red;
wire [5:0] green;
wire [5:0] blue;
`endif
`endif

// Create 4x color clocks for both ntsc and pal
ntsc_col16x ntsc_col16x(.clk_in(clk_col4x_ntsc),
                        .clk_col16x(clk_col16x_ntsc),
                        .reset(1'b0));

pal_col16x pal_col16x(.clk_in(clk_col4x_pal),
                        .clk_col16x(clk_col16x_pal),
                        .reset(1'b0));

wire clk_col16x_4tm; // must be used to generate dot4x (and possibly later for cas/ras module)
wire clk_col16x; // must be used exclusively for chroma generation

// This will select which clock 
`ifdef GEN_LUMA_CHROMA
wire color_sel = chip[0] ? (~ntsc_50) : 1'b0; // was (pal_60);
`else
wire color_sel = chip[0];
`endif

BUFGMUX colmux2(
            .I0(clk_col16x_ntsc),
            .I1(clk_col16x_pal),
            .O(clk_col16x_4tm),
            .S(chip[0]));

BUFGMUX colmux3(
            .I0(clk_col16x_ntsc),
            .I1(clk_col16x_pal),
            .O(clk_col16x),
            .S(color_sel));

// From the 4x color clock, generate an 16x color clock
// This is necessary to meet the minimum frequency of
// the PLL_ADV where we further multiple/divide it into
// a 4x dot clock.

`ifdef WITH_DVI
wire tx0_pclkx10;
wire tx0_pclkx2;
wire tx0_serdesstrobe;
`endif

// dot4x clock generator
clockgen mojo_clockgen(
             .src_clock(clk_col16x_4tm),  // we generate dot4x from the col16x
             .clk_dot4x(clk_dot4x),
             .chip(chip)
`ifdef WITH_DVI
             ,
             .tx0_pclkx10(tx0_pclkx10),
             .tx0_pclkx2(tx0_pclkx2),
             .tx0_serdesstrobe(tx0_serdesstrobe)
`endif
         );

`ifdef WITH_DVI
// Scale from 6 bits to 8 for DVI
wire[31:0] red_scaled;
wire[31:0] green_scaled;
wire[31:0] blue_scaled;
assign red_scaled = red * 255 / 63;
assign green_scaled = green * 255 / 63;
assign blue_scaled = blue * 255 / 63;
dvi_encoder_top dvi_tx0 (
                    .pclk        (clk_dot4x),
                    .pclkx2      (tx0_pclkx2),
                    .pclkx10     (tx0_pclkx10),
                    .serdesstrobe(tx0_serdesstrobe),
                    .rstin       (1'b0),
                    .blue_din    (blue_scaled[7:0]),
                    .green_din   (green_scaled[7:0]),
                    .red_din     (red_scaled[7:0]),
                    .hsync       (hsync),
                    .vsync       (vsync),
                    .de          (active),
                    .TMDS        (TX0_TMDS),
                    .TMDSB       (TX0_TMDSB));
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

`ifdef GEN_LUMA_CHROMA
wire ntsc_50;
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
`ifdef NEED_RGB
          .active(active),
          .hsync(hsync),
          .vsync(vsync),
          .red(red),
          .green(green),
          .blue(blue),
`endif
          .clk_col16x(clk_col16x),
`ifdef GEN_LUMA_CHROMA
          .luma_sink(luma_sink),
          .luma(luma),
          .chroma(chroma),
          .ntsc_50(ntsc_50),
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
          //.ls245_data_oe(ls245_data_oe),
          //.ls245_addr_oe(ls245_addr_oe),
          .vic_write_db(vic_write_db),
          .vic_write_ab(vic_write_ab)
      );

// Write to bus condition, else tri state.
assign dbl[7:0] = vic_write_db ? dbo : 8'bz; // CPU reading
assign adl = vic_write_ab ? ado[5:0] : 6'bz; // vic or stollen cycle
assign adh = vic_write_ab ? ado[11:6] : 6'bz;

// Set LOW unless we need otherwise.
assign ls245_addr_oe = 1'b0;
assign ls245_data_oe = 1'b0;

endmodule
