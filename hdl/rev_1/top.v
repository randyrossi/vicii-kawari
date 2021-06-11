`timescale 1ns/1ps

`include "../common.vh"

// Top level module for the Rev1 board.
//
// Color clocks, DVI + RGB out.
module top(
`ifdef HAVE_SYS_CLOCK
           input sys_clock,
`endif
`ifdef HAVE_COLOR_CLOCKS
           input clk_col4x_pal,
           input clk_col4x_ntsc,

           // If we are generating luma/chroma, add outputs
`ifdef GEN_LUMA_CHROMA
           output [5:0] luma,    // luma out
           output [5:0] chroma,  // chroma out
`endif

`endif  // HAVE_COLOR_CLOCKS
           input [1:0] chip_ext, // chip config from MCU
           input standard_sw,    // video standard toggle switch
`ifdef HAVE_MCU_EEPROM
           output tx,           // to mcm
           input rx,            // from mcm
           input rx_busy,       // from mcm (indicates receive buffer is full)
           input cclk,          // from mcm
`endif
           output cpu_reset,    // for pulling 6510 reset low
           input cpu_reset_i,   // for listening to reset from 6510 CPU
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
`elsif HAVE_SYS_CLOCK
             .src_clock(sys_clock),  // without color clocks, we generate dot4x from 50mhz
`else
             error Need HAVE_COLOR_CLOCKS OR SYS_CLOCK
`endif
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

`ifdef HAVE_MCU_EEPROM
wire[7:0] tx_data_4x;
wire tx_new_data_4x;
reg tx_busy_4x;
wire[7:0] rx_data_4x;
wire rx_new_data_4x;
`endif

// Instantiate the vicii with our clocks and pins.
vicii vic_inst(
          .rst(rst),
          .chip(chip),
          .cpu_reset_i(cpu_reset_i),
          .standard_sw(standard_sw),
`ifdef HAVE_MCU_EEPROM
          .chip_ext(chip_ext),
          .tx_data_4x(tx_data_4x),
          .tx_new_data_4x(tx_new_data_4x),
          .tx_busy_4x(tx_busy_4x | rx_busy),
          .rx_data_4x(rx_data_4x),
          .rx_new_data_4x(rx_new_data_4x),
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
`ifdef HAVE_COLOR_CLOCKS
          .clk_col16x(clk_col16x),
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
          .ls245_addr_dir(ls245_addr_dir),
          .vic_write_db(vic_write_db),
          .vic_write_ab(vic_write_ab)
      );

// Write to bus condition, else tri state.
assign dbl[7:0] = vic_write_db ? dbo : 8'bz; // CPU reading
assign adl = vic_write_ab ? ado[5:0] : 6'bz; // vic or stollen cycle
assign adh = vic_write_ab ? ado[11:6] : 6'bz;

`ifdef HAVE_MCU_EEPROM
// Propagate tx from 4x domain to clk_serial domain
// When tx_new_data goes high, avr_interface will transmit
// the config byte to the MCU.  There is a timing exception
// in the constraints for dot4x -> sys_clock for what I
// *think* is the right CDC solution.
(* ASYNC_REG = "TRUE" *) reg[7:0] tx_data_sys_pre;
(* ASYNC_REG = "TRUE" *) reg tx_new_data_sys_pre;
(* ASYNC_REG = "TRUE" *) reg[7:0] tx_data_sys;
(* ASYNC_REG = "TRUE" *) reg tx_new_data_sys;
(* ASYNC_REG = "TRUE" *) reg tx_busy_4x_pre;

always @(posedge sys_clock) tx_data_sys_pre <= tx_data_4x;
always @(posedge sys_clock) tx_data_sys <= tx_data_sys_pre;

always @(posedge sys_clock) tx_new_data_sys_pre <= tx_new_data_4x;
always @(posedge sys_clock) tx_new_data_sys <= tx_new_data_sys_pre;

always @(posedge clk_dot4x) tx_busy_4x_pre <= tx_busy_sys;
always @(posedge clk_dot4x) tx_busy_4x <= tx_busy_4x_pre;

wire [7:0] rx_data;
wire new_rx_data;
wire tx_busy_sys;

avr_interface mojo_avr_interface(
                  .clk(sys_clock),
                  .rst(rst),
                  .cclk(cclk),
                  .tx(tx),
                  .tx_busy(tx_busy_sys),
                  .rx(rx),
                  .tx_data(tx_data_sys),
                  .new_tx_data(tx_new_data_sys),
                  .rx_data(rx_data),
                  .new_rx_data(new_rx_data)
              );

serial_cross vic_serial_cross(
                 .in_clk(sys_clock),
                 .out_clk(clk_dot4x),
                 .in_data(rx_data),
                 .new_in_data(new_rx_data),
                 .out_data(rx_data_4x),
                 .new_out_data(rx_new_data_4x));
`endif

endmodule : top
