`timescale 1ns / 1ps

`include "common.vh"

module pixel_sequencer(
           input rst,
           input clk_dot4x,
           input clk_phi,
           input dot_rising_0,
           input phi_phase_start_15,
           input mcm,
           input bmm,
           input ecm,
           input [2:0] xpos_mod_8,
           input [2:0] xscroll,
           input [7:0] pixels_read,
           input [11:0] char_read,
           input vic_color b0c,
           input vic_color b1c,
           input vic_color b2c,
           input vic_color b3c,
           input vic_color ec,
           input left_right_border,
           input top_bot_border,
           input [1:0] sprite_cur_pixel [`NUM_SPRITES-1:0],
           input [7:0] sprite_pri,
           input [7:0] sprite_mmc,
           input vic_color sprite_col[0:`NUM_SPRITES - 1],
           input vic_color sprite_mc0,
           input vic_color sprite_mc1,
           output reg is_background_pixel1,
           output vic_color pixel_color3
       );

reg load_pixels;
reg shift_pixels;
reg ismc;
reg is_background_pixel2;

integer n;

// char and pixels delayed before entering shifter
reg [11:0] char_delayed[`DATA_PIXEL_DELAY + 1];
reg [7:0] pixels_delayed[`DATA_PIXEL_DELAY + 1];
reg [2:0] xscroll_delayed;
reg [1:0] sprite_pixels_delayed1[`NUM_SPRITES];

// pixels being shifted and the associated char (for color info)
reg [11:0] char_shifting;
reg [7:0] pixels_shifting;

// Transfer read character pixels and char values into waiting*[0] so they
// are available at the first dot of PHI2
always @(posedge clk_dot4x)
begin
    //if (rst) begin
    //    pixels_delayed[0] <= 8'd0;
    //    char_delayed[0] <= 12'd0;
    //end else
    if (clk_phi == `FALSE && phi_phase_start_15) begin
        pixels_delayed[0] <= pixels_read;
        char_delayed[0] <= char_read;
        xscroll_delayed <= xscroll; // aligns xscroll changes to start of high phase
    end
end

// Now delay these pixels until pixels_delayed[DATA_PIXEL_DELAY]
// is available for loading into shifting pixels by load_pixels
// flag starting with xpos ##0 and fully available until xpos ##7.
// This makes loading pixels on ##0 make the first pixel show
// up on ##1. Note, these delays are relative to xpos_d which is
// xpos with a negative offset.
always @(posedge clk_dot4x)
begin
    //if (rst) begin
    //    for (n = `DATA_PIXEL_DELAY; n > 0; n = n - 1) begin
    //        pixels_delayed[n] <= 8'd0;
    //        char_delayed[n] <= 12'd0;
    //    end
    //end else
    if (dot_rising_0) begin
        for (n = `DATA_PIXEL_DELAY; n > 0; n = n - 1) begin
            pixels_delayed[n] <= pixels_delayed[n-1];
            char_delayed[n] <= char_delayed[n-1];
        end
    end
end

// Delay sprite pixels
always @(posedge clk_dot4x)
begin
    //if (rst) begin
    //    for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
    //        sprite_pixels_delayed1[n][1:0] <= 2'b0;
    //    end
    //end else
    if (dot_rising_0) begin
        for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
            sprite_pixels_delayed1[n][1:0] <= sprite_cur_pixel[n][1:0];
        end
    end
end


always @(*)
    ismc = mcm & (bmm | ecm | char_shifting[11]);

// Use xpos_d here so we can properly delay our pixels
// using char_delayed[]/pixels_delayed[] regs.
always @(*)
    load_pixels = xpos_mod_8 == xscroll_delayed;

always @(posedge clk_dot4x)
    //if (rst) begin
    //    shift_pixels <= `FALSE;
    //end else
    if (dot_rising_0) begin // rising dot
        if (load_pixels)
            shift_pixels <= ~(mcm & (bmm | ecm | char_delayed[`DATA_PIXEL_DELAY][11]));
        else
            shift_pixels <= ismc ? ~shift_pixels : shift_pixels;
    end

always @(posedge clk_dot4x)
    //if (rst) begin
    //    char_shifting <= 12'b0;
    //end else
    if (dot_rising_0) begin
        if (load_pixels)
            char_shifting <= char_delayed[`DATA_PIXEL_DELAY];
    end

// Pixel shifter
always @(posedge clk_dot4x) begin
    if (rst) begin
        pixels_shifting <= 8'b0;
        //is_background_pixel1 <= `FALSE;
    end
    // set is_background_pixel1 here so it is valid on dot tick rise [0]
    // for the currently shifting pixel entering the final output pipeline
    else if (dot_rising_0) begin
        if (load_pixels) begin
            pixels_shifting <= pixels_delayed[`DATA_PIXEL_DELAY];
            is_background_pixel1 <= !pixels_delayed[`DATA_PIXEL_DELAY][7];
        end else if (shift_pixels) begin
            if (ismc) begin
                pixels_shifting <= {pixels_shifting[5:0], 2'b0};
                is_background_pixel1 <= !pixels_shifting[5];
            end else begin
                pixels_shifting <= {pixels_shifting[6:0], 1'b0};
                is_background_pixel1 <= !pixels_shifting[6];
            end
        end
    end
end

// handle display modes
vic_color pixel_color1; // stage 1
always @(posedge clk_dot4x)
begin
    //if (rst) begin
    //    is_background_pixel2 <= `FALSE;
    //    pixel_color1 <= BLACK;
    //end else
    if (dot_rising_0) begin
        // this will bring 2nd in line with delayed sprite pixels 2
        is_background_pixel2 <= is_background_pixel1;
        pixel_color1 <= BLACK;
        case ({ecm, bmm, mcm})
            MODE_STANDARD_CHAR:
                pixel_color1 <= pixels_shifting[7] ? vic_color'(char_shifting[11:8]):b0c;
            MODE_MULTICOLOR_CHAR:
                if (char_shifting[11])
                case (pixels_shifting[7:6])
                    2'b00: pixel_color1 <= b0c;
                    2'b01: pixel_color1 <= b1c;
                    2'b10: pixel_color1 <= b2c;
                    2'b11: pixel_color1 <= vic_color'({1'b0, char_shifting[10:8]});
                endcase
                else
                    pixel_color1 <= pixels_shifting[7] ? vic_color'(char_shifting[11:8]):b0c;
            MODE_STANDARD_BITMAP, MODE_INV_EXTENDED_BG_COLOR_STANDARD_BITMAP:
                pixel_color1 <= pixels_shifting[7] ? vic_color'(char_shifting[7:4]):vic_color'(char_shifting[3:0]);
            MODE_MULTICOLOR_BITMAP, MODE_INV_EXTENDED_BG_COLOR_MULTICOLOR_BITMAP:
            case (pixels_shifting[7:6])
                2'b00: pixel_color1 <= b0c;
                2'b01: pixel_color1 <= vic_color'(char_shifting[7:4]);
                2'b10: pixel_color1 <= vic_color'(char_shifting[3:0]);
                2'b11: pixel_color1 <= vic_color'(char_shifting[11:8]);
            endcase
            MODE_EXTENDED_BG_COLOR:
            case ({pixels_shifting[7], char_shifting[7:6]})
                3'b000: pixel_color1 <= b0c;
                3'b001: pixel_color1 <= b1c;
                3'b010: pixel_color1 <= b2c;
                3'b011: pixel_color1 <= b3c;
                default: pixel_color1 <= vic_color'(char_shifting[11:8]);
            endcase
            MODE_INV_EXTENDED_BG_COLOR_MULTICOLOR_CHAR:
                if (char_shifting[11])
                case (pixels_shifting[7:6])
                    2'b00: pixel_color1 <= b0c;
                    2'b01: pixel_color1 <= b1c;
                    2'b10: pixel_color1 <= b2c;
                    2'b11: pixel_color1 <= vic_color'(char_shifting[11:8]);
                endcase
                else
                case ({pixels_shifting[7], char_shifting[7:6]})
                    3'b000: pixel_color1 <= b0c;
                    3'b001: pixel_color1 <= b1c;
                    3'b010: pixel_color1 <= b2c;
                    3'b011: pixel_color1 <= b3c;
                    default: pixel_color1 <= vic_color'(char_shifting[11:8]);
                endcase
        endcase
    end
end

vic_color pixel_color2; // stage 2
always @(posedge clk_dot4x)
begin
    //if (rst) begin
    //    pixel_color2 = BLACK;
    //end else
    begin
        // illegal modes should have black pixels
        case ({ecm, bmm, mcm})
            MODE_INV_EXTENDED_BG_COLOR_MULTICOLOR_CHAR,
            MODE_INV_EXTENDED_BG_COLOR_STANDARD_BITMAP,
            MODE_INV_EXTENDED_BG_COLOR_MULTICOLOR_BITMAP:
                pixel_color2 = BLACK;
            default: pixel_color2 = pixel_color1;
        endcase
        // sprites overwrite pixels
        // The comparisons of background pixel and sprite pixels must be
        // on the same delay 'schedule' here.
        for (n = `NUM_SPRITES-1; n >= 0; n = n - 1) begin
            if (!sprite_pri[n] || is_background_pixel2) begin
                if (sprite_mmc[n]) begin  // multi-color mode ?
                    if (sprite_pixels_delayed1[n] != 2'b00) begin
                        case(sprite_pixels_delayed1[n])
                            2'b00:  ;
                            2'b01:  pixel_color2 = sprite_mc0;
                            2'b10:  pixel_color2 = sprite_col[n[2:0]];
                            2'b11:  pixel_color2 = sprite_mc1;
                        endcase
                    end
                end else if (sprite_pixels_delayed1[n][1]) begin
                    pixel_color2 = sprite_col[n[2:0]];
                end
            end
            // If a sprite with a lower priority caused a foreground pixel to be overwritten
            // due to its sprite_pri being 0, we must 'reset' the foreground pixel if a higher
            // priority sprite has sprite_pri 1 (Uncensored ski hill).  In other words, a higher
            // priority sprite's desire to leave foreground pixels alone overrides a lower
            // sprite's desire to overwrite it.
            if (sprite_pri[n] && !is_background_pixel2 && sprite_pixels_delayed1[n][1]) begin
                pixel_color2 = pixel_color1;
            end
        end
    end
end

// mask with border - pixel_color3 = stage 3
always @(posedge clk_dot4x)
begin
    //if (rst) begin
    //    pixel_color3 <= BLACK;
    //end else
    begin
        if (left_right_border | top_bot_border)
            pixel_color3 <= ec;
        else
            pixel_color3 <= pixel_color2;
    end
end

endmodule
