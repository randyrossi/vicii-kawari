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

`timescale 1ns / 1ps

`include "common.vh"

module hires_pixel_sequencer(
           input rst,
           input clk_dot4x,
           input clk_phi,
           input [3:0] dot_rising,
           input phi_phase_start_dav,
           input phi_phase_start_pl,
           input phi_phase_start_10,
           input [6:0] cycle_num,
           input [2:0] cycle_bit,
           input [2:0] xscroll,
           input [3:0] b0c,
           input [3:0] ec,
           input main_border,
           input vborder,
           input [3:0] color_base,
           output reg [3:0] hires_pixel_color1,
           output reg hires_stage1,
           output reg hires_is_background_pixel,
           input hires_enabled,
           input [2:0] hires_mode,
           input [2:0] hires_cycle_bit,
           input [7:0] hires_pixel_data,
           input [7:0] hires_color_data,
           input [2:0] hires_rc,
           input [5:0] blink_ctr,
           input hires_cursor
       );

integer n;

// Various delay registers
reg [2:0] xscroll_delayed;
reg [2:0] xscroll_delayed0;
reg [6:0] cycle_num_delayed0;
reg [6:0] cycle_num_delayed1;
reg [6:0] cycle_num_delayed;

reg hires_cursor_delayed0;
reg hires_cursor_delayed1;
reg hires_cursor_delayed2;
reg hires_cursor_delayed3;
reg hires_cursor_delayed4;
reg hires_cursor_delayed;
reg [7:0] hires_pixel_data_delayed0;
reg [7:0] hires_pixel_data_delayed1;
reg [7:0] hires_pixel_data_delayed2;
reg [7:0] hires_pixel_data_delayed3;
reg [7:0] hires_pixel_data_delayed4;
reg [7:0] hires_pixel_data_delayed;
reg [7:0] hires_color_data_delayed0;
reg [7:0] hires_color_data_delayed1;
reg [7:0] hires_color_data_delayed2;
reg [7:0] hires_color_data_delayed3;
reg [7:0] hires_color_data_delayed4;
reg [7:0] hires_color_data_delayed;

// pixels being shifted and the associated char (for color info)
reg [7:0] hires_color_shifting; // not really shifted, just goes with pixels shifting
reg [7:0] hires_pixels_shifting;
reg [15:0] hires2_pixels_shifting; // for 32k bitmap modes

reg [3:0] ec_d2;
reg [3:0] b0c_d2;

wire visible;
wire visible_d;
assign visible = cycle_num >= 15 && cycle_num <= 54;
assign visible_d = cycle_num_delayed >= 15 && cycle_num_delayed <= 54;

reg hires_stage0;

// Transfer read character pixels and char values into waiting*[0] so they
// are available at the first dot of PHI2
always @(posedge clk_dot4x)
begin
    if (phi_phase_start_dav) begin
        cycle_num_delayed0 <= cycle_num;
        cycle_num_delayed1 <= cycle_num_delayed0;

        xscroll_delayed0 <= xscroll;
    end

    if (phi_phase_start_10) begin
        hires_cursor_delayed0 <= hires_cursor;
        hires_cursor_delayed1 <= hires_cursor_delayed0;
        hires_cursor_delayed2 <= hires_cursor_delayed1;
        hires_cursor_delayed3 <= hires_cursor_delayed2;
        hires_cursor_delayed4 <= hires_cursor_delayed3;
        hires_pixel_data_delayed0 <= hires_pixel_data;
        hires_pixel_data_delayed1 <= hires_pixel_data_delayed0;
        hires_pixel_data_delayed2 <= hires_pixel_data_delayed1;
        hires_pixel_data_delayed3 <= hires_pixel_data_delayed2;
        hires_pixel_data_delayed4 <= hires_pixel_data_delayed3;
        hires_color_data_delayed0 <= hires_color_data;
        hires_color_data_delayed1 <= hires_color_data_delayed0;
        hires_color_data_delayed2 <= hires_color_data_delayed1;
        hires_color_data_delayed3 <= hires_color_data_delayed2;
        hires_color_data_delayed4 <= hires_color_data_delayed3;
    end

    if (phi_phase_start_pl) begin
        hires_cursor_delayed <= hires_cursor_delayed4;
        hires_pixel_data_delayed <= hires_pixel_data_delayed4;
        hires_color_data_delayed <= hires_color_data_delayed4;
    end

    if (!clk_phi && phi_phase_start_pl) begin
        cycle_num_delayed <= cycle_num_delayed1;

        if (visible && !vborder) begin
            xscroll_delayed <= xscroll_delayed0;
        end
    end

    if (hires_stage0) begin
        b0c_d2 <= b0c;
        ec_d2 <= ec;
    end

end

reg hires_pixel_value; // for text or 16k bitmap modes
reg[3:0] hires2_pixel_value; // for 32k bitmap modes, up to 4 bits to determine color
reg[1:0] hires_ff;
reg main_border_stage0;
always @(posedge clk_dot4x)
begin
    if (hires_stage0)
        hires_stage0 <= 1'b0;
    if (dot_rising[1] || dot_rising[3]) begin
        hires_stage0 <= 1'b1;
        main_border_stage0 <= main_border;

        // load pixels when xscroll matches pixel 0-7
        if (xscroll_delayed == hires_cycle_bit) begin
            hires_ff <= 2'b0;
            if (!vborder && visible_d) begin
                if (hires_mode == 3'b000 || hires_mode == 3'b001) begin
                   // Text or 16k bitmap with colors. We used both pixel and color data.
                   hires_pixels_shifting = hires_pixel_data_delayed;
                   hires_color_shifting = hires_color_data_delayed;
                end else if (hires_mode == 3'b100) begin
                   // 16k bitmap. Place the only byte we have at the top.
                   hires2_pixels_shifting = {hires_pixel_data_delayed, 8'b0};
                end else begin
                   // 32k bitmap modes.
                   // Here we use the color register for byte 1 and the pixel register
                   // for byte 2. So thename 'color' is misleading here.
                   hires2_pixels_shifting = {hires_color_data_delayed,
                                             hires_pixel_data_delayed};
                end
            end else begin
                if (hires_mode == 3'b000 || hires_mode == 3'b001) begin
                   // Text
                   hires_pixels_shifting = 8'b0;
                   hires_color_shifting = 8'b0;
                end else begin
                   // 16k/32k bitmap modes
                   hires2_pixels_shifting = 16'b0;
                end
            end
        end
        case (hires_mode)
           3'b000, 3'b001: begin
             // Text or 16k bitmap with color cells
             hires_pixel_value <= hires_pixels_shifting[7];
             hires_pixels_shifting = {hires_pixels_shifting[6:0], 1'b0};
           end
           3'b010: begin
             // 320x200x16
             if (hires_ff[0]) begin
                hires2_pixel_value <= hires2_pixels_shifting[15:12];
                hires2_pixels_shifting = {hires2_pixels_shifting[11:0], 4'b0};
             end
           end
           3'b011: begin
             // 640x200x4
             hires2_pixel_value <= hires2_pixels_shifting[15:12];
             hires2_pixels_shifting = {hires2_pixels_shifting[13:0], 2'b0};
           end
           3'b100: begin
             // 160x200x16
             if (hires_ff == 2'b00) begin
               hires2_pixel_value <= hires2_pixels_shifting[15:12];
               hires2_pixels_shifting = {hires2_pixels_shifting[11:0], 4'b0};
             end
           end
           default:
             // invalid
             ;
        endcase

        // We don't have a proper reset case in this module. This
        // flip flip toggling before reset was lifted was sometimes
        // causing a 'misalignment' and packed pixels were not being
        // interpreted correctly. This makes sure we start flipping and
        // flopping after reset. But,really this whole module should do
        // nothing while in reset.
        if (!rst)
           hires_ff <= hires_ff + 2'b1;
        else
           hires_ff <= 2'b01;
    end
end

always @(posedge clk_dot4x)
begin
    // This is the last stage of our hires mode.
    if (hires_stage1)
        hires_stage1 <= 1'b0;
    if (hires_stage0) begin
        hires_stage1 <= 1'b1;

        if (main_border_stage0)
            hires_pixel_color1 <= ec_d2;
        else begin
            case (hires_mode)
                3'b000: begin
                    // Text mode.
                    // Lower 4 bits = color index
                    // Bit 6 = reverse video
                    // Bit 5 = underline
                    // Bit 4 = blink
                    // 'shifting' here is not really shifting
                    hires_pixel_color1 <=
                    ((hires_color_shifting[`HIRES_BLNK_BIT] && blink_ctr[`HIRES_BLINK_FREQ]) |
                     ~hires_color_shifting[`HIRES_BLNK_BIT]) ?
                    ((hires_color_shifting[`HIRES_UNDR_BIT] && hires_rc == 3'd7) ?
                     hires_color_shifting[3:0] :
                     (hires_pixel_value ^
                      (hires_color_shifting[`HIRES_RVRS_BIT] | hires_cursor_delayed)) ?
                     hires_color_shifting[3:0] : b0c_d2) : b0c_d2;
                    hires_is_background_pixel <= !hires_pixel_value;
                end
                3'b001: begin
                    // 640x200 with 8x8 color cells. Uses only lower 4 bits of
                    // color as color index. 'shifting' here is not really
                    // shifting
                    hires_pixel_color1 <=
                        hires_pixel_value ? hires_color_shifting[3:0] : b0c_d2;
                    hires_is_background_pixel <= !hires_pixel_value;
                end 3'b010, 3'b100: begin
                  // 160x200x16 or 320x200x16
                  hires_pixel_color1 <= hires2_pixel_value[3:0];
                  hires_is_background_pixel <= (hires2_pixel_value[3:0] != b0c_d2);
                end
                3'b011: begin
                  // 640x200x4
                  hires_pixel_color1 <= {color_base[1:0], hires2_pixel_value[3:2]};
                  hires_is_background_pixel <= ({color_base[1:0], hires2_pixel_value[3:2]} != b0c_d2);
                end
                default:
                  ;
            endcase
        end
    end
end

endmodule
