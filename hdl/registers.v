`timescale 1ns / 1ps

`include "common.vh"

module registers(
           input rst,
           input clk_dot4x,
           input clk_phi,
           input phi_phase_start_dav_plus_2,
           input phi_phase_start_dav_plus_1,
           input phi_phase_start_dav,
           input ras,
           input ce,
           input rw,
           input aec,
           input [5:0] adi,
           input [7:0] dbi,
           input [8:0] raster_line,
           input irq,
           input ilp,
           input immc,
           input imbc,
           input irst,
           input [7:0] sprite_m2m,
           input [7:0] sprite_m2d,
           input [7:0] lpx,
           input [7:0] lpy,

           output reg [3:0] ec,
           output reg [3:0] b0c,
           output reg [3:0] b1c,
           output reg [3:0] b2c,
           output reg [3:0] b3c,
           output reg [2:0] xscroll,
           output reg [2:0] yscroll,
           output reg csel,
           output reg rsel,
           output reg den,
           output reg bmm,
           output reg ecm,
           output reg mcm,
           output reg irst_clr,
           output reg imbc_clr,
           output reg immc_clr,
           output reg ilp_clr,
           output reg [8:0] raster_irq_compare,
           output reg [7:0] sprite_en,
           output reg [7:0] sprite_xe,
           output reg [7:0] sprite_ye,
           output reg [7:0] sprite_pri,
           output reg [7:0] sprite_mmc,
           output reg [3:0] sprite_mc0,
           output reg [3:0] sprite_mc1,
           output [71:0] sprite_x_o,
           output [63:0] sprite_y_o,
           output [31:0] sprite_col_o,
           output reg m2m_clr,
           output reg m2d_clr,
           output reg handle_sprite_crunch,
           output reg [7:0] dbo,
           output reg [2:0] cb,
           output reg [3:0] vm,
           output reg elp,
           output reg emmc,
           output reg embc,
           output reg erst,
	   // pixel_color4, which is the final pixel color index, is used
	   // to address color register ram prefixed with the palette select
	   // bit, so 5 bit address
	   input [3:0] pixel_color4,
	   input half_bright,
	   input active,
	   output reg[3:0] red,
	   output reg[3:0] green,
	   output reg[3:0] blue,

	   // When we poke our custom regs that change config,
	   // we set the new config byte and raise new data flag
	   // for the MCU to pick up over serial.
	   output reg [7:0] tx_data_4x,
	   output reg tx_new_data_4x,

	   // These are the config bits coming from the MCU. They
	   // represent what the MCU wants things to be, not what
	   // they are presently in the FPGA.  They are latched
	   // into 'current' regs into reset block.
	   input [1:0] chip,
	   input is_15khz,
	   input is_hide_raster_lines,

	   // We export this so it can take effect immediately
	   output reg show_raster_lines,

	   // --- BEGIN EXTENSIONS ---
           input [14:0] video_ram_addr_b,
           output [7:0] video_ram_data_out_b,
           output reg [2:0] hires_char_pixel_base,
           output reg [3:0] hires_matrix_base,
           output reg [3:0] hires_color_base,
           output reg hires_enabled,
           output reg [1:0] hires_mode
	   // --- END EXTENSIONS ---
       );

// 2D arrays that need to be flattened for output
reg [8:0] sprite_x[0:`NUM_SPRITES - 1];
reg [7:0] sprite_y[0:`NUM_SPRITES - 1];
reg [3:0] sprite_col[0:`NUM_SPRITES - 1];

integer n;

// Handle flattening here
assign sprite_x_o = {sprite_x[0], sprite_x[1], sprite_x[2], sprite_x[3], sprite_x[4], sprite_x[5], sprite_x[6], sprite_x[7]};
assign sprite_y_o = {sprite_y[0], sprite_y[1], sprite_y[2], sprite_y[3], sprite_y[4], sprite_y[5], sprite_y[6], sprite_y[7]};
assign sprite_col_o = {sprite_col[0], sprite_col[1], sprite_col[2], sprite_col[3], sprite_col[4], sprite_col[5], sprite_col[6],sprite_col[7]};

reg res;

// Register Read/Write
reg [5:0] addr_latched;
reg addr_latch_done;
reg read_done;

// --- BEGIN EXTENSIONS ----
reg [1:0] extra_regs_activation_ctr;
reg extra_regs_activated;

// Flags to govern read accesses causing auto inc/dec
reg video_ram_r;
reg video_ram_r2;
reg auto_ram_sel;
reg color_regs_r;
reg color_regs_r2;
reg [1:0] color_regs_r_nibble;
reg [1:0] color_regs_wr_nibble;

reg palette_select;
reg [7:0] video_ram_flags;

// Port A used for CPU access
reg [14:0] video_ram_addr_a;
reg video_ram_wr_a;
reg [7:0] video_ram_hi_1;
reg [7:0] video_ram_lo_1;
reg [7:0] video_ram_idx_1;
reg [7:0] video_ram_hi_2;
reg [7:0] video_ram_lo_2;
reg [7:0] video_ram_idx_2;
reg [7:0] video_ram_data_in_a;
wire [7:0] video_ram_data_out_a;

// TODO : Port B will be used for video access

// For CPU register read/write to color regs
reg [4:0] color_regs_addr_a;
reg color_regs_wr_a;
reg color_regs_pre_wr_a;
reg [3:0] color_regs_wr_value;
reg [15:0] color_regs_data_in_a;
wire [15:0] color_regs_data_out_a;
wire [15:0] color_regs_data_out_b;

// Auto increment/decrement of extra reg addr should happen on reads/writes
// to the extra reg data port.  Some CPU instructions result in a single
// read or write.  However, some CPU instructions address the
// memory location over 2 cycles, once for a read and then again for a write.
// We defer read inc/dec until the following cycle in case it is immediately
// followed by a write. This ensures increment happens after the CPU
// instruction is complete.

// We have enough block ram on the Mojo's Spartan6 for one bank of 64k. But
// we're going to limit ourselves to 32k for video ram and leave another 32k
// for other purposes. If using a different FPGA, the address constructed here
// could add bank select lines here.
VIDEO_RAM video_ram(clk_dot4x,
                    video_ram_wr_a, // CPU can read/write
                    video_ram_addr_a,
                    video_ram_data_in_a,
                    video_ram_data_out_a,
                    1'b0,          // Video can only read
                    video_ram_addr_b,
                    8'b0,          // VIdeo can only read
                    video_ram_data_out_b
                    );

COLOR_REGS color_regs(clk_dot4x,
                    color_regs_wr_a,
                    color_regs_addr_a,
                    color_regs_data_in_a,
                    color_regs_data_out_a,
                    1'b0,
                    { palette_select, pixel_color4},
                    16'b0,
                    color_regs_data_out_b
                    );

// --- END EXTENSIONS ----

reg [1:0] last_chip;
reg last_is_15khz;
reg [1:0] tx_new_data_sr;

// Keep tx new data flag high for 2 ticks
always @(posedge clk_dot4x)
begin
   tx_new_data_4x <= tx_new_data_sr[1];
end

always @(posedge clk_dot4x)
    if (rst) begin
        //ec <= BLACK;
        //b0c <= BLACK;
        //b1c <= BLACK;
        //b2c <= BLACK;
        //b3c <= BLACK;
        //xscroll <= 3'd0;
        //yscroll <= 3'd3;
        //csel <= `FALSE;
        //rsel <= `FALSE;
        //den <= `TRUE;
        //bmm <= `FALSE;
        //ecm <= `FALSE;
        //res <= `FALSE;
        //mcm <= `FALSE;
        irst_clr <= `FALSE;
        imbc_clr <= `FALSE;
        immc_clr <= `FALSE;
        ilp_clr <= `FALSE;
        //raster_irq_compare <= 9'b0;
        //sprite_en <= 8'b0;
        //sprite_xe <= 8'b0;
        //sprite_ye <= 8'b0;
        //sprite_pri <= 8'b0;
        //sprite_mmc <= 8'b0;
        //sprite_mc0 <= BLACK;
        //sprite_mc1 <= BLACK;
        //for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
        //    sprite_x[n] <= 9'b0;
        //    sprite_y[n] <= 8'b0;
        //    sprite_col[n] <= BLACK;
        // end
        //m2m_clr <= `FALSE;
        //m2d_clr <= `FALSE;
        erst <= `FALSE;
        embc <= `FALSE;
        emmc <= `FALSE;
        elp <= `FALSE;
        //dbo[7:0] <= 8'd0;
        //handle_sprite_crunch <= `FALSE;

        // --- BEGIN EXTENSIONS ----
        extra_regs_activation_ctr <= 2'b0;

	// Latch these config bits during reset
	show_raster_lines <= ~is_hide_raster_lines;
	last_chip <= chip;
	last_is_15khz <= is_15khz;
`ifdef IS_SIMULATOR
        extra_regs_activated <= 0'b1;
        video_ram_flags <= 8'b0;

	`ifdef HIRES_TEXT
	// Test mode 0 : Text
        hires_enabled <= 1'b1;
	hires_mode <= 2'b00;
	// char pixels @0000(4K)
        hires_char_pixel_base <= 3'b0;
	// color table @1000(2K)
        hires_color_base <= 4'b10;
	// matrix @1800(2K)
        hires_matrix_base <= 4'b11;
	`endif
	`ifdef HIRES_BITMAP1
        hires_enabled <= 1'b1;
	hires_mode <= 2'b01;
        hires_char_pixel_base <= 3'b0; // ignored
	// pixels @0000(16k)
        hires_matrix_base <= 4'b0000;
	// color table @8000(2K)
        hires_color_base <= 4'b1000;
	`endif
	`ifdef HIRES_BITMAP2
        hires_enabled <= 1'b1;
	hires_mode <= 2'b10;
        hires_char_pixel_base <= 3'b0; // ignored
        hires_matrix_base <= 4'b0000; // ignored
        hires_color_base <= 4'b0000; // ignored
	`endif
	`ifdef HIRES_BITMAP3
        hires_enabled <= 1'b1;
	hires_mode <= 2'b11;
        hires_char_pixel_base <= 3'b0; // ignored
        hires_matrix_base <= 4'b0000; // ignored
        hires_color_base <= 4'b0000; // ignored
	`endif
`else
        extra_regs_activated <= 1'b0;
`endif
        // --- END EXTENSIONS ----

    end else
    begin
        tx_new_data_sr <= {tx_new_data_sr[0], 1'b0};

        if (phi_phase_start_dav_plus_1) begin
            if (!clk_phi) begin
                // always clear these immediately after they may
                // have been used. This should be DAV + 1
                irst_clr <= `FALSE;
                imbc_clr <= `FALSE;
                immc_clr <= `FALSE;
                ilp_clr <= `FALSE;
                m2m_clr <= `FALSE;
                m2d_clr <= `FALSE;
            end

            addr_latch_done <= `FALSE;
            read_done <= `FALSE;
            // clear sprite crunch immediately after it may
            // have been used
            handle_sprite_crunch <= `FALSE;
        end
        if (!ras && clk_phi && !addr_latch_done) begin
            // Make sure we 'pretend' we can only see 6 address bits unless
            // extra regs are activated so 64 reg space repeats as expected.
            addr_latched <= adi[5:0];
            addr_latch_done <= `TRUE;
        end
        if (aec && !ce && addr_latch_done) begin
            // READ from register
            // For registers that clear collisions, we do it on [dav].
            // Otherwise, we'd do it way too early if we did it at the
            // same time we assert dbo in the block below.  VICE sync
            // complains it is too early.
            if (rw && phi_phase_start_dav) begin
                case (addr_latched[5:0])
                    /* 0x1e */ `REG_SPRITE_2_SPRITE_COLLISION: begin
                        // reading this register clears the value
                        m2m_clr <= 1;
                    end
                    /* 0x1f */ `REG_SPRITE_2_DATA_COLLISION: begin
                        // reading this register clears the value
                        m2d_clr <= 1;
                    end
                    default: ;
                endcase
            end
            if (rw && !read_done) begin
                read_done <= `TRUE;
                case (addr_latched[5:0])
                    /* 0x00 */ `REG_SPRITE_X_0:
                        dbo[7:0] <= sprite_x[0][7:0];
                    /* 0x02 */ `REG_SPRITE_X_1:
                        dbo[7:0] <= sprite_x[1][7:0];
                    /* 0x04 */ `REG_SPRITE_X_2:
                        dbo[7:0] <= sprite_x[2][7:0];
                    /* 0x06 */ `REG_SPRITE_X_3:
                        dbo[7:0] <= sprite_x[3][7:0];
                    /* 0x08 */ `REG_SPRITE_X_4:
                        dbo[7:0] <= sprite_x[4][7:0];
                    /* 0x0a */ `REG_SPRITE_X_5:
                        dbo[7:0] <= sprite_x[5][7:0];
                    /* 0x0c */ `REG_SPRITE_X_6:
                        dbo[7:0] <= sprite_x[6][7:0];
                    /* 0x0e */ `REG_SPRITE_X_7:
                        dbo[7:0] <= sprite_x[7][7:0];
                    /* 0x01 */ `REG_SPRITE_Y_0:
                        dbo[7:0] <= sprite_y[0];
                    /* 0x03 */ `REG_SPRITE_Y_1:
                        dbo[7:0] <= sprite_y[1];
                    /* 0x05 */ `REG_SPRITE_Y_2:
                        dbo[7:0] <= sprite_y[2];
                    /* 0x07 */ `REG_SPRITE_Y_3:
                        dbo[7:0] <= sprite_y[3];
                    /* 0x09 */ `REG_SPRITE_Y_4:
                        dbo[7:0] <= sprite_y[4];
                    /* 0x0b */ `REG_SPRITE_Y_5:
                        dbo[7:0] <= sprite_y[5];
                    /* 0x0d */ `REG_SPRITE_Y_6:
                        dbo[7:0] <= sprite_y[6];
                    /* 0x0f */ `REG_SPRITE_Y_7:
                        dbo[7:0] <= sprite_y[7];
                    /* 0x10 */ `REG_SPRITE_X_BIT_8:
                        dbo[7:0] <= {sprite_x[7][8],
                                     sprite_x[6][8],
                                     sprite_x[5][8],
                                     sprite_x[4][8],
                                     sprite_x[3][8],
                                     sprite_x[2][8],
                                     sprite_x[1][8],
                                     sprite_x[0][8]};
                    /* 0x11 */ `REG_SCREEN_CONTROL_1: begin
                        dbo[2:0] <= yscroll;
                        dbo[3] <= rsel;
                        dbo[4] <= den;
                        dbo[5] <= bmm;
                        dbo[6] <= ecm;
                        dbo[7] <= raster_line[8];
                    end
                    /* 0x12 */ `REG_RASTER_LINE: dbo[7:0] <= raster_line[7:0];
                    /* 0x13 */ `REG_LIGHT_PEN_X: dbo[7:0] <= lpx;
                    /* 0x14 */ `REG_LIGHT_PEN_Y: dbo[7:0] <= lpy;
                    /* 0x15 */ `REG_SPRITE_ENABLE: dbo[7:0] <= sprite_en;
                    /* 0x16 */ `REG_SCREEN_CONTROL_2:
                        dbo[7:0] <= {2'b11, res, mcm, csel, xscroll};
                    /* 0x17 */ `REG_SPRITE_EXPAND_Y:
                        dbo[7:0] <= sprite_ye;
                    /* 0x18 */ `REG_MEMORY_SETUP: begin
                        dbo[0] <= 1'b1;
                        dbo[3:1] <= cb[2:0];
                        dbo[7:4] <= vm[3:0];
                    end
                    // NOTE: Our irq is inverted already
                    /* 0x19 */ `REG_INTERRUPT_STATUS:
                        dbo[7:0] <= {irq, 3'b111, ilp, immc, imbc, irst};
                    /* 0x1a */ `REG_INTERRUPT_CONTROL:
                        dbo[7:0] <= {4'b1111, elp, emmc, embc, erst};
                    /* 0x1b */ `REG_SPRITE_PRIORITY:
                        dbo[7:0] <= sprite_pri;
                    /* 0x1c */ `REG_SPRITE_MULTICOLOR_MODE:
                        dbo[7:0] <= sprite_mmc;
                    /* 0x1d */ `REG_SPRITE_EXPAND_X:
                        dbo[7:0] <= sprite_xe;
                    /* 0x1e */ `REG_SPRITE_2_SPRITE_COLLISION:
                        dbo[7:0] <= sprite_m2m;
                    /* 0x1f */ `REG_SPRITE_2_DATA_COLLISION:
                        dbo[7:0] <= sprite_m2d;
                    /* 0x20 */ `REG_BORDER_COLOR:
                        dbo[7:0] <= {4'b1111, ec};
                    /* 0x21 */ `REG_BACKGROUND_COLOR_0:
                        dbo[7:0] <= {4'b1111, b0c};
                    /* 0x22 */ `REG_BACKGROUND_COLOR_1:
                        dbo[7:0] <= {4'b1111, b1c};
                    /* 0x23 */ `REG_BACKGROUND_COLOR_2:
                        dbo[7:0] <= {4'b1111, b2c};
                    /* 0x24 */ `REG_BACKGROUND_COLOR_3:
                        dbo[7:0] <= {4'b1111, b3c};
                    /* 0x25 */ `REG_SPRITE_MULTI_COLOR_0:
                        dbo[7:0] <= {4'b1111, sprite_mc0};
                    /* 0x26 */ `REG_SPRITE_MULTI_COLOR_1:
                        dbo[7:0] <= {4'b1111, sprite_mc1};
                    /* 0x27 */ `REG_SPRITE_COLOR_0:
                        dbo[7:0] <= {4'b1111, sprite_col[0]};
                    /* 0x28 */ `REG_SPRITE_COLOR_1:
                        dbo[7:0] <= {4'b1111, sprite_col[1]};
                    /* 0x29 */ `REG_SPRITE_COLOR_2:
                        dbo[7:0] <= {4'b1111, sprite_col[2]};
                    /* 0x2a */ `REG_SPRITE_COLOR_3:
                        dbo[7:0] <= {4'b1111, sprite_col[3]};
                    /* 0x2b */ `REG_SPRITE_COLOR_4:
                        dbo[7:0] <= {4'b1111, sprite_col[4]};
                    /* 0x2c */ `REG_SPRITE_COLOR_5:
                        dbo[7:0] <= {4'b1111, sprite_col[5]};
                    /* 0x2d */ `REG_SPRITE_COLOR_6:
                        dbo[7:0] <= {4'b1111, sprite_col[6]};
                    /* 0x2e */ `REG_SPRITE_COLOR_7:
                        dbo[7:0] <= {4'b1111, sprite_col[7]};

                    // --- BEGIN EXTENSIONS ----

                    `VIDEO_MEM_1_IDX:
                        if (extra_regs_activated)
                           dbo[7:0] <= video_ram_idx_1;
                        else
                           dbo[7:0] <= 8'hFF;
                    `VIDEO_MEM_2_IDX:
                        if (extra_regs_activated)
                           dbo[7:0] <= video_ram_idx_2;
                        else
                           dbo[7:0] <= 8'hFF;
                    `VIDEO_MODE1:
                        if (extra_regs_activated)
                           dbo[7:0] <= { 1'b0,
			              hires_mode,
				      hires_enabled,
				      palette_select,
				      hires_char_pixel_base };
                        else
                           dbo[7:0] <= 8'hFF;
                    `VIDEO_MODE2:
                        if (extra_regs_activated)
                           dbo[7:0] <= { hires_color_base, hires_matrix_base };
                        else
                           dbo[7:0] <= 8'hFF;
                    `VIDEO_MEM_1_HI:
                        if (extra_regs_activated)
                           dbo[7:0] <= video_ram_hi_1;
                        else
                           dbo[7:0] <= 8'hFF;
                    `VIDEO_MEM_1_LO:
                        if (extra_regs_activated)
                           dbo[7:0] <= video_ram_lo_1;
                        else
                           dbo[7:0] <= 8'hFF;
                    `VIDEO_MEM_1_VAL:
                        if (extra_regs_activated) begin
                          // reg overlay or video mem
                          auto_ram_sel <= 0;
                          read_ram(
                           .overlay(video_ram_flags[5]),
                           .ram_lo(video_ram_lo_1),
                           .ram_hi(video_ram_hi_1),
                           .ram_idx(video_ram_idx_1));
                        end else
                          dbo[7:0] <= 8'hFF;
                    `VIDEO_MEM_2_HI:
                        if (extra_regs_activated)
                          dbo[7:0] <= video_ram_hi_2;
                        else
                           dbo[7:0] <= 8'hFF;
                    `VIDEO_MEM_2_LO:
                        if (extra_regs_activated)
                          dbo[7:0] <= video_ram_lo_2;
                        else
                           dbo[7:0] <= 8'hFF;
                    `VIDEO_MEM_2_VAL:
                        if (extra_regs_activated) begin
                          // reg overlay or video mem
                          auto_ram_sel <= 1;
                          read_ram(
                           .overlay(video_ram_flags[5]),
                           .ram_lo(video_ram_lo_2),
                           .ram_hi(video_ram_hi_2),
                           .ram_idx(video_ram_idx_2));
                        end else
                          dbo[7:0] <= 8'hFF;
                    /* 0x3F */ `VIDEO_MEM_FLAGS:
                        if (extra_regs_activated)
                           dbo[7:0] <= video_ram_flags;
                        else
                           dbo[7:0] <= 8'hFF;

                    // --- END EXTENSIONS ----

                    default:
                        dbo[7:0] <= 8'hFF;
                endcase
            end
            // WRITE to register
            else if (!rw && phi_phase_start_dav) begin
                case (addr_latched[5:0])
                    /* 0x00 */ `REG_SPRITE_X_0:
                        sprite_x[0][7:0] <= dbi[7:0];
                    /* 0x02 */ `REG_SPRITE_X_1:
                        sprite_x[1][7:0] <= dbi[7:0];
                    /* 0x04 */ `REG_SPRITE_X_2:
                        sprite_x[2][7:0] <= dbi[7:0];
                    /* 0x06 */ `REG_SPRITE_X_3:
                        sprite_x[3][7:0] <= dbi[7:0];
                    /* 0x08 */ `REG_SPRITE_X_4:
                        sprite_x[4][7:0] <= dbi[7:0];
                    /* 0x0a */ `REG_SPRITE_X_5:
                        sprite_x[5][7:0] <= dbi[7:0];
                    /* 0x0c */ `REG_SPRITE_X_6:
                        sprite_x[6][7:0] <= dbi[7:0];
                    /* 0x0e */ `REG_SPRITE_X_7:
                        sprite_x[7][7:0] <= dbi[7:0];
                    /* 0x01 */ `REG_SPRITE_Y_0:
                        sprite_y[0] <= dbi[7:0];
                    /* 0x03 */ `REG_SPRITE_Y_1:
                        sprite_y[1] <= dbi[7:0];
                    /* 0x05 */ `REG_SPRITE_Y_2:
                        sprite_y[2] <= dbi[7:0];
                    /* 0x07 */ `REG_SPRITE_Y_3:
                        sprite_y[3] <= dbi[7:0];
                    /* 0x09 */ `REG_SPRITE_Y_4:
                        sprite_y[4] <= dbi[7:0];
                    /* 0x0b */ `REG_SPRITE_Y_5:
                        sprite_y[5] <= dbi[7:0];
                    /* 0x0d */ `REG_SPRITE_Y_6:
                        sprite_y[6] <= dbi[7:0];
                    /* 0x0f */ `REG_SPRITE_Y_7:
                        sprite_y[7] <= dbi[7:0];
                    /* 0x10 */ `REG_SPRITE_X_BIT_8: begin
                        sprite_x[7][8] <= dbi[7];
                        sprite_x[6][8] <= dbi[6];
                        sprite_x[5][8] <= dbi[5];
                        sprite_x[4][8] <= dbi[4];
                        sprite_x[3][8] <= dbi[3];
                        sprite_x[2][8] <= dbi[2];
                        sprite_x[1][8] <= dbi[1];
                        sprite_x[0][8] <= dbi[0];
                    end
                    /* 0x11 */ `REG_SCREEN_CONTROL_1: begin
                        yscroll <= dbi[2:0];
                        rsel <= dbi[3];
                        den <= dbi[4];
                        bmm <= dbi[5];
                        ecm <= dbi[6];
                        raster_irq_compare[8] <= dbi[7];
                    end
                    /* 0x12 */ `REG_RASTER_LINE: raster_irq_compare[7:0] <= dbi[7:0];
                    /* 0x15 */ `REG_SPRITE_ENABLE: sprite_en <= dbi[7:0];
                    /* 0x16 */ `REG_SCREEN_CONTROL_2: begin
                        xscroll <= dbi[2:0];
                        csel <= dbi[3];
                        mcm <= dbi[4];
                        res <= dbi[5];
                    end
                    /* 0x17 */ `REG_SPRITE_EXPAND_Y: begin
                        // must be handled before end of phase (before reset)
                        handle_sprite_crunch <= `TRUE;
                        sprite_ye <= dbi[7:0];
                    end
                    /* 0x18 */ `REG_MEMORY_SETUP: begin
                        cb[2:0] <= dbi[3:1];
                        vm[3:0] <= dbi[7:4];
                    end
                    /* 0x19 */ `REG_INTERRUPT_STATUS: begin
                        irst_clr <= dbi[0];
                        imbc_clr <= dbi[1];
                        immc_clr <= dbi[2];
                        ilp_clr <= dbi[3];
                    end
                    /* 0x1a */ `REG_INTERRUPT_CONTROL: begin
                        erst <= dbi[0];
                        embc <= dbi[1];
                        emmc <= dbi[2];
                        elp <= dbi[3];
                    end
                    /* 0x1b */ `REG_SPRITE_PRIORITY:
                        sprite_pri <= dbi[7:0];
                    /* 0x1c */ `REG_SPRITE_MULTICOLOR_MODE:
                        sprite_mmc <= dbi[7:0];
                    /* 0x1d */ `REG_SPRITE_EXPAND_X:
                        sprite_xe <= dbi[7:0];
                    /* 0x20 */ `REG_BORDER_COLOR:
                        ec <= dbi[3:0];
                    /* 0x21 */ `REG_BACKGROUND_COLOR_0:
                        b0c <= dbi[3:0];
                    /* 0x22 */ `REG_BACKGROUND_COLOR_1:
                        b1c <= dbi[3:0];
                    /* 0x23 */ `REG_BACKGROUND_COLOR_2:
                        b2c <= dbi[3:0];
                    /* 0x24 */ `REG_BACKGROUND_COLOR_3:
                        b3c <= dbi[3:0];
                    /* 0x25 */ `REG_SPRITE_MULTI_COLOR_0:
                        sprite_mc0 <= dbi[3:0];
                    /* 0x26 */ `REG_SPRITE_MULTI_COLOR_1:
                        sprite_mc1 <= dbi[3:0];
                    /* 0x27 */ `REG_SPRITE_COLOR_0:
                        sprite_col[0] <= dbi[3:0];
                    /* 0x28 */ `REG_SPRITE_COLOR_1:
                        sprite_col[1] <= dbi[3:0];
                    /* 0x29 */ `REG_SPRITE_COLOR_2:
                        sprite_col[2] <= dbi[3:0];
                    /* 0x2a */ `REG_SPRITE_COLOR_3:
                        sprite_col[3] <= dbi[3:0];
                    /* 0x2b */ `REG_SPRITE_COLOR_4:
                        sprite_col[4] <= dbi[3:0];
                    /* 0x2c */ `REG_SPRITE_COLOR_5:
                        sprite_col[5] <= dbi[3:0];
                    /* 0x2d */ `REG_SPRITE_COLOR_6:
                        sprite_col[6] <= dbi[3:0];
                    /* 0x2e */ `REG_SPRITE_COLOR_7:
                        sprite_col[7] <= dbi[3:0];

                    // --- BEGIN EXTENSIONS ----
                    `VIDEO_MEM_1_IDX:
                        if (extra_regs_activated)
                           video_ram_idx_1 <= dbi;
                    `VIDEO_MEM_2_IDX:
                        if (extra_regs_activated)
                           video_ram_idx_2 <= dbi;
		    `VIDEO_MODE1:
                        if (extra_regs_activated) begin
                          hires_mode <= dbi[6:5];
                          hires_enabled <= dbi[`HIRES_ENABLE];
                          palette_select <= dbi[`PALETTE_SELECT_BIT];
                          hires_char_pixel_base <= dbi[2:0];
		        end
		    `VIDEO_MODE2:
                        if (extra_regs_activated) begin
			  hires_matrix_base <= dbi[3:0];
			  hires_color_base <= dbi[7:4];
		        end

                    /* 0x3f */ `VIDEO_MEM_FLAGS:
                        if (~extra_regs_activated) begin
                        case (dbi[7:0])
                        /* "V" */ 8'd86:
                            if (extra_regs_activation_ctr == 2'd0)
                                 extra_regs_activation_ctr <= extra_regs_activation_ctr + 2'b1;
                        /* "I" */ 8'd73:
                            if (extra_regs_activation_ctr == 2'd1)
                                 extra_regs_activation_ctr <= extra_regs_activation_ctr + 2'b1;
                            else
                                 extra_regs_activation_ctr <= 2'd0;
                        /* "C" */ 8'd67:
                            if (extra_regs_activation_ctr == 2'd2)
                                extra_regs_activation_ctr <= extra_regs_activation_ctr + 2'b1;
                            else
                                extra_regs_activation_ctr <= 2'd0;
                        /* "2" */ 8'd50:
                            if (extra_regs_activation_ctr == 2'd3)
                                extra_regs_activated <= 1'b1;
                            else
                                extra_regs_activation_ctr <= 2'd0;
                        default:
                            extra_regs_activation_ctr <= 2'd0;
                        endcase
                        end else begin
                            video_ram_flags <= dbi[7:0];
                            if (video_ram_flags[7])
                               extra_regs_activated <= 1'b0;
                        end

                    `VIDEO_MEM_1_HI:
                        if (extra_regs_activated)
                           video_ram_hi_1 <= dbi[7:0];
                    `VIDEO_MEM_1_LO:
                        if (extra_regs_activated)
                           video_ram_lo_1 <= dbi[7:0];
                    `VIDEO_MEM_1_VAL:
                        if (extra_regs_activated) begin
                          // reg overlay or video mem
                          auto_ram_sel <= 0;
                          write_ram(
                           .overlay(video_ram_flags[5]),
                           .ram_lo(video_ram_lo_1),
                           .ram_hi(video_ram_hi_1),
                           .ram_idx(video_ram_idx_1));
                        end
                    `VIDEO_MEM_2_HI:
                        if (extra_regs_activated)
                           video_ram_hi_2 <= dbi[7:0];
                    `VIDEO_MEM_2_LO:
                        if (extra_regs_activated)
                           video_ram_lo_2 <= dbi[7:0];
                    `VIDEO_MEM_2_VAL:
                        if (extra_regs_activated) begin
                          // reg overlay or video mem
                          auto_ram_sel <= 1;
                          write_ram(
                           .overlay(video_ram_flags[5]),
                           .ram_lo(video_ram_lo_2),
                           .ram_hi(video_ram_hi_2),
                           .ram_idx(video_ram_idx_2));
                        end

                    // --- END EXTENSIONS ----

                    default:;
                endcase
            end
        end

        // --- BEGIN EXTENSIONS ----

        // CPU read from video mem
        if (video_ram_r)
            dbo[7:0] <= video_ram_data_out_a;
    
        // CPU write to color register ram
        if (color_regs_pre_wr_a) begin
            // Now we can do the write
            color_regs_pre_wr_a <= 0;
            color_regs_wr_a <= 1;
	    case (color_regs_wr_nibble)
               2'b00:
		   color_regs_data_in_a <= {color_regs_wr_value, color_regs_data_out_a[11:0]};
               2'b01:
                   color_regs_data_in_a <= {color_regs_data_out_a[15:12] , color_regs_wr_value, color_regs_data_out_a[7:0]};
               2'b10:
                   color_regs_data_in_a <= {color_regs_data_out_a[15:8], color_regs_wr_value, color_regs_data_out_a[3:0]};
               2'b11:
                   color_regs_data_in_a <= {color_regs_data_out_a[15:4], color_regs_wr_value};
            endcase
        end

        // CPU read from color regs
        if (color_regs_r) begin
	    case (color_regs_r_nibble)
               2'b00: dbo[7:0] <= { 4'b0, color_regs_data_out_a[15:12] };
               2'b01: dbo[7:0] <= { 4'b0, color_regs_data_out_a[11:8] };
               2'b10: dbo[7:0] <= { 4'b0, color_regs_data_out_a[7:4] };
               2'b11: dbo[7:0] <= { 4'b0, color_regs_data_out_a[3:0] };
            endcase
        end

	// NOTE: This location means video_ram_wr_a will be high for two
	// cycles.  color_regs_wr_a is only high for one.  But we needed
	// an extra cycle to read color regs before we could update the
	// 12 bit value properly.
        if (~clk_phi && phi_phase_start_dav_plus_2) begin
            // Always clear both flags and propagate r to r2 here.
            video_ram_r <= 0;
            video_ram_r2 <= video_ram_r;
            video_ram_wr_a <= 0;

	    color_regs_r <= 0;
	    color_regs_r2 <= color_regs_r;
	    color_regs_wr_a <= 0;

            if (video_ram_r2 || video_ram_wr_a || color_regs_r2 || color_regs_wr_a) begin
                // Handle auto increment /decrement after port access
                if (auto_ram_sel == 0) begin // loc 1 of port a
                    case(video_ram_flags[1:0]) // auto inc port a
                    2'd1: begin
                        if (video_ram_lo_1 < 8'hff)
                            video_ram_lo_1 <= video_ram_lo_1 + 8'b1;
                        else begin
                             video_ram_lo_1 <= 8'h00;
                             video_ram_hi_1 <= video_ram_hi_1 + 8'b1;
                         end
                    end
                    2'd2: begin
                       if (video_ram_lo_1 > 8'h00)
                            video_ram_lo_1 <= video_ram_lo_1 - 8'b1;
                       else begin
                            video_ram_lo_1 <= 8'hff;
                            video_ram_hi_1 <= video_ram_hi_1 - 8'b1;
                       end
                    end
                    default:
                       ;
                    endcase
                end else begin // loc 2 of port a
                    case(video_ram_flags[3:2]) // auto inc port b
                    2'd1: begin
                       if (video_ram_lo_2 < 8'hff)
                           video_ram_lo_2 <= video_ram_lo_2 + 8'b1;
                       else begin
                            video_ram_lo_2 <= 8'h00;
                            video_ram_hi_2 <= video_ram_hi_2 + 8'b1;
                        end
                    end
                    2'd2: begin
                       if (video_ram_lo_2 > 8'h00)
                            video_ram_lo_2 <= video_ram_lo_2 - 8'b1;
                       else begin
                            video_ram_lo_2 <= 8'hff;
                            video_ram_hi_2 <= video_ram_hi_2 - 8'b1;
                       end
                    end
                    default:
                       ;
                    endcase
                end

            end
        end
        // --- END EXTENSIONS ----
    end

// At every pixel clock tick, set red,green,blue from color
// register ram according to the pixel_color4 address.
always @(posedge clk_dot4x)
begin
`ifndef IS_SIMULATOR
    if (active) begin
`endif
       if (half_bright) begin
          red <= {1'b0, color_regs_data_out_b[15:13]};
          green <= {1'b0, color_regs_data_out_b[11:9]};
          blue <= {1'b0, color_regs_data_out_b[7:5]};
       end else begin
          red <= color_regs_data_out_b[15:12];
          green <= color_regs_data_out_b[11:8];
          blue <= color_regs_data_out_b[7:4];
       end
`ifndef IS_SIMULATOR
    end else begin
          red <= 4'b0;
          green <= 4'b0;
          blue <= 4'b0;
    end
`endif
end

// For color ram:
//     flip read bit on and set address and which nibble (out of 4)
//     is to be read, dbo will be set by the 'CPU read from color regs' block
//     above.
// For video ram:
//     flip read bit on and set address. dbo will be set by the
//     'CPU read from video ram' block above.
//
// In both cases, read happens next cycle and r flags turned off.
task read_ram(
    input overlay,
    input [7:0] ram_lo,
    input [7:0] ram_hi,
    input [7:0] ram_idx);
    begin
       if (overlay) begin
          if (ram_lo < 8'h80) begin
              // _r stores which byte within the 16 bit
              // lookup value we want
              color_regs_r <= 1'b1;
              color_regs_r_nibble <= ram_lo[1:0];
              color_regs_addr_a <= ram_lo[6:2];
          end else begin
              case (ram_lo)
                 `EXT_REG_VIDEO_FREQ:
		         dbo <= {7'b0, is_15khz};
                 `EXT_REG_CHIP_MODEL:
		         dbo <= {6'b0, chip};
                 `EXT_REG_DISPLAY_FLAGS:
		         dbo <= {7'b0, show_raster_lines};
                 `EXT_REG_VERSION:
			 dbo <= {`VERSION_MAJOR, `VERSION_MINOR};
                 `EXT_REG_VARIANT_NAME1:
			 dbo <= `VARIANT_NAME1;
                 `EXT_REG_VARIANT_NAME2:
			 dbo <= `VARIANT_NAME2;
                 `EXT_REG_VARIANT_NAME3:
			 dbo <= `VARIANT_NAME3;
                 `EXT_REG_VARIANT_NAME4:
			 dbo <= `VARIANT_NAME4;
                 `EXT_REG_VARIANT_NAME5:
			 dbo <= `VARIANT_NAME5;
                 `EXT_REG_VARIANT_NAME6:
			 dbo <= `VARIANT_NAME6;
                 `EXT_REG_VARIANT_NAME7:
			 dbo <= `VARIANT_NAME7;
                 `EXT_REG_VARIANT_NAME8:
			 dbo <= `VARIANT_NAME8;
                 `EXT_REG_VARIANT_NAME9:
			 dbo <= 8'd0;
                 default: begin
                     // We fallback to RAM if not peeking a register.
                     video_ram_r <= 1;
                     video_ram_addr_a <= {ram_hi[6:0], ram_lo} + {7'b0, ram_idx};
                 end
              endcase
          end
       end else begin
           video_ram_r <= 1;
           video_ram_addr_a <= {ram_hi[6:0], ram_lo} + {7'b0, ram_idx};
           end
       end
endtask

// For color ram:
//     Write happens in two stages. First pre_wr flag is set along with
//     value and which nibble (of 4) and the adddress.  When stage 1 is
//     handled above, the value is read out first, the nibble updated
//     and then the write op is done.
// For video ram:
//     Write happens in one stage. We set the wr flag, address and value
//     here.
//
// In both cases, wr flags are turned off by dav_plus2
task write_ram(
    input overlay,
    input [7:0] ram_lo,
    input [7:0] ram_hi,
    input [7:0] ram_idx);
    begin
       if (overlay) begin
           if (ram_lo < 8'h80) begin
              // In order to write to individual 4 bit
              // values within the 16 bit register, we
              // have to read it first, then write.
              color_regs_pre_wr_a <= 1;
              color_regs_wr_value <= dbi[3:0];
              color_regs_wr_nibble <= ram_lo[1:0];
              color_regs_addr_a <= ram_lo[6:2];
           end else begin
              // When we poke certain config registers, we
	      // reconstruct a new configuration byte and
	      // pass it to the MCU over serial.  Then, it
	      // will save the values and the new config
	      // bits will be reflected after the next
	      // cold boot.
              case (ram_lo)
                 // Not safe to allow this to be changed from
		 // CPU. Already burned by this with accidental
		 // overwrite of this register. This can effectively
		 // disable your display so leave this only to the
		 // serial connection to change.
                 //`EXT_REG_VIDEO_FREQ:
                 // begin
                 //   last_is_15khz <= dbi[0];
                 //   tx_data_4x <= {4'b0,
                 //                  ~show_raster_lines,
                 //                  dbi[0],
                 //                  last_chip};
                 //   tx_new_data_sr <= 2'b11;
                 end
                 `EXT_REG_CHIP_MODEL:
                  begin
                    last_chip <= dbi[1:0];
                    tx_data_4x <= {4'b0,
			           ~show_raster_lines,
				   last_is_15khz,
				   dbi[1:0]};
                    tx_new_data_sr <= 2'b11;
                 end
                 `EXT_REG_DISPLAY_FLAGS:
                  begin
		    show_raster_lines <= dbi[`SHOW_RASTER_LINES];
                    tx_data_4x <= {4'b0,
			           ~dbi[`SHOW_RASTER_LINES],
				   last_is_15khz,
				   last_chip};
                    tx_new_data_sr <= 2'b11;
                 end
                 default: begin
                    // We fallback to RAM if not poking a register.
                    video_ram_wr_a <= 1;
                    video_ram_data_in_a <= dbi[7:0];
                    video_ram_addr_a <= {ram_hi[6:0], ram_lo} + {7'b0, ram_idx};
                 end
              endcase
           end
        end else begin
           video_ram_wr_a <= 1;
           video_ram_data_in_a <= dbi[7:0];
           video_ram_addr_a <= {ram_hi[6:0], ram_lo} + {7'b0, ram_idx};
        end
    end
endtask

endmodule
