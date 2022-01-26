`timescale 1ns/1ps

`include "../common.vh"

module top(
       input clk_col4x_ntsc, // from pin
       input clk_col4x_pal, // from pin

       input clk_col16x_ntsc, // from pll
       input clk_dot4x_ntsc, // from pll
       input clk_col16x_pal, // from pll
       input clk_dot4x_pal, // from pll
    
       output reg ntsc_dot, // throw away signal for mux hack
       output reg pal_dot, // throw away signal for mux hack
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
           output flash_d1,
           output flash_d2,
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
           output adl_OE, // address enable (lower 6 bits)

           output [5:0] adh,     // address (high 6 bits)
           
           input [7:0] dbl_IN, // data bus lines in (ram/rom)
           output [7:0] dbl_OUT, // data bus ines out (ram/rom)
           output dbl_OE,  // data bus enable

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

// TODO - export dot clock for RGB header
assign clk_dot4x_ext = 1'b0;

wire rst;
assign cpu_reset = rst;

//assign pll_inst1_RESET = 1'b1;
//assign pll_inst1_CLKSEL = {1'b0, chip};

// ======== MUX HACK ==============
wire clk_dot4x;
// Put the muxed clock onto the clock tree
EFX_GBUFCE mux1(
    .CE(1'b1),
    .I(standard_sw ? clk_dot4x_pal : clk_dot4x_ntsc),
    .O(clk_dot4x)
    );

wire clk_col16x;
// Put the muxed clock onto the clock tree
EFX_GBUFCE mux2(
    .CE(1'b1),
    .I(standard_sw ? clk_col16x_pal : clk_col16x_ntsc),
    .O(clk_col16x)
    );

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
// ======== END MUX HACK ==========

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
`endif
          .adi(adl_IN[5:0]),
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
assign dbl_OE = vic_write_db;

assign adl_OUT = ado[5:0]; // vic or stollen cycle
assign adl_OE = vic_write_ab;
assign adh = ado[11:6];

// Set LOW unless we need otherwise.
assign ls245_addr_oe = 1'b0;
assign ls245_data_oe = 1'b0;

endmodule

