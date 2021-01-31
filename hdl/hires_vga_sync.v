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
reg ff = 1'b1;

// generate sync signals active low
assign hsync = ~((h_count >= hs_sta) & (h_count < hs_end));
assign vsync = ~((v_count >= vs_sta) & (v_count < vs_end));

// active: high during active pixel drawing
assign active = ~((h_count < ha_sta) | (v_count > va_end - 1));

// TODO: Try "8 64 32" for alternative horiz sync params
always @ (posedge clk_dot4x)
begin
    if (rst)
    begin
        h_count <= 0;
        case (chip)
            `CHIP6569, `CHIPUNUSED: begin
                hs_sta <= 20;   //  h front porch 20
                hs_end <= 140;  // +h sync pulse  20 + 120
                ha_sta <= 200;  // +h back porch  20 + 120 + 60
		if (is_15khz) begin
                   // v front porch 5
                   // v sync pulse 2
                   // v back porch 20
                   // HEIGHT = 312
                   vs_sta <= 290;  // HEIGHT - v back porch - v sync pulse
                   vs_end <= 292;  // HEIGHT - v back porch
                   va_end <= 285;  // HEIGHT - v back porch - v sync pulse - v front porch
                end else begin
                   // v front porch 11
                   // v sync pulse 3
                   // v back porch 41
                   // HEIGHT = 624
                   vs_sta <= 580;  // HEIGHT - v back porch - v sync pulse
                   vs_end <= 583;  // HEIGHT - v back porch
                   va_end <= 569;  // HEIGHT - v back porch - v sync pulse - v front porch
                end
                hoffset <= 10;
                voffset = 20;
                max_width = 1007; //504x2-1
                max_height = is_15khz ? 311 : 623;
                v_count <= is_15khz ? (311 - voffset) : (623 - voffset);
            end
            `CHIP6567R8: begin
                hs_sta <= 20;   //  h front porch 20
                hs_end <= 144;  // +h sync pulse  20 + 124
                ha_sta <= 206;  // +h back porch  20 + 124 + 62
		if (is_15khz) begin
                   // v front porch 5
                   // v sync pulse 2
                   // v back porch 5
                   // HEIGHT = 263
                   vs_sta <= 256;  // HEIGHT - v back porch - v sync pulse
                   vs_end <= 258;  // HEIGHT - v back porch
                   va_end <= 251;  // HEIGHT - v back porch - v sync pulse - v front porch
                end else begin
                   // v front porch 10
                   // v sync pulse 3
                   // v back porch 11
                   // HEIGHT = 526
                   vs_sta <= 512;  // HEIGHT - v back porch - v sync pulse
                   vs_end <= 515;  // HEIGHT - v back porch
                   va_end <= 502;  // HEIGHT - v back porch - v sync pulse - v front porch
		end
                hoffset <= 20;
                voffset = 52;
                max_width = 1039; //520x2-1
                max_height = is_15khz ? 262 : 525;
                v_count <= is_15khz ? (262 - voffset) : (525 - voffset);
            end
            `CHIP6567R56A: begin
                hs_sta <= 20;   //  h front porch 20
                hs_end <= 142;  // +h sync pulse  20 + 122
                ha_sta <= 204;  // +h back porch  20 + 122 +62
		if (is_15khz) begin
                   // v front porch 5
                   // v sync pulse 2
                   // v back porch 4
                   // HEIGHT = 262
                   vs_sta <= 256; // HEIGHT - v back porch - v sync pulse
                   vs_end <= 258; // HEIGHT - v back porch
                   va_end <= 251; // HEIGHT - v back porch - v sync pulse - v front porch
                end else begin
                   // v front porch 10
                   // v sync pulse 3
                   // v back porch 9
                   // HEIGHT = 524
                   vs_sta <= 512; // HEIGHT - v back porch - v sync pulse
                   vs_end <= 515; // HEIGHT - v back porch
                   va_end <= 502; // HEIGHT - v back porch - v sync pulse - v front porch
		end
                hoffset <= 20;
                voffset = 52;
                max_width = 1023; //512x2-1
                max_height = is_15khz ? 261 : 523;
                v_count <= is_15khz ? (261 - voffset) : (523 - voffset);
            end
        endcase
    end else begin
        // This is nearly identical to the lores version of vga_sync
        // except the x dimension is also doubled so we need a 4x dot
        // clock instead of 2x.
	ff = ~ff;
	if ((is_15khz && ff) | !is_15khz) begin
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
linebuf_RAM line_buf_0(clk_dot4x, active_buf, active_buf ? hires_raster_x : output_x, pixel_color3, dout0);
linebuf_RAM line_buf_1(clk_dot4x, !active_buf, !active_buf ? hires_raster_x : output_x, pixel_color3, dout1);

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
