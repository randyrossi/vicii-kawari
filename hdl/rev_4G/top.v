`timescale 1ns/1ps

`include "../common.vh"

module top(
       input clk_col4x_ntsc, // from pin
       input clk_col4x_pal, // from pin

       input clk_col16x_ntsc, // from pll
       input clk_dot4x_ntsc, // from pll
       input clk_dot40x_ntsc, // from pll
       input clk_col16x_pal, // from pll
       input clk_dot4x_pal, // from pll
       input clk_dot40x_pal, // from pll

       output reg ntsc_dot, // throw away signal for mux hack
       output reg ntsc_dot_10, // throw away signal for mux hack
       output reg pal_dot, // throw away signal for mux hack
       output reg pal_dot_10, // throw away signal for mux hack
       output reg ntsc_col, // throw away signal for mux hack
       output reg pal_col, // throw away signal for mux hack

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
           input cpu_reset_i,   // for listening to 6510 reset
           input standard_sw,   // video standard toggle switch
           output clk_phi,      // output phi clock for CPU
`ifdef GEN_RGB
           output clk_dot4x_ext,// pixel clock for VGA/DVI
           output hsync,        // hsync signal for VGA/DVI
           output vsync,        // vsync signal for VGA/DVI
           output [5:0] red,    // red out for VGA/DVI or Composite Encoder
           output [5:0] green,  // green out for VGA/DVI or Composite Encoder
           output [5:0] blue,   // blue out for VGA/DVI or Composite Encoder
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
`ifdef WITH_DVI
           ,
           output tmds_data_r,
           output tmds_data_g,
           output tmds_data_b,
           output tmds_clock
`endif
);

// TODO - export dot clock for RGB header
assign clk_dot4x_ext = 1'b0;

wire rst;
assign cpu_reset = rst;

`ifdef USE_MUX_HACK
`define OOT_CLOCK_4X clk_dot4x
`define DOT_CLOCK_40X clk_dot40x
`define COL_CLOCK_16X clk_col16x
`else
// Fix to one or the other for testing
`define DOT_CLOCK_4X clk_dot4x_ntsc
`define DOT_CLOCK_40X clk_dot40x_ntsc
`define COL_CLOCK_16X clk_col16x_ntsc
`endif

// ======== MUX HACK ==============
// There seems to be no clock mux for the Trion
// family. This is a hack to mux our clock. It
// appears to work but produces a warning indicating
// this might introduce extra clock skew.  However,
// it doesn't seemt o be a problem.

`ifdef USE_MUX_HACK
wire clk_dot4x;
// Put the muxed clock onto the clock tree
EFX_GBUFCE mux1(
    .CE(1'b1),
    .I(standard_sw ? clk_dot4x_ntsc : clk_dot4x_pal),
    .O(clk_dot4x)
    );

wire clk_dot40x;
// Put the muxed clock onto the clock tree
EFX_GBUFCE mux3(
    .CE(1'b1),
    .I(standard_sw ? clk_dot40x_ntsc : clk_dot40x_pal),
    .O(clk_dot40x)
    );

wire clk_col16x;
// Put the muxed clock onto the clock tree
EFX_GBUFCE mux2(
    .CE(1'b1),
    .I(standard_sw ? clk_col16x_ntsc : clk_col16x_pal),
    .O(clk_col16x)
    );

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

always @(posedge clk_dot40x_ntsc)
begin
    ntsc_dot_10 <= ~ntsc_dot_10;
end

always @(posedge clk_dot40x_pal)
begin
    pal_dot_10 <= ~pal_dot_10;
end

always @(posedge clk_col16x_ntsc)
begin
    ntsc_col <= ~ntsc_col;
end

always @(posedge clk_col16x_pal)
begin
    pal_col <= ~pal_col;
end
`endif

wire [7:0] dbo;
wire [11:0] ado;

wire vic_write_ab;
wire vic_write_db;

wire [1:0] chip;

// Instantiate the vicii with our clocks and pins.
vicii vic_inst(
          .rst(rst),
          .chip(chip),
          .rw_ctl(rw_ctl),
          .cpu_reset_i(cpu_reset_i),
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
          .clk_dot4x(`DOT_CLOCK_4X),
          .clk_phi(clk_phi),
`ifdef NEED_RGB
          .active(active),
          .hsync(hsync),
          .vsync(vsync),
          .red(red),
          .green(green),
          .blue(blue),
`endif
          .clk_col16x(`COL_CLOCK_16X),
`ifdef GEN_LUMA_CHROMA
          .luma_sink(luma_sink),
          .luma(luma),
          .chroma(chroma),
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
          .ba(ba),
          .cas(cas),
          .ras(ras),
          .ls245_data_dir(ls245_data_dir),
          .ls245_addr_dir(ls245_addr_dir),
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

`ifdef WITH_DVI
// Scale from 6 bits to 8 for DVI
wire[31:0] red_scaled;
wire[31:0] green_scaled;
wire[31:0] blue_scaled;
assign red_scaled = red * 255 / 63;
assign green_scaled = green * 255 / 63;
assign blue_scaled = blue * 255 / 63;

`ifdef HALF_X_RES
// Turn this on if we set native x in both
// registers and vga sync modules. Tests
// 16Mhz dot clock instead of 32mhz
reg ff1;
reg ff2;
always @(posedge `DOT_CLOCK_4X) ff1=~ff1;
always @(posedge `DOT_CLOCK_40X) ff2=~ff2;
`endif

dvi dvi_tx0 (
`ifdef HALF_X_RES
   .clk_pixel    (ff1), //`DOT_CLOCK_4X),
   .clk_pixel_x10(ff2), //`DOT_CLOCK_40X),
`else
   .clk_pixel    (`DOT_CLOCK_4X),
   .clk_pixel_x10(`DOT_CLOCK_40X),
`endif
   .reset        (1'b0),
   .rgb          ({red_scaled[7:0], green_scaled[7:0], blue_scaled[7:0]}),
   .hsync        (hsync),
   .vsync        (vsync),
   .de           (active),
   .tmds         ({tmds_data_r, tmds_data_g, tmds_data_b}),
   .tmds_clock   (tmds_clock));
`endif

endmodule
