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
           input is_native_y_in,
			  input is_native_x_in,
`ifdef CONFIGURABLE_TIMING
            input timing_change_in,
            input [7:0] timing_1x_fporch_ntsc,
            input [7:0] timing_1x_bporch_ntsc,
            input [7:0] timing_1x_sync_ntsc,
            input [7:0] timing_1y_fporch_ntsc,
            input [7:0] timing_1y_bporch_ntsc,
            input [7:0] timing_1y_sync_ntsc,
            input [7:0] timing_2x_fporch_ntsc,
            input [7:0] timing_2x_bporch_ntsc,
            input [7:0] timing_2x_sync_ntsc,
            input [7:0] timing_2y_fporch_ntsc,
            input [7:0] timing_2y_bporch_ntsc,
            input [7:0] timing_2y_sync_ntsc,
            input [7:0] timing_1x_fporch_pal,
            input [7:0] timing_1x_bporch_pal,
            input [7:0] timing_1x_sync_pal,
            input [7:0] timing_1y_fporch_pal,
            input [7:0] timing_1y_bporch_pal,
            input [7:0] timing_1y_sync_pal,
            input [7:0] timing_2x_fporch_pal,
            input [7:0] timing_2x_bporch_pal,
            input [7:0] timing_2x_sync_pal,
            input [7:0] timing_2y_fporch_pal,
            input [7:0] timing_2y_bporch_pal,
            input [7:0] timing_2y_sync_pal,
`endif
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
reg [9:0] va_end; // used for pal only
reg [9:0] va_sta; // used for ntsc only


reg timing_change;
reg is_native_x;
reg is_native_y;
reg [10:0] h_count;  // output x position
reg [9:0] v_count;  // output y position
reg [1:0] ff;

// generate sync signals active low
assign hsync = ~((h_count >= hs_sta) & (h_count < hs_end));
assign vsync = ~((v_count >= vs_sta) & (v_count < vs_end));

// active: high during active pixel drawing
assign active = chip[0] ? ~((h_count < ha_sta) | (v_count > va_end)) : ~((h_count < ha_sta) | (v_count < va_sta));

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
        h_count <= 0;
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

wire [10:0] output_x;

assign output_x = h_count;

// When the line buffer is being written to, we use raster_x (the VIC native
// resolution x) as the address.
// When the line buffer is being read from, we used h_count.
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

        pixel_color4 = active_buf ? dout1 : dout0;

    end
end

task set_params();
    begin
        case (chip)
            `CHIP6569R1, `CHIP6569R5: begin
                if (is_native_x) begin
                    hs_sta <= 10;   // front portch 10
                    hs_end <= 70;   // sync pulse 60
                    ha_sta <= 100;  // back porch 30
						  // WIDTH 504
                end else begin
                    hs_sta <= 20;  // front porch 20
                    hs_end <= 140;  // sync pulse 120
                    ha_sta <= 200; //  back porch 60
						  // WIDTH 1008
                end
                if (is_native_y) begin
                   // v front porch 5
                   // v sync pulse 2
                   // v back porch 10
                   va_end <= 295;  // HEIGHT - v back porch - v sync pulse - v front porch
                   vs_sta <= 300;  // HEIGHT - v back porch - v sync pulse
                   vs_end <= 302;  // HEIGHT - v back porch
                   // HEIGHT = 312
                end else begin
                   // v front porch 10
                   // v sync pulse 3
                   // v back porch 20
                   va_end <= 591;  // HEIGHT - v back porch - v sync pulse - v front porch
                   vs_sta <= 601;  // HEIGHT - v back porch - v sync pulse
                   vs_end <= 604;  // HEIGHT - v back porch
                   // HEIGHT = 624
                end
                max_height <= is_native_y ? 10'd311 : 10'd623;
                max_width <= is_native_x ? 11'd503 : 11'd1007;
            end
            `CHIP6567R8: begin
                if (is_native_x) begin
                    hs_sta <= 10;  // front porch 10
                    hs_end <= 70;  // h sync pulse 60
                    ha_sta <= 80;  // h back porch 10
                    // WIDTH 520
                end else begin
                    hs_sta <= 20;  // front porch 20
                    hs_end <= 140; // sync pulse 120
                    ha_sta <= 160; // back porch 20
                    // WIDTH 1040
                end
                if (is_native_y) begin
                   // v front porch 35
                   // v sync pulse 2
                   // v back porch 2
                   vs_sta <= 35;
                   vs_end <= 37;
                   va_sta <= 39;
                   // HEIGHT = 263
                end else begin
                   // v front porch 70
                   // v sync pulse 2
                   // v back porch 4
                   vs_sta <= 70;
                   vs_end <= 72;
                   va_sta <= 76;
                   // HEIGHT = 526
                end
                max_height <= is_native_y ? 10'd262 : 10'd525;
                max_width <= is_native_x ? 11'd519 : 11'd1039;
                v_count <= is_native_y ? (10'd262) : (10'd525);
            end
            `CHIP6567R56A: begin
                if (is_native_x) begin
                    hs_sta <= 10;  // front porch 10
                    hs_end <= 70;  // h sync pulse 60
                    ha_sta <= 80;  // h back porch 10
                    // WIDTH 512
                end else begin
                    hs_sta <= 20;  // front porch 20
                    hs_end <= 140; // sync pulse 120
                    ha_sta <= 160; // back porch 20
                    // WIDTH 1024
                end
                if (is_native_y) begin
                   // v front porch 35
                   // v sync pulse 2
                   // v back porch 2
                   vs_sta <= 35;
                   vs_end <= 37;
                   va_sta <= 39;
                   // HEIGHT = 262
                end else begin
                   // v front porch 70
                   // v sync pulse 2
                   // v back porch 4
                   vs_sta <= 70;
                   vs_end <= 72;
                   va_sta <= 76;
                   // HEIGHT = 524
                end
                max_height <= is_native_y ? 10'd261 : 10'd523;
                max_width <= is_native_x ? 11'd511 : 11'd1023;
                v_count <= is_native_y ? (10'd261) : (10'd523);
            end
        endcase
    end
endtask

`ifdef CONFIGURABLE_TIMING
task set_params_configurable();
    begin
        case (chip)
            /* verilator lint_off WIDTH */
            `CHIP6569R1, `CHIP6569R5: begin
                if (is_native_x) begin
                    hs_sta <= timing_1x_fporch_pal;
                    hs_end <= timing_1x_fporch_pal + timing_1x_sync_pal;
                    ha_sta <= timing_1x_fporch_pal +  timing_1x_sync_pal + timing_1x_bporch_pal;
						  // WIDTH 504
                end else begin
                    hs_sta <= timing_2x_fporch_pal;
                    hs_end <= timing_2x_fporch_pal + timing_2x_sync_pal;
                    ha_sta <= timing_2x_fporch_pal +  timing_2x_sync_pal + timing_2x_bporch_pal;
						  // WIDTH 1008
                end
                // NOTE: PAL vertical sync is from 'bottom' edge.
                if (is_native_y) begin
                   va_end <= 312 - (timing_1y_fporch_pal +  timing_1y_sync_pal + timing_1y_bporch_pal);
                   vs_sta <= 312 - (timing_1y_sync_pal + timing_1y_bporch_pal);
                   vs_end <= 312 - (timing_1y_bporch_pal);
                   // HEIGHT = 312
                end else begin
                   va_end <= 624 - (timing_2y_fporch_pal +  timing_2y_sync_pal + timing_2y_bporch_pal);
                   vs_sta <= 624 - (timing_2y_sync_pal + timing_2y_bporch_pal);
                   vs_end <= 624 - (timing_2y_bporch_pal);
                   // HEIGHT = 624
                end
                max_height <= is_native_y ? 10'd311 : 10'd623;
                max_width <= is_native_x ? 11'd503 : 11'd1007;
            end
            `CHIP6567R8: begin
                if (is_native_x) begin
                    hs_sta <= timing_1x_fporch_ntsc;
                    hs_end <= timing_1x_fporch_ntsc + timing_1x_sync_ntsc;
                    ha_sta <= timing_1x_fporch_ntsc + timing_1x_sync_ntsc + timing_1x_bporch_ntsc;
                    // WIDTH 520
                end else begin
                    hs_sta <= timing_2x_fporch_ntsc;
                    hs_end <= timing_2x_fporch_ntsc + timing_2x_sync_ntsc;
                    ha_sta <= timing_2x_fporch_ntsc + timing_2x_sync_ntsc + timing_2x_bporch_ntsc;
                    // WIDTH 1040
                end
                // NOTE: NTSC vertical sync is from 'top' edge.
                if (is_native_y) begin
                   vs_sta <= timing_1y_fporch_ntsc;
                   vs_end <= timing_1y_fporch_ntsc + timing_1y_sync_ntsc;
                   va_sta <= timing_1y_fporch_ntsc + timing_1y_sync_ntsc + timing_1y_bporch_ntsc;
                   // HEIGHT = 263
                end else begin
                   vs_sta <= timing_2y_fporch_ntsc;
                   vs_end <= timing_2y_fporch_ntsc + timing_2y_sync_ntsc;
                   va_sta <= timing_2y_fporch_ntsc + timing_2y_sync_ntsc + timing_2y_bporch_ntsc;
                   // HEIGHT = 526
                end
                max_height <= is_native_y ? 10'd262 : 10'd525;
                max_width <= is_native_x ? 11'd519 : 11'd1039;
            end
            `CHIP6567R56A: begin
                if (is_native_x) begin
                    hs_sta <= timing_1x_fporch_ntsc;
                    hs_end <= timing_1x_fporch_ntsc + timing_1x_sync_ntsc;
                    ha_sta <= timing_1x_fporch_ntsc + timing_1x_sync_ntsc + timing_1x_bporch_ntsc;
                    // WIDTH 512
                end else begin
                    hs_sta <= timing_2x_fporch_ntsc;
                    hs_end <= timing_2x_fporch_ntsc + timing_2x_sync_ntsc;
                    ha_sta <= timing_2x_fporch_ntsc + timing_2x_sync_ntsc + timing_2x_bporch_ntsc;
                    // WIDTH 1024
                end
                // NOTE: NTSC vertical sync is from 'top' edge.
                if (is_native_y) begin
                   vs_sta <= timing_1y_fporch_ntsc;
                   vs_end <= timing_1y_fporch_ntsc + timing_1y_sync_ntsc;
                   va_sta <= timing_1y_fporch_ntsc + timing_1y_sync_ntsc + timing_1y_bporch_ntsc;
                   // HEIGHT = 262
                end else begin
                   vs_sta <= timing_2y_fporch_ntsc;
                   vs_end <= timing_2y_fporch_ntsc + timing_2y_sync_ntsc;
                   va_sta <= timing_2y_fporch_ntsc + timing_2y_sync_ntsc + timing_2y_bporch_ntsc;
                   // HEIGHT = 524
                end
                max_height <= is_native_y ? 10'd261 : 10'd523;
                max_width <= is_native_x ? 11'd511 : 11'd1023;
            end
            /* verilator lint_on WIDTH */
        endcase
    end
endtask
`endif

endmodule : hires_vga_sync
