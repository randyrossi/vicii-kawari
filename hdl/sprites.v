`timescale 1ns/1ps

`include "common.vh"

module sprites(
        input rst,
        input clk_dot4x,
        input clk_phi,
        input [3:0] cycle_type,
        input dot_rising_0,
        input phi_phase_start_0,
        input phi_phase_start_1,
        input phi_phase_start_2,
        input phi_phase_start_13,
        input phi_phase_start_davp1,
        input [8:0] xpos_d, // top bit omitted for comparison to x
        input [6:0] cycle_num,
        input handle_sprite_crunch,
        input [8:0] sprite_x[0:`NUM_SPRITES - 1],
        input [7:0] sprite_y[0:`NUM_SPRITES - 1],
        input [7:0] sprite_xe,
        input [7:0] sprite_ye,
        input [7:0] sprite_en,
        input [7:0] sprite_mmc,
        input [2:0] sprite_cnt,
        input [7:0] raster_line, // top bit omitted for comparison to y
        input vic_write_db,
        input is_background_pixel1,
        input top_bot_border,
        input left_right_border,
        input imbc_clr,
        input immc_clr,
        input [6:0] sprite_dmachk1,
        input [6:0] sprite_dmachk2,
        input [6:0] sprite_yexp_chk,
        input [6:0] sprite_disp_chk,
        input m2m_clr,
        input m2d_clr,
        input [23:0] sprite_pixels [0:`NUM_SPRITES-1],
        output reg immc,
        output reg imbc,
        output reg [1:0] sprite_cur_pixel [`NUM_SPRITES-1:0],
        output reg [5:0] sprite_mc[0:`NUM_SPRITES - 1],
        output reg sprite_dma[0:`NUM_SPRITES - 1],
        output reg [7:0] sprite_m2m,
        output reg [7:0] sprite_m2d
);

integer n;
reg [5:0] sprite_mcbase[0:`NUM_SPRITES - 1];
reg       sprite_xe_ff[0:`NUM_SPRITES-1];
reg       sprite_ye_ff[0:`NUM_SPRITES-1];
reg [7:0] sprite_shift;
reg       sprite_mmc_ff[0:`NUM_SPRITES-1];
reg [23:0] sprite_pixels_shifting [0:`NUM_SPRITES-1];

always @(posedge clk_dot4x)
    if (rst) begin
        for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
            sprite_mc[n] = 6'd63;
            sprite_mcbase[n] = 6'd63;
            sprite_ye_ff[n] = 1;
            sprite_dma[n] = 0;
        end
    end else begin
        // update mcbase
        if (clk_phi && phi_phase_start_1 && cycle_num == 15) begin
            for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
                if (sprite_ye_ff[n]) begin
                    sprite_mcbase[n] = sprite_mc[n];
                    if (sprite_mcbase[n] == 63)
                        sprite_dma[n] = 0;
                end
            end
        end
        if (handle_sprite_crunch) begin // happens phi_phase_start[REG_DAV+1]
            // sprite crunch
            for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
                if (!sprite_ye[n] && !sprite_ye_ff[n]) begin
                    if (cycle_num == 14) begin
                        sprite_mc[n] = (6'h2a & (sprite_mcbase[n] & sprite_mc[n])) |
                                 (6'h15 & (sprite_mcbase[n] | sprite_mc[n])) ;
                    end
                    sprite_ye_ff[n] = `TRUE;
                end
            end
        end
        // check dma
        // NOTE: We used to do this on phi2 high like vice but this can't be correct because
        // it causes ba to go low much too late for sprite 0.  An exception for checking
        // dma/mcbase/ye_ff was added to the simulator.
        if (!clk_phi && phi_phase_start_1 && (cycle_num == sprite_dmachk1 || cycle_num == sprite_dmachk2)) begin
            for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
                if (!sprite_dma[n] && sprite_en[n] && raster_line[7:0] == sprite_y[n]) begin
                    sprite_dma[n] = 1;
                    sprite_mcbase[n] = 0;
                    sprite_ye_ff[n] = 1;
                end
            end
        end
        // check sprite expansion
        if (clk_phi && phi_phase_start_1 && cycle_num == sprite_yexp_chk) begin
            for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
                if (sprite_dma[n] && sprite_ye[n])
                    sprite_ye_ff[n] = !sprite_ye_ff[n];
            end
        end
        // sprite display check
        if (clk_phi && phi_phase_start_1 && cycle_num == sprite_disp_chk) begin
            for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
                sprite_mc[n] = sprite_mcbase[n];
            end
        end

        // Advance sprite byte offset while dma is happening (at end of cycle)
        // Increment on [1] just before cycle_type changes for the next half
        // cycle (safe for sprite_cnt too).
        // TODO: If we set this to [1], it work's just fine but our VICE sync fails
        // on every MC value as being one off. Set this to [13] but [1] looks much
        // better in the logic analyser since the address transitions happen at
        // the expected times.
        if (phi_phase_start_13) begin
            case (cycle_type)
                VIC_HS1,VIC_LS2,VIC_HS3:
                    if (sprite_dma[sprite_cnt])
                        sprite_mc[sprite_cnt] = sprite_mc[sprite_cnt] + 1'b1;
                default: ;
            endcase
        end
    end

always @(posedge clk_dot4x)
begin
    if (rst) begin
        for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
            sprite_shift[n] = `FALSE;
            sprite_xe_ff[n] <= `FALSE;
            //sprite_pixels_shifting[n] <= 24'b0;
            sprite_mmc_ff[n] <= `FALSE;
            //sprite_cur_pixel[n] <= 2'b0;
        end
    end
    else begin
        if (dot_rising_0) begin
            // when xpos matches sprite_x, turn on shift
            for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
                if (sprite_x[n] == xpos_d[8:0]) begin
                    sprite_shift[n] = `TRUE;
                end
            end

            // shift pixels into sprite_cur_pixel
            for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
                if (sprite_shift[n]) begin
                    sprite_xe_ff[n] <= !sprite_xe_ff[n] & sprite_xe[n];
                    if (!sprite_xe_ff[n]) begin
                        sprite_mmc_ff[n] <= !sprite_mmc_ff[n] & sprite_mmc[n];
                        if (!sprite_mmc_ff[n])
                            sprite_cur_pixel[n] <= sprite_pixels_shifting[n][23:22];
                        sprite_pixels_shifting[n] <= {sprite_pixels_shifting[n][22:0], 1'b0};
                    end
                end
                else begin
                    sprite_xe_ff[n] <= `FALSE;
                    sprite_mmc_ff[n] <= `FALSE;
                    sprite_cur_pixel[n] <= 2'b00;
                end
            end
        end

        // must be [2] or greater for sprite_cnt to be valid here
        if (!clk_phi && phi_phase_start_2) begin
            case (cycle_type)
                VIC_LP:
                    sprite_shift[sprite_cnt] = `FALSE;
                default: ;
            endcase
        end

        // Transfer pixels from read register into the shifting register.  No real reason
        // we needed to do this. It just keeps the bus accesses all together in one module.
        if (!vic_write_db && phi_phase_start_davp1) begin
            case (cycle_type)
                VIC_HS1, VIC_LS2, VIC_HS3:
                    if (sprite_dma[sprite_cnt])
                        sprite_pixels_shifting[sprite_cnt] <= sprite_pixels[sprite_cnt];
                default: ;
            endcase
        end
    end
end

// Sprite to sprite collision logic (m2m)
// NOTE: VICE seems to want m2m collisions to rise by the end of the low
// phase of phi. So we defer collisions discovered during the high phase
// until next next low phase.
reg [`NUM_SPRITES-1:0] collision;
always @*
    for (n = 0; n < `NUM_SPRITES; n = n + 1)
        collision[n] = sprite_cur_pixel[n][1];

reg m2m_triggered;
reg [7:0] sprite_m2m_pending;
reg immc_pending;

always @(posedge clk_dot4x)
    if (rst) begin
        sprite_m2m <= 8'b0;
        sprite_m2m_pending <= 8'b0;
        m2m_triggered <= `FALSE;
        immc <= `FALSE;
        immc_pending <= `FALSE;
    end else begin
        if (immc_clr) begin
            immc <= `FALSE;
            immc_pending <= `FALSE;
        end
        if (phi_phase_start_0 && !clk_phi) begin
            // must do this before m2m_clr itself is reset on [1]
            if (m2m_clr) begin
                sprite_m2m[7:0] <= 8'd0;
                sprite_m2m_pending[7:0] <= 8'd0;
                m2m_triggered <= `FALSE;
            end
        end
        // This is the deferral mentioned above
        if (!clk_phi) begin
            sprite_m2m <= sprite_m2m_pending;
            immc <= immc_pending;
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
                sprite_m2m_pending <= sprite_m2m_pending | collision;
                if (!m2m_triggered) begin
                    m2m_triggered <= `TRUE;
                    immc_pending <= `TRUE;
                end
            end
        endcase
    end

// Sprite to data collision logic (m2d)
// NOTE: VICE seems to want m2d collisions to rise by the end of the low
// phase of phi. So we defer collisions discovered during the high phase
// until next next low phase.
reg [7:0] sprite_m2d_pending;
reg m2d_triggered;
reg imbc_pending;

always @(posedge clk_dot4x)
    if (rst) begin
        sprite_m2d <= 8'b0;
        sprite_m2d_pending <= 8'b0;
        m2d_triggered <= `FALSE;
        imbc <= `FALSE;
        imbc_pending <= `FALSE;
    end
    else begin
        if (imbc_clr) begin
            imbc <= `FALSE;
            imbc_pending <= `FALSE;
        end
        // must do this before m2m_clr itself is reset on [1]
        if (phi_phase_start_0 && !clk_phi) begin
            if (m2d_clr) begin
                sprite_m2d <= 8'd0;
                sprite_m2d_pending <= 8'd0;
                m2d_triggered <= `FALSE;
            end
        end
        // This is the deferral mentioned above
        if (!clk_phi) begin
            sprite_m2d <= sprite_m2d_pending;
            imbc <= imbc_pending;
        end
        for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
            if (sprite_cur_pixel[n][1] & !is_background_pixel1 & !(left_right_border | top_bot_border)) begin
                sprite_m2d_pending[n] <= `TRUE;
                if (!m2d_triggered) begin
                    m2d_triggered <= `TRUE;
                    imbc_pending <= `TRUE;
                end
            end
        end
    end

endmodule: sprites
