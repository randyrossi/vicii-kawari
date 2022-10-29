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

module pixel_sequencer(
           input clk_dot4x,
           input clk_phi,
           input [3:0] dot_rising,
           input phi_phase_start_pl,
           input phi_phase_start_dav,
           input mcm,
           input bmm,
           input ecm,
           input idle,
           input [6:0] cycle_num,
           input [2:0] cycle_bit,
`ifdef PIXEL_LOG
           input [8:0] raster_line,
`endif
           input [2:0] xscroll,
           input [7:0] pixels_read,
           input [11:0] char_read,
           input [3:0] b0c,
           input [3:0] b1c,
           input [3:0] b2c,
           input [3:0] b3c,
           input [3:0] ec,
           input main_border,
           input [15:0] sprite_cur_pixel_o,
           input [7:0] sprite_pri_d,
           input [7:0] sprite_mmc_d,
           input [31:0] sprite_col_o,  // delayed before use
           input [3:0] sprite_mc0,  // delayed before use
           input [3:0] sprite_mc1,  // delayed before use
           input vborder,
           output reg is_background_pixel0,
           output reg stage0,
           output reg stage1,
           output reg [3:0] pixel_color1,
`ifdef HIRES_MODES
           // Added to let low res sprites 'shine through' to hires sequencer.
           // Easy hack to get sprites on hires modes (with limitations). This
           // flag essentially overrides the hires/lores multiplexer logic
           // and uses the pixel color from the lores sequencer.
           output reg hires_sprite_active,
`endif
           input [3:0] active_sprite_d
       );

integer n;

// Destinations for flattened inputs that need to be sliced back into an array
wire [1:0] sprite_cur_pixel [`NUM_SPRITES-1:0];
wire [3:0] sprite_col [`NUM_SPRITES-1:0];

// Handle un-flattening inputs here
assign sprite_cur_pixel[0] = sprite_cur_pixel_o[15:14];
assign sprite_cur_pixel[1] = sprite_cur_pixel_o[13:12];
assign sprite_cur_pixel[2] = sprite_cur_pixel_o[11:10];
assign sprite_cur_pixel[3] = sprite_cur_pixel_o[9:8];
assign sprite_cur_pixel[4] = sprite_cur_pixel_o[7:6];
assign sprite_cur_pixel[5] = sprite_cur_pixel_o[5:4];
assign sprite_cur_pixel[6] = sprite_cur_pixel_o[3:2];
assign sprite_cur_pixel[7] = sprite_cur_pixel_o[1:0];

assign sprite_col[0] = sprite_col_o[31:28];
assign sprite_col[1] = sprite_col_o[27:24];
assign sprite_col[2] = sprite_col_o[23:20];
assign sprite_col[3] = sprite_col_o[19:16];
assign sprite_col[4] = sprite_col_o[15:12];
assign sprite_col[5] = sprite_col_o[11:8];
assign sprite_col[6] = sprite_col_o[7:4];
assign sprite_col[7] = sprite_col_o[3:0];

// Various delay registers
reg [2:0] xscroll_delayed;
reg [2:0] xscroll_delayed0;
reg [7:0] pixels_read_delayed0;
reg [7:0] pixels_read_delayed1;
reg [7:0] pixels_read_delayed;
reg [11:0] char_read_delayed0;
reg [11:0] char_read_delayed1;
reg [11:0] char_read_delayed;
reg [6:0] cycle_num_delayed0;
reg [6:0] cycle_num_delayed1;
reg [6:0] cycle_num_delayed;

reg [3:0] sprite_col_d1 [`NUM_SPRITES-1:0];
reg [3:0] sprite_col_d2 [`NUM_SPRITES-1:0];
reg [3:0] sprite_mc0_d1;
reg [3:0] sprite_mc0_d2;
reg [3:0] sprite_mc1_d1;
reg [3:0] sprite_mc1_d2;

// pixels being shifted and the associated char (for color info)
reg [11:0] char_shifting;
reg [7:0] pixels_shifting;

reg [3:0] ec_d2;
reg [3:0] b0c_d2;
reg [3:0] b1c_d2;
reg [3:0] b2c_d2;
reg [3:0] b3c_d2;

wire visible;
wire visible_d;
assign visible = cycle_num >= 15 && cycle_num <= 54;
assign visible_d = cycle_num_delayed >= 15 && cycle_num_delayed <= 54;

// For color splits to work on sprites, we need to delay
// register changes by 2 pixels and to become valid by stage0
always @(posedge clk_dot4x)
begin
    if (dot_rising[1]) begin
        for (n = `NUM_SPRITES-1; n >= 0; n = n - 1) begin
            sprite_col_d1[n[2:0]] <= sprite_col[n[2:0]];
            sprite_col_d2[n[2:0]] <= sprite_col_d1[n[2:0]];
        end
        sprite_mc0_d1 <= sprite_mc0;
        sprite_mc0_d2 <= sprite_mc0_d1;
        sprite_mc1_d1 <= sprite_mc1;
        sprite_mc1_d2 <= sprite_mc1_d1;
    end
end

always @(posedge clk_dot4x)
begin
    // Pixels are delayed so they first become valid precicely
    // when cycle_bit == 0.  So when xscroll == 0, pixels start
    // to render at the first pixel of a 8x8 cell.  This means
    // we have 8 possible start positions that xscroll controls
    // within each cell (as expected).
    if (phi_phase_start_dav) begin
        pixels_read_delayed0 <= pixels_read;
        pixels_read_delayed1 <= pixels_read_delayed0;

        char_read_delayed0 <= char_read;
        char_read_delayed1 <= char_read_delayed0;

        cycle_num_delayed0 <= cycle_num;
        cycle_num_delayed1 <= cycle_num_delayed0;

        xscroll_delayed0 <= xscroll;
    end

    if (!clk_phi && phi_phase_start_pl) begin
        pixels_read_delayed <= pixels_read_delayed1;
        char_read_delayed <= char_read_delayed1;
        cycle_num_delayed <= cycle_num_delayed1;
        if (visible && !vborder) begin
            xscroll_delayed <= xscroll_delayed0;
        end
    end

    if (stage0) begin
        b0c_d2 <= b0c;
        b1c_d2 <= b1c;
        b2c_d2 <= b2c;
        b3c_d2 <= b3c;
        ec_d2 <= ec;
    end
end

reg g_mc_ff;
reg mcm_d;
reg mcm_d_prev;
reg bmm_d;
reg ecm_d;

// pixel_value is not a color, it encodes
// {bcm,bmm,mcm,px1,px0}
reg [4:0] pixel_value;
reg main_border_stage0;
always @(posedge clk_dot4x)
begin
    if (stage0)
        stage0 <= 1'b0;

    // First tick of a pixel
    if (dot_rising[1]) begin
        // We 'work' on several stages of a pixel over the next 3 dot4x
        // ticks. It begins here when we set stage0 high.
        stage0 <= 1'b1;
        main_border_stage0 <= main_border;

        if (cycle_bit == 4) begin
            mcm_d = mcm;
            bmm_d = bmm_d | bmm;
            ecm_d = ecm_d | ecm;
        end else if (cycle_bit == 6) begin
            bmm_d = bmm_d & bmm;
            ecm_d = ecm_d & ecm;
        end else if (cycle_bit == 7) begin
            if (mcm_d && !mcm_d_prev)
                g_mc_ff = 0;
            mcm_d_prev = mcm_d;
        end

`ifdef PIXEL_LOG
        if (cycle_num >= 15 && cycle_num <=54) begin
            $display("PIXEL %d WITH XSCROLL=%d VM11=%d%d VM16=%d(%d) MC=%d",
                     cycle_bit, xscroll_delayed, bmm_d, ecm_d, mcm_d_prev, mcm_d, g_mc_ff);
        end
`endif

        // load pixels when xscroll matches pixel 0-7
        if (xscroll_delayed == cycle_bit) begin
            g_mc_ff = 1;
            if (!vborder && visible_d) begin
                pixels_shifting = pixels_read_delayed;
                if (!idle) begin
                    char_shifting = char_read_delayed;
                end else begin
                    char_shifting = 12'b0;
                end
            end else
                pixels_shifting = 8'b0;

`ifdef PIXEL_LOG
            if (cycle_num >= 15 && cycle_num <=54) begin
                $display("LINE %03x", raster_line);
                $display("%d CHECK LOADING %x %x",
                         cycle_num, idle ? 12'b0 : char_read_delayed, pixels_shifting);
            end
`endif
        end

        // mc pixels if MCM=1 and BMM=1, or MCM=1 & CBUF[11]=1
        if (mcm_d_prev) begin
            if (bmm_d | char_shifting[11]) begin
                if (g_mc_ff) begin
                    pixel_value <= {ecm_d, bmm_d, mcm_d, pixels_shifting[7:6]};
                    is_background_pixel0 <= !pixels_shifting[7];
                end else
                    pixel_value <= {ecm_d, bmm_d, mcm_d, pixel_value[1:0]};
            end else begin
                pixel_value <= {ecm_d, bmm_d, mcm_d, pixels_shifting[7] ? 2'b11 : 2'b0};
                is_background_pixel0 <= !pixels_shifting[7];
            end
        end else begin
            if (bmm_d | char_shifting[11])
                pixel_value <= {ecm_d, bmm_d, mcm_d, pixels_shifting[7], 1'b0};
            else
                pixel_value <= {ecm_d, bmm_d, mcm_d, pixels_shifting[7] ? 2'b11 : 2'b0};
            is_background_pixel0 <= !pixels_shifting[7];
        end
        pixels_shifting = {pixels_shifting[6:0], 1'b0};
    end

    if (dot_rising[3]) begin
        g_mc_ff = ~g_mc_ff;
    end
end

// Handle display modes in stage0
always @(posedge clk_dot4x)
begin
    if (stage1)
        stage1 <= 1'b0;
    if (stage0) begin
        stage1 <= 1'b1;
        // Switch on pixel_value's vidmode and then use lower 2 bits for
        // color interpretation.
        // ECM, BMM, MCM, PX1, PX0
`ifdef PIXEL_LOG
        $display("PV:%02x FROM %02x", pixel_value, pixels_shifting);
`endif
        if (main_border_stage0)
            pixel_color1 = ec_d2;
        else begin
            case (pixel_value[4:2])
                `MODE_STANDARD_CHAR:
                    pixel_color1 = pixel_value[1] ? char_shifting[11:8]:b0c_d2;
                `MODE_MULTICOLOR_CHAR:
                    if (char_shifting[11])
                    case (pixel_value[1:0])
                        2'b00: pixel_color1 = b0c_d2;
                        2'b01: pixel_color1 = b1c_d2;
                        2'b10: pixel_color1 = b2c_d2;
                        2'b11: pixel_color1 = {1'b0, char_shifting[10:8]};
                    endcase
                    else
                        pixel_color1 = pixel_value[1] ? {1'b0,char_shifting[10:8]}:b0c_d2;
                `MODE_STANDARD_BITMAP:
                    pixel_color1 = pixel_value[1] ? char_shifting[7:4]:char_shifting[3:0];
                `MODE_MULTICOLOR_BITMAP:
                case (pixel_value[1:0])
                    2'b00: pixel_color1 = b0c_d2;
                    2'b01: pixel_color1 = char_shifting[7:4];
                    2'b10: pixel_color1 = char_shifting[3:0];
                    2'b11: pixel_color1 = char_shifting[11:8];
                endcase
                `MODE_EXTENDED_BG_COLOR:
                case ({pixel_value[1], char_shifting[7:6]})
                    3'b000: pixel_color1 = b0c_d2;
                    3'b001: pixel_color1 = b1c_d2;
                    3'b010: pixel_color1 = b2c_d2;
                    3'b011: pixel_color1 = b3c_d2;
                    default: pixel_color1 = char_shifting[11:8];
                endcase
                `MODE_INV_EXTENDED_BG_COLOR_MULTICOLOR_CHAR:
                    pixel_color1 = `BLACK;
                `MODE_INV_EXTENDED_BG_COLOR_MULTICOLOR_BITMAP:
                    pixel_color1 = `BLACK;
                `MODE_INV_EXTENDED_BG_COLOR_STANDARD_BITMAP:
                    pixel_color1 = `BLACK;
            endcase

            // sprites overwrite pixels
            // The comparisons of background pixel and sprite pixels must be
            // on the same delay 'schedule' here.  Also, the pri, mmc and colors
            // need to be delayed so they split this properly on reg changes.
`ifdef HIRES_MODES
            hires_sprite_active = 1'b0;
`endif
            if (active_sprite_d[3]) begin
                if (!sprite_pri_d[active_sprite_d[2:0]] || is_background_pixel0) begin
                    if (sprite_mmc_d[active_sprite_d[2:0]]) begin  // multi-color mode ?
                        case(sprite_cur_pixel[active_sprite_d[2:0]])
                            2'b00: ;
                            2'b01:  begin
                                pixel_color1 = sprite_mc0_d2;
`ifdef HIRES_MODES
                                hires_sprite_active = 1'b1;
`endif
                            end
                            2'b10:  begin
                                pixel_color1 = sprite_col_d2[active_sprite_d[2:0]];
`ifdef HIRES_MODES
                                hires_sprite_active = 1'b1;
`endif
                            end
                            2'b11:  begin
                                pixel_color1 = sprite_mc1_d2;
`ifdef HIRES_MODES
                                hires_sprite_active = 1'b1;
`endif
                            end
                        endcase
                    end else if (sprite_cur_pixel[active_sprite_d[2:0]][1]) begin
                        pixel_color1 = sprite_col_d2[active_sprite_d[2:0]];
`ifdef HIRES_MODES
                        hires_sprite_active = 1'b1;
`endif
                    end
                end
            end
        end
    end
end

endmodule
