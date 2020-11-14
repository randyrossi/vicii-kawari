`timescale 1ns / 1ps

`include "common.vh"

module pixel_sequencer(
           input rst,
           input clk_dot4x,
           input clk_phi,
           input dot_rising_0,
           input dot_rising_1,
           input phi_phase_start_pixel_latch, // when we latch pixels_read into pixels_read_delayed
           input phi_phase_start_xscroll_latch,
           input mcm,
           input bmm,
           input ecm,
           input [2:0] xpos_mod_8,
           input [6:0] cycle_num,
           input [2:0] xscroll,
           input [7:0] pixels_read,
           input [11:0] char_read,
           input [3:0] b0c,
           input [3:0] b1c,
           input [3:0] b2c,
           input [3:0] b3c,
           input [3:0] ec,
           input main_border,
           output reg main_border_stage1,
           input [15:0] sprite_cur_pixel_o,
           input [7:0] sprite_pri,
           input [7:0] sprite_mmc,
           input [31:0] sprite_col_o,
           input [3:0] sprite_mc0,
           input [3:0] sprite_mc1,
           output reg is_background_pixel1,
           output reg stage1,
           output reg [3:0] pixel_color3
       );

reg load_pixels;
reg shift_pixels;
reg ismc;
reg is_background_pixel0;
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

reg [2:0] xscroll_delayed;
reg [7:0] pixels_read_delayed;
reg [11:0] char_read_delayed;
 
// pixels being shifted and the associated char (for color info)
reg [11:0] char_shifting;
reg [7:0] pixels_shifting;

// Transfer read character pixels and char values into waiting*[0] so they
// are available at the first dot of PHI2
always @(posedge clk_dot4x)
begin
    if (`XSCROLL_LATCH_PHASE && phi_phase_start_xscroll_latch) begin
        // pick up xscroll only inside visible cycles
        if (cycle_num >= 15 && cycle_num <= 55)
           xscroll_delayed <= xscroll;
    end
    // Need to delay pixels to align properly with delayed xpos
    // value so we don't load pixels too early.  Basically, pixels_read
    // needs to be visislbe to the sequencer first when xpos_mod_8 == 0
    // which is when load_pixels rises.
    if (`PIXEL_LATCH_PHASE && phi_phase_start_pixel_latch) begin
        pixels_read_delayed <= pixels_read;
        char_read_delayed <= char_read;
    end
end

always @(*)
    ismc = mcm & (bmm | ecm | char_shifting[11]);

always @(*)
    load_pixels = xpos_mod_8 == xscroll_delayed;

always @(posedge clk_dot4x)
    //if (rst) begin
    //    shift_pixels <= `FALSE;
    //end else
    if (dot_rising_0) begin // rising dot
        if (load_pixels)
            shift_pixels <= ~(mcm & (bmm | ecm | char_read_delayed[11]));
        else
            shift_pixels <= ismc ? ~shift_pixels : shift_pixels;
    end

reg stage0;
always @(posedge clk_dot4x)
    //if (rst) begin
    //    char_shifting <= 12'b0;
    //end else
    if (dot_rising_1) begin
        stage0 <= 1'b1;
        if (load_pixels)
            char_shifting <= char_read_delayed;
    end

// Pixel shifter
always @(posedge clk_dot4x) begin
    if (rst) begin
        pixels_shifting <= 8'b0;
        //is_background_pixel0 <= `FALSE;
    end
    else if (dot_rising_1) begin
        if (load_pixels) begin
            pixels_shifting <= pixels_read_delayed;
            is_background_pixel0 <= !pixels_read_delayed[7];
        end else if (shift_pixels) begin
            if (ismc) begin
                pixels_shifting <= {pixels_shifting[5:0], 2'b0};
                is_background_pixel0 <= !pixels_shifting[5];
            end else begin
                pixels_shifting <= {pixels_shifting[6:0], 1'b0};
                is_background_pixel0 <= !pixels_shifting[6];
            end
        end
    end
end

// handle display modes
reg [3:0] pixel_color1; // stage 1
always @(posedge clk_dot4x)
begin
    //if (rst) begin
    //    is_background_pixel1 <= 1'b0;
    //    pixel_color1 <= `BLACK;
    //end else
    if (stage0) begin
        pixel_color1 <= `BLACK;
	is_background_pixel1 <= is_background_pixel0;
	main_border_stage1 <= main_border;
	stage0 <= 1'b0;
	stage1 <= 1'b1;
        case ({ecm, bmm, mcm})
            `MODE_STANDARD_CHAR:
                pixel_color1 <= pixels_shifting[7] ? char_shifting[11:8]:b0c;
            `MODE_MULTICOLOR_CHAR:
                if (char_shifting[11])
                case (pixels_shifting[7:6])
                    2'b00: pixel_color1 <= b0c;
                    2'b01: pixel_color1 <= b1c;
                    2'b10: pixel_color1 <= b2c;
                    2'b11: pixel_color1 <= {1'b0, char_shifting[10:8]};
                endcase
                else
                    pixel_color1 <= pixels_shifting[7] ? char_shifting[11:8]:b0c;
            `MODE_STANDARD_BITMAP, `MODE_INV_EXTENDED_BG_COLOR_STANDARD_BITMAP:
                pixel_color1 <= pixels_shifting[7] ? char_shifting[7:4]:char_shifting[3:0];
            `MODE_MULTICOLOR_BITMAP, `MODE_INV_EXTENDED_BG_COLOR_MULTICOLOR_BITMAP:
            case (pixels_shifting[7:6])
                2'b00: pixel_color1 <= b0c;
                2'b01: pixel_color1 <= char_shifting[7:4];
                2'b10: pixel_color1 <= char_shifting[3:0];
                2'b11: pixel_color1 <= char_shifting[11:8];
            endcase
            `MODE_EXTENDED_BG_COLOR:
            case ({pixels_shifting[7], char_shifting[7:6]})
                3'b000: pixel_color1 <= b0c;
                3'b001: pixel_color1 <= b1c;
                3'b010: pixel_color1 <= b2c;
                3'b011: pixel_color1 <= b3c;
                default: pixel_color1 <= char_shifting[11:8];
            endcase
            `MODE_INV_EXTENDED_BG_COLOR_MULTICOLOR_CHAR:
                if (char_shifting[11])
                case (pixels_shifting[7:6])
                    2'b00: pixel_color1 <= b0c;
                    2'b01: pixel_color1 <= b1c;
                    2'b10: pixel_color1 <= b2c;
                    2'b11: pixel_color1 <= char_shifting[11:8];
                endcase
                else
                case ({pixels_shifting[7], char_shifting[7:6]})
                    3'b000: pixel_color1 <= b0c;
                    3'b001: pixel_color1 <= b1c;
                    3'b010: pixel_color1 <= b2c;
                    3'b011: pixel_color1 <= b3c;
                    default: pixel_color1 <= char_shifting[11:8];
                endcase
        endcase
    end
end

reg [3:0] pixel_color2; // stage 2
reg stage2;
always @(posedge clk_dot4x)
begin
    //if (rst) begin
    //    pixel_color2 = `BLACK;
    //end else
    if (stage1) begin
        stage1 <= 1'b0;
	stage2 <= 1'b1;
        // illegal modes should have black pixels
        case ({ecm, bmm, mcm})
            `MODE_INV_EXTENDED_BG_COLOR_MULTICOLOR_CHAR,
            `MODE_INV_EXTENDED_BG_COLOR_STANDARD_BITMAP,
            `MODE_INV_EXTENDED_BG_COLOR_MULTICOLOR_BITMAP:
                pixel_color2 = `BLACK;
            default: pixel_color2 = pixel_color1;
        endcase
        // sprites overwrite pixels
        // The comparisons of background pixel and sprite pixels must be
        // on the same delay 'schedule' here.
        for (n = `NUM_SPRITES-1; n >= 0; n = n - 1) begin
            if (!sprite_pri[n] || is_background_pixel1) begin
                if (sprite_mmc[n]) begin  // multi-color mode ?
                    if (sprite_cur_pixel[n] != 2'b00) begin
                        case(sprite_cur_pixel[n])
                            2'b00:  ;
                            2'b01:  pixel_color2 = sprite_mc0;
                            2'b10:  pixel_color2 = sprite_col[n[2:0]];
                            2'b11:  pixel_color2 = sprite_mc1;
                        endcase
                    end
                end else if (sprite_cur_pixel[n][1]) begin
                    pixel_color2 = sprite_col[n[2:0]];
                end
            end
            // If a sprite with a lower priority caused a foreground pixel to be overwritten
            // due to its sprite_pri being 0, we must 'reset' the foreground pixel if a higher
            // priority sprite has sprite_pri 1 (Uncensored ski hill).  In other words, a higher
            // priority sprite's desire to leave foreground pixels alone overrides a lower
            // sprite's desire to overwrite it.
            if (sprite_pri[n] && !is_background_pixel1 && sprite_cur_pixel[n][1]) begin
                case ({ecm, bmm, mcm})
                    `MODE_INV_EXTENDED_BG_COLOR_MULTICOLOR_CHAR,
                    `MODE_INV_EXTENDED_BG_COLOR_STANDARD_BITMAP,
                    `MODE_INV_EXTENDED_BG_COLOR_MULTICOLOR_BITMAP:
                        pixel_color2 = `BLACK;
                    default: pixel_color2 = pixel_color1;
                endcase
            end
        end
    end
end

// mask with border - pixel_color3 = stage 3
always @(posedge clk_dot4x)
begin
    //if (rst) begin
    //    pixel_color3 <= `BLACK;
    //end else
    if (stage2) begin
	stage2 <= 1'b0;
        if (main_border)
            pixel_color3 <= ec;
        else
            pixel_color3 <= pixel_color2;
    end
end

endmodule
