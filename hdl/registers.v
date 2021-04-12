`timescale 1ns / 1ps

`include "common.vh"

module registers(
           input rst,
`ifdef REV_1_BOARD
           input cpu_reset_i,
`endif
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
	   output reg[5:0] red,
	   output reg[5:0] green,
	   output reg[5:0] blue,

	   // When we poke our custom regs that change config,
	   // we set the new config byte and raise new data flag
	   // for the MCU to pick up over serial.
	   output reg [7:0] tx_data_4x,
	   output reg tx_new_data_4x,

      // When rx_new_data goes high, interpret the next byte
		// in the command data stream from the AVR
		input [7:0] rx_data_4x,
      input rx_new_data_4x,

	   // These are the config bits coming from the MCU. They
	   // represent what the MCU wants things to be, not what
	   // they are presently in the FPGA.  They are latched
	   // into 'current' regs into reset block.
	   input [1:0] chip,

	   // Current settings
	   output reg last_raster_lines,
		output reg last_is_15khz,

`ifdef CONFIGURABLE_LUMAS
      output [95:0] lumareg_o,
		output [127:0] phasereg_o,
		output [47:0] amplitudereg_o,
		output reg [5:0] blanking_level,
		output reg [2:0] burst_amplitude,
`endif
		
	   // --- BEGIN EXTENSIONS ---
      input [14:0] video_ram_addr_b,
      output [7:0] video_ram_data_out_b,
      output reg [2:0] hires_char_pixel_base,
      output reg [3:0] hires_matrix_base,
      output reg [3:0] hires_color_base,
      output reg hires_enabled,
      output reg [1:0] hires_mode,
	   output reg [7:0] hires_cursor_hi,
	   output reg [7:0] hires_cursor_lo
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

`ifdef CONFIGURABLE_LUMAS
reg [5:0] luma[15:0];
reg [7:0] phase[15:0];
reg [2:0] amplitude[15:0];
assign lumareg_o = {luma[0],luma[1],luma[2],luma[3],luma[4],luma[5],luma[6],luma[7],luma[8],luma[9],luma[10],luma[11],luma[12],luma[13],luma[14],luma[15]};
assign phasereg_o = {phase[0],phase[1],phase[2],phase[3],phase[4],phase[5],phase[6],phase[7],phase[8],phase[9],phase[10],phase[11],phase[12],phase[13],phase[14],phase[15]};
assign amplitudereg_o = {amplitude[0],amplitude[1],amplitude[2],amplitude[3],amplitude[4],amplitude[5],amplitude[6],amplitude[7],amplitude[8],amplitude[9],amplitude[10],amplitude[11],amplitude[12],amplitude[13],amplitude[14],amplitude[15]};
`endif

reg res;

// Register Read/Write
reg [5:0] addr_latched;
reg addr_latch_done;
reg read_done;

// --- BEGIN EXTENSIONS ----
reg [1:0] extra_regs_activation_ctr;
reg extra_regs_activated;

// Flags to govern read accesses causing auto inc/dec
reg video_ram_r; // also used to trigger auto inc after read
reg video_ram_r2; // also used to trigger auto inc after read
reg auto_ram_sel; // which pointer are we auto incrementing?
reg color_regs_r; // also used to trigger auto inc after read
reg color_regs_r2; // also used to trigger auto inc after read
reg video_ram_aw; // auto increment after write is necessary
reg color_regs_aw; // auto increment after write is necessary
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
reg [5:0] color_regs_wr_value;
reg [23:0] color_regs_data_in_a;
wire [23:0] color_regs_data_out_a;
wire [23:0] color_regs_data_out_b;

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
                    8'b0,          // Video can only read
                    video_ram_data_out_b
                    );

COLOR_REGS color_regs(clk_dot4x,
                    color_regs_wr_a, // write to color ram
                    color_regs_addr_a, // addr for color ram read/write
                    color_regs_data_in_a,
                    color_regs_data_out_a,
                    1'b0, // we never write to port b
                    { palette_select, pixel_color4}, // read addr for color lookups
                    24'b0, // we never write to port b
                    color_regs_data_out_b // read value for color lookups
                    );

// --- END EXTENSIONS ----

reg [1:0] last_chip;
reg [10:0] tx_new_data_ctr;
reg tx_new_data_start;
reg [7:0] tx_cfg_change_1;
reg [7:0] tx_cfg_change_2;

reg rx_new_data_ff;
reg [7:0] rx_cfg_change_1;

// When transmitting config changes over serial tx, we transmit
// two bytes for every register change. The first is the register
// number and the second is the value. The tx_new_data strobe
// is separated for these two bytes by ~2048 dot4x ticks which gives
// enough time for the serial module to transmit a byte before
// transmitting the next one. The tx strobe is held high for two
// dot4x ticks.  2048 dot 4x ticks = 64 dot clock periods.  Worst
// case dot clock period is approx 122.5 nanoseconds.  So that's
// 7840 nano seconds for 7.8 us to transmit a byte.  Therefore, when
// the 6502 is making register changes with the persistence flag
// turned on, it should not change registers faster than 15.6us
// which seems good enough for BASIC to stay away from.  6502
// assembly might not work though.  This start value (2048) can
// probably be reduced but I haven't found the lowest value possible.

always @(posedge clk_dot4x)
begin
   // Signal from other process blocks to start the serial transmission.
   if (tx_new_data_start) begin
	   tx_new_data_ctr <= 11'd2047;
   end

   if (tx_new_data_ctr > 0)
	   tx_new_data_ctr <= tx_new_data_ctr - 11'b1;
		
   if (tx_new_data_ctr == 1 || tx_new_data_ctr == 2) begin
      tx_new_data_4x <= 1'b1;
		tx_data_4x <= tx_cfg_change_2;
   end else if (tx_new_data_ctr == 2046 || tx_new_data_ctr == 2047) begin
      tx_new_data_4x <= 1'b1;
		tx_data_4x <= tx_cfg_change_1;
   end else	
      tx_new_data_4x <= 1'b0;
end


always @(posedge clk_dot4x)
    if (rst) begin
`ifdef TEST_PATTERN
        ec <= `LIGHT_BLUE;
        b0c <= `BLUE;
        den <= `TRUE;
`endif
        //ec <= `BLACK;
        //b0c <= `BLACK;
        //den <= `FALSE;
        //b1c <= BLACK;
        //b2c <= BLACK;
        //b3c <= BLACK;
        //xscroll <= 3'd0;
        //yscroll <= 3'd3;
        //csel <= `FALSE;
        //rsel <= `FALSE;
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

`ifdef CONFIGURABLE_LUMAS
        luma[0] <= 6'b010011; // 0
        luma[1] <= 6'b111011; // 8
        luma[2] <= 6'b011111; // 2
        luma[3] <= 6'b101100; // 6
        luma[4] <= 6'b100010; // 3
        luma[5] <= 6'b100111; // 5
        luma[6] <= 6'b011100; // 1
        luma[7] <= 6'b110010; // 7
        luma[8] <= 6'b100010; // 3
        luma[9] <= 6'b011100; // 1
        luma[10] <= 6'b100111; // 5
        luma[11] <= 6'b011111; // 2
        luma[12] <= 6'b100110; // 4
        luma[13] <= 6'b110010; // 7
        luma[14] <= 6'b100110; // 4
        luma[15] <= 6'b101100; // 6
        amplitude[0] <= 3'b111; // no modulation
        amplitude[1] <= 3'b111; // no modulation
        amplitude[2] <= 3'b010;
        amplitude[3] <= 3'b010;
        amplitude[4] <= 3'b001;
        amplitude[5] <= 3'b001;
        amplitude[6] <= 3'b010;
        amplitude[7] <= 3'b000;
        amplitude[8] <= 3'b000;
        amplitude[9] <= 3'b010;
        amplitude[10] <= 3'b010;
        amplitude[11] <= 3'b111; // no modulation
        amplitude[12] <= 3'b111; // no modulation
        amplitude[13] <= 3'b010;
        amplitude[14] <= 3'b010;
        amplitude[15] <= 3'b111; // no modulation
        phase[0] <= 8'd0;  // unmodulated
        phase[1] <= 8'd0;  // unmodulated
        phase[2] <= 8'd80; // 112.5 deg
        phase[3] <= 8'd208; // 292.5 deg
        phase[4] <= 8'd32; // 45 deg
        phase[5] <= 8'd160; // 225 deg
        phase[6] <= 8'd0; // 0 deg
        phase[7] <= 8'd128; // 180 deg
        phase[8] <= 8'd96; // 135 deg
        phase[9] <= 8'd112; // 157.5 deg
        phase[10] <= 8'd80; // 112.5 deg
        phase[11] <= 8'd0;  // unmodulated
        phase[12] <= 8'd0;  // unmodulated
        phase[13] <= 8'd160; // 225 deg
        phase[14] <= 8'd0; // 0 deg
        phase[15] <= 8'd0;  // unmodulated
		  blanking_level <= 6'b010010;
		  burst_amplitude <= 3'b010;
`endif

   // --- BEGIN EXTENSIONS ----
   extra_regs_activation_ctr <= 2'b0;

	// Latch these config bits during reset
	last_chip <= chip;
	last_raster_lines <= 1'b0;
	last_is_15khz <= 1'b0;
	rx_new_data_ff <= 1'b0;
   video_ram_flags <= 8'b0;
`ifdef IS_SIMULATOR
   extra_regs_activated <= 0'b1;

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
        // Cursor top left
        hires_cursor_hi <= 8'h18;
        hires_cursor_lo <= 8'b00;
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
	hires_mode <= 2'b00;
	hires_enabled <= 1'b0;
	hires_char_pixel_base <= 3'b0;
   hires_matrix_base <= 4'b0000; // ignored
   hires_color_base <= 4'b0000; // ignored
	hires_cursor_hi <= 8'b0;
	hires_cursor_lo <= 8'b0;
`endif
    // --- END EXTENSIONS ----

    end else
    begin
	 
`ifdef REV_1_BOARD
         // For now, this is dummy code to keep the reset in line
         // from getting thrown away. Replace this with code to
         // actually reset the extension registers at some point
         // on the real board.  Remove this ifdef when mojo_v3 is
         // deprecated.
	 if (cpu_reset_i)
	    ec <= 4'b1;
`endif
		 
        // Always reset start flag. write_ram may flip this true if a register was
		  // changed and it should be persisted.
        tx_new_data_start = 1'b0;

        // Handle incoming serial commands.
        // This is guaranteed to go back low on next tick.
		  // Serial rx will not trigger register set unless the
		  // stream is prefixed by 3 0xff bytes first.
        if (rx_new_data_4x) begin
	         rx_new_data_ff <= ~rx_new_data_ff;
	         if (~rx_new_data_ff) begin
			      // Config byte 1
				   rx_cfg_change_1 <= rx_data_4x;
			   end else begin
			      // Config byte 2
				   write_ram(
                  .overlay(1'b1),
                  .ram_lo(rx_cfg_change_1), // 1st byte from rx
                  .ram_hi(8'b0), // ignored
                  .ram_idx(8'b0), // ignored
					   .data(rx_data_4x), // 2nd byte from rx
					   .do_tx(1'b0) // no tx
                 );
			   end
        end
		  
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
`ifdef TEST_PATTERN
                        den <= `TRUE;
`else
                        den <= dbi[4];
`endif
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
`ifndef TEST_PATTERN
                    /* 0x20 */ `REG_BORDER_COLOR:
                        ec <= dbi[3:0];
                    /* 0x21 */ `REG_BACKGROUND_COLOR_0:
                        b0c <= dbi[3:0];
`endif
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
                           .ram_idx(video_ram_idx_1),
									.data(dbi),
									.do_tx(1'b1));
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
                           .ram_idx(video_ram_idx_2),
									.data(dbi),
									.do_tx(1'b1));
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
            color_regs_pre_wr_a <= 1'b0;
            color_regs_wr_a <= 1'b1;
				color_regs_aw <= 1'b1;
            case (color_regs_wr_nibble)
               2'b00:
                   color_regs_data_in_a <= {color_regs_wr_value, color_regs_data_out_a[17:0]};
               2'b01:
                   color_regs_data_in_a <= {color_regs_data_out_a[23:18] , color_regs_wr_value, color_regs_data_out_a[11:0]};
               2'b10:
                   color_regs_data_in_a <= {color_regs_data_out_a[23:12], color_regs_wr_value, color_regs_data_out_a[5:0]};
               2'b11:
                   color_regs_data_in_a <= {color_regs_data_out_a[23:6], color_regs_wr_value}; // never used
            endcase
        end

        // CPU read from color regs
        if (color_regs_r) begin
            case (color_regs_r_nibble)
               2'b00: dbo[7:0] <= { 2'b0, color_regs_data_out_a[23:18] };
               2'b01: dbo[7:0] <= { 2'b0, color_regs_data_out_a[17:12] };
               2'b10: dbo[7:0] <= { 2'b0, color_regs_data_out_a[11:6] };
               2'b11: dbo[7:0] <= { 2'b0, color_regs_data_out_a[5:0] };
            endcase
        end

        // Only need 1 tick to write to video ram
        if (video_ram_wr_a)
		     video_ram_wr_a <= 1'b0;

        // Only need 1 tick to write to color ram
        if (color_regs_wr_a)
		     color_regs_wr_a <= 1'b0;

        // Near the start of the low cycle, handle auto increment of
		  // our vram pointers.
        if (~clk_phi && phi_phase_start_dav_plus_2) begin
            // Always clear both flags and propagate r to r2 here.
            video_ram_r <= 0;
            video_ram_r2 <= video_ram_r;
				video_ram_aw <= 1'b0;

            color_regs_r <= 0;
            color_regs_r2 <= color_regs_r;
				color_regs_aw <= 1'b0;

            // We propagated r to r2 on reads so that we auto increment
				// two cycles after a read due to some instructions reading first,
				// then writing.  If we didn't do this, those instructions would
				// cause two increments when we only wanted one.  So this effectively
				// waits a full cycle before commiting to increment after a read.
            if (video_ram_r2 || video_ram_aw || color_regs_r2 || color_regs_aw) begin
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
          red <= {1'b0, color_regs_data_out_b[23:19]};
          green <= {1'b0, color_regs_data_out_b[17:13]};
          blue <= {1'b0, color_regs_data_out_b[11:7]};
       end else begin
          red <= color_regs_data_out_b[23:18];
          green <= color_regs_data_out_b[17:12];
          blue <= color_regs_data_out_b[11:6];
       end
`ifndef IS_SIMULATOR
    end else begin
          red <= 6'b0;
          green <= 6'b0;
          blue <= 6'b0;
    end
`endif
end

// For color ram:
//     flip read bit on and set address and which 6-bit-nibble (out of 4)
//     is to be read, dbo will be set by the 'CPU read from color regs' block
//     above.
// For video ram:
//     flip read bit on and set address. dbo will be set by the
//     'CPU read from video ram' block above.
//
// In both cases, read happens next cycle and r flags turned off.
//
// If overlay is on, ram_hi and ram_idx are ignored and it will never
// trigger a vram read.
task read_ram(
    input overlay,
    input [7:0] ram_lo,
    input [7:0] ram_hi,
    input [7:0] ram_idx);
    begin
       if (overlay) begin
          if (ram_lo < 8'h80) begin
              // _r_nibble stores which 6-bit-nibble within the 24 bit
              // lookup value we want.  The lowest 6-bits are never used.
              color_regs_r <= 1'b1;
              color_regs_r_nibble <= ram_lo[1:0];
              color_regs_addr_a <= ram_lo[6:2];
          end else begin
              case (ram_lo)
                 `EXT_REG_VIDEO_FREQ:
		         dbo <= {7'b0, last_is_15khz};
                 `EXT_REG_CHIP_MODEL:
		         dbo <= {6'b0, last_chip};
                 `EXT_REG_DISPLAY_FLAGS:
		         dbo <= {7'b0, last_raster_lines};
                 `EXT_REG_CURSOR_LO:
		         dbo <= hires_cursor_lo;
                 `EXT_REG_CURSOR_HI:
		         dbo <= hires_cursor_hi;
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
`ifdef CONFIGURABLE_LUMAS
					  `EXT_REG_LUMA0:
					     dbo <= {2'b0, luma[0]};
					  `EXT_REG_LUMA1:
					     dbo <= {2'b0, luma[1]};
					  `EXT_REG_LUMA2:
					     dbo <= {2'b0, luma[2]};
					  `EXT_REG_LUMA3:
					     dbo <= {2'b0, luma[3]};
					  `EXT_REG_LUMA4:
					     dbo <= {2'b0, luma[4]};
					  `EXT_REG_LUMA5:
					     dbo <= {2'b0, luma[5]};
					  `EXT_REG_LUMA6:
					     dbo <= {2'b0, luma[6]};
					  `EXT_REG_LUMA7:
					     dbo <= {2'b0, luma[7]};
					  `EXT_REG_LUMA8:
					     dbo <= {2'b0, luma[8]};
					  `EXT_REG_LUMA9:
					     dbo <= {2'b0, luma[9]};
					  `EXT_REG_LUMA10:
					     dbo <= {2'b0, luma[10]};
					  `EXT_REG_LUMA11:
					     dbo <= {2'b0, luma[11]};
					  `EXT_REG_LUMA12:
					     dbo <= {2'b0, luma[12]};
					  `EXT_REG_LUMA13:
					     dbo <= {2'b0, luma[13]};
					  `EXT_REG_LUMA14:
					     dbo <= {2'b0, luma[14]};
					  `EXT_REG_LUMA15:
					     dbo <= {2'b0, luma[15]};

					  `EXT_REG_PHASE0:
					     dbo <= phase[0];
					  `EXT_REG_PHASE1:
					     dbo <= phase[1];
					  `EXT_REG_PHASE2:
					     dbo <= phase[2];
					  `EXT_REG_PHASE3:
					     dbo <= phase[3];
					  `EXT_REG_PHASE4:
					     dbo <= phase[4];
					  `EXT_REG_PHASE5:
					     dbo <= phase[5];
					  `EXT_REG_PHASE6:
					     dbo <= phase[6];
					  `EXT_REG_PHASE7:
					     dbo <= phase[7];
					  `EXT_REG_PHASE8:
					     dbo <= phase[8];
					  `EXT_REG_PHASE9:
					     dbo <= phase[9];
					  `EXT_REG_PHASE10:
					     dbo <= phase[10];
					  `EXT_REG_PHASE11:
					     dbo <= phase[11];
					  `EXT_REG_PHASE12:
					     dbo <= phase[12];
					  `EXT_REG_PHASE13:
					     dbo <= phase[13];
					  `EXT_REG_PHASE14:
					     dbo <= phase[14];
					  `EXT_REG_PHASE15:
					     dbo <= phase[15];

					  `EXT_REG_AMPL0:
					     dbo <= {5'b0, amplitude[0]};
					  `EXT_REG_AMPL1:
					     dbo <= {5'b0, amplitude[1]};
					  `EXT_REG_AMPL2:
					     dbo <= {5'b0, amplitude[2]};
					  `EXT_REG_AMPL3:
					     dbo <= {5'b0, amplitude[3]};
					  `EXT_REG_AMPL4:
					     dbo <= {5'b0, amplitude[4]};
					  `EXT_REG_AMPL5:
					     dbo <= {5'b0, amplitude[5]};
					  `EXT_REG_AMPL6:
					     dbo <= {5'b0, amplitude[6]};
					  `EXT_REG_AMPL7:
					     dbo <= {5'b0, amplitude[7]};
					  `EXT_REG_AMPL8:
					     dbo <= {5'b0, amplitude[8]};
					  `EXT_REG_AMPL9:
					     dbo <= {5'b0, amplitude[9]};
					  `EXT_REG_AMPL10:
					     dbo <= {5'b0, amplitude[10]};
					  `EXT_REG_AMPL11:
					     dbo <= {5'b0, amplitude[11]};
					  `EXT_REG_AMPL12:
					     dbo <= {5'b0, amplitude[12]};
					  `EXT_REG_AMPL13:
					     dbo <= {5'b0, amplitude[13]};
					  `EXT_REG_AMPL14:
					     dbo <= {5'b0, amplitude[14]};
					  `EXT_REG_AMPL15:
					     dbo <= {5'b0, amplitude[15]};
					  `EXT_REG_BLANKING:
					     dbo <= {2'b0, blanking_level};
					  `EXT_REG_BURSTAMP:
					     dbo <= {5'b0, burst_amplitude};
`endif  // CONFIGURABLE_LUMAS
                 default: ;
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
//     value and which 6-bit-nibble (of 4) and the adddress.  When stage 1 is
//     handled above, the value is read out first, the nibble updated
//     and then the write op is done.
// For video ram:
//     Write happens in one stage. We set the wr flag, address and value
//     here.
//
// In both cases, wr flags are turned one cycle after they are set.
//
// If overlay is on, ram_hi and ram_idx are ignored and it will never
// trigger a vram write.
//
// If do_tx is 1, we transmit this change to the MCU for persistence.
task write_ram(
    input overlay,
    input [7:0] ram_lo,
    input [7:0] ram_hi,
    input [7:0] ram_idx,
	 input [7:0] data,
	 input do_tx);
    begin
       if (overlay) begin
           if (ram_lo < 8'h80) begin
              // In order to write to individual 6 bit
              // values within the 24 bit register, we
              // have to read it first, then write.
              color_regs_pre_wr_a <= 1'b1;
              color_regs_wr_value <= data[5:0];
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
                 // Not safe to allow last_is_15khz to be changed from
                 // CPU. Already burned by this with accidental
                 // overwrite of this register. This can effectively
                 // disable your display so leave this only to the
                 // serial connection to change.
                 `EXT_REG_CHIP_MODEL:
                  begin
                    last_chip <= data[1:0];
						  if (do_tx) begin
						      tx_cfg_change_1 <= `EXT_REG_CHIP_MODEL;
						      tx_cfg_change_2 <= {6'b0, data[1:0]};
						      tx_new_data_start = 1'b1;					  
                    end
                 end
                 `EXT_REG_DISPLAY_FLAGS:
                  begin
                    last_raster_lines <= data[`SHOW_RASTER_LINES];
						  if (do_tx) begin
						     tx_cfg_change_1 <= `EXT_REG_DISPLAY_FLAGS;
						     tx_cfg_change_2 <= {7'b0, data[`SHOW_RASTER_LINES]};
                       tx_new_data_start = 1'b1;
                    end
                 end
                 `EXT_REG_CURSOR_LO:
                    hires_cursor_lo <= data;
                 `EXT_REG_CURSOR_HI:
                    hires_cursor_hi <= data;
`ifdef CONFIGURABLE_LUMAS
					  `EXT_REG_LUMA0:
					     luma[0] <= data[5:0];
					  `EXT_REG_LUMA1:
					     luma[1] <= data[5:0];
					  `EXT_REG_LUMA2:
					     luma[2] <= data[5:0];
					  `EXT_REG_LUMA3:
					     luma[3] <= data[5:0];
					  `EXT_REG_LUMA4:
					     luma[4] <= data[5:0];
					  `EXT_REG_LUMA5:
					     luma[5] <= data[5:0];
					  `EXT_REG_LUMA6:
					     luma[6] <= data[5:0];
					  `EXT_REG_LUMA7:
					     luma[7] <= data[5:0];
					  `EXT_REG_LUMA8:
					     luma[8] <= data[5:0];
					  `EXT_REG_LUMA9:
					     luma[9] <= data[5:0];
					  `EXT_REG_LUMA10:
					     luma[10] <= data[5:0];
					  `EXT_REG_LUMA11:
					     luma[11] <= data[5:0];
					  `EXT_REG_LUMA12:
					     luma[12] <= data[5:0];
					  `EXT_REG_LUMA13:
					     luma[13] <= data[5:0];
					  `EXT_REG_LUMA14:
					     luma[14] <= data[5:0];
					  `EXT_REG_LUMA15:
					     luma[15] <= data[5:0];

					  `EXT_REG_PHASE0:
					     phase[0] <= data[7:0];
					  `EXT_REG_PHASE1:
					     phase[1] <= data[7:0];
					  `EXT_REG_PHASE2:
					     phase[2] <= data[7:0];
					  `EXT_REG_PHASE3:
					     phase[3] <= data[7:0];
					  `EXT_REG_PHASE4:
					     phase[4] <= data[7:0];
					  `EXT_REG_PHASE5:
					     phase[5] <= data[7:0];
					  `EXT_REG_PHASE6:
					     phase[6] <= data[7:0];
					  `EXT_REG_PHASE7:
					     phase[7] <= data[7:0];
					  `EXT_REG_PHASE8:
					     phase[8] <= data[7:0];
					  `EXT_REG_PHASE9:
					     phase[9] <= data[7:0];
					  `EXT_REG_PHASE10:
					     phase[10] <= data[7:0];
					  `EXT_REG_PHASE11:
					     phase[11] <= data[7:0];
					  `EXT_REG_PHASE12:
					     phase[12] <= data[7:0];
					  `EXT_REG_PHASE13:
					     phase[13] <= data[7:0];
					  `EXT_REG_PHASE14:
					     phase[14] <= data[7:0];
					  `EXT_REG_PHASE15:
					     phase[15] <= data[7:0];

					  `EXT_REG_AMPL0:
					     amplitude[0] <= data[2:0];
					  `EXT_REG_AMPL1:
					     amplitude[1] <= data[2:0];
					  `EXT_REG_AMPL2:
					     amplitude[2] <= data[2:0];
					  `EXT_REG_AMPL3:
					     amplitude[3] <= data[2:0];
					  `EXT_REG_AMPL4:
					     amplitude[4] <= data[2:0];
					  `EXT_REG_AMPL5:
					     amplitude[5] <= data[2:0];
					  `EXT_REG_AMPL6:
					     amplitude[6] <= data[2:0];
					  `EXT_REG_AMPL7:
					     amplitude[7] <= data[2:0];
					  `EXT_REG_AMPL8:
					     amplitude[8] <= data[2:0];
					  `EXT_REG_AMPL9:
					     amplitude[9] <= data[2:0];
					  `EXT_REG_AMPL10:
					     amplitude[10] <= data[2:0];
					  `EXT_REG_AMPL11:
					     amplitude[11] <= data[2:0];
					  `EXT_REG_AMPL12:
					     amplitude[12] <= data[2:0];
					  `EXT_REG_AMPL13:
					     amplitude[13] <= data[2:0];
					  `EXT_REG_AMPL14:
					     amplitude[14] <= data[2:0];
					  `EXT_REG_AMPL15:
					     amplitude[15] <= data[2:0];
					  `EXT_REG_BLANKING:
					     blanking_level <= data[5:0];
					  `EXT_REG_BURSTAMP:
					     burst_amplitude <= data[2:0];
`endif  // CONFIGURABLE_LUMAS
                 default: ;
              endcase
           end
        end else begin
           video_ram_wr_a <= 1'b1;
			  video_ram_aw <= 1'b1;
           video_ram_data_in_a <= data[7:0];
           video_ram_addr_a <= {ram_hi[6:0], ram_lo} + {7'b0, ram_idx};
        end
    end
endtask

endmodule
