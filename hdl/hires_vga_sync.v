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
           input is_15khz,
           input wire rst,
           input [1:0] chip,
           input [9:0] raster_x,
           input [10:0] hires_raster_x,
           input [8:0] raster_y,
           input [3:0] pixel_color3,
           output wire hsync,             // horizontal sync
           output wire vsync,             // vertical sync
           output wire active,
           output reg [3:0] pixel_color4,
           output reg half_bright
       );

reg [10:0] max_width;
reg [9:0] max_height;
reg [10:0] hs_sta;
reg [10:0] hs_end;
reg [10:0] ha_sta;
reg [9:0] vs_sta;
reg [9:0] vs_end;
reg [9:0] va_end;
reg [10:0] hoffset;
reg [9:0] voffset;

reg [10:0] h_count;  // output x position
reg [9:0] v_count;  // output y position
reg [1:0] ff;

// generate sync signals active low
assign hsync = ~((h_count >= hs_sta) & (h_count < hs_end));
assign vsync = ~((v_count >= vs_sta) & (v_count < vs_end));

// active: high during active pixel drawing
assign active = ~((h_count < ha_sta) | (v_count > va_end - 1));

wire is_native_x;
assign is_native_x = 1'b0; // TODO : Make config

// These conditions determine whether we advance our h/v counts
// based whether we are doubling X/Y resolutions or not.  See
// the table below for more info.
wire advance;
assign advance = (!is_15khz && !is_native_x) ||
                 (is_15khz && !is_native_x && (ff == 2'b01 || ff == 2'b11)) ||
				     (!is_15khz && is_native_x && (ff == 2'b01 || ff == 2'b11)) ||
				     (is_15khz && is_native_x && ff == 2'b01);

always @ (posedge clk_dot4x)
begin
    if (rst)
    begin
        h_count <= 0;
		  ff <= 2'b01;
        case (chip)
            `CHIP6569R1, `CHIP6569R5: begin
                if (is_native_x) begin
                    ha_sta <= 100;  // +h front porch 30 = 504 - 404
                    hs_end <= 70;   // +h sync pulse 60 = 504 - 434
                    hs_sta <= 10;   //  h back porch 10 = 504 - 494
						  // WIDTH 504
                end else begin
                    ha_sta <= 200;  // +h front porch 60 = 1008 - 808
                    hs_end <= 140;  // +h sync pulse 120 = 1008 - 868
                    hs_sta <= 20;   //  h back porch 20 = 1008 - 988
						  // WIDTH 1008
                end
                if (is_15khz) begin
                   // v front porch 5
                   // v sync pulse 2
                   // v back porch 20
                   va_end <= 285;  // HEIGHT - v back porch - v sync pulse - v front porch
                   vs_sta <= 290;  // HEIGHT - v back porch - v sync pulse
                   vs_end <= 292;  // HEIGHT - v back porch
                   // HEIGHT = 312
                end else begin
                   // v front porch 11
                   // v sync pulse 3
                   // v back porch 41
                   va_end <= 569;  // HEIGHT - v back porch - v sync pulse - v front porch
                   vs_sta <= 580;  // HEIGHT - v back porch - v sync pulse
                   vs_end <= 583;  // HEIGHT - v back porch
                   // HEIGHT = 624
                end
                hoffset <= 11'd10;
                voffset = 10'd20;
                max_height <= is_15khz ? 10'd311 : 10'd623;
                max_width <= is_native_x ? 11'd503 : 11'd1007;
                v_count <= is_15khz ? (10'd311 - voffset) : (10'd623 - voffset);
            end
            `CHIP6567R8: begin
                if (is_native_x) begin
                    ha_sta <= 103;  // +h front porch 31 = 520 - 417
                    hs_end <= 72;   // +h sync pulse 62 = 520 - 448
                    hs_sta <= 10;   //  h back porch 10 = 520 - 510
                    // WIDTH 520
                end else begin
                    ha_sta <= 206;  // +h front porch 62 = 1040 - 834
                    hs_end <= 144;  // +h sync pulse 124 = 1040 - 896 
                    hs_sta <= 20;   //  h back porch 20 = 1040 - 1020
                    // WIDTH 1040
                end
                if (is_15khz) begin
                   // v front porch 5
                   // v sync pulse 2
                   // v back porch 5
                   va_end <= 251;  // HEIGHT - v back porch - v sync pulse - v front porch
                   vs_sta <= 256;  // HEIGHT - v back porch - v sync pulse
                   vs_end <= 258;  // HEIGHT - v back porch
                   // HEIGHT = 263
                end else begin
                   // v front porch 10
                   // v sync pulse 3
                   // v back porch 11
                   va_end <= 502;  // HEIGHT - v back porch - v sync pulse - v front porch
                   vs_sta <= 512;  // HEIGHT - v back porch - v sync pulse
                   vs_end <= 515;  // HEIGHT - v back porch
                   // HEIGHT = 526
                end
                hoffset <= 11'd20;
                voffset = 10'd52;
                max_height <= is_15khz ? 10'd262 : 10'd525;
                max_width <= is_native_x ? 11'd519 : 11'd1039;
                v_count <= is_15khz ? (10'd262 - voffset) : (10'd525 - voffset);
            end
            `CHIP6567R56A: begin
                if (is_native_x) begin
                    ha_sta <= 102;  // +h front porch 31 = 512 - 410
                    hs_end <= 71;   // +h sync pulse 61 = 512 - 441
                    hs_sta <= 10;   //  h back porch 10 = 512 - 502
                    // WIDTH 512
                end else begin
                    ha_sta <= 204;  // +h front porch 62 = 1024 - 820
                    hs_end <= 142;  // +h sync pulse 122 = 1024 - 882
                    hs_sta <= 20;   //  h back porch 20 = 1024 - 1004
                    // WIDTH 1024
                end
                if (is_15khz) begin
                   // v front porch 5
                   // v sync pulse 2
                   // v back porch 4
                   va_end <= 251; // HEIGHT - v back porch - v sync pulse - v front porch
                   vs_sta <= 256; // HEIGHT - v back porch - v sync pulse
                   vs_end <= 258; // HEIGHT - v back porch
                   // HEIGHT = 262
                end else begin
                   // v front porch 10
                   // v sync pulse 3
                   // v back porch 9
                   va_end <= 502; // HEIGHT - v back porch - v sync pulse - v front porch
                   vs_sta <= 512; // HEIGHT - v back porch - v sync pulse
                   vs_end <= 515; // HEIGHT - v back porch
                   // HEIGHT = 524
                end
                hoffset <= 11'd20;
                voffset = 10'd52;
                max_height <= is_15khz ? 10'd261 : 10'd523;
                max_width <= is_native_x ? 11'd511 : 11'd1023;
                v_count <= is_15khz ? (10'd261 - voffset) : (10'd523 - voffset);
            end
        endcase
    end else begin
	     // Resolution | advance on counter | pixel clock       | case
        // -------------------------------------------------------------------------
        // 2xX & 2xY  | 0,1,2,3            | 4x DIV 1          | !15khz && !native_x
		  // 2xX & 1xY  | 1,3                | 4x DIV 2          | 15khz && !native_x
		  // 1xX & 2xY  | 1,3                | 4x DIV 2          | !15khz && native_x
		  // 1xX & 1xY  | 1                  | 4x DIV 4 (native) | 15khz & native_x
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
            v_count <= max_height - voffset;
        end
    end
end

// Double buffer flip flop.  When active_buf is HIGH, we are writing to
// line_buf_0 while reading from line_buf_1.  Reversed when active_buf is LOW.
reg active_buf;

// Cover the max possible here. Not all may be used depending on chip.
wire [3:0] dout0; // output color from line_buf_0
wire [3:0] dout1; // output color from line_buf_1

wire [10:0] output_x;

assign output_x = h_count - hoffset;

// When the line buffer is being written to, we use raster_x (the VIC native
// resolution x) as the address.
// When the line buffer is being read from, we used h_count (this scan
// doubler's x adjusted by hoffset) as the address.
linebuf_RAM line_buf_0(clk_dot4x, active_buf, active_buf ? is_native_x ? {1'b0, raster_x} : hires_raster_x : output_x, pixel_color3, dout0);
linebuf_RAM line_buf_1(clk_dot4x, !active_buf, !active_buf ? is_native_x ? {1'b0, raster_x} : hires_raster_x : output_x, pixel_color3, dout1);

reg [3:0] dot_rising;
always @(posedge clk_dot4x)
    if (rst)
        dot_rising <= 4'b1000;
    else
        dot_rising <= {dot_rising[2:0], dot_rising[3]};

// Whenever we reach the beginning of a raster line, swap buffers.
always @(posedge clk_dot4x)
begin
    if (!rst) begin
        if (dot_rising[1]) begin
            if (raster_x == 0)
                active_buf = ~active_buf;
        end

        if (h_count >= hoffset)
            pixel_color4 = active_buf ? dout1 : dout0;

    end
end

endmodule : hires_vga_sync
