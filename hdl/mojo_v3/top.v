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

// NOTE: WITH_DVI support here is only included to test the
// dvi encoder is producing an image.  It's not possible to use
// the development 'hat' with DVI.  If using WITH_DVI, the
// pins selected by placement will not be compatible with the 'hat'.
// It's meant to verify we can get an image over DVI only.
module top(
           input sys_clock,
`ifdef HAVE_COLOR_CLOCKS
           input clk_col4x_pal,
           input clk_col4x_ntsc,

           // use_scan_doubler is valid only when HAVE_COLOR_CLOCKS is
	   // set. If an external composite encoder is going to be used,
	   // use_scan_doubler must be false. If use_scan_doubler is false,
	   // RGB values will be driven by the pixel sequencer directly at
	   // native resolution (which is what you need for a composite
	   // encoder). Otherwise, RGB values will go through the scan doubler
	   // suitable for VGA or DVI output. (NOTE: The vga scan doubler may
           // not be configured to double anything. It depends on how
           // it is configured but it is still required for any VGA/DVI
	   // output). When HAVE_COLOR_CLOCKS is not set only VGA or DVI
	   // output is possible so the scan doubler is always used in that
	   // case.
           input use_scan_doubler,

           // If we have a composite encoder, we output two
           // signals to drive it.
`ifdef HAVE_COMPOSITE_ENCODER
           output clk_colref,    // color ref for encoder
           output csync,         // csync for encoder
`endif
           // If we are generating luma/chroma, add outputs
`ifdef GEN_LUMA_CHROMA
           output [5:0] luma,    // luma out
           output [5:0] chroma,  // chroma out
`endif

`endif  // HAVE_COLOR_CLOCKS
           input [1:0] chip,    // chip config from MCU
           input is_15khz,      // freq config pin from MCU
           input is_hide_raster_lines, // config pin from MCU
           output tx,           // to mcm
           input rx,            // from mcm (unused a.t.m)
           input cclk,          // from mcm
           output cpu_reset,    // reset for 6510 CPU
           output clk_phi,      // output phi clock for CPU

           output clk_dot4x_ext,// pixel clock
           output hsync,        // hsync signal for VGA/DVI
           output vsync,        // vsync signal for VGA/DVI
           output active,       // display active for DVI
           output [5:0] red,    // red out for VGA/DVI or Composite Encoder
           output [5:0] green,  // green out for VGA/DVI or Composite Encoder
           output [5:0] blue,   // blue out for VGA/DVI or Composite Encoder

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
           output rwo,
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
`ifdef WITH_DVI
           ,
           output wire [3:0] TX0_TMDS,
           output wire [3:0] TX0_TMDSB
`endif
       );

// Never writing to DRAM (yet)
assign rwo = 1'b0;

wire rst;
wire clk_dot4x;

`ifdef HAVE_COLOR_CLOCKS
// When we have color clocks available, we select which
// one we want to enter the 2x clock gen (below) based
// on the chip model by using a BUFGMUX. 1=PAL, 0 = NTSC
wire clk_col4x;
BUFGMUX colmux(
   .I0(clk_col4x_ntsc),
   .I1(clk_col4x_pal),
	.O(clk_col4x),
   .S(chip[0]));	

`ifdef HAVE_COMPOSITE_ENCODER
// Since we have color clocks, we will output a color
// reference clock by dividing the incoming 4x color
// by 4.  This can be used by an external composite
// encoder chip to generate luma/chroms and/or composite
// signals.  Unless we have color clocks available, composite
// is not possible.
clk_div4 clk_colorgen (
             .clk_in(clk_col4x),     // from 4x color clock
             .reset(rst),
             .clk_out(clk_colref));  // create color ref clock
`endif

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
`endif

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
`ifdef HAVE_COLOR_CLOCKS
             .src_clock(clk_col8x),  // with color clocks, we generate dot4x from clk_col8x
`else
             .src_clock(sys_clock),  // without color clocks, we generate dot4x from 50mhz
`endif
             .clk_dot4x(clk_dot4x),
             .rst(rst),
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
`ifdef HAVE_COLOR_CLOCKS
          .use_scan_doubler(use_scan_doubler),
          .clk_col16x(clk_col16x),
`ifdef HAVE_COMPOSITE_ENCODER
          .csync(csync),
`endif
`ifdef GEN_LUMA_CHROMA
          .luma(luma),
          .chroma(chroma),
`endif
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

// Propagate tx from 4x domain to clk_serial domain
// When tx_new_data goes high, avr_interface will transmit
// the config byte to the MCU.  There is a timing exception
// in the constraints for dot4x -> sys_clock for what I
// *think* is the right CDC solution.
(* ASYNC_REG = "TRUE" *) reg[7:0] tx_data_sys_pre;
(* ASYNC_REG = "TRUE" *) reg tx_new_data_sys_pre;
(* ASYNC_REG = "TRUE" *) reg[7:0] tx_data_sys;
(* ASYNC_REG = "TRUE" *) reg tx_new_data_sys;

always @(posedge sys_clock) tx_data_sys_pre <= tx_data_4x;
always @(posedge sys_clock) tx_data_sys <= tx_data_sys_pre;

always @(posedge sys_clock) tx_new_data_sys_pre <= tx_new_data_4x;
always @(posedge sys_clock) tx_new_data_sys <= tx_new_data_sys_pre;

avr_interface mojo_avr_interface(
    .clk(sys_clock),
    .rst(1'b0),
    .cclk(cclk),
    .tx(tx),
    //.rx(rx),
    .tx_data(tx_data_sys),
    .new_tx_data(tx_new_data_sys)
    // We don't ever receive from the MCU over serial (yet)
    //output [7:0] rx_data,
    //output new_rx_data
  );

endmodule : top
