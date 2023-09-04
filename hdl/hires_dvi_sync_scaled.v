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

`include "common.vh"

// A module to produce horizontal and vertical sync pulses for VGA/HDMI output.
// Timings are not standard and may not work on all monitors.

// This version of sync/pixel generator uses slower clocks than the full
// clk_dot4x. We can use a slower clock but get the same vertical refresh
// rate by reducing the horizontal width.  This chart outlines the changes:
//
// standard |clk_dot4x | orig_width   | clk_dvi   | dvi_width | xoffset | frac
// ----------------------------------------------------------------------------
// 6567R8   |32.727272 | 1040 (520x2) | 26.590909 | 845       | 136     | 13/16
// 6567R56A |32.727272 | 1024 (512x2) | 26.590909 | 832       | 142     | 13/16
// 6569     |31.527955 | 1008 (504x2) | 29.557458 | 945       | 78      | 15/16
// 6569(alt)|31.527955 | 1008 (504x2) | 27.586961 | 882       | 98      | 14/16
//
// The benefit is the DVI 10x pixel clock does not have to be as high
// and we get better sync/pixel stability.  Also, we can chop off some
// of the border area that is not normally visible anyway.  The 'alt' version
// of 6569 at 14/16 was added to give users who have very picky monitors
// an alternative.  It seems 50hz resolutions are more difficult to get
// right.
//
// NOTE: This module cannot be compiled without HIRES_MODES enabled. The
// widths for two of the 3 chips are not evenly divisible by 2. Turning on 1x
// in the CONFIG will make no difference. A separate version of dvi sync must
// be created with 1/2 the pixel clocks shown above and then the full native
// 1x resolution can be supported. This requires alternate clock mult/div
// settings to get the 16.36mhz and 15.76mhz clocks. If used, no hires modes
// will work. There seems to be no advantage do doing this though and will
// look fuzzy on monitors as they scale up a small image.  It seems better to
// always double the horizontal width, at least for DVI output.

`ifdef PAL_32MHZ
`define PAL_MAX_WIDTH 11'd1007
`define PAL_WIDTH 11'd1008
`define PAL_OFFSET 11'd0
`define PAL_CONFIGURABLE_OFFSET 11'd768
`elsif PAL_15MHZ
`define PAL_MAX_WIDTH 11'd503
`define PAL_WIDTH 11'd504
`define PAL_OFFSET 11'd0
`define PAL_CONFIGURABLE_OFFSET 11'd384
`elsif PAL_27MHZ
`define PAL_MAX_WIDTH 11'd881
`define PAL_WIDTH 11'd882
`define PAL_OFFSET 11'd102 // no effect here, see registers.v
`define PAL_CONFIGURABLE_OFFSET 11'd768
`elsif PAL_29MHZ
`define PAL_MAX_WIDTH 11'd944
`define PAL_WIDTH 11'd945
`define PAL_OFFSET 11'd70 // no effect here, see registers.v
`define PAL_CONFIGURABLE_OFFSET 11'd768
`endif

`ifdef NTSC_32MHZ
`define NTSCR8_MAX_WIDTH 11'd1039
`define NTSCR8_WIDTH 11'd1040
`define NTSCR8_OFFSET 11'd0
`define NTSCR56_MAX_WIDTH 11'd1023
`define NTSCR56_WIDTH 11'd1024
`define NTSCR56_OFFSET 11'd0
`define NTSC_CONFIGURABLE_OFFSET 11'd768
`elsif NTSC_16MHZ
`define NTSCR8_MAX_WIDTH 11'd519
`define NTSCR8_WIDTH 11'd520
`define NTSCR8_OFFSET 11'd0
`define NTSCR56_MAX_WIDTH 11'd513
`define NTSCR56_WIDTH 11'd512
`define NTSCR56_OFFSET 11'd0
`define NTSC_CONFIGURABLE_OFFSET 11'd384
`elsif NTSC_26MHZ
`define NTSCR8_MAX_WIDTH 11'd844
`define NTSCR8_WIDTH 11'd845
`define NTSCR8_OFFSET 11'd140 // no effect here, see registers.v
`define NTSCR56_MAX_WIDTH 11'd831
`define NTSCR56_WIDTH 11'd832
`define NTSCR56_OFFSET 11'd150 // no effect here, see registers.v
`define NTSC_CONFIGURABLE_OFFSET 11'd768
`endif

// A block ram module to hold a single raster line of pixel colors
module dvi_linebuf_RAM
       #(
           parameter addr_width = 11, // covers max width of 520
           data_width = 4   // 4 bit color index
       )
       (
           input wire [data_width-1:0] din,
           input wire [addr_width-1:0] addr,
           input wire rclk,
           input wire re,
           input wire wclk,
           input wire we,
           output reg [data_width-1:0] dout
       );

`ifdef WITH_64K
(* ram_style = "distributed" *) reg [data_width-1:0] ram_single_port[2**addr_width-1:0];
`else
(* ram_style = "block" *) reg [data_width-1:0] ram_single_port[2**addr_width-1:0];
`endif

always @(posedge wclk)
begin
    if (we)
        ram_single_port[addr] <= din;
end

always @(posedge rclk)
begin
    if (re)
       dout <= ram_single_port[addr];
end

endmodule

    // This module manages a double buffer of raster lines. It stores the current
    // pixel_color3 value into one buffer using raster_x as the address.  It reads
    // pixels from the other buffer using h_count as the address.  h_count increments
    // at 2x the rate of raster_x but each line is 'drawn' twice.  So v_count also
    // increments at 2x the rate as raster_y.  We are always one raster line behind.
    // The buffers are swapped after drawing a single input raster line so that we
    // are always filling one buffer while reading from the other.
    module hires_dvi_sync(
        input wire clk_dot4x,
        input wire clk_dvi,
        input [3:0] dot_rising,
        input is_native_y_in,
        input is_native_x_in,
        input hpolarity,
        input vpolarity,
        input enable_csync,
`ifdef CONFIGURABLE_TIMING
        input timing_change_in,
        input [7:0] timing_h_blank,
        input [7:0] timing_h_fporch,
        input [7:0] timing_h_sync,
        input [7:0] timing_h_bporch,
        input [7:0] timing_v_blank,
        input [7:0] timing_v_fporch,
        input [7:0] timing_v_sync,
        input [7:0] timing_v_bporch,
`endif
        input wire rst,
        input wire rst_dvi,
        input [1:0] chip,
        input [9:0] raster_x, // native res counters
        input [8:0] raster_y, // native res counters
        input [9:0] xpos,
`ifdef HIRES_MODES
        input [10:0] hires_raster_x,
`endif
        input [3:0] pixel_color3,
        output reg hsync,             // horizontal sync
        output reg vsync,             // vertical sync
        output reg active,
        output reg [3:0] pixel_color4,
        output reg half_bright
    );

reg [10:0] max_width; // compared to hcount which can be 2x
reg [9:0] max_height; // compared to vcount which can be 2y
reg [10:0] x_offset;

reg [10:0] hs_sta; // compared against hcount which can be 2x
reg [10:0] hs_end; // compared against hcount which can be 2x
reg [10:0] ha_sta; // compared against hcount which can be 2x
reg [10:0] ha_end; // compared against hcount which can be 2x
reg [9:0] vs_sta; // compared against vcount which can be 2y
reg [9:0] vs_end; // compared against vcount which can be 2y
reg [9:0] va_sta; // compared against vcount which can be 2y
reg [9:0] va_end; // compared against vcount which can be 2y

reg [10:0] h_count;  // output x position
reg [9:0] v_count;  // output y position
reg [1:0] ff;

wire hsync_ah;
wire vsync_ah;
wire csync_ah;

wire hsync_int;
wire vsync_int;
wire csync_int;

// Active high
assign hsync_ah = h_count >= hs_sta & h_count < hs_end;
assign vsync_ah = ((v_count == vs_end & h_count < hs_end) | v_count < vs_end) &
                  ((v_count == vs_sta & h_count >= hs_sta) | v_count > vs_sta);
assign csync_ah = hsync_ah | vsync_ah;

// Turn to active low if poliarity flag says so
assign hsync_int = hpolarity ? hsync_ah : ~hsync_ah;
assign vsync_int = vpolarity ? vsync_ah : ~vsync_ah;
assign csync_int = hpolarity ? csync_ah : ~csync_ah;

// Assign hsync/vsync or combine to csync if needed
always @ (posedge clk_dvi)
begin
   hsync <= enable_csync ? csync_int : hsync_int;
   vsync <= enable_csync ? 1'b0 : vsync_int;
end

// Note this is inverted so inclusive/exclusive comparisons swap
// around for va_end and va_sta
wire nvactive;
wire pvactive;
assign nvactive =
               (v_count >= va_end) &
               ((v_count == va_sta & h_count < ha_sta) | v_count < va_sta);
assign pvactive =
               (v_count < va_sta) |
               ((v_count != va_end | h_count < ha_sta) & v_count >= va_end);

// active: high during active pixel drawing
always @ (posedge clk_dvi)
begin
   active <= ~(
              (h_count > ha_end | h_count <= ha_sta) |
              (chip[0] ? pvactive : nvactive)
              );
end

wire advance;
assign advance = 1'b1;

always @ (posedge clk_dvi)
begin
    if (rst_dvi)
    begin
        ff <= 2'b01;
    end else begin
        // Resolution | advance on counter | pixel clock       | case
        // -------------------------------------------------------------------------
        // 2xX & 2xY  | 0,1,2,3            | 4x DIV 1          | !native_y && !native_x
        // 2xX & 1xY  | 1,3                | 4x DIV 2          | native_y && !native_x
        // 1xX & 2xY  | 1,3                | 4x DIV 2          | !native_y && native_x
        // 1xX & 1xY  | 1                  | 4x DIV 4 (native) | native_y & native_x
        ff <= ff + 2'b1;
        if (advance) begin
            if (h_count < max_width) begin
                h_count <= h_count + 11'b1;
            end else begin
                h_count <= 0;

                if (v_count < max_height) begin
                    v_count <= v_count + 9'b1;
                    half_bright <= ~half_bright;
                end else begin
                    v_count <= 0;
                    half_bright <= 0;
                end
            end
        end
    end
end

// Double buffer flip flop.  When active_buf is HIGH, we are writing to
// line_buf_0 while reading from line_buf_1.  Reversed when active_buf is LOW.
reg active_buf;

// Cover the max possible here. Not all may be used depending on chip.
wire [3:0] dout0; // output color from line_buf_0
wire [3:0] dout1; // output color from line_buf_1

reg [9:0] raster_x_dvi_1;
reg [9:0] raster_x_dvi;
always @(posedge clk_dvi) raster_x_dvi_1 <= raster_x;
always @(posedge clk_dvi) raster_x_dvi <= raster_x_dvi_1;
reg [8:0] raster_y_dvi_1;
reg [8:0] raster_y_dvi;
always @(posedge clk_dvi) raster_y_dvi_1 <= raster_y;
always @(posedge clk_dvi) raster_y_dvi <= raster_y_dvi_1;

`ifdef PAL_15MHZ
`ifndef NTSC_16MHZ
ERROR "Must define both PAL AND NTSC to HALF DOT CLOCK"
`endif
`ifdef HIRES_MODES
ERROR "Can't define HIRES_MODES for HALF DOT CLOCK RES"
`endif
`define BUF_X_COUNTER {1'b0, raster_x}
`else
`define BUF_X_COUNTER hires_raster_x
`endif

// When the line buffer is being written to, we use raster_x (the VIC native
// resolution x) as the address.
// When the line buffer is being read from, we use h_count.
dvi_linebuf_RAM line_buf_0(pixel_color3, // din
                       `BUF_X_COUNTER,
                       clk_dot4x, // rclk
                       !active_buf, // re
                       clk_dot4x, // wclk
                       active_buf, // we
                       dout0); // dout

dvi_linebuf_RAM line_buf_1(pixel_color3,
                       `BUF_X_COUNTER,
                       clk_dot4x,
                       active_buf,
                       clk_dot4x,
                       !active_buf,
                       dout1);

// Whenever we reach the beginning of a raster line, swap buffers.

always @(posedge clk_dot4x)
begin
    if (!rst) begin
        if (dot_rising[1]) begin
            if (raster_x == 0)
                active_buf = ~active_buf;
        end
    end
end

always @(posedge clk_dot4x) begin
    pixel_color4 <= active_buf ? dout1 : dout0;
end

`ifndef CONFIGURABLE_TIMING
`ifdef SIMULATOR_BOARD
always @(posedge clk_dvi)
`else
always @(chip)
`endif
    begin
        case (chip)
            `CHIP6569R1, `CHIP6569R3: begin
`ifdef PAL_32MHZ
                // WIDTH 1008  HEIGHT 312(624)
                ha_end=11'd998; // start 998
                hs_sta=11'd0;  // fporch  10
                hs_end=11'd64;  // sync  64
                ha_sta=11'd132;  // bporch 68
`elsif PAL_15MHZ
                // WIDTH 504  HEIGHT 312(624)
                ha_end=11'd494; // start 494
                hs_sta=11'd0;  // fporch  10
                hs_end=11'd32;  // sync  32
                ha_sta=11'd66;  // bporch 34
`elsif PAL_27MHZ
                // WIDTH 882  HEIGHT 312(624)
                ha_end=11'd852; // start 852 (84)
                hs_sta=11'd0;  // fporch  30 (wrap 882)
                hs_end=11'd64;  // sync  64
                ha_sta=11'd132;  // bporch 68
`elsif PAL_29MHZ
                // WIDTH 945  HEIGHT 312(624)
                // 782x576 (non-standard)
                ha_end=11'd914; // start 914 (146)
                hs_sta=11'd0;  // fporch  31 (wrap 945)
                hs_end=11'd64;  // sync  64
                ha_sta=11'd132;  // bporch 68
`endif
                va_end=10'd592;  // start 592 (80)
                vs_sta=10'd7;  // fporch   39 (624 wrap)
                vs_end=10'd12;  // sync   5
                va_sta=10'd17;  // bporch   5
                // 576p = 592-17+1
                max_height = 10'd623;
                max_width = `PAL_MAX_WIDTH; 
                x_offset = `PAL_OFFSET;
            end
            `CHIP6567R8: begin
`ifdef NTSC_32MHZ
                // WIDTH 1040  HEIGHT 263(526)
                ha_end=11'd1030; // start 1030
                hs_sta=11'd0;  // fporch 10
                hs_end=11'd64;  // sync 64
                ha_sta=11'd88;  // bporch  24
`elsif NTSC_16MHZ
                // WIDTH 520  HEIGHT 263(526)
                ha_end=11'd510; // start 510
                hs_sta=11'd0;  // fporch 10
                hs_end=11'd32;  // sync 32
                ha_sta=11'd44;  // bporch  24
`elsif NTSC_26MHZ
                // 720x480
                // WIDTH 845  HEIGHT 263(526)
                ha_end=11'd826; // start 826 (58)
                hs_sta=11'd11;  // fporch 30 (wrap 845)
                hs_end=11'd75;  // sync 64
                ha_sta=11'd106;  // bporch  31
`endif
                va_end=10'd20;  // start  20
                vs_sta=10'd22;  // fporch   2
                vs_end=10'd44;  // sync   22
                va_sta=10'd66;  // bporch   22
                // 480p = 526-(66-20)
                max_height = 10'd525;
                max_width = `NTSCR8_MAX_WIDTH;
                x_offset = `NTSCR8_OFFSET;
            end
            `CHIP6567R56A: begin
`ifdef NTSC_32MHZ
                // WIDTH 1024  HEIGHT 262(524)
                ha_end=11'd1014;  // start 1014
                hs_sta=11'd0;  // fporch  10
                hs_end=11'd64;  // sync  64
                ha_sta=11'd88;  // bporch  24
`elsif NTSC_26MHZ
                // 724x480
                // WIDTH 832  HEIGHT 262(524)
                ha_end=11'd814;  // start 814 (46)
                hs_sta=11'd2;  // fporch  20 (wrap 832)
                hs_end=11'd66;  // sync  64
                ha_sta=11'd90;  // bporch  24
`endif
                // 480p = 524-(66-22)
                va_end=10'd22;  // start  22
                vs_sta=10'd24;  // fporch   2
                vs_end=10'd46;  // sync  22
                va_sta=10'd66;  // bporch  20
                max_height = 10'd523;
                max_width = `NTSCR56_MAX_WIDTH;
                x_offset = `NTSCR56_OFFSET;
            end
        endcase
    end
`else
// There are restrictions on the values that can be placed into the timing
// registers that the TIMED program will not enforce.  For example, any
// hs_sta value must end up being>=0. Otherwise, the range comparison
// for hsync will not make sense.
// Ranges must never straddle 0 for any chip.
`ifdef SIMULATOR_BOARD
always @(posedge clk_dvi)
`else
always @(chip, timing_change_in)
`endif
    begin
        case (chip)
            `CHIP6569R1, `CHIP6569R3: begin
                ha_end = {3'b000, timing_h_blank} + `PAL_CONFIGURABLE_OFFSET;
                hs_sta = ha_end + {3'b000, timing_h_fporch};
                if (hs_sta >= `PAL_WIDTH) hs_sta = hs_sta - `PAL_WIDTH;
                hs_end = hs_sta + {3'b000, timing_h_sync};
                if (hs_end >= `PAL_WIDTH) hs_end = hs_end - `PAL_WIDTH;
                ha_sta = hs_end + {3'b000, timing_h_bporch};
                if (ha_sta >= `PAL_WIDTH) ha_sta = ha_sta - `PAL_WIDTH;
                // WIDTH 882 or 945
                va_end = {2'b10, timing_v_blank}; // starts at 512
                vs_sta = va_end + {2'b00, timing_v_fporch};
                if (vs_sta >= 624) vs_sta = vs_sta - 624;
                vs_end = vs_sta + {2'b00, timing_v_sync};
                if (vs_end >= 624) vs_end = vs_end - 624;
                va_sta = vs_end + {2'b00, timing_v_bporch};
                if (vs_sta >= 624) vs_sta = vs_sta - 624;
                // HEIGHT 312(624)
                max_height = 10'd623;
                max_width = `PAL_MAX_WIDTH;
                x_offset = `PAL_OFFSET;
            end
            `CHIP6567R8: begin
                ha_end = {3'b000, timing_h_blank} + `NTSC_CONFIGURABLE_OFFSET;
                hs_sta = ha_end + {3'b000, timing_h_fporch};
                if (hs_sta >= `NTSCR8_WIDTH) hs_sta = hs_sta - `NTSCR8_WIDTH;
                hs_end = hs_sta + {3'b000, timing_h_sync};
                if (hs_end >= `NTSCR8_WIDTH) hs_end = hs_end - `NTSCR8_WIDTH;
                ha_sta = hs_end + {3'b000, timing_h_bporch};
                if (ha_sta >= `NTSCR8_WIDTH) ha_sta = ha_sta - `NTSCR8_WIDTH;
                // WIDTH 845
                va_end = {2'b00, timing_v_blank};
                vs_sta = va_end + {2'b00, timing_v_fporch};
                vs_end = vs_sta + {2'b00, timing_v_sync};
                va_sta = vs_end + {2'b00, timing_v_bporch};
                // HEIGHT 263(526)
                max_height = 10'd525;
                max_width = `NTSCR8_MAX_WIDTH;
                x_offset = `NTSCR8_OFFSET;
            end
            `CHIP6567R56A: begin
                ha_end = {3'b000, timing_h_blank} + `NTSC_CONFIGURABLE_OFFSET;
                hs_sta = ha_end + {3'b000, timing_h_fporch};
                if (hs_sta >= `NTSCR56_WIDTH) hs_sta = hs_sta - `NTSCR56_WIDTH;
                hs_end = hs_sta + {3'b000, timing_h_sync};
                if (hs_end >= `NTSCR56_WIDTH) hs_end = hs_end - `NTSCR56_WIDTH;
                ha_sta = hs_end + {3'b000, timing_h_bporch};
                if (ha_sta >= `NTSCR56_WIDTH) ha_sta = ha_sta - `NTSCR56_WIDTH;
                // WIDTH 832
                va_end = {2'b00, timing_v_blank};
                vs_sta = va_end + {2'b00, timing_v_fporch};
                vs_end = vs_sta + {2'b00, timing_v_sync};
                va_sta = vs_end + {2'b00, timing_v_bporch};
                // HEIGHT 262(524)
                max_height = 10'd523;
                max_width = `NTSCR56_MAX_WIDTH;
                x_offset = `NTSCR56_OFFSET;
            end
        endcase

    end
`endif

endmodule
