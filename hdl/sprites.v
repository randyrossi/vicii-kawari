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

`timescale 1ns/1ps

`include "common.vh"

// This is the sprite pixel sequencer/collision detection module.
// Timing here is critical and sprites must get activated at
// precicely the right time so that sprite priority register
// changes causing splits happen between pixels 5 & 6. Same
// for the sprite x expansion bits register.
//
// Register changes become valid on PPS[1] after the falling
// edge of PHI. Code that needs sprite_pri or sprite_xe needs
// it valid by pixel 6.  So our sprites can't trigger too early
// or we won't be able to process those sprite splits properly
// (xe/pri).  We also need to have sprite_mmc valid by pixel #7.
//
// PPS[1] corresponds to dot_rising_1 on pixel ticks.
// We can shift sprite pixels to be worked on later but we can't
// move the time sprite_pri/sprite_xe become available
// any earlier.  So our sprite pixels are delayed such that pixels
// 6 & 7 arrive after the falling edge of PHI.  Since sprite_pri
// is needed earliest, other splits like sprite_mmc, mmc colors,
// background colors, etc, can be made to 'land' on the right pixels
// by delaying those changes. See the pixel sequencer for other
// examples.
//
// Also, the pixel sequencer is responsible for overlaying gfx
// pixels with sprite pixels depending on priority.  Any value
// that is computed from the sprite pixel sequencer for a pixel
// must be carried over to the pixel sequencer's 'schedule' by
// suitable delay.  See below for more details.
module sprites(
           input rst,
           input clk_dot4x,
           input clk_phi,
           input [7:0] dbi8,
           input [7:0] last_bus,
           input [3:0] cycle_type,
           input dot_rising_1,
           input phi_phase_start_m2clr,
           input phi_phase_start_1,
           input phi_phase_start_dav,
           input [8:0] xpos, // top bit omitted for comparison to x
           input [6:0] cycle_num,
           input [2:0] cycle_bit,
           input handle_sprite_crunch,
           input [71:0] sprite_x_o,
           input [63:0] sprite_y_o,
           input [7:0] sprite_xe,
           input [7:0] sprite_ye,
           input [7:0] sprite_en,
           input [7:0] sprite_mmc,
           input [7:0] sprite_pri,
           input [2:0] sprite_cnt,
           input [7:0] raster_line, // top bit omitted for comparison to y
           input aec,
           input is_background_pixel,
`ifdef HIRES_MODES
           input hires_enabled,
           input hires_is_background_pixel,
`endif
           input stage0,
           input imbc_clr,
           input immc_clr,
           input [6:0] sprite_dmachk1,
           input [6:0] sprite_dmachk2,
           input [6:0] sprite_yexp_chk,
           input [6:0] sprite_disp_chk,
           input m2m_clr,
           input m2d_clr,
           output reg immc,
           output reg imbc,
           output wire [15:0] sprite_cur_pixel_o,
           output wire [47:0] sprite_mc_o,
           output reg [`NUM_SPRITES - 1:0] sprite_dma,
           output reg [7:0] sprite_m2m,
           output reg [7:0] sprite_m2d,
           output reg [7:0] sprite_mmc_d,
           output reg [7:0] sprite_pri_d,
           output reg [3:0] active_sprite_d
       );

integer n;

// Destinations for flattened inputs that need to be sliced back into an array
wire [8:0] sprite_x[0:`NUM_SPRITES - 1];
wire [7:0] sprite_y[0:`NUM_SPRITES - 1];

// 2D arrays that need to be flattened for output
reg [5:0] sprite_mc[0:`NUM_SPRITES - 1];
reg [1:0] sprite_cur_pixel [`NUM_SPRITES-1:0];

reg [1:0] sprite_cur_pixel1 [`NUM_SPRITES-1:0];
reg [1:0] sprite_cur_pixel2 [`NUM_SPRITES-1:0];
reg [1:0] sprite_cur_pixel3 [`NUM_SPRITES-1:0];
reg [1:0] sprite_cur_pixel4 [`NUM_SPRITES-1:0];
reg [1:0] sprite_cur_pixel5 [`NUM_SPRITES-1:0];
reg [1:0] sprite_cur_pixel6 [`NUM_SPRITES-1:0];

// Other internal regs
reg [5:0] sprite_mcbase[0:`NUM_SPRITES - 1];
reg       sprite_xe_ff[0:`NUM_SPRITES-1];
reg       sprite_ye_ff[0:`NUM_SPRITES-1];
reg [7:0] sprite_active;
reg [7:0] sprite_halt;
reg [7:0] sprite_mmc_ff;
reg [7:0] sprite_display;
reg [31:0] sprite_pixels_shifting [0:`NUM_SPRITES-1];

// Keeps track of mmc for mmc split effect on mmc_ff
reg [7:0] sprite_mmc_next;

// Sprite X is delayed by 2 pixels to split sprites properly
reg [8:0] sprite_x_d[0:`NUM_SPRITES - 1];
reg [8:0] sprite_x_d2[0:`NUM_SPRITES - 1];

// mmc values that 'belong' to corresponding delayed sprite_cur_pixel
// that the pixel sequencer needs to use
reg [7:0] sprite_mmc1;
reg [7:0] sprite_mmc2;
reg [7:0] sprite_mmc3;
reg [7:0] sprite_mmc4;
reg [7:0] sprite_mmc5;
reg [7:0] sprite_mmc6;

// pri values that 'belong' to corresponding delayed sprite_cur_pixel
// that the pixel sequencer needs to use
reg [7:0] sprite_pri1;
reg [7:0] sprite_pri2;
reg [7:0] sprite_pri3;
reg [7:0] sprite_pri4;
reg [7:0] sprite_pri5;
reg [7:0] sprite_pri6;

reg [3:0] active_sprite1;
reg [3:0] active_sprite2;
reg [3:0] active_sprite3;
reg [3:0] active_sprite4;
reg [3:0] active_sprite5;
reg [3:0] active_sprite6;


// Handle un-flattening here
assign sprite_x[0] = sprite_x_o[71:63];
assign sprite_x[1] = sprite_x_o[62:54];
assign sprite_x[2] = sprite_x_o[53:45];
assign sprite_x[3] = sprite_x_o[44:36];
assign sprite_x[4] = sprite_x_o[35:27];
assign sprite_x[5] = sprite_x_o[26:18];
assign sprite_x[6] = sprite_x_o[17:9];
assign sprite_x[7] = sprite_x_o[8:0];

assign sprite_y[0] = sprite_y_o[63:56];
assign sprite_y[1] = sprite_y_o[55:48];
assign sprite_y[2] = sprite_y_o[47:40];
assign sprite_y[3] = sprite_y_o[39:32];
assign sprite_y[4] = sprite_y_o[31:24];
assign sprite_y[5] = sprite_y_o[23:16];
assign sprite_y[6] = sprite_y_o[15:8];
assign sprite_y[7] = sprite_y_o[7:0];

// Handle flattening outputs here
assign sprite_mc_o = {sprite_mc[0], sprite_mc[1], sprite_mc[2], sprite_mc[3], sprite_mc[4], sprite_mc[5], sprite_mc[6], sprite_mc[7]};
assign sprite_cur_pixel_o = {sprite_cur_pixel[0], sprite_cur_pixel[1], sprite_cur_pixel[2], sprite_cur_pixel[3], sprite_cur_pixel[4], sprite_cur_pixel[5], sprite_cur_pixel[6], sprite_cur_pixel[7]};

always @(posedge clk_dot4x)
    if (rst) begin
        for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
            sprite_mc[n] <= 6'd63;
            sprite_mcbase[n] <= 6'd63;
            sprite_ye_ff[n] <= 1;
            //sprite_dma[n] <= 0;
        end
    end else begin
        // update mcbase
        if (clk_phi && phi_phase_start_1 && cycle_num == 15) begin
            for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
                if (sprite_ye_ff[n]) begin
                    sprite_mcbase[n] <= sprite_mc[n];
                    if (sprite_mc[n] == 63) // equiv sprite_mcbase[n] == 63 after assignment above
                        sprite_dma[n] <= 0;
                end
            end
        end
        if (handle_sprite_crunch) begin // happens phi_phase_start[REG_DAV+1]
            // sprite crunch
            for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
                if (!sprite_ye[n] && !sprite_ye_ff[n]) begin
                    // NOTE: When DAV is set to 0, we have to compare the
                    // cycle to 15 even though the register set happened on 14.
                    // That's because we would have just crossed over to the
                    // next cycle by the time handle_sprite_crunch rose.
                    if (cycle_num == `SPRITE_CRUNCH_CYCLE_CHECK) begin
                        sprite_mc[n] <=
                                 (6'h2a & (sprite_mcbase[n] & sprite_mc[n])) |
                                 (6'h15 & (sprite_mcbase[n] | sprite_mc[n])) ;
                    end
                    sprite_ye_ff[n] <= `TRUE;
                end
            end
        end
        // check dma
        // NOTE: VICE does this on high but that is much too late for
        // sprite 0. BA will not go low early enough.
        if (!clk_phi && phi_phase_start_1 &&
                (cycle_num == sprite_dmachk1 || cycle_num == sprite_dmachk2))
        begin
            for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
                if (!sprite_dma[n] && sprite_en[n]
                        && raster_line[7:0] == sprite_y[n]) begin
                    sprite_dma[n] <= 1;
                    sprite_mcbase[n] <= 0;
                    sprite_ye_ff[n] <= 1;
                end
            end
        end
        // check sprite expansion
        if (clk_phi && phi_phase_start_1 && cycle_num == sprite_yexp_chk) begin
            for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
                if (sprite_dma[n] && sprite_ye[n])
                    sprite_ye_ff[n] <= !sprite_ye_ff[n];
            end
        end
        // sprite display check
        if (clk_phi && phi_phase_start_1 && cycle_num == sprite_disp_chk) begin
            for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
                sprite_mc[n] <= sprite_mcbase[n];
                if (sprite_dma[n]) begin
                    if (sprite_en[n] && raster_line[7:0] == sprite_y[n]) begin
                        sprite_display[n] = 1'b1;
                    end
                end else begin
                    sprite_display[n] = 1'b0;
                end
            end
        end

        // Advance sprite byte offset while dma is happening (at end of cycle)
        // Need to increment before cycle_type changes for the next half
        // cycle.
        if (phi_phase_start_1) begin
            case (cycle_type)
                `VIC_HS1,`VIC_LS2,`VIC_HS3:
                    if (sprite_dma[sprite_cnt])
                        sprite_mc[sprite_cnt] <= sprite_mc[sprite_cnt] + 1'b1;
                default: ;
            endcase
        end
    end

// We have to delay spritex by two pixels in order
// to match sprite-x splits properly.
always @(posedge clk_dot4x)
begin
    if (dot_rising_1) begin
        for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
            sprite_x_d[n] <= sprite_x[n];
            sprite_x_d2[n] <= sprite_x_d[n];
        end
    end
end

// Used in the stop bit logic below. Since we pushed our
// sprite pixels out by 2, our cycle type checks would not
// match the adjusted pixel comparison numbers unless
// keep track of the previous cycle.
reg[3:0] prev_cycle_type;
reg[2:0] prev_sprite_cnt;
always @(posedge clk_dot4x)
begin
    // This will keep track of prev cycle/sprite count
    // valid at the same time cycle_type changes.
    if (phi_phase_start_dav) begin
        prev_cycle_type <= cycle_type;
        prev_sprite_cnt <= sprite_cnt;
    end
end

// Sprite pixel sequencer.
// The bits that 'fall off' the shift register get put
// into sprite_cur_pixel1. They are then delayed before being
// interpreted by the pixel sequencer. Sprite collisions
// happen on the delayed pixels.
always @(posedge clk_dot4x)
begin
    if (rst) begin
        for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
            sprite_active[n] = `FALSE;
            sprite_halt[n] = `FALSE;
            sprite_xe_ff[n] = `TRUE;
            sprite_mmc_ff[n] = `TRUE;
        end
    end
    else begin
        // Handle sprite mmc split.
        // Krestage3 - Will fail with "No VIC inside" without this flip flop quirk
        // This is timed to happen on the first tick of pixel 7 which appears
        // as the second pixel in the low phase.  The register set of
        // sprite_mmc_next will be valid for dot_rising_1 because these are
        // blocking assignments.  So when pixel 7 'work' is performed, this
        // is visible.  NOTE: This is hard coded behavior for 6569 where
        // the split happens between pixel 6 & 7.
        if (dot_rising_1 && cycle_bit == `SPRITE_PIXEL_7) begin
            //$display("before cycle %d line %d : %d %d %d",
            //    cycle_num, raster_line, sprite_mmc_ff, sprite_mmc, sprite_mmc_next);
            sprite_mmc_ff = sprite_mmc_ff & ~(sprite_mmc ^ sprite_mmc_next);
            sprite_mmc_next = sprite_mmc;
            //$display("after cycle %d line %d : %d %d %d",
            //    cycle_num, raster_line, sprite_mmc_ff, sprite_mmc, sprite_mmc_next);
        end

        // We activate a sprite pixel when xpos hits sprite_x.
        // We also set things like active and halt bits at this time.
        if (dot_rising_1) begin
            // The sprite pixel shifter will deactivate a sprite
            // or halt the shifter entirely around the cycles that
            // perform dma access. This logic comes from VICE.
            // NOTE: Since we pushed our pixels out by 2 in order to
            // simulate pri/xe splits preperly, we have to use a delayed
            // check on the cycle type for the pixel #'s to make sense here.
            // Deactivate on pixel 2 on 2nd dma cycle
            // Halt on pixel 3 on spr ptr cycle
            // Resume on pixel 7 on 3rd dma cycle
            if (cycle_bit == `SPRITE_PIXEL_2 &&
                    (prev_cycle_type == `VIC_LS2 || prev_cycle_type == `VIC_LPI2)) begin
                sprite_active[prev_sprite_cnt] = `FALSE;
                sprite_cur_pixel1[prev_sprite_cnt] = 0;
            end else if (cycle_bit == `SPRITE_PIXEL_3 &&
                         prev_cycle_type == `VIC_LP) begin
                sprite_halt[prev_sprite_cnt] = `TRUE;
                sprite_pixels_shifting[prev_sprite_cnt] <= 32'b0;
            end else if (cycle_bit == `SPRITE_PIXEL_7 &&
                         (prev_cycle_type == `VIC_HS3 || prev_cycle_type == `VIC_HPI3))
                sprite_halt[prev_sprite_cnt] = `FALSE;

            // When xpos matches sprite_x, turn on the shifter
            // As noted above, we actually trigger the active flag
            // one pixel after the xpos match since this is the
            // final tick of an xpos.
            for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
                if (sprite_display[n] && !sprite_halt[n] &&
                        sprite_x_d2[n] == xpos[8:0]) begin
                    sprite_active[n] = `TRUE;
                    sprite_xe_ff[n] = `TRUE;
                    sprite_mmc_ff[n] = `TRUE;
                end
            end
        end

        // Do the work to produce a sprite pixel in the first tick of xpos.
        // We also keep track of the priority and mmc values at the time cur
        // pixel is created so that those values may enter the same delay
        // pipeline as cur pixel. (The pixel sequencer needs to work on the
        // mmc and pri values that go with the cur pixel for splits to work.)
        if (dot_rising_1) begin
            // Top bit is true if there is an active sprite. Lower 3 bits
            // indicate which sprite number is active.
            active_sprite1 = {4'b0};
            // Shift pixels into sprite_cur_pixel for each sprite.
            // We keep track of which sprite is active for the pixel
            // sequencer when it does its overlap logic.
            for (n = `NUM_SPRITES-1; n >= 0; n = n - 1) begin
                //$display("%d BIT %d SPRITE %d active %d halt %d reg %x pixel %d",raster_line, cycle_bit >= 2 ? cycle_bit -2 : 6 + cycle_bit,n,
                //    sprite_active[n], sprite_halt[n], sprite_pixels_shifting[n], sprite_cur_pixel[n]);
                // Is this sprite active?
                if (sprite_active[n]) begin
                    //$display("SPR %d with a:%d h:%d x:%d xf:%d m:%d mf:%d p:%d BIT=%d", n,
                    //    sprite_active[n], sprite_halt[n], sprite_xe[n],
                    //       sprite_xe_ff[n], sprite_mmc[n], sprite_mmc_ff[n], sprite_pri[n],
                    //          cycle_bit >=2 ? cycle_bit - 2: 6 + cycle_bit);
                    // NOTE: Just like VICE, we use the upper byte of this
                    // 32 bit register to allow the last 8 (or 4 for mmc)
                    // shifting pixels drift in so this !=0 comparison will
                    // make this block keep shifting even though 0's are being
                    // grabbed out of the register.  This keeps our xe_ff in
                    // sync with VICE.
                    if (sprite_pixels_shifting[n] != 0 || sprite_cur_pixel1[n] != 0) begin
                        if (!sprite_halt[n]) begin
                            if (sprite_xe_ff[n]) begin
                                if (sprite_mmc_next[n]) begin
                                    if (sprite_mmc_ff[n]) begin
                                        //$display("SPR %d GOT %d (dbl) FROM %06x",
                                        //    n,sprite_pixels_shifting[n][23:22], sprite_pixels_shifting[n]);
                                        sprite_cur_pixel1[n] = sprite_pixels_shifting[n][23:22];
                                    end
                                    sprite_mmc_ff[n] = !sprite_mmc_ff[n];
                                end else begin
                                    //$display("SPR %d GOT %d (single) FROM %06x",n,
                                    //    {sprite_pixels_shifting[n][23], 1'b0}, sprite_pixels_shifting[n]);
                                    sprite_cur_pixel1[n] = {sprite_pixels_shifting[n][23], 1'b0};
                                end
                                sprite_mmc1[n] <= sprite_mmc_next[n];
                            end
                            sprite_pri1[n] <= sprite_pri[n];
                            if (sprite_xe_ff[n]) begin
                                sprite_pixels_shifting[n] <= {sprite_pixels_shifting[n][30:0], 1'b0};
                            end
                            if (sprite_xe[n])
                                sprite_xe_ff[n] = !sprite_xe_ff[n];
                            else
                                sprite_xe_ff[n] = `TRUE;
                        end

                        // Keep track of active sprite
                        if (sprite_cur_pixel1[n] != 2'b0)
                            active_sprite1 = {1'b1, n[2:0]};
                    end
                    else begin
                        sprite_active[n] = `FALSE;
                    end
                end
            end

// For some reason, EFINIX does not like this delay logic
// in a separate process block.  It 'sees' the cur pixel
// and active_sprite as valid on the same tick which is 
// not how Xilinx behaves.  So this switch is here to
// move this logic to either a separate process block as
// originally coded for Xilinx or to do it here that seems
// to work for Efinix Trion. *sigh*
`ifdef EFINIX
            // Now delay sprite stuff by 6 pixels so that these
            // signals are valid by stage0 in the pixel sequencer.
            // This ensures things like priority splits happen when
            // the current pixel is actually overlayed in the gfx
            // pipeline. Same for mmc splits.
            for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
               sprite_cur_pixel2[n] <= sprite_cur_pixel1[n];
               sprite_cur_pixel3[n] <= sprite_cur_pixel2[n];
               sprite_cur_pixel4[n] <= sprite_cur_pixel3[n];
               sprite_cur_pixel5[n] <= sprite_cur_pixel4[n];
               sprite_cur_pixel6[n] <= sprite_cur_pixel5[n];
               sprite_cur_pixel[n] <= sprite_cur_pixel6[n];
            end

            sprite_mmc2 <= sprite_mmc1;
            sprite_mmc3 <= sprite_mmc2;
            sprite_mmc4 <= sprite_mmc3;
            sprite_mmc5 <= sprite_mmc4;
            sprite_mmc6 <= sprite_mmc5;
            sprite_mmc_d <= sprite_mmc6;

            sprite_pri2 <= sprite_pri1;
            sprite_pri3 <= sprite_pri2;
            sprite_pri4 <= sprite_pri3;
            sprite_pri5 <= sprite_pri4;
            sprite_pri6 <= sprite_pri5;
            sprite_pri_d <= sprite_pri6;

            active_sprite2 <= active_sprite1;
            active_sprite3 <= active_sprite2;
            active_sprite4 <= active_sprite3;
            active_sprite5 <= active_sprite4;
            active_sprite6 <= active_sprite5;
            active_sprite_d <= active_sprite6;
`endif // EFINIX

        end

        // s-access - This must be done here instead of bus_access.v because
        // this is where the shifting logic resides.  NOTE: On
        // spriteenable2.prg test, sprite 0's first byte is accessed before
        // AEC had a chance to remain LOW due to d015 futzing just before the
        // fetch cycle.  When AEC is low, shift the last bus value into
        // the register which is set from registers.v. This condition never
        // overlaps with dot_rising_1 above.
        if (phi_phase_start_dav) begin
            case (cycle_type)
                `VIC_HS1, `VIC_LS2, `VIC_HS3:
                   if (!aec)
                       sprite_pixels_shifting[sprite_cnt] <=
                           {sprite_pixels_shifting[sprite_cnt][23:0], dbi8[7:0]};
                   else
                       sprite_pixels_shifting[sprite_cnt] <=
                           {sprite_pixels_shifting[sprite_cnt][23:0], last_bus};
                // Apparently, the VIC always reads into sprite registers even
                // when the cycle is idle. Without this, errata by emulamers
                // part 3 does not work.
                `VIC_LPI2, `VIC_HPI1, `VIC_HPI3:
                    sprite_pixels_shifting[sprite_cnt] <=
                        {sprite_pixels_shifting[sprite_cnt][23:0], dbi8[7:0]};
                default: ;
            endcase
        end
    end
end

`ifndef EFINIX
always @(posedge clk_dot4x)
begin
        if (dot_rising_1) begin
            // Now delay sprite stuff by 6 pixels so that these
            // signals are valid by stage0 in the pixel sequencer.
            // This ensures things like priority splits happen when
            // the current pixel is actually overlayed in the gfx
            // pipeline. Same for mmc splits.
            for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
               sprite_cur_pixel2[n] <= sprite_cur_pixel1[n];
               sprite_cur_pixel3[n] <= sprite_cur_pixel2[n];
               sprite_cur_pixel4[n] <= sprite_cur_pixel3[n];
               sprite_cur_pixel5[n] <= sprite_cur_pixel4[n];
               sprite_cur_pixel6[n] <= sprite_cur_pixel5[n];
               sprite_cur_pixel[n] <= sprite_cur_pixel6[n];
            end

            sprite_mmc2 <= sprite_mmc1;
            sprite_mmc3 <= sprite_mmc2;
            sprite_mmc4 <= sprite_mmc3;
            sprite_mmc5 <= sprite_mmc4;
            sprite_mmc6 <= sprite_mmc5;
            sprite_mmc_d <= sprite_mmc6;

            sprite_pri2 <= sprite_pri1;
            sprite_pri3 <= sprite_pri2;
            sprite_pri4 <= sprite_pri3;
            sprite_pri5 <= sprite_pri4;
            sprite_pri6 <= sprite_pri5;
            sprite_pri_d <= sprite_pri6;

            active_sprite2 <= active_sprite1;
            active_sprite3 <= active_sprite2;
            active_sprite4 <= active_sprite3;
            active_sprite5 <= active_sprite4;
            active_sprite6 <= active_sprite5;
            active_sprite_d <= active_sprite6;
        end
end
`endif

// Sprite to sprite collision logic (m2m)
// TODO: This makes sprite-sprite collisions happen on the DELAYED
// sprite pixels. Find out if this is correct.
reg [`NUM_SPRITES-1:0] collision;
always @*
    for (n = 0; n < `NUM_SPRITES; n = n + 1)
        collision[n] = sprite_mmc_d[n] ? (sprite_cur_pixel[n][1] | sprite_cur_pixel[n][0]) : sprite_cur_pixel[n][1];

reg m2m_triggered;
always @(posedge clk_dot4x)
    if (rst) begin
        sprite_m2m <= 8'b0;
        m2m_triggered <= `FALSE;
        immc <= `FALSE;
    end else begin
        if (immc_clr) begin
            immc <= `FALSE;
        end
        if (phi_phase_start_m2clr && `M2CLR_PHASE) begin
            // must use before m2m_clr is reset in registers
            if (m2m_clr) begin
                sprite_m2m[7:0] <= 8'd0;
                m2m_triggered <= `FALSE;
            end
        end
        case(collision)
            8'b00000000,
            8'b00000001,
            8'b00000010,
            8'b00000100,
            8'b00001000,
            8'b00010000,
            8'b00100000,
            8'b01000000,
            8'b10000000:
                ;
            default:
            begin
                sprite_m2m <= sprite_m2m | collision;
                if (!m2m_triggered) begin
                    m2m_triggered <= `TRUE;
                    immc <= `TRUE;
                end
            end
        endcase
    end

// Sprite to data collision logic (m2d)
reg m2d_triggered;

always @(posedge clk_dot4x)
    if (rst) begin
        sprite_m2d <= 8'b0;
        m2d_triggered <= `FALSE;
        imbc <= `FALSE;
    end
    else begin
        if (imbc_clr) begin
            imbc <= `FALSE;
        end
        if (phi_phase_start_m2clr && `M2CLR_PHASE) begin
            // must use before m2d_clr is reset in registers
            if (m2d_clr) begin
                sprite_m2d <= 8'd0;
                m2d_triggered <= `FALSE;
            end
        end
        // This triggers at the same time the sprite stage of the pixel
        // sequencer works.  So sprite to data collisions happen on the
        // delayed sprite pixels that overwrite any gfx pixels.
        if (stage0) begin
            for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
                if (((sprite_mmc_d[n] && sprite_cur_pixel[n] != 0) || // multicolor
                        (!sprite_mmc_d[n] && sprite_cur_pixel[n][1] != 0)) & // non multicolor
`ifdef HIRES_MODES
                        ((!hires_enabled && !is_background_pixel) || (hires_enabled && !hires_is_background_pixel))
`else
                        !is_background_pixel
`endif
                        ) begin
                    sprite_m2d[n] <= `TRUE;
                    if (!m2d_triggered) begin
                        m2d_triggered <= `TRUE;
                        imbc <= `TRUE;
                    end
                end
            end
        end
    end

endmodule
