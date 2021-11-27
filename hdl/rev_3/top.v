`timescale 1ns/1ps

`include "../common.vh"

// Top level module for the Rev1 board.
//
// Color clocks, DVI + RGB out.
module top(
           input clk_col4x_pal,
           input clk_col4x_ntsc,

           // If we are generating luma/chroma, add outputs
`ifdef GEN_LUMA_CHROMA
           output [5:0] luma,    // luma out
           output [5:0] chroma,  // chroma out
`endif

`ifdef WITH_EXTENSIONS
           input cfg_reset,
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
           output eeprom_s,
`endif
`endif // WITH_EXTENSIONS

           output flash_d1,
           output flash_d2,

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

assign flash_d1 = 1'b1;
assign flash_d2 = 1'b1;

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

reg chip_mux1;
reg chip_mux2;
always @(posedge clk_col4x_ntsc) chip_mux1 <= chip[0];
always @(posedge clk_col4x_ntsc) chip_mux2 <= chip_mux1;

// When we have color clocks available, we select which
// one we want to enter the 2x clock gen (below) based
// on the chip model by using a BUFGMUX. 1=PAL, 0 = NTSC
wire clk_col4x;
BUFGMUX colmux(
            .I0(clk_col4x_ntsc),
            .I1(clk_col4x_pal),
            .O(clk_col4x),
            .S(chip_mux2));

// From the 4x color clock, generate an 8x color clock
// This is necessary to meet the minimum frequency of
// the PLL_ADV where we further multiple/divide it into
// a 4x dot clock.
wire clk_col8x;
wire clk_col16x;
x2_clockgen x2_clockgen(
                .clk_in(clk_col4x),
                .clk_out_x2(clk_col8x), // for PLL to gen dot4x
                .clk_out_x4(clk_col16x), // for LUMA/CHROMA gen
                .reset(1'b0));

`ifdef WITH_DVI
wire tx0_pclkx10;
wire tx0_pclkx2;
wire tx0_serdesstrobe;
`endif

// dot4x clock generator
// If we have color clocks, pass in the col8x clock
// which will produce an accurate dot4x clock.
// Otherwise, we are using the system 50mhz clock
// and we use a dynamically configured PLL to get us
// as close as possible.
clockgen mojo_clockgen(
             .src_clock(clk_col8x),  // with color clocks, we generate dot4x from clk_col8x
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

// Instantiate the vicii with our clocks and pins.
vicii vic_inst(
          .rst(rst),
          .chip(chip),
          .cpu_reset_i(cpu_reset_i),
          .standard_sw(standard_sw),
`ifdef HAVE_FLASH
          .flash_s(flash_s),
`endif
`ifdef HAVE_EEPROM
          .eeprom_s(eeprom_s),
`endif
`ifdef WITH_SPI
          .spi_d(spi_d),
          .spi_q(spi_q),
          .spi_c(spi_c),
`endif
`ifdef WITH_EXTENSIONS
          .cfg_reset(cfg_reset),
          .spi_lock(cfg1),
          .extensions_lock(cfg2),
          .persistence_lock(cfg3),
`endif
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
          .luma(luma),
          .chroma(chroma),
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
          .ls245_addr_dir(ls245_addr_dir),
          .vic_write_db(vic_write_db),
          .vic_write_ab(vic_write_ab)
      );

// Write to bus condition, else tri state.
assign dbl[7:0] = vic_write_db ? dbo : 8'bz; // CPU reading
assign adl = vic_write_ab ? ado[5:0] : 6'bz; // vic or stollen cycle
assign adh = vic_write_ab ? ado[11:6] : 6'bz;

endmodule : top
