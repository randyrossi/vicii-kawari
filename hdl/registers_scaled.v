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

module rgb_RAM
       #(
           parameter addr_width = 11,
           data_width = 36
       )
       (
           input wire wclk,
           input wire [data_width-1:0] din,
           input wire [addr_width-1:0] waddr,
           input wire [addr_width-1:0] raddr,
           input wire we,
           input wire rclk,
           output reg [data_width-1:0] dout
       );

(* ram_style = "distributed" *) reg [data_width-1:0] ram_loc[2**addr_width-1:0];

always @(posedge wclk)
begin
  if (we)
    ram_loc[waddr] <= din;
end

always @(posedge rclk)
begin
    dout <= ram_loc[raddr];
end

endmodule

module registers
       #(
           parameter ram_width = `VIDEO_RAM_WIDTH,
           ram_hi_width = `VIDEO_RAM_HI_WIDTH
       )
       (
           output reg rst = 1'b1,
`ifdef HIRES_RESET
           input cpu_reset_i,
`endif
`ifdef SIMULATOR_BOARD
           input[1:0] sim_chip,
`endif
           input standard_sw,
           input clk_dot4x,
           input clk_dvi,
           input clk_phi,
           input [15:0] phi_phase_start,
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
`ifdef WITH_RAM
           output reg idma,
`endif
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
`ifdef WITH_RAM
           output reg idma_clr,
`endif
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
           output reg [7:0] last_bus,
           output reg [2:0] cb,
           output reg [3:0] vm,
           output reg elp,
           output reg emmc,
           output reg embc,
           output reg erst,
`ifdef WITH_RAM
           output reg edma,
`endif
           // pixel_color3 is from native res pixel sequencer and should be used
           // to look up luma/phase/chroma values
           input [3:0] pixel_color3,
`ifdef LUMACODE
           input [1:0] lumacode_p1,
           input [1:0] lumacode_p2,
`endif
           // pixel_color4 is from the scan doubler and should be used to look up
           // RGB color register ram, 4 bit address.
`ifdef NEED_RGB
           input [3:0] pixel_color4,
           input half_bright,
           input active,
           output reg[5:0] red,
           output reg[5:0] green,
           output reg[5:0] blue,
           // Current settings
           output reg last_raster_lines, // for dvi/vga only
           output reg last_is_native_y, // for dvi/vga only
           output reg last_is_native_x, // for dvi/vga only
           output reg last_enable_csync, // for dvi/vga only
           output reg last_hpolarity, // for vga only
           output reg last_vpolarity, // for vga only
`endif
`ifdef GEN_LUMA_CHROMA
           output reg white_line = 1'b1,
`ifdef LUMACODE
           output reg lumacode = 1'b0,
`endif
           output reg ntsc_50 = 1'b0,
           //output reg pal_60 = 1'b0,
           output reg [5:0] lumareg_o,
           output reg [7:0] phasereg_o,
           output reg [3:0] amplitudereg_o,
`endif

`ifdef WITH_EXTENSIONS

`ifdef HAVE_FLASH
           output reg flash_s = 1'b1,
`endif
`ifdef HAVE_EEPROM
           input cfg_reset,
           output reg eeprom_s = 1'b1,
`endif
           input spi_lock,
           input extensions_lock,
           input persistence_lock,
`ifdef GEN_LUMA_CHROMA
`ifdef CONFIGURABLE_LUMAS
           output reg [5:0] blanking_level,
           output reg [3:0] burst_amplitude,
`endif
`endif
`ifdef CONFIGURABLE_TIMING
           output reg timing_change,
           output reg [7:0] timing_h_blank,
           output reg [7:0] timing_h_fporch,
           output reg [7:0] timing_h_sync,
           output reg [7:0] timing_h_bporch,
           output reg [7:0] timing_v_blank,
           output reg [7:0] timing_v_fporch,
           output reg [7:0] timing_v_sync,
           output reg [7:0] timing_v_bporch,
`endif
`ifdef HIRES_MODES
           input [ram_width-1:0] video_ram_addr_b,
           output [7:0] video_ram_data_out_b,
           output reg [2:0] hires_char_pixel_base,
           output reg [3:0] hires_matrix_base,
           output reg [3:0] hires_color_base,
           output reg hires_enabled,
           output reg hires_allow_bad,
           output reg [2:0] hires_mode,
           output reg [7:0] hires_cursor_hi,
           output reg [7:0] hires_cursor_lo,
`endif
`ifdef WITH_SPI
           output reg    spi_d = 1'b1,
           input         spi_q,
           output reg    spi_c = 1'b1,
`endif
`ifdef WITH_RAM
           input [3:0] cycle_type,
           input idle,
           output reg dma_done = 1'b1,
           output reg [15:0] dma_addr,
`endif
`endif // WITH_EXTENSIONS

           output reg rw_ctl = 1'b0,
           output reg [1:0] chip
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

`ifdef WITH_EXTENSIONS
// Default to min version. If we never read any eeprom values,
// this is the value that will be returned.
reg[7:0] cfg_version = 8'hff;
reg[7:0] magic_1;
reg[7:0] magic_2;
reg[7:0] magic_3;
reg[7:0] magic_4;
reg [1:0] extra_regs_activation_ctr;
reg extra_regs_activated;
reg [1:0] spi_reg_activation_ctr;
reg spi_reg_activated;

`ifdef WITH_RAM
// Flags to govern read accesses causing auto inc/dec
reg video_ram_r; // also used to trigger auto inc after read
reg video_ram_r2; // also used to trigger auto inc after read
reg video_ram_aw; // auto increment after write is necessary
`endif

`ifdef CONFIGURABLE_RGB
reg color_regs_r; // also used to trigger auto inc after read
reg color_regs_r2; // also used to trigger auto inc after read
reg color_regs_aw; // auto increment after write is necessary
reg [1:0] color_regs_r_nibble;
reg [1:0] color_regs_wr_nibble;
`endif

`ifdef CONFIGURABLE_LUMAS
reg luma_regs_r; // also used to trigger auto inc after read
reg luma_regs_r2; // also used to trigger auto inc after read
reg luma_regs_aw; // auto increment after write is necessary
reg [1:0] luma_regs_r_nibble;
reg [1:0] luma_regs_wr_nibble;
`endif

`ifdef WITH_MATH
reg [31:0] result32;
reg [15:0] u_op_1;
reg [15:0] u_op_2;
reg signed [15:0] s_op_1;
reg signed [15:0] s_op_2;
wire u_div_done;
wire s_div_done;
wire [15:0] u_quotient;
wire [15:0] u_remain;
wire [15:0] s_quotient;
wire [15:0] s_remain;
reg [7:0] operator;
reg divzero;
`endif

reg [1:0] flag_port_1_func;
reg [1:0] flag_port_2_func;
reg port_selector; // which port are we applying func to
reg flag_regs_overlay;
reg flag_persist;

reg [7:0] port_hi_1;
reg [7:0] port_lo_1;
reg [7:0] port_idx_1;
reg [7:0] port_hi_2;
reg [7:0] port_lo_2;
reg [7:0] port_idx_2;

`ifdef WITH_RAM
// Port A used for CPU access
reg [ram_width-1:0] video_ram_addr_a;
reg video_ram_wr_a;
reg [7:0] video_ram_data_in_a;
wire [7:0] video_ram_data_out_a;

reg [15:0] video_ram_copy_src; // for both vmem<->vmem or dram<->vmem
reg [15:0] video_ram_copy_dst; // for both vmem<->vmem or dram<->vmem
reg [15:0] video_ram_copy_num; // for vmem<->vmem
reg [15:0] video_dma_copy_num; // for dram<->vmem
// For vmem<->vmem, direction of copy
// For dram<->vmem, 0=dram->vmem, 1=vmem->dram
reg video_ram_copy_dir;
// 0= write off, set read addr
// 1= read data, set write addr, write on
reg [1:0] video_ram_copy_state;
reg video_ram_copy_done = 1'b1;

reg [15:0] video_ram_fill_dst;
reg [15:0] video_ram_fill_num;
reg [7:0] video_ram_fill_val;
reg video_ram_fill_done = 1'b1;

`ifdef WITH_BLITTER
reg [9:0] blit_width;
reg [9:0] blit_height;
reg [15:0] blit_src_ptr;
reg [1:0] blit_src_x;
reg [7:0] blit_src_stride;

reg [15:0] blit_dst_ptr;
reg [1:0] blit_dst_x;
reg [7:0] blit_dst_stride;

reg [7:0] blit_flags;

reg blit_done = 1'b1;
reg [15:0] blit_src_cur;
reg [15:0] blit_dst_cur;
reg [7:0] blit_d; // dest mem byte
reg [7:0] blit_s; // src mem byte
reg [7:0] blit_o; // output byte
reg [8:0] blit_dst_pos; // dest byte offset from base ptr
reg [8:0] blit_src_pos; // src byte offset from base ptr
reg [9:0] blit_line; // keep track of raster line of bitmap
reg [1:0] blit_dst_align; // num pixels out of alignment
reg [1:0] blit_src_align; // num pixels out of alignment
reg [2:0] blit_src_avail; // num pixels available from src
reg [2:0] blit_dst_avail; // num pixels available from dst
reg [2:0] blit_out_avail; // num pixels available from out
reg [9:0] blit_pixels_written; // num pixels written from output
reg [2:0] blit_state;
reg blit_init;

wire [2:0] PIXELS_PER_BYTE;
assign PIXELS_PER_BYTE = hires_mode == 3'b011 ? 3'd4 : 3'd2;

`endif // WITH_BLITTER

`endif // WITH_RAM

// Regarding pre_wr registers below: We need an additional cycle to
// read existing values before writing. Otherwise, the data_out_a
// register will have garbage. This goes for both color and luma
// registers where we pack components inside a wider register.

`ifdef CONFIGURABLE_RGB
// For CPU register read/write to color regs
reg [3:0] color_regs_addr_a; // 16 regs
reg color_regs_wr_a;
reg color_regs_pre_wr_a;
reg color_regs_pre_wr2_a;
reg [5:0] color_regs_wr_value;
reg [23:0] color_regs_data_in_a;
wire [23:0] color_regs_data_out_a;
wire [23:0] color_regs_data_out_b;
reg [17:0] prev_col;
`else
// When no configurable luma, we still populate this for
// the scaler.
reg [23:0] color_regs_data_out_b;
reg [17:0] prev_col;
`endif

`ifdef CONFIGURABLE_LUMAS
// For CPU register read/write to luma regs
reg [3:0] luma_regs_addr_a;
reg luma_regs_wr_a;
reg luma_regs_pre_wr_a;
reg luma_regs_pre_wr2_a;
reg [7:0] luma_regs_wr_value;
reg [17:0] luma_regs_data_in_a;
wire [17:0] luma_regs_data_out_a;
wire [17:0] luma_regs_data_out_b;
`endif

`ifndef HIRES_MODES
// Implies WITH_RAM and WITH_EXTENSIONS
// When extensions are enabled but we have no hires modes,
// then nothing needs to read from port b of video ram.
// So we have to define the wire/reg here.
wire [ram_width-1:0] video_ram_addr_b;
wire [7:0] video_ram_data_out_b;
assign video_ram_addr_b = {8'b0, `VIDEO_RAM_LO_PAD};
`endif

`ifdef WITH_RAM
// Auto increment/decrement of extra reg addr should happen on reads/writes
// to the extra reg data port.  Some CPU instructions result in a single
// read or write.  However, some CPU instructions address the
// memory location over 2 cycles, once for a read and then again for a write.
// We defer read inc/dec until the following cycle in case it is immediately
// followed by a write. This ensures increment happens after the CPU
// instruction is complete.
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
`endif // WITH_RAM

reg active_buf;
reg [10:0] scale_ctr_waddr;
reg [10:0] scale_ctr_raddr;
wire [35:0] linebuf_color1;
wire [35:0] linebuf_color2;

// These buffers store each pixel color RGB value
// (and the previous one).  We use a double buffer so we
// always read from one while writing to the other.
// The buffer is filled with one complete line from
// the dot4x clock while the clk_dvi scans twice
// for each line. The buffer is being filled from the
// RGB value lookup from pixel_color3 coming from the
// sync module.

rgb_RAM lbr1(
    clk_dot4x,
    {color_regs_data_out_b[23:6], prev_col},
    scale_ctr_waddr,
    scale_ctr_raddr,
    active_buf,
    clk_dvi,
    linebuf_color1
);   

rgb_RAM lbr2(
    clk_dot4x,
    {color_regs_data_out_b[23:6], prev_col},
    scale_ctr_waddr,
    scale_ctr_raddr,
    ~active_buf,
    clk_dvi,
    linebuf_color2
);   

`ifdef CONFIGURABLE_RGB
COLOR_REGS color_regs(clk_dot4x,
                      color_regs_wr_a, // write to color ram
                      color_regs_addr_a, // addr for color ram read/write
                      color_regs_data_in_a,
                      color_regs_data_out_a,
                      1'b0, // we never write to port b
                      clk_dot4x,
`ifdef NEED_RGB
                      pixel_color4, // read addr for color lookups
`else
                      4'b0,
`endif
                      24'b0, // we never write to port b
                      color_regs_data_out_b // read value for color lookups
                     );
`else
always @(pixel_color4)
begin
    case (pixel_color4)
        `BLACK:{color_regs_data_out_b} = {6'h00, 6'h00, 6'h00, 6'h00};
        `WHITE:{color_regs_data_out_b} = {6'h3f, 6'h3f, 6'h3f, 6'h00};
        `RED:{color_regs_data_out_b} = {6'h2b, 6'h0a, 6'h0a, 6'h00};
        `CYAN:{color_regs_data_out_b} = {6'h18, 6'h36, 6'h33, 6'h00};
        `PURPLE:{color_regs_data_out_b} = {6'h2c, 6'h0f, 6'h2d, 6'h00};
        `GREEN:{color_regs_data_out_b} = {6'h12, 6'h31, 6'h12, 6'h00};
        `BLUE:{color_regs_data_out_b} = {6'h0d, 6'h0e, 6'h31, 6'h00};
        `YELLOW:{color_regs_data_out_b} = {6'h39, 6'h3b, 6'h13, 6'h00};
        `ORANGE:{color_regs_data_out_b} = {6'h2d, 6'h16, 6'h07, 6'h00};
        `BROWN:{color_regs_data_out_b} = {6'h1a, 6'h0e, 6'h02, 6'h00};
        `PINK:{color_regs_data_out_b} = {6'h3a, 6'h1d, 6'h1b, 6'h00};
        `DARK_GREY:{color_regs_data_out_b} = {6'h13, 6'h13, 6'h13, 6'h00};
        `GREY:{color_regs_data_out_b} = {6'h21, 6'h21, 6'h21, 6'h00};
        `LIGHT_GREEN:{color_regs_data_out_b} = {6'h29, 6'h3e, 6'h27, 6'h00};
        `LIGHT_BLUE:{color_regs_data_out_b} = {6'h1c, 6'h1f, 6'h39, 6'h00};
        `LIGHT_GREY:{color_regs_data_out_b} = {6'h2d, 6'h2d, 6'h2d, 6'h00};
    endcase
end

`endif

// Lumacode : pixel_color3 is an index from 0-15
//            4 valid luma values are placed in luma registers 0-3
//            low phase of pixel : luma_value = luma_reg[pixel_color3[1:0]]
//            hi phase of pixel : luma_value = luma_reg[pixel_color3[3:2]]
`ifdef CONFIGURABLE_LUMAS
LUMA_REGS luma_regs(clk_dot4x,
                    luma_regs_wr_a, // write to luma ram
                    luma_regs_addr_a, // addr for luma ram read/write
                    luma_regs_data_in_a,
                    luma_regs_data_out_a,
                    1'b0, // we never write to port b
`ifdef LUMACODE
                    lumacode ?
                        (lumacode_ff[1] ?
                             // First half pixel
                             {2'b0, lumacode_p1 } :
                             // Second half pixel
                             {2'b0, lumacode_p2 }) :
                        pixel_color3, // read addr for luma lookups
`else
                    pixel_color3, // read addr for luma lookups
`endif
                    18'b0, // we never write to port b
                    luma_regs_data_out_b // read value for luma lookups
                   );
`endif
`endif // WITH_EXTENSIONS

`ifdef HAVE_EEPROM
`include "registers_eeprom.vh"
`else
`include "registers_no_eeprom.vh"
`endif

`ifdef WITH_EXTENSIONS
`ifdef HAVE_FLASH
`include "registers_flash.vh"
`endif

`ifdef WITH_MATH

divide u_divider(.clk(clk_dot4x),
                 .sign(1'b0),
                 .done(u_div_done),
                 .dividend(u_op_1),
                 .divider(u_op_2),
                 .quotient(u_quotient),
                 .remainder(u_remain));

divide s_divider(.clk(clk_dot4x),
                 .sign(1'b1),
                 .done(s_div_done),
                 .dividend(s_op_1),
                 .divider(s_op_2),
                 .quotient(s_quotient),
                 .remainder(s_remain));

always @(posedge clk_dot4x)
begin
    case (operator)
        `U_MULT: begin
            result32 = {16'b0, u_op_1} * {16'b0, u_op_2};
            divzero = 0;
        end
        `U_DIV: begin
            if (u_op_2 == 0)
                divzero = 1;
            else if (u_div_done) begin
                result32[15:0] = u_quotient;
                result32[31:16] = u_remain;
                divzero = 0;
            end
        end
        `S_MULT: begin
            result32 = {s_op_1[15],s_op_1[15],s_op_1[15],s_op_1[15],s_op_1[15],s_op_1[15],s_op_1[15],s_op_1[15],s_op_1[15],s_op_1[15],s_op_1[15],s_op_1[15],s_op_1[15],s_op_1[15],s_op_1[15],s_op_1[15], s_op_1[15:0]} *
            {s_op_2[15],s_op_2[15],s_op_2[15],s_op_2[15],s_op_2[15],s_op_2[15],s_op_2[15],s_op_2[15],s_op_2[15],s_op_2[15],s_op_2[15],s_op_2[15],s_op_2[15],s_op_2[15],s_op_2[15],s_op_2[15], s_op_2[15:0]};
            divzero = 0;
        end
        `S_DIV: begin
            if (s_op_2 == 0)
                divzero = 1;
            else if (s_div_done) begin
                result32[15:0] = s_quotient;
                result32[31:16] = s_remain;
                divzero = 0;
            end
        end
        default: ;
    endcase
end
`endif // WITH_MATH

`endif // WITH_EXTENSIONS

// Master process block for registers
always @(posedge clk_dot4x)
begin
    handle_persist(rst);

    if (rst) begin

`ifdef TEST_PATTERN
        ec <= `LIGHT_BLUE;
        b0c <= `BLUE;
        den <= `TRUE;
`endif
`ifdef HAVE_FLASH
        flash_busy <= 1'b0;
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
        //irst_clr <= `FALSE;
        //imbc_clr <= `FALSE;
        //immc_clr <= `FALSE;
        //ilp_clr <= `FALSE;
        //idma_clr <= `FALSE;
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
        //erst <= `FALSE;
        //embc <= `FALSE;
        //emmc <= `FALSE;
        //elp <= `FALSE;
        //edma <= `FALSE;
        //dbo[7:0] <= 8'd0;
        //handle_sprite_crunch <= `FALSE;

`ifdef NEED_RGB
        //last_raster_lines <= 1'b0;
        //last_is_native_y <= 1'b0;
        //last_is_native_x <= 1'b0;
        //last_enable_csync <= 1'b0;
        //last_hpolarity <= 1'b0;
        //last_vpolarity <= 1'b0;
`endif

`ifdef WITH_EXTENSIONS
`ifdef GEN_LUMA_CHROMA
`ifdef CONFIGURABLE_LUMAS
        blanking_level <= 6'd12;
        burst_amplitude <= 4'd12;
`endif
`endif
`ifdef CONFIGURABLE_TIMING
        timing_change <= 1'b0;
`ifdef ANALOG_RGB_TIMING
        timing_h_blank <= 126; // +384
        timing_h_fporch <= 10;
        timing_h_sync <= 70;
        timing_h_bporch <= 20;
`else
        timing_h_blank <= 84;
        timing_h_fporch <= 30;
        timing_h_sync <= 64;
        timing_h_bporch <= 68;
`endif
        timing_v_blank <= 74;
        timing_v_fporch <= 38;
        timing_v_sync <= 5;
        timing_v_bporch <= 5;
`endif
        //extra_regs_activation_ctr <= 2'b0;

        //flag_port_1_func <= 2'b0;
        //flag_port_2_func <= 2'b0;
        //flag_regs_overlay <= 1'b0;
        //flag_persist <= 1'b0;

`ifdef SIMULATOR_BOARD
        extra_regs_activated <= 1'b1;
`ifdef HIRES_MODES
	`ifdef HIRES_TEXT
        // Test mode 0 : Text
        hires_enabled <= 1'b1;
        hires_allow_bad <= 1'b0;
        hires_mode <= 3'b000;
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
        hires_allow_bad <= 1'b0;
        hires_mode <= 3'b001;
        hires_char_pixel_base <= 3'b0; // ignored
        // pixels @0000(16k)
        hires_matrix_base <= 4'b0000;
        // color table @8000(2K)
        hires_color_base <= 4'b1000;
	`endif
	`ifdef HIRES_BITMAP2
        hires_enabled <= 1'b1;
        hires_allow_bad <= 1'b0;
        hires_mode <= 3'b010;
        hires_char_pixel_base <= 3'b0; // ignored
        hires_matrix_base <= 4'b0000; // 32k bank
        hires_color_base <= 4'b0000; // ignored
	`endif
	`ifdef HIRES_BITMAP3
        hires_enabled <= 1'b1;
        hires_allow_bad <= 1'b0;
        hires_mode <= 3'b011;
        hires_char_pixel_base <= 3'b0; // ignored
        hires_matrix_base <= 4'b0000; // 32k bank
        hires_color_base <= 4'b0000; // 4 color bank
	`endif
	`ifdef HIRES_BITMAP4
        hires_enabled <= 1'b1;
        hires_allow_bad <= 1'b0;
        hires_mode <= 3'b100;
        hires_char_pixel_base <= 3'b0; // ignored
        // pixels @0000(16k)
        hires_matrix_base <= 4'b0000;
        hires_color_base <= 4'b0000; // ignored
	`endif
`endif // HIRES_MODES

        /*
        `ifdef HAVE_FLASH
               //FOR TESTING FLASH WRITE IN SIM
               if (spi_lock) begin
                 flash_begin <= `FLASH_WRITE;
                 // Grab the write address from 0x35,0x36,0x3a
                 flash_vmem_addr <= 0;
                 flash_addr <= 24'h7d000;
                 flash_command_ctr <= `FLASH_CMD_WREN;
                 flash_bit_ctr <= 6'd0;
                 flash_busy <= 1'b1;
                 flash_verify_error <= 1'b0;
                 flash_page_ctr = 6'b0;
               end
        `endif
        */
        /*
        `ifdef HAVE_FLASH
               //FOR TESTING FLASH READ IN SIM
               if (spi_lock) begin
                 flash_begin <= `FLASH_READ;
                 // Grab the write address from 0x35,0x36,0x3a
                 flash_vmem_addr <= 0;
                 flash_addr <= 24'h7d000;
                 flash_command_ctr <= `FLASH_CMD_READ;
                 flash_bit_ctr <= 6'd0;
                 flash_busy <= 1'b1;
                 flash_verify_error <= 1'b0;
                 flash_page_ctr = 6'b0;
               end
        `endif
        */

`else // SIMULATION_BOARD
        //extra_regs_activated <= 1'b0;
`ifdef HIRES_MODES
        //hires_mode <= 3'b000;
        //hires_enabled <= 1'b0;
        //hires_allow_bad <= 1'b0;
        //hires_char_pixel_base <= 3'b0;
        //hires_matrix_base <= 4'b0000; // ignored
        //hires_color_base <= 4'b0000; // ignored
        //hires_cursor_hi <= 8'b0;
        //hires_cursor_lo <= 8'b0;
`endif // HIRES_MODES

`endif // SIMULATOR_BOARD
`endif // WITH_EXTENSIONS

    end else
    begin

`ifdef WITH_EXTENSIONS
`ifdef HAVE_FLASH
        handle_flash();
`endif
`ifdef HIRES_MODES
`ifdef HIRES_RESET

        // This block will detect a reset (if the reset line is
        // hooked up to the 6510 CPU reset pin) and reset hires
        // registers and restore all extra regs as well if eeprom
        // is included.
`ifdef HAVE_EEPROM
        if (!cpu_reset_i && extra_regs_activated && !eeprom_busy) begin
`else
        if (!cpu_reset_i && extra_regs_activated) begin
`endif
            hires_mode <= 3'b000;
            hires_enabled <= 1'b0;
            hires_allow_bad <= 1'b0;
            hires_char_pixel_base <= 3'b0;
            hires_matrix_base <= 4'b0000;
            hires_color_base <= 4'b0000;
            hires_cursor_hi <= 8'b0;
            hires_cursor_lo <= 8'b0;
            spi_reg_activated <= 1'b0;
`ifdef HAVE_EEPROM
            state_ctr_reset_for_read <= 1;
            // TODO: Else, we should reset color regs from hardcoded values.
`endif
        end
`endif // HIRES_RESET
`endif // HIRES_MODES

`ifdef HAVE_EEPROM
        if (!cfg_reset && !eeprom_busy) begin
            eeprom_busy <= 1'b1;
            eeprom_w_addr <= { 2'b0, `EXT_REG_MAGIC_0 };
            eeprom_w_value <= 8'h00;
            state_ctr_reset_for_write <= 1'b1;
            ec <= `WHITE;
            b0c <= `WHITE;
        end
`endif
`endif // WITH_EXTENSIONS

`ifdef WITH_RAM
        if (idma_clr)
            idma <= `FALSE;
`endif

        if (phi_phase_start[`DATA_DAV_PLUS_1]) begin
            if (!clk_phi) begin
                // always clear these immediately after they may
                // have been used. This should be DAV + 1
                irst_clr <= `FALSE;
                imbc_clr <= `FALSE;
                immc_clr <= `FALSE;
                ilp_clr <= `FALSE;
`ifdef WITH_RAM
                idma_clr <= `FALSE;
`endif
                m2m_clr <= `FALSE;
                m2d_clr <= `FALSE;
            end

            addr_latch_done <= `FALSE;
            last_bus <= 8'hff;
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
            if (rw && phi_phase_start[`DATA_DAV]) begin
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

            if (rw) begin
                last_bus <= dbo;

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
`ifdef WITH_RAM
                        dbo[7:0] <= {irq, 
                           extra_regs_activated ? {2'b11 , idma} : 3'b111,
                               ilp, immc, imbc, irst};
`else
                        dbo[7:0] <= {irq, 3'b111, ilp, immc, imbc, irst};
`endif
                    /* 0x1a */ `REG_INTERRUPT_CONTROL:
`ifdef WITH_RAM
                        dbo[7:0] <= {1'b1, 
                           extra_regs_activated ? {2'b11, edma} : 3'b111,
                               elp, emmc, embc, erst};
`else
                        dbo[7:0] <= {1'b1, 3'b111, elp, emmc, embc, erst};
`endif
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
                    default:
// Make sure we qualify this with a check on extra regs
// activated or not if we have extensions. We don't want to
// set dbo here and then possibly again down below.
`ifdef WITH_EXTENSIONS
                        if (~extra_regs_activated)
`endif // WITH_EXTENSIONS
                            dbo[7:0] <= 8'hFF;

                endcase

`ifdef WITH_EXTENSIONS
                if (extra_regs_activated) begin
                    case (addr_latched[5:0])
`ifdef WITH_MATH
                        /* 0x2f */ 6'h2f: begin
                            dbo[7:0] <= result32[31:24];
                        end
                        /* 0x30 */ 6'h30: begin
                            dbo[7:0] <= result32[23:16];
                        end
                        /* 0x31 */ 6'h31: begin
                            dbo[7:0] <= result32[15:8];
                        end
                        /* 0x32 */ 6'h32: begin
                            dbo[7:0] <= result32[7:0];
                        end
                        /* 0x33 */ 6'h33: begin
                            dbo[7:0] <= {7'b0, divzero};
                        end
`endif
                        `SPI_REG:
                            dbo[7:0] <= {
                                2'b0,
                                persistence_lock,
                                extensions_lock,
                                spi_lock,
`ifdef HAVE_FLASH
                                flash_verify_error,
                                flash_busy,
`else
                                1'b0,
                                1'b0,
`endif
`ifdef WITH_SPI
                                spi_q
`else
                                1'b0
`endif
                            };
                        `VIDEO_MEM_1_IDX:
                            dbo[7:0] <= port_idx_1;
                        `VIDEO_MEM_2_IDX:
                            dbo[7:0] <= port_idx_2;
                        `VIDEO_MODE1: begin
`ifdef HIRES_MODES
                            dbo[7:0] <= { hires_mode,
                                          hires_enabled,
                                          hires_allow_bad,
                                          hires_char_pixel_base };
`else
                            dbo[7:0] <= { 1'b0,
                                          2'b0,
                                          1'b0,
                                          1'b0,
                                          3'b0 };
`endif
                        end
                        `VIDEO_MODE2:
`ifdef HIRES_MODES
                            dbo[7:0] <= { hires_color_base, hires_matrix_base };
`else
                            dbo[7:0] <= { 4'b0, 4'b0 };
`endif
                        `VIDEO_MEM_1_HI:
                            dbo[7:0] <= port_hi_1;
                        `VIDEO_MEM_1_LO:
                            dbo[7:0] <= port_lo_1;
                        `VIDEO_MEM_1_VAL:
                        begin
                            // reg overlay or video mem
                            port_selector <= 0;
                            read_ram(
                                .overlay(flag_regs_overlay),
                                .ram_lo(port_lo_1),
                                .ram_hi(port_hi_1),
                                .ram_idx(port_idx_1));
                        end
                        `VIDEO_MEM_2_HI:
                            dbo[7:0] <= port_hi_2;
                        `VIDEO_MEM_2_LO:
                            dbo[7:0] <= port_lo_2;
                        `VIDEO_MEM_2_VAL:
                        begin
                            // reg overlay or video mem
                            port_selector <= 1;
                            read_ram(
                                .overlay(flag_regs_overlay),
                                .ram_lo(port_lo_2),
                                .ram_hi(port_hi_2),
                                .ram_idx(port_idx_2));
                        end
                        /* 0x3F */ `VIDEO_MEM_FLAGS:
                            dbo[7:0] <= { 1'b0,
                                          flag_persist,
                                          flag_regs_overlay,
`ifdef HAVE_EEPROM
                                          eeprom_busy, // eeprom busy
`else
                                          1'b0,
`endif
                                          flag_port_2_func,
                                          flag_port_1_func
                                        };
                        default:;
                    endcase
                end
`endif // WITH_EXTENSIONS

            end
            // WRITE to register
            else begin /* ~rw */
                if (phi_phase_start[`DATA_DAV]) begin
                    last_bus <= dbi;
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
`ifdef WITH_RAM
                        idma_clr <= dbi[4];
`endif
                    end
                    /* 0x1a */ `REG_INTERRUPT_CONTROL: begin
                        erst <= dbi[0];
                        embc <= dbi[1];
                        emmc <= dbi[2];
                        elp <= dbi[3];
`ifdef WITH_RAM
                        edma <= dbi[4];
`endif
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
                    default:;
                    endcase
                end

`ifdef WITH_EXTENSIONS
                // We have an extra condition to only do this write
                // once for extended registers because we have counters
                // and state machines that rely on that.
                if (phi_phase_start[`DATA_DAV]) begin
                    if (~extra_regs_activated) begin
                        case (addr_latched[5:0])
                            // Handle activation sequence here.
                            /* 0x3f */ `VIDEO_MEM_FLAGS:
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
                                    // extensions_lock must CLOSED
                                    if (extra_regs_activation_ctr == 2'd3
                                            && ~extensions_lock)
                                        extra_regs_activated <= 1'b1;
                                    else
                                        extra_regs_activation_ctr <= 2'd0;
                                default:
                                    extra_regs_activation_ctr <= 2'd0;
                            endcase
                            default:;
                        endcase
                    end else begin /* extra_regs_activated */
                        case (addr_latched[5:0])
`ifdef WITH_MATH
                            /* 0x2f */ 6'h2f: begin
                                u_op_1[15:8] <= dbi[7:0];
                                s_op_1[15:8] <= dbi[7:0];
                            end
                            /* 0x30 */ 6'h30: begin
                                u_op_1[7:0] <= dbi[7:0];
                                s_op_1[7:0] <= dbi[7:0];
                            end
                            /* 0x31 */ 6'h31: begin
                                u_op_2[15:8] <= dbi[7:0];
                                s_op_2[15:8] <= dbi[7:0];
                            end
                            /* 0x32 */ 6'h32: begin
                                u_op_2[7:0] <= dbi[7:0];
                                s_op_2[7:0] <= dbi[7:0];
                            end
                            /* 0x33 */ 6'h33: begin
                                operator <= dbi[7:0];
                            end
`endif
                            /* 0x34 */ `SPI_REG:
                            begin
                                // As an extra precaution, the spi reg is guarded
                                // by an addiional activation sequence.
                                if (~spi_reg_activated)
                                case (dbi[7:0])
                                    /* "S" */ 8'd83:
                                        if (spi_reg_activation_ctr == 2'd0)
                                            spi_reg_activation_ctr <= spi_reg_activation_ctr + 2'b1;
                                    /* "P" */ 8'd80:
                                        if (spi_reg_activation_ctr == 2'd1)
                                            spi_reg_activation_ctr <= spi_reg_activation_ctr + 2'b1;
                                        else
                                            spi_reg_activation_ctr <= 2'd0;
                                    /* "I" */ 8'd73:
                                        if (spi_reg_activation_ctr == 2'd2)
                                            spi_reg_activated <= 1'b1;
                                        else
                                            spi_reg_activation_ctr <= 2'd0;
                                    default:
                                        spi_reg_activation_ctr <= 2'd0;
                                endcase
                                else begin
                                    // Bit 7 indicates bulk op
                                    if (dbi[7]) begin
`ifdef HAVE_FLASH
                                        // spi_lock must be OPEN for SPI access
                                        if (!flash_busy && spi_lock) begin
                                            // This is a bulk flash command. Last two
                                            // bits of dbi represent the operation.
                                            // FLASH_WRITE 01
                                            // FLASH_READ  10
                                            flash_begin <= dbi[1:0];
                                            // Greb vmem address
                                            flash_vmem_addr <= {port_hi_2[ram_hi_width-1:0], port_lo_2};
                                            // Grab the flash write address
                                            flash_addr <=
                                            {port_idx_1,
                                             port_hi_1,
                                             port_lo_1};
                                            if (dbi[1:0] == `FLASH_WRITE)
                                                flash_command_ctr <= `FLASH_CMD_WREN;
                                            else
                                                flash_command_ctr <= `FLASH_CMD_READ;
                                            flash_bit_ctr <= 6'd0;
                                            flash_busy <= 1'b1;
                                            flash_verify_error <= 1'b0;
                                            flash_page_ctr = `FLASH_PAGE_RESET;
                                            $display("start flash");
                                        end
`endif
                                    end else begin
                                        // Directly set SPI lines
                                        // spi_lock must be OPEN for SPI access
                                        if (spi_lock) begin
`ifdef HAVE_FLASH
                                            flash_s <= dbi[0];
`endif
`ifdef WITH_SPI
                                            spi_c <= dbi[1];
                                            spi_d <= dbi[2];
`endif
`ifdef HAVE_EEPROM
                                            eeprom_s <= dbi[3];
`endif
                                        end
                                    end
                                end
                            end
                            `VIDEO_MEM_1_IDX:
                                port_idx_1 <= dbi;
                            `VIDEO_MEM_2_IDX:
                                port_idx_2 <= dbi;
                            `VIDEO_MODE1:
                            begin
`ifdef HIRES_MODES
                                hires_mode <= dbi[7:5];
                                hires_enabled <= dbi[`HIRES_ENABLE];
                                hires_allow_bad <= dbi[`HIRES_ALLOW_BAD];
                                hires_char_pixel_base <= dbi[2:0];
`endif
                            end
                            `VIDEO_MODE2:
                            begin
`ifdef HIRES_MODES
                                hires_matrix_base <= dbi[3:0];
                                hires_color_base <= dbi[7:4];
`endif
                            end
                            /* 0x3f */ `VIDEO_MEM_FLAGS:
                            begin
                                flag_port_1_func <= dbi[`FLAG_PORT1_FUNCTION];
                                flag_port_2_func <= dbi[`FLAG_PORT2_FUNCTION];
                                flag_regs_overlay <= dbi[`FLAG_REGS_OVERLAY_BIT];
                                flag_persist <= dbi[`FLAG_PERSIST_BIT];
                                if (dbi[`FLAG_DISABLE_BIT])
                                    extra_regs_activated <= 1'b0;
                            end
                            `VIDEO_MEM_1_HI:
                                port_hi_1 <= dbi[7:0];
                            `VIDEO_MEM_1_LO:
                                port_lo_1 <= dbi[7:0];
                            `VIDEO_MEM_1_VAL:
                            begin
                                // NOTE: Prior to 1.16, this included !overlay
                                // flag too but prevented us from dma copying
                                // into overlay regs from vram.  So was removed
                                // should matter much but is a subtle diff.
                                if (flag_port_1_func == 2'b11 &&
                                    flag_port_2_func == 2'b11)
                                begin
`ifdef WITH_RAM
                                    // block copy or fill operation
                                    if (dbi[0]) begin
                                        // copy low to high
                                        video_ram_copy_dst <= { port_hi_1, port_lo_1 };
                                        video_ram_copy_src <= { port_hi_2, port_lo_2 };
                                        video_ram_copy_num <= { port_idx_2, port_idx_1 };
                                        video_ram_copy_state <= 2'b0;
                                        video_ram_copy_dir <= 1'b0;
                                        video_ram_copy_done <= 1'b0;
                                    end else if (dbi[1]) begin
                                        // copy high to low
                                        video_ram_copy_dst <= { port_hi_1, port_lo_1 } + { port_idx_2, port_idx_1 } - 1'b1;
                                        video_ram_copy_src <= { port_hi_2, port_lo_2 } + { port_idx_2, port_idx_1 } - 1'b1;
                                        video_ram_copy_num <= { port_idx_2, port_idx_1 };
                                        video_ram_copy_state <= 2'b0;
                                        video_ram_copy_dir <= 1'b1;
                                        video_ram_copy_done <= 1'b0;
                                    end else if (dbi[2]) begin
                                        // fill
                                        video_ram_fill_dst <= { port_hi_1, port_lo_1 };
                                        video_ram_fill_num <= { port_idx_2, port_idx_1 };
                                        video_ram_fill_val <= port_lo_2;
                                        video_ram_fill_done <= 1'b0;
                                    end else if (dbi[3]) begin
                                        // DMA DRAM to VMEM
                                        video_ram_copy_dst <= { port_hi_1, port_lo_1 };
                                        dma_addr <= { port_hi_2, port_lo_2 }; // DRAM src
                                        video_dma_copy_num <= { port_idx_2, port_idx_1 };
                                        video_ram_copy_dir <= 1'b0;
                                        dma_done <= 1'b0;
                                    end else if (dbi[4]) begin
                                        // DMA VMEM to DRAM
                                        dma_addr <= { port_hi_1, port_lo_1 }; // DRAM dest
                                        video_ram_copy_src <= { port_hi_2, port_lo_2 };
                                        video_dma_copy_num <= { port_idx_2, port_idx_1 };
                                        video_ram_copy_dir <= 1'b1;
                                        dma_done <= 1'b0;
`ifdef WITH_BLITTER
                                    end else if (dbi[5]) begin
                                        // Set Blitter SRC Info
                                        blit_width <= u_op_1[9:0];
                                        blit_height <= u_op_2[9:0];
                                        // src_ptr = base + x / PIXELS_PER_BYTE + y * STRIDE
                                        blit_src_ptr <=
                                            { port_idx_1, port_idx_2 } +
                                            { port_hi_1, port_lo_1 } / { 13'b0, PIXELS_PER_BYTE } +
                                            port_lo_2 * port_hi_2;
                                        blit_src_x <= port_lo_1[1:0];
                                        blit_src_stride <= port_hi_2;
                                    end else if (dbi[6]) begin
                                        // Set Blitter DST Info & Execute
                                        blit_flags <= u_op_1[15:8];
                                        // dst_ptr = base + x / PIXELS_PER_BYTE + y * STRIDE
                                        blit_dst_ptr <=
                                            { port_idx_1, port_idx_2 } +
                                            { port_hi_1, port_lo_1 } / { 13'b0, PIXELS_PER_BYTE } +
                                             port_lo_2 * port_hi_2;
                                        blit_dst_x <= port_lo_1[1:0];
                                        blit_dst_stride <= port_hi_2;
                                        blit_done <= 0;
                                        blit_state <= 0;
                                        blit_init <= 1;
`endif // WITH_BLITTER
                                    end
`else
                                    ;
`endif
                                end else begin
                                    // reg overlay or video mem
                                    // persistence lock must be open to allow
                                    port_selector <= 0;
                                    write_ram(
                                        .overlay(flag_regs_overlay),
                                        .ram_lo(port_lo_1),
                                        .ram_hi(port_hi_1),
                                        .ram_idx(port_idx_1),
                                        .data(dbi),
                                        .from_cpu(1'b1),
                                        .do_persist(flag_persist));
                                end
                            end
                            `VIDEO_MEM_2_HI:
                                port_hi_2 <= dbi[7:0];
                            `VIDEO_MEM_2_LO:
                                port_lo_2 <= dbi[7:0];
                            `VIDEO_MEM_2_VAL:
                            begin
                                // reg overlay or video mem
                                // persistence lock must be open to allow
                                port_selector <= 1;
                                write_ram(
                                    .overlay(flag_regs_overlay),
                                    .ram_lo(port_lo_2),
                                    .ram_hi(port_hi_2),
                                    .ram_idx(port_idx_2),
                                    .data(dbi),
                                    .from_cpu(1'b1),
                                    .do_persist(flag_persist));
                            end
                            default:;
                        endcase
                    end
                end
`endif // WITH_EXTENSIONS
            end // rw or not
        end // ready to handle r/w

`ifdef WITH_EXTENSIONS

`ifdef WITH_RAM
        // CPU read from video mem
        if (video_ram_r)
            dbo[7:0] <= video_ram_data_out_a;
`endif

`ifdef CONFIGURABLE_RGB
        // CPU write to color register ram
        if (color_regs_pre_wr2_a) begin
            color_regs_pre_wr_a <= 1'b1;
            color_regs_pre_wr2_a <= 1'b0;
        end
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
`endif

`ifdef CONFIGURABLE_LUMAS
        // CPU write to luma register ram
        if (luma_regs_pre_wr2_a) begin
            luma_regs_pre_wr_a <= 1'b1;
            luma_regs_pre_wr2_a <= 1'b0;
        end
        if (luma_regs_pre_wr_a) begin
            // Now we can do the write
            luma_regs_pre_wr_a <= 1'b0;
            luma_regs_wr_a <= 1'b1;
            luma_regs_aw <= 1'b1;
            // 18-bits : llllllppppppppaaaa
            case (luma_regs_wr_nibble)
                2'b00: //luma
                    luma_regs_data_in_a <= {luma_regs_wr_value[5:0], luma_regs_data_out_a[11:0]};
                2'b01: // phase
                    luma_regs_data_in_a <= {luma_regs_data_out_a[17:12] , luma_regs_wr_value[7:0], luma_regs_data_out_a[3:0]};
                2'b10: // amplitude
                    luma_regs_data_in_a <= {luma_regs_data_out_a[17:4], luma_regs_wr_value[3:0]};
                default:
                    ;
            endcase
        end
`endif

`ifdef CONFIGURABLE_RGB
        // CPU read from color regs
        if (color_regs_r) begin
            case (color_regs_r_nibble)
                2'b00: dbo[7:0] <= { 2'b0, color_regs_data_out_a[23:18] };
                2'b01: dbo[7:0] <= { 2'b0, color_regs_data_out_a[17:12] };
                2'b10: dbo[7:0] <= { 2'b0, color_regs_data_out_a[11:6] };
                2'b11: dbo[7:0] <= { 2'b0, color_regs_data_out_a[5:0] };
            endcase
        end
`endif

`ifdef CONFIGURABLE_LUMAS
        // CPU read from luma regs
        if (luma_regs_r) begin
            case (luma_regs_r_nibble)
                2'b00: dbo[7:0] <= { 2'b0, luma_regs_data_out_a[17:12] };
                2'b01: dbo[7:0] <= luma_regs_data_out_a[11:4];
                2'b10: dbo[7:0] <= { 4'b0, luma_regs_data_out_a[3:0] };
                default: ;
            endcase
        end
`endif

`ifdef WITH_RAM
        // Only need 1 tick to write to video ram
        if (video_ram_wr_a)
            video_ram_wr_a <= 1'b0;
`endif

`ifdef CONFIGURABLE_RGB
        // Only need 1 tick to write to color ram
        if (color_regs_wr_a)
            color_regs_wr_a <= 1'b0;
`endif

`ifdef CONFIGURABLE_LUMAS
        // Only need 1 tick to write to color ram
        if (luma_regs_wr_a)
            luma_regs_wr_a <= 1'b0;
`endif

        // Near the start of the low cycle, handle auto increment of
        // our vram pointers.
        if (~clk_phi && phi_phase_start[`DATA_DAV_PLUS_2]) begin
`ifdef WITH_RAM
            // Always clear both flags and propagate r to r2 here.
            video_ram_r <= 0;
            video_ram_r2 <= video_ram_r;
            video_ram_aw <= 1'b0;
`endif

`ifdef CONFIGURABLE_RGB
            color_regs_r <= 0;
            color_regs_r2 <= color_regs_r;
            color_regs_aw <= 1'b0;
`endif

`ifdef CONFIGURABLE_LUMAS
            luma_regs_r <= 0;
            luma_regs_r2 <= luma_regs_r;
            luma_regs_aw <= 1'b0;
`endif

            // We propagated r to r2 on reads so that we auto increment
            // two cycles after a read due to some instructions reading first,
            // then writing.  If we didn't do this, those instructions would
            // cause two increments when we only wanted one.  So this effectively
            // waits a full cycle before commiting to increment after a read.
            if (1'b0
`ifdef WITH_RAM
                    || video_ram_r2 || video_ram_aw
`endif
`ifdef CONFIGURABLE_RGB
                    || color_regs_r2 || color_regs_aw
`endif
`ifdef CONFIGURABLE_LUMAS
                    || luma_regs_r2 || luma_regs_aw
`endif
               ) begin
                // Handle auto increment /decrement after port access
                if (port_selector == 0) begin // loc 1 of port a
                    case(flag_port_1_func) // auto inc port a
                        2'd1: begin
                            if (port_lo_1 < 8'hff)
                                port_lo_1 <= port_lo_1 + 8'b1;
                            else begin
                                port_lo_1 <= 8'h00;
                                port_hi_1 <= port_hi_1 + 8'b1;
                            end
                        end
                        2'd2: begin
                            if (port_lo_1 > 8'h00)
                                port_lo_1 <= port_lo_1 - 8'b1;
                            else begin
                                port_lo_1 <= 8'hff;
                                port_hi_1 <= port_hi_1 - 8'b1;
                            end
                        end
                        default:
                            ;
                    endcase
                end else begin // loc 2 of port a
                    case(flag_port_2_func) // auto inc port b
                        2'd1: begin
                            if (port_lo_2 < 8'hff)
                                port_lo_2 <= port_lo_2 + 8'b1;
                            else begin
                                port_lo_2 <= 8'h00;
                                port_hi_2 <= port_hi_2 + 8'b1;
                            end
                        end
                        2'd2: begin
                            if (port_lo_2 > 8'h00)
                                port_lo_2 <= port_lo_2 - 8'b1;
                            else begin
                                port_lo_2 <= 8'hff;
                                port_hi_2 <= port_hi_2 - 8'b1;
                            end
                        end
                        default:
                            ;
                    endcase
                end
            end
        end

`ifdef WITH_RAM
        // Handle VRAM block copy here (vmem<->vmem)
        if (video_ram_copy_num > 0) begin
            if (video_ram_copy_state == 2'b0) begin
                // read
                video_ram_addr_a <= video_ram_copy_src[ram_width-1:0];
            end else if (video_ram_copy_state == 2'b10) begin
                // write
                // NOTE: Ability to write into overlay with copy added in 1.16
                if (flag_regs_overlay) begin
                   write_ram(
                      .overlay(1'b1),
                      .ram_lo(video_ram_copy_dst[7:0]),
                      .ram_hi(8'd0),
                      .ram_idx(8'd0),
                      .data(video_ram_data_out_a),
                      .from_cpu(1'b1),
                      .do_persist(1'b0));
                end else begin
                   video_ram_wr_a <= 1'b1;
                   video_ram_addr_a <= video_ram_copy_dst[ram_width-1:0];
                   video_ram_data_in_a <= video_ram_data_out_a;
                end
                video_ram_copy_num <= video_ram_copy_num - 16'b1;
                if (video_ram_copy_dir) begin
                    video_ram_copy_src <= video_ram_copy_src - 16'b1;
                    video_ram_copy_dst <= video_ram_copy_dst - 16'b1;
                end else begin
                    video_ram_copy_src <= video_ram_copy_src + 16'b1;
                    video_ram_copy_dst <= video_ram_copy_dst + 16'b1;
                end
            end
            video_ram_copy_state <= video_ram_copy_state + 2'b1;
        end
        else if (video_ram_copy_num == 0 && !video_ram_copy_done) begin
            video_ram_copy_done <= 1'b1;
            port_idx_1 <= 8'b0; // signal done
            port_idx_2 <= 8'b0;
            idma <= `TRUE;
        end
        // Handle VMEM block fill here
        if (video_ram_fill_num > 0) begin
            video_ram_wr_a <= 1'b1;
            video_ram_addr_a <= video_ram_fill_dst[ram_width-1:0];
            video_ram_data_in_a <= video_ram_fill_val;
            video_ram_fill_dst <= video_ram_fill_dst + 16'b1;
            video_ram_fill_num <= video_ram_fill_num - 16'b1;
        end
        else if (video_ram_fill_num == 0 && !video_ram_fill_done) begin
            video_ram_fill_done <= 1'b1;
            port_idx_1 <= 8'b0; // signal done
            port_idx_2 <= 8'b0;
            idma <= `TRUE;
        end
        // Handle DMA here
        if (!aec && video_dma_copy_num > 0 && (cycle_type == `VIC_LI || cycle_type == `VIC_LG && idle)) begin
           if (video_ram_copy_dir) begin
              // VMEM->DRAM
              // cycle_type is not valid until [2]
              if (phi_phase_start[2]) begin
                 // setup read from VMEM
                 video_ram_addr_a <= video_ram_copy_src[ram_width-1:0];
              end else if (phi_phase_start[4]) begin
                 // setup write to DRAM, address is set in addressgen.v
                 dbo <= video_ram_data_out_a;
                 rw_ctl <= 1;
              end else if (phi_phase_start[15]) begin
                 // all done, move to next byte
                 video_dma_copy_num <= video_dma_copy_num - 16'd1;
                 rw_ctl <= 0;
                 video_ram_copy_src <= video_ram_copy_src + 16'b1;
                 dma_addr <= dma_addr + 16'b1;
              end
           end else begin
              // DRAM->VMEM
              // cycle_type is not valid until [2]
              if (phi_phase_start[2]) begin
                 // setup read from DRAM, address is set in addressgen.v
                 rw_ctl <= 0;
              end else if (phi_phase_start[0]) begin
                 // do the read from DRAM and setup the write to VMEM
                 video_dma_copy_num <= video_dma_copy_num - 16'd1;
                 video_ram_wr_a <= 1'b1;
                 video_ram_addr_a <= video_ram_copy_dst[ram_width-1:0];
                 video_ram_data_in_a <= dbi;
                 dma_addr <= dma_addr + 16'b1;
                 video_ram_copy_dst <= video_ram_copy_dst + 16'b1;
              end
           end
        end
        else if (video_dma_copy_num == 0 && !dma_done) begin
           dma_done <= 1'b1;
           port_idx_1 <= 8'b0; // signal done
           port_idx_2 <= 8'b0;
           idma <= `TRUE;
        end
`ifdef WITH_BLITTER
        // HANDLE blit here
        // We operate pixel by pixel.
        // We draw pixels from src or dst from the upper bits (from the left).
        // We shift pixels into our out byte (from the right).
        // When the out byte is full of pixels, we flush to memory.
        if (!blit_done) begin
           //$display("blit state %d",blit_state);
           case (blit_state)
             // init
             3'd0: begin
                if (blit_init) begin
                   $display("W:%d H%d SRC:%04x S:%d",
                      blit_width, blit_height, blit_src_ptr, blit_src_stride);
                   $display("FL:%d DST:%04x S:%d",
                      blit_flags, blit_dst_ptr, blit_dst_stride);
                   $display("PIXELS_PER_BYTE = %d  ", PIXELS_PER_BYTE);
                   blit_src_cur = blit_src_ptr;
                   blit_dst_cur = blit_dst_ptr;
                   if (PIXELS_PER_BYTE == 3'd2) begin
                      blit_dst_align = {1'b0, blit_dst_x[0]};
                      blit_src_align = {1'b0, blit_src_x[0]};
                   end else begin
                      blit_dst_align = blit_dst_x[1:0];
                      blit_src_align = blit_src_x[1:0];
                   end
                   $display("DST ALIGN = %d", blit_dst_align);
                   $display("SRC ALIGN = %d", blit_src_align);
                   blit_src_avail = 0;
                   blit_dst_avail = 0;
                   blit_out_avail = 0;
                   blit_pixels_written = 0;
                   blit_src_pos = 0;
                   blit_dst_pos = 0;
                   blit_line = 0;
                   blit_init <= 0;
                end
                // Still need this tick for writes from 3'd7 state below
             end
             3'd1: begin
                // Do we need to read dst pixels?
                if (blit_dst_avail == 0) begin
                   video_ram_addr_a <= blit_dst_cur + {7'b0, blit_dst_pos};
                end
             end
             3'd2:
                ;
                // Need to wait for read
             3'd3: begin
                // Save dst pixels from read in previous state. For now, we
                // assume we have PIXELS_PER_BYTE available pixels.
                if (blit_dst_avail == 0) begin
$display("blit dst read %02x from %4x", video_ram_data_out_a, video_ram_addr_a);
                   blit_dst_avail = PIXELS_PER_BYTE;
$display("blit dst avail %d", blit_dst_avail);
                   blit_d = video_ram_data_out_a;
                end

                // Do we need to read src pixels?
                if (blit_src_avail == 0) begin
                   video_ram_addr_a <= blit_src_cur + {7'b0, blit_src_pos};
                end
             end
             3'd4:
                // Need to wait for read
                ;
             3'd5: begin
                // Save src pixels from read in previous state. For now, we
                // assume we have PIXELS_PER_BYTE available pixels.
                if (blit_src_avail == 0) begin
$display("blit src read %02x from %4x", video_ram_data_out_a, video_ram_addr_a);
                   blit_src_avail = PIXELS_PER_BYTE;
$display("blit src avail %d", blit_src_avail);
                   blit_s = video_ram_data_out_a;
                   // We advance our src byte index here. If we hit the src stride,
                   // move to the next src line and reset src alignment.
                   blit_src_pos = blit_src_pos + 1;
                end

                // Handle dst misalignemnt.
                if (blit_dst_align != 0) begin
                   // If we are not aligned, move the pixels in dst that
                   // should remain untouched to the out byte. Adjust
                   // avail counters.
                   if (PIXELS_PER_BYTE == 3'd2) begin
                      // This case is easy.
                      blit_o = { 4'b0, blit_d[7:4] };
                      blit_d = { blit_d[3:0], 4'b0 };
                      blit_out_avail = 3'b1; // one went to out
                      blit_dst_avail = 3'b1; // one stays in dst
$display("blit dst avail reduced to %d", blit_dst_avail);
                   end else begin
                      // This case is a little more difficult.
                      // When we have 2 bits per pixel (or 4 pixels per byte)
                      // we push pixels we need to save into out and
                      // dst is what remains.  There are 3 cases of mis-alignment
                      // here.
                      if (blit_dst_align == 2'd1) begin
                         blit_o = { 6'b0, blit_d[7:6] };
                         blit_d = { blit_d[5:0], 2'b0 };
                      end else if (blit_dst_align == 2'd2) begin
                         blit_o = { 4'b0, blit_d[7:4] };
                         blit_d = { blit_d[3:0], 4'b0 };
                      end else if (blit_dst_align == 2'd3) begin
                         blit_o = { 2'b0, blit_d[7:2] };
                         blit_d = { blit_d[1:0], 6'b0 };
                      end
                      blit_out_avail = {1'b0, blit_dst_align};
                      blit_dst_avail = 4 - blit_dst_align;
$display("blit dst avail reduced to %d", blit_dst_avail);
                   end
                   blit_dst_align = 0;
                end

                if (blit_src_align != 0) begin
                   if (PIXELS_PER_BYTE == 3'd2) begin
                     blit_s = { blit_s[3:0], 4'b0 };
                     blit_src_avail = blit_src_avail - 1;
$display("blit src avail reduced to %d", blit_src_avail);
                   end else begin
                      if (blit_src_align == 2'd1)
                         blit_s = { blit_s[5:0], 2'b0 };
                      else if (blit_src_align == 2'd2)
                         blit_s = { blit_s[3:0], 4'b0 };
                      else if (blit_src_align == 2'd3)
                         blit_s = { blit_s[1:0], 6'b0 };
                      blit_src_avail = 4 - blit_src_align;
$display("blit src avail reduced to %d", blit_src_avail);
                   end
                   blit_src_align = 0;
                end
             end
             3'd6: begin
                // As long as we have not written width pixels yet.
                // Figure out new pixel = dst pixel OP src pixel
                // Shift out byte up by one pixel to make room in lower bits for new pixel
                // 'Consume' pixel from src and dst and adjust avail counts
                if (blit_pixels_written < blit_width) begin
                   // src pixel is blit_s[7:4]
                   // dst pixel is blit_d[7:4]
                   if (PIXELS_PER_BYTE == 3'd2) begin
                      if (blit_flags[3] && blit_s[7:4] == blit_flags[7:4])
                         blit_o = { blit_o[3:0], blit_d[7:4] }; // transparent
                      else begin
                        case (blit_flags[2:0])
                           3'd0: blit_o = { blit_o[3:0], blit_s[7:4] };
                           3'd1: blit_o = { blit_o[3:0], blit_s[7:4] | blit_d[7:4] };
                           3'd2: blit_o = { blit_o[3:0], blit_s[7:4] & blit_d[7:4] };
                           3'd3: blit_o = { blit_o[3:0], blit_s[7:4] ^ blit_d[7:4] };
                           default:
                              ;
                        endcase
                      end
                      blit_d = { blit_d[3:0], 4'b0 };
                      blit_s = { blit_s[3:0], 4'b0 };
                   end else begin
                      if (blit_flags[3] && blit_s[7:6] == blit_flags[5:4])
                         blit_o = { blit_o[5:0], blit_d[7:6] }; // transparent
                      else begin
                        case (blit_flags[2:0])
                           3'd0: blit_o = { blit_o[5:0], blit_s[7:6] };
                           3'd1: blit_o = { blit_o[5:0], blit_s[7:6] | blit_d[7:6]};
                           3'd2: blit_o = { blit_o[5:0], blit_s[7:6] & blit_d[7:6]};
                           3'd3: blit_o = { blit_o[5:0], blit_s[7:6] ^ blit_d[7:6]};
                           default:
                              ;
                        endcase
                      end
                      blit_d = { blit_d[5:0], 2'b0 };
                      blit_s = { blit_s[5:0], 2'b0 };
                   end
                   blit_src_avail = blit_src_avail - 1;
                   blit_pixels_written = blit_pixels_written + 1;
                end else begin
                   // We can get here if we wrote blit_width pixels but didn't
                   // fill out the output byte yet. So we simply need to pad
                   // with whatever we have left in the dst
                   if (PIXELS_PER_BYTE == 3'd2) begin
                      blit_o = { blit_o[3:0], blit_d[7:4] };
                      blit_d = { blit_d[3:0], 4'b0 };
                   end else begin
                      blit_o = { blit_o[5:0], blit_d[7:6] };
                      blit_d = { blit_d[5:0], 2'b0 };
                   end
                end
                blit_dst_avail = blit_dst_avail - 1;
                blit_out_avail = blit_out_avail + 1;
$display("blit o now %d with %d avail", blit_o, blit_out_avail);
$display("blit d now %d with %d avail", blit_d, blit_dst_avail);
$display("blit s now %d with %d avail", blit_s, blit_src_avail);
             end
             3'd7: begin
                // If out byte is full of pixels, write it to mem now
                if (blit_out_avail == PIXELS_PER_BYTE) begin
$display("write %02x to %04x", blit_o, blit_dst_cur + {7'b0, blit_dst_pos});
                   video_ram_addr_a <= blit_dst_cur + {7'b0, blit_dst_pos};
                   video_ram_wr_a <= 1'b1;
                   video_ram_data_in_a <= blit_o;
                   blit_out_avail = 0;
                   // Advance dst byte index here.
                   blit_dst_pos = blit_dst_pos + 1;
                   if (blit_pixels_written >= blit_width) begin
                      // We wrote enough pixels for a raster line.
                      // Move to next raster line.
                      blit_pixels_written = 0;
                      blit_dst_pos = 0;
                      blit_dst_cur = blit_dst_cur + { 8'b0, blit_dst_stride};
                      blit_line = blit_line + 1;
$display("blit next dst line (%d)", blit_line);
                      // We must reset align flag since we're back to the start.
                      if (PIXELS_PER_BYTE == 3'd2)
                         blit_dst_align = {1'b0, blit_dst_x[0]};
                      else
                         blit_dst_align = blit_dst_x[1:0];

$display("blit next src line");
                      blit_src_pos = 0;
                      blit_src_cur = blit_src_cur + { 8'b0, blit_src_stride };
                      if (PIXELS_PER_BYTE == 3'd2)
                         blit_src_align = {1'b0, blit_src_x[0]};
                      else
                         blit_src_align = blit_src_x[1:0];
                      blit_src_avail = 0;

                      // If we've done all the lines, we are done our blit.
                      if (blit_line == blit_height) begin
                         idma <= `TRUE;
                         blit_done <= 1'b1;
                         port_hi_2 <= 0; // signal done
                      end
                   end
                end
             end
          endcase
          blit_state <= blit_state + 1;
        end
`endif // WITH_BLITTER

`endif // WITH_RAM

`endif // WITH_EXTENSIONS
    end // rst or not
end

`ifdef NEED_RGB

reg [17:0] output_color;
reg [5:0] final_red;
reg [5:0] final_green;
reg [5:0] final_blue;
reg [3:0] weight1;
reg [3:0] weight2;

wire [9:0] iblue1;
wire [9:0] iblue2;
wire [9:0] iblue;
wire [9:0] igreen1;
wire [9:0] igreen2;
wire [9:0] igreen;
wire [9:0] ired1;
wire [9:0] ired2;
wire [9:0] ired;

// Mux the final color based on active_buf. We read from
// the buf we are not currently filling.
wire [35:0] linebuf_color;
assign linebuf_color = active_buf ? linebuf_color2 : linebuf_color1;

// Calculate the weighted sum for the two pixels this
// output pixel spans across.  We are hard coded to do
// 10 to 9 downscale so a pixel never spans more than
// 2 pixels.
assign iblue1 = (linebuf_color[5:0] * weight1);
assign iblue2 = (linebuf_color[23:18] * weight2);
assign iblue = (iblue1 + iblue2) / 10;

assign igreen1 = (linebuf_color[11:6] * weight1);
assign igreen2 = (linebuf_color[29:24] * weight2);
assign igreen = (igreen1 + igreen2) / 10;

assign ired1 = (linebuf_color[17:12] * weight1);
assign ired2 = (linebuf_color[35:30] * weight2);
assign ired = (ired1 + ired2) / 10;


// Read this as:
// IsPal ? PalVal otherwise is NTSCR56A? NTSCR56AVal otherwise NTSCR8Val
//
// max waddr is simply the max full width of the avail graphics at dot4x
// max raddr is max width from sync module divided by .9 (+ or - 1)
// start raddr is chosen to center the gfx area
// then max raddr is shifted up but that amount
//
// PAL       1007 , 881 / .9 = 978 + 44 = 1022
// NTSCR56A  1017 , 832 / .9 = 923 + 90 = 1013
// NTSCR8    1039 , 844 / .9 = 937 + 78 = 1015
//
`ifndef SIMULATOR_BOARD
wire [10:0] max_scale_raddr;
wire [10:0] max_scale_waddr;
wire [10:0] start_scale_raddr;
assign max_scale_waddr = chip[0] ? 11'd1007 : (chip[1] ? 11'd1023 : 11'd1039);
assign max_scale_raddr = chip[0] ? 11'd1026 : (chip[1] ? 11'd1013 : 11'd1015);
assign start_scale_raddr = chip[0] ? 11'd48 : (chip[1] ? 11'd90 : 11'd78);
`else
// Simulator build doesn't handle continuous
// assignments properly?
reg [10:0] max_scale_raddr;
reg [10:0] max_scale_waddr;
reg [10:0] start_scale_raddr;
always @(posedge clk_dot4x)
begin
max_scale_waddr = chip[0] ? 11'd1007 : (chip[1] ? 11'd1023 : 11'd1039);
max_scale_raddr = chip[0] ? 11'd1026 : (chip[1] ? 11'd1013 : 11'd1015);
start_scale_raddr = chip[0] ? 11'd48 : (chip[1] ? 11'd90 : 11'd78);
end
`endif

// This handles our write counter when we
// translate index values to rgb values
// and stuff them into our linebuf ram.
// The flipflop is here because the dot
// clock is for 2x and 2y.  So to increment
// one x, we do it on every other clock cycle.
// This only works with 2x/2y config.
reg ff;
always @(posedge clk_dot4x)
   if (rst) begin
      scale_ctr_waddr <= 11'd0;
   end else begin
      ff <= ~ff;
      if (ff) begin
         prev_col <= color_regs_data_out_b[23:6];
         if (scale_ctr_waddr == max_scale_waddr) begin
            scale_ctr_waddr <= 11'd0;
            active_buf <= ~active_buf;
         end else begin
            scale_ctr_waddr <= scale_ctr_waddr + 11'd1;
         end
      end
   end


// This is a custom 10:9 interpolating scaler.
// It uses the weighted sum across 10 pixels to
// produce 9. We start with a weight of 9 for the
// current pixel and 1 for the adjacent pixel. Each
// time we move one pixel to the right, the weights
// increase/reduce on either side until we reach
// the last pixel with weight 1 and 9. Then we
// skip a pixel and the cycle starts again.  This
// effectively scales 10 pixels down to 9 so we
// get a .9 scale factor. This reduces the width
// of the visible region enough to get a decent
// amount of border on 720x576 PAL mode.
always @(posedge clk_dvi)
begin
   if (rst) begin
      scale_ctr_raddr <= start_scale_raddr;
      weight1 <= 4'd9;
      weight2 <= 4'd1;
   end else begin
      // 978 read addr is equivalent to 1007 write addr
      // then we shift by our starting point to center
      if (scale_ctr_raddr == max_scale_raddr) begin
         scale_ctr_raddr <= start_scale_raddr;
         weight1 <= 4'd9;
         weight2 <= 4'd1;
      end
      else begin
         if (weight1 > 1) weight1 <= weight1 - 4'd1;
         else weight1 <= 4'd9;
         if (weight2 < 9) weight2 <= weight2 + 4'd1;
         else weight2 <= 4'd1;

         scale_ctr_raddr <= scale_ctr_raddr + (weight1 == 1 ? 11'd2 : 11'd1);
      end

      final_blue = iblue[5:0];
      final_green = igreen[5:0];
      final_red = ired[5:0];

//$display ("in=%d previn=%d srcx=%d dstx=%d b1=%d, b2=%d, weight1=%d, weight2=%d, ws=%d", color_regs_data_out_b[11:6] , prev_col[5:0], scale_ctr_raddr, scale_ctr_waddr, linebuf_color[5:0], linebuf_color[23:18], weight1, weight2, final_blue);

      output_color <= {final_red, final_green, final_blue};
   end
end

// At every pixel clock tick, set red,green,blue from color
// register ram according to the pixel_color4 address.
always @(posedge clk_dvi)
begin
`ifndef HIDE_SYNC
    if (active) begin
`endif
        if (half_bright) begin
            red <= {1'b0, output_color[17:13]};
            green <= {1'b0, output_color[11:7]};
            blue <= {1'b0, output_color[5:1]};
        end else begin
            red <= output_color[17:12];
            green <= output_color[11:6];
            blue <= output_color[5:0];
        end
`ifndef HIDE_SYNC
    end else begin
        red <= 6'b0;
        green <= 6'b0;
        blue <= 6'b0;
    end
`endif
end
`endif

// Use make_luma_bin.c to generate the code
// for the non-configurable sections.
`ifdef GEN_LUMA_CHROMA
`ifdef LUMACODE
reg [1:0] lumacode_ff = 2'd3; // important for alignment
`endif
always @(posedge clk_dot4x)
begin
`ifdef CONFIGURABLE_LUMAS
`ifdef LUMACODE
    lumacode_ff <= lumacode_ff + 2'd1;
`endif
    lumareg_o <= luma_regs_data_out_b[17:12];
    phasereg_o <= luma_regs_data_out_b[11:4];
    amplitudereg_o <= luma_regs_data_out_b[3:0];
`else
    if (chip[0]) begin // PAL
    case (pixel_color3)
`ifdef REV_3_BOARD
        `BLACK      : lumareg_o <= 6'h0c;
        `WHITE      : lumareg_o <= 6'h3f;
        `RED        : lumareg_o <= 6'h18;
        `CYAN       : lumareg_o <= 6'h2a;
        `PURPLE     : lumareg_o <= 6'h1b;
        `GREEN      : lumareg_o <= 6'h23;
        `BLUE       : lumareg_o <= 6'h15;
        `YELLOW     : lumareg_o <= 6'h32;
        `ORANGE     : lumareg_o <= 6'h1b;
        `BROWN      : lumareg_o <= 6'h15;
        `PINK       : lumareg_o <= 6'h23;
        `DARK_GREY  : lumareg_o <= 6'h18;
        `GREY       : lumareg_o <= 6'h21;
        `LIGHT_GREEN: lumareg_o <= 6'h32;
        `LIGHT_BLUE : lumareg_o <= 6'h21;
        `LIGHT_GREY : lumareg_o <= 6'h2a;
`else
        `BLACK      : lumareg_o <= 6'h08;
        `WHITE      : lumareg_o <= 6'h3f;
        `RED        : lumareg_o <= 6'h2a;
        `CYAN       : lumareg_o <= 6'h37;
        `PURPLE     : lumareg_o <= 6'h2d;
        `GREEN      : lumareg_o <= 6'h33;
        `BLUE       : lumareg_o <= 6'h25;
        `YELLOW     : lumareg_o <= 6'h3b;
        `ORANGE     : lumareg_o <= 6'h2d;
        `BROWN      : lumareg_o <= 6'h25;
        `PINK       : lumareg_o <= 6'h33;
        `DARK_GREY  : lumareg_o <= 6'h2a;
        `GREY       : lumareg_o <= 6'h32;
        `LIGHT_GREEN: lumareg_o <= 6'h3b;
        `LIGHT_BLUE : lumareg_o <= 6'h32;
        `LIGHT_GREY : lumareg_o <= 6'h37;
`endif
    endcase
    end
    else begin // NTSC
    case (pixel_color3)
`ifdef REV_3_BOARD
        `BLACK      : lumareg_o <= 6'h0c;
        `WHITE      : lumareg_o <= 6'h3f;
        `RED        : lumareg_o <= 6'h18;
        `CYAN       : lumareg_o <= 6'h2a;
        `PURPLE     : lumareg_o <= 6'h1b;
        `GREEN      : lumareg_o <= 6'h23;
        `BLUE       : lumareg_o <= 6'h15;
        `YELLOW     : lumareg_o <= 6'h32;
        `ORANGE     : lumareg_o <= 6'h1b;
        `BROWN      : lumareg_o <= 6'h15;
        `PINK       : lumareg_o <= 6'h23;
        `DARK_GREY  : lumareg_o <= 6'h18;
        `GREY       : lumareg_o <= 6'h21;
        `LIGHT_GREEN: lumareg_o <= 6'h32;
        `LIGHT_BLUE : lumareg_o <= 6'h21;
        `LIGHT_GREY : lumareg_o <= 6'h2a;
`else
        `BLACK      : lumareg_o <= 6'h18;
        `WHITE      : lumareg_o <= 6'h3f;
        `RED        : lumareg_o <= 6'h2f;
        `CYAN       : lumareg_o <= 6'h39;
        `PURPLE     : lumareg_o <= 6'h32;
        `GREEN      : lumareg_o <= 6'h36;
        `BLUE       : lumareg_o <= 6'h2c;
        `YELLOW     : lumareg_o <= 6'h3c;
        `ORANGE     : lumareg_o <= 6'h32;
        `BROWN      : lumareg_o <= 6'h2c;
        `PINK       : lumareg_o <= 6'h36;
        `DARK_GREY  : lumareg_o <= 6'h2f;
        `GREY       : lumareg_o <= 6'h35;
        `LIGHT_GREEN: lumareg_o <= 6'h3c;
        `LIGHT_BLUE : lumareg_o <= 6'h35;
        `LIGHT_GREY : lumareg_o <= 6'h39;
`endif
    endcase
    end

    case (pixel_color3)
        `BLACK      : phasereg_o <= 8'h00; // unmodulated
        `WHITE      : phasereg_o <= 8'h00; // unmodulated
        `RED        : phasereg_o <= 8'h50; // 112.5 degrees
        `CYAN       : phasereg_o <= 8'hd0; // 292.5 degrees
        `PURPLE     : phasereg_o <= 8'h20; // 45.0 degrees
        `GREEN      : phasereg_o <= 8'ha0; // 225.0 degrees
        `BLUE       : phasereg_o <= 8'hf1; // 338.9 degrees
        `YELLOW     : phasereg_o <= 8'h80; // 180.0 degrees
        `ORANGE     : phasereg_o <= 8'h60; // 135.0 degrees
        `BROWN      : phasereg_o <= 8'h70; // 157.5 degrees
        `PINK       : phasereg_o <= 8'h50; // 112.5 degrees
        `DARK_GREY  : phasereg_o <= 8'h00; // unmodulated
        `GREY       : phasereg_o <= 8'h00; // unmodulated
        `LIGHT_GREEN: phasereg_o <= 8'ha0; // 225.0 degrees
        `LIGHT_BLUE : phasereg_o <= 8'hf1; // 338.9 degrees
        `LIGHT_GREY : phasereg_o <= 8'h00; // unmodulated
    endcase

    case (pixel_color3)
        `BLACK      : amplitudereg_o <= 4'h00; // unmodulated
        `WHITE      : amplitudereg_o <= 4'h00; // unmodulated
        `RED        : amplitudereg_o <= 4'h0d;
        `CYAN       : amplitudereg_o <= 4'h0a;
        `PURPLE     : amplitudereg_o <= 4'h0c;
        `GREEN      : amplitudereg_o <= 4'h0b;
        `BLUE       : amplitudereg_o <= 4'h0b;
        `YELLOW     : amplitudereg_o <= 4'h0f;
        `ORANGE     : amplitudereg_o <= 4'h0f;
        `BROWN      : amplitudereg_o <= 4'h0b;
        `PINK       : amplitudereg_o <= 4'h0c;
        `DARK_GREY  : amplitudereg_o <= 4'h00; // unmodulated
        `GREY       : amplitudereg_o <= 4'h00; // unmodulated
        `LIGHT_GREEN: amplitudereg_o <= 4'h0d;
        `LIGHT_BLUE : amplitudereg_o <= 4'h0d;
        `LIGHT_GREY : amplitudereg_o <= 4'h00; // unmodulated
    endcase
`endif
end
`endif

// read_ram and write_ram task definitions
`ifdef WITH_EXTENSIONS
`include "registers_ram.vi"
`endif // WITH_EXTENSIONS

`ifdef HAVE_EEPROM
`include "registers_eeprom.vi"
`else
`include "registers_no_eeprom.vi"
`endif

`ifdef WITH_EXTENSIONS
`ifdef HAVE_FLASH
`include "registers_flash.vi"
`endif
`endif // WITH_EXTENSIONS

endmodule
