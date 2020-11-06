`timescale 1ns / 1ps

`include "common.vh"

module registers(
           input rst,
           input clk_dot4x,
           input clk_phi,
           input phi_phase_start_15,
           input phi_phase_start_1,
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
           output reg erst
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
    end else
    begin
        // always clear these at the end of the high phase
        if (phi_phase_start_15 && clk_phi) begin
            irst_clr <= `FALSE;
            imbc_clr <= `FALSE;
            immc_clr <= `FALSE;
            ilp_clr <= `FALSE;
        end
        if (phi_phase_start_1) begin
		      addr_latch_done <= `FALSE;
				read_done <= `FALSE;
        end
        // sprite crunch simulation must be done before [15] of
        // the current phase
        if (phi_phase_start_15) begin
            handle_sprite_crunch <= `FALSE;
        end
        // m2m/m2d clear after register reads must be
        // done on [1] of the next low phase
        if (phi_phase_start_1 && !clk_phi) begin
            m2m_clr <= `FALSE;
            m2d_clr <= `FALSE;
        end
        if (!ras && clk_phi && !addr_latch_done) begin
            addr_latched <= adi[5:0];
            addr_latch_done <= `TRUE;
		  end
        if (aec && !ce && addr_latch_done) begin
            // READ from register
            if (rw && !read_done) begin
					 read_done <= `TRUE;
                case (addr_latched)
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
                    /* 0x1e */ `REG_SPRITE_2_SPRITE_COLLISION: begin
                        dbo[7:0] <= sprite_m2m;
                        // reading this register clears the value
                        m2m_clr <= 1;
                    end
                    /* 0x1f */ `REG_SPRITE_2_DATA_COLLISION: begin
                        dbo[7:0] <= sprite_m2d;
                        // reading this register clears the value
                        m2d_clr <= 1;
                    end
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
                        dbo[7:0] <= 8'hFF;
                endcase
            end
            // WRITE to register
            else if (!rw && phi_phase_start_dav) begin
                    case (addr_latched)
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
                        default:;
                    endcase
            end
        end
    end
endmodule
