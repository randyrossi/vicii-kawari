`timescale 1ns / 1ps

`include "common.vh"

module pixel_sequencer(
           input rst,
           input clk_dot4x,
           input clk_phi,
           input dot_rising_0,
           input dot_rising_1,
           // chosen to make pixels/chars delayed valid when load_pixels rises
           // (when xpos_mod_8 == 0)
           input phi_phase_start_pl,
           input phi_phase_start_dav,
           input phi_phase_start_xscroll_latch,
           input mcm,
           input bmm,
           input ecm,
           input [2:0] xpos_mod_8,
           input idle,
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
           input [7:0] sprite_pri_d,
           input [7:0] sprite_mmc_d,
           input [31:0] sprite_col_o,  // delayed before use
           input [3:0] sprite_mc0,  // delayed before use
           input [3:0] sprite_mc1,  // delayed before use
           input vborder,
           output reg is_background_pixel1,
           output reg stage0,
           output reg stage1,
           output reg [3:0] pixel_color3,
	   input [3:0] active_sprite_d
       );

reg load_pixels;
reg shift_pixels;
reg ismc;
reg is_background_pixel0;
integer n;

wire visible;
assign visible = cycle_num >= 15 && cycle_num <= 55;
wire visible_d;
assign visible_d = cycle_num >= 17 && cycle_num <= 57;

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
reg [7:0] pixels_read_delayed0;
reg [7:0] pixels_read_delayed1;
reg [7:0] pixels_read_delayed;
reg [11:0] char_read_delayed0;
reg [11:0] char_read_delayed1;
reg [11:0] char_read_delayed;

reg [3:0] sprite_col_d1 [`NUM_SPRITES-1:0];
reg [3:0] sprite_col_d2 [`NUM_SPRITES-1:0];
reg [3:0] sprite_mc0_d1;
reg [3:0] sprite_mc0_d2;
reg [3:0] sprite_mc1_d1;
reg [3:0] sprite_mc1_d2;

reg [3:0] b0c_d1;
reg [3:0] b1c_d1;
reg [3:0] b2c_d1;
reg [3:0] b3c_d1;

// pixels being shifted and the associated char (for color info)
reg [11:0] char_shifting;
reg [7:0] pixels_shifting;

// For color splits to work on sprites, we need to delay
// register changes by 2 pixels and to become valid by stage1
always @(posedge clk_dot4x)
begin
    if (stage0) begin
       for (n = `NUM_SPRITES-1; n >= 0; n = n - 1) begin
          sprite_col_d1[n[2:0]] <= sprite_col[n[2:0]];
          sprite_col_d2[n[2:0]] <= sprite_col_d1[n[2:0]];
       end
       b0c_d1 <= b0c;
       b1c_d1 <= b1c;
       b2c_d1 <= b2c;
       b3c_d1 <= b3c;
       sprite_mc0_d1 <= sprite_mc0;
       sprite_mc0_d2 <= sprite_mc0_d1;
       sprite_mc1_d1 <= sprite_mc1;
       sprite_mc1_d2 <= sprite_mc1_d1;
    end
end

// Transfer read character pixels and char values into waiting*[0] so they
// are available at the first dot of PHI2
always @(posedge clk_dot4x)
begin
    if (`XSCROLL_LATCH_PHASE && phi_phase_start_xscroll_latch) begin
        // pick up xscroll only inside visible cycles
        if (visible && !vborder)
           xscroll_delayed <= xscroll;
    end
    // Need to delay pixels to align properly with adjusted xpos
    // value so we don't load pixels too early.  Basically, pixels_read
    // needs to be visible to the sequencer first when xpos_mod_8 == 0
    // which is when load_pixels rises.
    if (phi_phase_start_dav) begin
        pixels_read_delayed0 <= pixels_read;
        pixels_read_delayed1 <= pixels_read_delayed0;

        char_read_delayed0 <= char_read;
        char_read_delayed1 <= char_read_delayed0;
    end
// This was left over from the time when we grabbed
// pixels/chars exacty at pps 0. But now that it
// has been pushed over a bit, we can share this
// logic between sim and non-sim. Leave here in case
// it's useful again.
//`ifndef IS_SIMULATOR
//    if (phi_phase_start_0) begin
//        pixels_read_delayed <= pixels_read_delayed0;
//        char_read_delayed <= char_read_delayed0;
//    end
//`else
    if (!clk_phi && phi_phase_start_pl) begin
        pixels_read_delayed <= pixels_read_delayed1;
        char_read_delayed <= char_read_delayed1;
    end
//`endif
end

always @(*)
    ismc = mcm & (bmm | ecm | char_shifting[11]);

always @(*)
    load_pixels = xpos_mod_8 == xscroll_delayed;

always @(posedge clk_dot4x)
    //if (rst) begin
    //    shift_pixels <= `FALSE;
    //end else
    // Make shift_pixels valid at the beginning of the next pixel.
    if (dot_rising_0) begin
        if (load_pixels)
            shift_pixels <= ~(mcm & (bmm | ecm | char_read_delayed[11]));
        else
            shift_pixels <= ismc ? ~shift_pixels : shift_pixels;
    end

always @(posedge clk_dot4x)
begin
    //if (rst) begin
    //    char_shifting <= 12'b0;
    //end else
    // Grab data into our shift register on the first tick of our pixel.
    if (dot_rising_1) begin
        // We 'work' on several stages of a pixel over the next 3 dot4x
	// ticks. It begins here when we set stage0 high.
        stage0 <= 1'b1;
	if (load_pixels) begin
            if (!vborder && visible_d) begin
                if (!idle) begin
                    char_shifting <= char_read_delayed;
                end else begin
                    char_shifting <= 12'b0;
		end
            end
        end
    end
    // This will happen on the next pixel tick. Clear the stage reg
    // in prep for the next pixel.
    if (stage0)
        stage0 <= 1'b0;
end

// Pixel shifter
always @(posedge clk_dot4x) begin
    if (rst) begin
        pixels_shifting <= 8'b0;
        //is_background_pixel0 <= `FALSE;
    end
    // Grab data into our shift register on the first tick of our pixel.
    // Also keep track of whether this is a background pixe or not.
    else if (dot_rising_1) begin
        if (load_pixels) begin
            if (!vborder && visible_d) begin
               pixels_shifting <= pixels_read_delayed;
               is_background_pixel0 <= !pixels_read_delayed[7];
            end else begin
               pixels_shifting <= 8'b0;
               is_background_pixel0 <= 1'b1;
            end
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

// Handle display modes in stage0
reg [3:0] pixel_color1;
always @(posedge clk_dot4x)
begin
    //if (rst) begin
    //    is_background_pixel1 <= 1'b0;
    //    pixel_color1 <= `BLACK;
    //end else
    if (stage1)
        stage1 <= 1'b0;
    if (stage0) begin
        pixel_color1 <= `BLACK;
        is_background_pixel1 <= is_background_pixel0;
        main_border_stage1 <= main_border;
        stage1 <= 1'b1;
        case ({ecm, bmm, mcm})
            `MODE_STANDARD_CHAR:
                pixel_color1 <= pixels_shifting[7] ? char_shifting[11:8]:b0c_d1;
            `MODE_MULTICOLOR_CHAR:
                if (char_shifting[11])
                case (pixels_shifting[7:6])
                    2'b00: pixel_color1 <= b0c_d1;
		    2'b01: pixel_color1 <= b1c_d1;
		    2'b10: pixel_color1 <= b2c_d1;
		    2'b11: pixel_color1 <= {1'b0, char_shifting[10:8]};
                endcase
		else
                    pixel_color1 <= pixels_shifting[7] ? char_shifting[11:8]:b0c_d1;
            `MODE_STANDARD_BITMAP, `MODE_INV_EXTENDED_BG_COLOR_STANDARD_BITMAP:
                pixel_color1 <= pixels_shifting[7] ? char_shifting[7:4]:char_shifting[3:0];
            `MODE_MULTICOLOR_BITMAP, `MODE_INV_EXTENDED_BG_COLOR_MULTICOLOR_BITMAP:
            case (pixels_shifting[7:6])
                2'b00: pixel_color1 <= b0c_d1;
                2'b01: pixel_color1 <= char_shifting[7:4];
                2'b10: pixel_color1 <= char_shifting[3:0];
                2'b11: pixel_color1 <= char_shifting[11:8];
            endcase
            `MODE_EXTENDED_BG_COLOR:
            case ({pixels_shifting[7], char_shifting[7:6]})
                3'b000: pixel_color1 <= b0c_d1;
                3'b001: pixel_color1 <= b1c_d1;
                3'b010: pixel_color1 <= b2c_d1;
                3'b011: pixel_color1 <= b3c_d1;
                default: pixel_color1 <= char_shifting[11:8];
            endcase
            `MODE_INV_EXTENDED_BG_COLOR_MULTICOLOR_CHAR:
                if (char_shifting[11])
                case (pixels_shifting[7:6])
                    2'b00: pixel_color1 <= b0c_d1;
                    2'b01: pixel_color1 <= b1c_d1;
                    2'b10: pixel_color1 <= b2c_d1;
                    2'b11: pixel_color1 <= char_shifting[11:8];
                endcase
                else
                case ({pixels_shifting[7], char_shifting[7:6]})
                    3'b000: pixel_color1 <= b0c_d1;
                    3'b001: pixel_color1 <= b1c_d1;
                    3'b010: pixel_color1 <= b2c_d1;
                    3'b011: pixel_color1 <= b3c_d1;
                    default: pixel_color1 <= char_shifting[11:8];
                endcase
        endcase
    end
end

// Handle sprite overlay in stage 1
// NOTE: This is also when sprites.v will handle sprite to data collisions
reg [3:0] pixel_color2;
reg main_border_stage2;
always @(posedge clk_dot4x)
begin
    //if (rst) begin
    //    pixel_color2 = `BLACK;
    //end else
    if (stage1) begin
        main_border_stage2 <= main_border_stage1;
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
        // on the same delay 'schedule' here.  Also, the pri, mmc and colors
	// need to be delayed so they split this properly on reg changes.
	if (active_sprite_d[3]) begin
            if (!sprite_pri_d[active_sprite_d[2:0]] || is_background_pixel1) begin
                if (sprite_mmc_d[active_sprite_d[2:0]]) begin  // multi-color mode ?
                        case(sprite_cur_pixel[active_sprite_d[2:0]])
                            2'b00:  ;
                            2'b01:  pixel_color2 = sprite_mc0_d2;
                            2'b10:  pixel_color2 = sprite_col_d2[active_sprite_d[2:0]];
                            2'b11:  pixel_color2 = sprite_mc1_d2;
                        endcase
                end else if (sprite_cur_pixel[active_sprite_d[2:0]][1]) begin
                    pixel_color2 = sprite_col_d2[active_sprite_d[2:0]];
                end
            end
        end
    end
end

// We delay the stage2 output by 1 more pixel
// to 'reach' edge color transitions.

reg[3:0] pixel_color2a;
reg main_border_stage2a;
always @(posedge clk_dot4x)
begin
    if (dot_rising_1) begin
        pixel_color2a <= pixel_color2;
        main_border_stage2a <= main_border_stage2;
    end
end

// Final stage 3. Border mask.
always @(posedge clk_dot4x)
begin
    if (main_border_stage2a)
        pixel_color3 <= ec;
    else
        pixel_color3 <= pixel_color2a;
end

endmodule
