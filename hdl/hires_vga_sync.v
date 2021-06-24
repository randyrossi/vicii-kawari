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

(* ram_style = "block" *) reg [data_width-1:0] ram_single_port[2**addr_width-1:0];

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
        input [7:0] timing_h_blank_ntsc,
        input [7:0] timing_h_fporch_ntsc,
        input [7:0] timing_h_sync_ntsc,
        input [7:0] timing_h_bporch_ntsc,
        input [7:0] timing_v_blank_ntsc,
        input [7:0] timing_v_fporch_ntsc,
        input [7:0] timing_v_sync_ntsc,
        input [7:0] timing_v_bporch_ntsc,
        input [7:0] timing_h_blank_pal,
        input [7:0] timing_h_fporch_pal,
        input [7:0] timing_h_sync_pal,
        input [7:0] timing_h_bporch_pal,
        input [7:0] timing_v_blank_pal,
        input [7:0] timing_v_fporch_pal,
        input [7:0] timing_v_sync_pal,
        input [7:0] timing_v_bporch_pal,
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
        output wire hsync,             // horizontal sync
        output wire vsync,             // vertical sync
        output wire active,
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

reg timing_change;
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
// The range checks on vsync must take into account the horizontal start and
// end, otherwise we cut short the last line's scan too early and start it
// too soon if hs_sta is > 0.
assign hsync_ah = ((h_count >= hs_sta) & (h_count <= hs_end));
assign vsync_ah = (
           ((v_count == vs_sta & h_count >= hs_sta) | v_count > vs_sta) &
           (v_count < vs_end | (v_count == vs_end & h_count < hs_end))
       );
assign csync_ah = hsync_ah | vsync_ah;

// Turn to active low if poliarity flag says so
assign hsync_int = hpolarity ? hsync_ah : ~hsync_ah;
assign vsync_int = vpolarity ? vsync_ah : ~vsync_ah;
assign csync_int = hpolarity ? csync_ah : ~csync_ah;

// Assign hsync/vsync or combine to csync if needed
assign hsync = enable_csync ? csync_int : hsync_int;
assign vsync = enable_csync ? 1'b0 : vsync_int;

// active: high during active pixel drawing
// Find the union within the range vae<->vas and hae<->has and negate it.
//
//            ae as
//             |  |
// xxxxxxxxxxxxx  xxx
// xxxxxxxxxxxxx  xxx
// xxxxxxxxxxxxx  xxx
// xxxxxxxxxxxxx  xxx
// xxxxxxxxxxxxx  xxx
// xxxxxxxxxxxxx  xxx
// xxxxxxxxxxxxx  xxx-ae
//
// xxxxxxxxxxxxx  xxx-as
// xxxxxxxxxxxxx  xxx
// Same logic as above for h/v sync except for active ranges.  Also need
// to treat first and last active lines special so we don't start active
// too soon or end it too early when ha_end > 0
// For PAL, we have to invert the range because the blanking region crosses
// 0. (See va_sta and va_end for PAL)
wire vactive;
assign vactive =
               ((v_count == va_end & h_count >= ha_end) | v_count > va_end) &
               ((v_count == va_sta & h_count < ha_sta) | v_count < va_sta);

// NOTE: For PAL, we invert the vactive because the blanking region crosses
// 0. So consider va_sta and va_end as opposites of their names.
assign active = ~(
           (h_count >= ha_end & h_count <= ha_sta) |
           (chip[0] ? ~vactive : vactive)
       );

// These conditions determine whether we advance our h/v counts
// based whether we are doubling X/Y resolutions or not.  See
// the table below for more info.
wire advance;
assign advance = (!is_native_y && !is_native_x) ||
       (is_native_y && !is_native_x && (ff == 2'b01 || ff == 2'b11)) ||
       (!is_native_y && is_native_x && (ff == 2'b01 || ff == 2'b11)) ||
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
                h_count <= h_count + 10'b1;
            end else begin
                h_count <= 0;
                if (v_count < max_height) begin
                    v_count <= v_count + 9'b1;
                    half_bright <= ~half_bright;
                end else begin
                    v_count <= 0;
                    // First line is always full brightness
                    half_bright <= 0;
                end
            end
        end
        if (raster_x == 0 && raster_y == 0) begin
            v_count <= max_height;

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
            `CHIP6569R1, `CHIP6569R5: begin
                // WIDTH 504  HEIGHT 312
                // NOTE: For PAL, we invert the range va_sta and va_end
		// because the blanking region crosses 0.  So va_sta is
		// really active end and va_end is really active start.
                ha_end=11'd0;  // start   0
                hs_sta=11'd10;  // fporch  10
                hs_end=11'd70;  // sync  60
                ha_sta=11'd90;  // bporch  20
                va_end=10'd20;  // INVERTED above so actually va_sta
                va_sta=10'd284;  // INVERTED above so actually va_end
                vs_sta=10'd289;  // fporch   5
                vs_end=10'd291;  // sync   2
		                 // bporch 40 takes us to 311 + 20
                max_height <= is_native_y ? 10'd311 : 10'd623;
                max_width <= is_native_x ? 11'd503 : 11'd1007;
            end
            `CHIP6567R8: begin
                // WIDTH 520  HEIGHT 263
                ha_end=11'd0;  // start   0
                hs_sta=11'd10;  // fporch  10
                hs_end=11'd70;  // sync  60
                ha_sta=11'd80;  // bporch  10
                va_end=10'd11;  // start  11
                vs_sta=10'd19;  // fporch   8
                vs_end=10'd22;  // sync   3
                va_sta=10'd24;  // bporch   2
                max_height <= is_native_y ? 10'd262 : 10'd525;
                max_width <= is_native_x ? 11'd519 : 11'd1039;
            end
            `CHIP6567R56A: begin
                // WIDTH 512  HEIGHT 262
                ha_end=11'd0;  // start   0
                hs_sta=11'd10;  // fporch  10
                hs_end=11'd70;  // sync  60
                ha_sta=11'd80;  // bporch  10
                va_end=10'd11;  // start  11
                vs_sta=10'd19;  // fporch   8
                vs_end=10'd22;  // sync   3
                va_sta=10'd24;  // bporch   2
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
            `CHIP6569R1, `CHIP6569R5: begin
                ha_end = {3'b000, timing_h_blank_pal};
                hs_sta = ha_end + {3'b000, timing_h_fporch_pal};
                hs_end = hs_sta + {3'b000, timing_h_sync_pal};
                ha_sta = hs_end + {3'b000, timing_h_bporch_pal};
                // WIDTH 504
                // NOTE: For PAL, we invert the range va_sta and va_end
		// because the blanking region crosses 0.  So va_sta is
		// really active end and va_end is really active start.
                va_sta = {2'b01, timing_v_blank_pal}; // starts at 256
                vs_sta = va_sta + {2'b00, timing_v_fporch_pal};
                vs_end = vs_sta + {2'b00, timing_v_sync_pal};
                va_end = vs_end + {2'b00, timing_v_bporch_pal} - 10'd311;
                // HEIGHT 312
                max_height <= is_native_y ? 10'd311 : 10'd623;
                max_width <= is_native_x ? 11'd503 : 11'd1007;
                // Use this to generate code for static settings above
                /*
                $display("ha_end=11'd%d;  // start %d", ha_end, timing_h_blank_pal);
                $display("hs_sta=11'd%d;  // fporch %d", hs_sta, timing_h_fporch_pal);
                $display("hs_end=11'd%d;  // sync %d", hs_end, timing_h_sync_pal);
                $display("ha_sta=11'd%d;  // bporch %d", ha_sta, timing_h_bporch_pal);
                $display("va_end=10'd%d;  // start %d", va_end, timing_v_blank_pal);
                $display("vs_sta=10'd%d;  // fporch %d", vs_sta, timing_v_fporch_pal);
                $display("vs_end=10'd%d;  // sync %d", vs_end, timing_v_sync_pal);
                $display("va_sta=10'd%d;  // bporch %d ", va_sta, timing_v_bporch_pal);
                */
            end
            `CHIP6567R8: begin
                ha_end = {3'b000, timing_h_blank_ntsc};
                hs_sta = ha_end + {3'b000, timing_h_fporch_ntsc};
                hs_end = hs_sta + {3'b000, timing_h_sync_ntsc};
                ha_sta = hs_end + {3'b000, timing_h_bporch_ntsc};
                va_end = {2'b00, timing_v_blank_ntsc};
                vs_sta = va_end + {2'b00, timing_v_fporch_ntsc};
                vs_end = vs_sta + {2'b00, timing_v_sync_ntsc};
                va_sta = vs_end + {2'b00, timing_v_bporch_ntsc};
                // HEIGHT 263
                max_height <= is_native_y ? 10'd262 : 10'd525;
                max_width <= is_native_x ? 11'd519 : 11'd1039;
                // Use this to generate code for static settings above
                /*
                $display("ha_end=11'd%d;  // start %d", ha_end, timing_h_blank_ntsc);
                $display("hs_sta=11'd%d;  // fporch %d", hs_sta, timing_h_fporch_ntsc);
                $display("hs_end=11'd%d;  // sync %d", hs_end, timing_h_sync_ntsc);
                $display("ha_sta=11'd%d;  // bporch %d", ha_sta, timing_h_bporch_ntsc);
                $display("va_end=10'd%d;  // start %d", va_end, timing_v_blank_ntsc);
                $display("vs_sta=10'd%d;  // fporch %d", vs_sta, timing_v_fporch_ntsc);
                $display("vs_end=10'd%d;  // sync %d", vs_end, timing_v_sync_ntsc);
                $display("va_sta=10'd%d;  // bporch %d ", va_sta, timing_v_bporch_ntsc);
                */
            end
            `CHIP6567R56A: begin
                ha_end = {3'b000, timing_h_blank_ntsc};
                hs_sta = ha_end + {3'b000, timing_h_fporch_ntsc};
                hs_end = hs_sta + {3'b000, timing_h_sync_ntsc};
                ha_sta = hs_end + {3'b000, timing_h_bporch_ntsc};
                // WIDTH 512
                va_end = {2'b00, timing_v_blank_ntsc};
                vs_sta = va_end + {2'b00, timing_v_fporch_ntsc};
                vs_end = vs_sta + {2'b00, timing_v_sync_ntsc};
                va_sta = vs_end + {2'b00, timing_v_bporch_ntsc};
                // HEIGHT 262
                max_height <= is_native_y ? 10'd261 : 10'd523;
                max_width <= is_native_x ? 11'd511 : 11'd1023;
                // Use this to generate code for static settings above
                /*
                $display("ha_end=11'd%d;  // start %d", ha_end, timing_h_blank_ntsc);
                $display("hs_sta=11'd%d;  // fporch %d", hs_sta, timing_h_fporch_ntsc);
                $display("hs_end=11'd%d;  // sync %d", hs_end, timing_h_sync_ntsc);
                $display("ha_sta=11'd%d;  // bporch %d", ha_sta, timing_h_bporch_ntsc);
                $display("va_end=10'd%d;  // start %d", va_end, timing_v_blank_ntsc);
                $display("vs_sta=10'd%d;  // fporch %d", vs_sta, timing_v_fporch_ntsc);
                $display("vs_end=10'd%d;  // sync %d", vs_end, timing_v_sync_ntsc);
                $display("va_sta=10'd%d;  // bporch %d ", va_sta, timing_v_bporch_ntsc);
                */
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

endmodule : hires_vga_sync
