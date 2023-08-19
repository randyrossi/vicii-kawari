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

// A block ram module to hold a single raster line of pixel colors
module linebuf_RAM
       #(
           parameter addr_width = 11, // covers max width of 520
           data_width = 4   // 4 bit color index
       )
       (
           input wire clk,
           input wire we,
           input wire [addr_width-1:0] addr,
           input wire [data_width-1:0] din,
           output reg [data_width-1:0] dout
       );

`ifdef WITH_64K
(* ram_style = "distributed" *) reg [data_width-1:0] ram_single_port[2**addr_width-1:0];
`else
(* ram_style = "block" *) reg [data_width-1:0] ram_single_port[2**addr_width-1:0];
`endif

always @(posedge clk)
begin
    if (we)
        ram_single_port[addr] <= din;
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
    module hires_vga_sync(
        input wire clk_dot4x,
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

reg [10:0] hs_sta; // compared against hcount which can be 2x
reg [10:0] hs_end; // compared against hcount which can be 2x
reg [10:0] ha_sta; // compared against hcount which can be 2x
reg [10:0] ha_end; // compared against hcount which can be 2x
reg [9:0] vs_sta; // compared against vcount which can be 2y
reg [9:0] vs_end; // compared against vcount which can be 2y
reg [9:0] va_sta; // compared against vcount which can be 2y
reg [9:0] va_end; // compared against vcount which can be 2y

`ifdef CONFIGURABLE_TIMING
reg timing_change;
`endif
reg is_native_x;
reg is_native_y;
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
always @ (posedge clk_dot4x)
begin
   hsync <= enable_csync ? csync_int : hsync_int;
   vsync <= enable_csync ? 1'b0 : vsync_int;
end

// active: high during active pixel drawing
always @ (posedge clk_dot4x)
begin
   active <= ~(
              (h_count >= ha_end | h_count <= ha_sta) |
              (v_count >= va_end && v_count <= va_sta)
              );
end

// These conditions determine whether we advance our h/v counts
// based whether we are doubling X/Y resolutions or not.  See
// the table below for more info.
wire advance;
assign advance = (!is_native_y && !is_native_x) ||
       ((is_native_y ^ is_native_x) && (ff == 2'b01 || ff == 2'b11)) ||
       (is_native_y && is_native_x && ff == 2'b01);

always @ (posedge clk_dot4x)
begin
    if (rst)
    begin
        //h_count <= 0;
        //v_count <= 0;
        ff <= 2'b01;
`ifdef CONFIGURABLE_TIMING
        set_params_configurable();
`else
        set_params();
`endif
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
        if (raster_x == 0 && raster_y == 0) begin
            //v_count <= max_height;

            if (is_native_x_in != is_native_x || is_native_y_in != is_native_y
`ifdef CONFIGURABLE_TIMING
                    || timing_change_in != timing_change
`endif
               )
            begin
                is_native_x = is_native_x_in;
                is_native_y = is_native_y_in;
`ifdef CONFIGURABLE_TIMING
                timing_change <= timing_change_in;
                set_params_configurable();
`else
                set_params();
`endif
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

// When the line buffer is being written to, we use raster_x (the VIC native
// resolution x) as the address.
// When the line buffer is being read from, we use h_count.
`ifdef HIRES_MODES
linebuf_RAM line_buf_0(clk_dot4x, active_buf, active_buf ? (is_native_x ? {1'b0, raster_x} : hires_raster_x) : h_count, pixel_color3, dout0);
linebuf_RAM line_buf_1(clk_dot4x, !active_buf, !active_buf ? (is_native_x ? {1'b0, raster_x} : hires_raster_x) : h_count, pixel_color3, dout1);
`else
linebuf_RAM line_buf_0(clk_dot4x, active_buf, active_buf ? {1'b0, raster_x} : h_count, pixel_color3, dout0);
linebuf_RAM line_buf_1(clk_dot4x, !active_buf, !active_buf ? {1'b0, raster_x} : h_count, pixel_color3, dout1);
`endif

// Whenever we reach the beginning of a raster line, swap buffers.
always @(posedge clk_dot4x)
begin
    if (!rst) begin
        if (dot_rising[1]) begin
            if (raster_x == 0)
                active_buf = ~active_buf;
        end

        pixel_color4 = active_buf ? dout1 : dout0;

    end
end

`ifndef CONFIGURABLE_TIMING
task set_params();
    begin
        case (chip)
            `CHIP6569R1, `CHIP6569R3: begin
                // WIDTH 504  HEIGHT 312
                ha_end=11'd494;  // start   494
                hs_sta=11'd10;  // fporch  20
                hs_end=11'd48;  // sync  38
                ha_sta=11'd90;  // bporch  26
                va_end=10'd300;  // start 300
                vs_sta=10'd301;  // fporch   1
                vs_end=10'd309;  // sync   8
                va_sta=10'd310;  // bporch  1
                max_height <= is_native_y ? 10'd311 : 10'd623;
                max_width <= is_native_x ? 11'd503 : 11'd1007;
            end
            `CHIP6567R8: begin
                // WIDTH 520  HEIGHT 263
                ha_end=11'd510;  // start   510
                hs_sta=11'd10;  // fporch  20
                hs_end=11'd49;  // sync  39
                ha_sta=11'd90;  // bporch  41
                va_end=10'd13;  // start  13
                vs_sta=10'd14;  // fporch   1
                vs_end=10'd22;  // sync   8
                va_sta=10'd23;  // bporch   1
                max_height <= is_native_y ? 10'd262 : 10'd525;
                max_width <= is_native_x ? 11'd519 : 11'd1039;
            end
            `CHIP6567R56A: begin
                // WIDTH 512  HEIGHT 262
                ha_end=11'd502;  // start   502
                hs_sta=11'd10;  // fporch  20
                hs_end=11'd48;  // sync  38
                ha_sta=11'd90;  // bporch  42
                va_end=10'd13;  // start  13
                vs_sta=10'd14;  // fporch   1
                vs_end=10'd22;  // sync   8
                va_sta=10'd23;  // bporch   1
                max_height <= is_native_y ? 10'd261 : 10'd523;
                max_width <= is_native_x ? 11'd511 : 11'd1023;
            end
        endcase
        // Adjust for 2x or 2y timing
        if (!is_native_x) begin
            ha_end = { ha_end[9:0], 1'b0 };
            hs_sta = { hs_sta[9:0], 1'b0 };
            hs_end = { hs_end[9:0], 1'b0 };
            ha_sta = { ha_sta[9:0], 1'b0 };
        end
        if (!is_native_y) begin
            va_end = { va_end[8:0], 1'b0 };
            vs_sta = { vs_sta[8:0], 1'b0 };
            vs_end = { vs_end[8:0], 1'b0 };
            va_sta = { va_sta[8:0], 1'b0 };
        end
    end
endtask
`else
task set_params_configurable();
    begin
        case (chip)
            `CHIP6569R1, `CHIP6569R3: begin
                ha_end = {3'b000, timing_h_blank} + 11'd384;
                hs_sta = ha_end + {3'b000, timing_h_fporch};
                if (hs_sta >= 11'd504) hs_sta = hs_sta - 11'd504;
                hs_end = hs_sta + {3'b000, timing_h_sync};
                if (hs_end >= 11'd504) hs_end = hs_end - 11'd504;
                ha_sta = hs_end + {3'b000, timing_h_bporch};
                if (ha_sta >= 11'd504) ha_sta = ha_sta - 11'd504;
                // WIDTH 504
                va_end = {2'b01, timing_v_blank}; // starts at 256
                vs_sta = va_end + {2'b00, timing_v_fporch};
                vs_end = vs_sta + {2'b00, timing_v_sync};
                va_sta = vs_end + {2'b00, timing_v_bporch};
                // HEIGHT 312
                max_height <= is_native_y ? 10'd311 : 10'd623;
                max_width <= is_native_x ? 11'd503 : 11'd1007;
                // Use this to generate code for static settings above
            end
            `CHIP6567R8: begin
                ha_end = {3'b000, timing_h_blank} + 11'd384;
                hs_sta = ha_end + {3'b000, timing_h_fporch};
                if (hs_sta >= 11'd520) hs_sta = hs_sta - 11'd520;
                hs_end = hs_sta + {3'b000, timing_h_sync};
                if (hs_end >= 11'd520) hs_end = hs_end - 11'd520;
                ha_sta = hs_end + {3'b000, timing_h_bporch};
                if (ha_sta >= 11'd520) ha_sta = ha_sta - 11'd520;
                // WIDTH 520
                va_end = {2'b00, timing_v_blank};
                vs_sta = va_end + {2'b00, timing_v_fporch};
                vs_end = vs_sta + {2'b00, timing_v_sync};
                va_sta = vs_end + {2'b00, timing_v_bporch};
                // HEIGHT 263
                max_height <= is_native_y ? 10'd262 : 10'd525;
                max_width <= is_native_x ? 11'd519 : 11'd1039;
            end
            `CHIP6567R56A: begin
                ha_end = {3'b000, timing_h_blank} + 11'd384;
                hs_sta = ha_end + {3'b000, timing_h_fporch};
                if (hs_sta >= 11'd512) hs_sta = hs_sta - 11'd512;
                hs_end = hs_sta + {3'b000, timing_h_sync};
                if (hs_end >= 11'd512) hs_end = hs_end - 11'd512;
                ha_sta = hs_end + {3'b000, timing_h_bporch};
                if (ha_sta >= 11'd512) ha_sta = ha_sta - 11'd512;
                // WIDTH 512
                va_end = {2'b00, timing_v_blank};
                vs_sta = va_end + {2'b00, timing_v_fporch};
                vs_end = vs_sta + {2'b00, timing_v_sync};
                va_sta = vs_end + {2'b00, timing_v_bporch};
                // HEIGHT 262
                max_height <= is_native_y ? 10'd261 : 10'd523;
                max_width <= is_native_x ? 11'd511 : 11'd1023;
            end
        endcase
        // Adjust for 2x or 2y timing
        if (!is_native_x) begin
            ha_end = { ha_end[9:0], 1'b0 };
            hs_sta = { hs_sta[9:0], 1'b0 };
            hs_end = { hs_end[9:0], 1'b0 };
            ha_sta = { ha_sta[9:0], 1'b0 };
        end
        if (!is_native_y) begin
            va_end = { va_end[8:0], 1'b0 };
            vs_sta = { vs_sta[8:0], 1'b0 };
            vs_end = { vs_end[8:0], 1'b0 };
            va_sta = { va_sta[8:0], 1'b0 };
        end
    end
endtask
`endif

endmodule
