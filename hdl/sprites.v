`timescale 1ns/1ps

`include "common.vh"

module sprites(
        input rst,
        input clk_dot4x,
        input clk_phi,
        input [11:0] dbi,
        input [3:0] cycle_type,
        input dot_rising_0,
        input dot_rising_1,
        input phi_phase_start_13,
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
        input [2:0] sprite_cnt,
        input [7:0] raster_line, // top bit omitted for comparison to y
        input aec,
        input is_background_pixel,
        input main_border,
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
        output reg [7:0] sprite_m2d
);

integer n;

// Destinations for flattened inputs that need to be sliced back into an array
wire [8:0] sprite_x[0:`NUM_SPRITES - 1];
wire [7:0] sprite_y[0:`NUM_SPRITES - 1];

// 2D arrays that need to be flattened for output
reg [5:0] sprite_mc[0:`NUM_SPRITES - 1];
reg [1:0] sprite_cur_pixel [`NUM_SPRITES-1:0];

// Other internal regs
reg [5:0] sprite_mcbase[0:`NUM_SPRITES - 1];
reg       sprite_xe_ff[0:`NUM_SPRITES-1];
reg       sprite_ye_ff[0:`NUM_SPRITES-1];
reg [7:0] sprite_active;
reg [7:0] sprite_halt;
reg       sprite_mmc_ff[0:`NUM_SPRITES-1];
reg [23:0] sprite_pixels_shifting [0:`NUM_SPRITES-1];

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

// NOTE: If we match VICE, then ba will go low much too late for sprite 0.  Slight
// difference between simulator and non-simulator code.
`ifndef IS_SIMULATOR
`define PHI_DMA_CONDITION !clk_phi
`else
`define PHI_DMA_CONDITION clk_phi
`endif

always @(posedge clk_dot4x)
    if (rst) begin
        for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
            sprite_mc[n] <= 6'd63;
            sprite_mcbase[n] <= 6'd63;
            sprite_ye_ff[n] <= 1;
            sprite_dma[n] <= 0;
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
                    // NOTE: When DAV == 0, we have to check against
		    // 15 even though the register set happened on 14.
		    // That's because we crossed over to the next cycle
		    // by the time handle_sprite_crunch rose.
                    if (cycle_num == 15) begin
                        sprite_mc[n] <= (6'h2a & (sprite_mcbase[n] & sprite_mc[n])) |
                                 (6'h15 & (sprite_mcbase[n] | sprite_mc[n])) ;
                    end
                    sprite_ye_ff[n] <= `TRUE;
                end
            end
        end
        // check dma
        if (`PHI_DMA_CONDITION && phi_phase_start_1 && (cycle_num == sprite_dmachk1 || cycle_num == sprite_dmachk2)) begin
            for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
                if (!sprite_dma[n] && sprite_en[n] && raster_line[7:0] == sprite_y[n]) begin
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
                `VIC_HS1,`VIC_LS2,`VIC_HS3:
                    if (sprite_dma[sprite_cnt])
                        sprite_mc[sprite_cnt] <= sprite_mc[sprite_cnt] + 1'b1;
                default: ;
            endcase
        end
    end

// The bits that 'fall off' the shift register get put
// here. They are then delayed before being interpreted
// by the pixel sequencer or sprite to sprite collision
// detection.
always @(posedge clk_dot4x)
begin
    if (rst) begin
        for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
            sprite_active[n] = `FALSE;
            sprite_halt[n] = `FALSE;
            sprite_xe_ff[n] = `FALSE;
            //sprite_pixels_shifting[n] <= 24'b0;
            sprite_mmc_ff[n] = `FALSE;
            //sprite_cur_pixel[n] <= 2'b0;
        end
    end
    else begin
        // Handle next pixel
        if (dot_rising_0) begin
            // The sprite pixel shifter will deactivate a sprite
            // or halt the shifter entirely around the cycles that
            // perform dma access. 
            if (cycle_bit == 2 && (cycle_type == `VIC_LS2 || cycle_type == `VIC_LPI2)) begin
                sprite_active[sprite_cnt] = `FALSE;
                sprite_cur_pixel[sprite_cnt] <= 0;
            end else if (cycle_bit == 3 && cycle_type == `VIC_LP) begin
                sprite_halt[sprite_cnt] = `TRUE;
                sprite_pixels_shifting[sprite_cnt] <= 24'b0;
            end else if (cycle_bit == 7 && (cycle_type == `VIC_HS3 || cycle_type == `VIC_HPI3))
                sprite_halt[sprite_cnt] = `FALSE;

            // when xpos matches sprite_x, turn on shift
            for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
               if (!sprite_halt[n] && sprite_x[n] == xpos[8:0]) begin
                   sprite_active[n] = `TRUE;
                   sprite_xe_ff[n] = `FALSE;
                   sprite_mmc_ff[n] = `FALSE;
               end
            end

            // shift pixels into sprite_cur_pixel
            for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
                //$display("XPOS %d SPRITE %d active %d halt %d reg %x pixel %d",xpos_d,n,
                //    sprite_active[n], sprite_halt[n], sprite_pixels_shifting[n], sprite_cur_pixel[n]);
                // Is this sprite shifting?
                if (sprite_active[n]) begin
                    if (sprite_pixels_shifting[n] != 0 || sprite_cur_pixel[n] != 0) begin
                       if (!sprite_halt[n]) begin
                          if (!sprite_xe_ff[n]) begin
                              if (!sprite_mmc_ff[n])
                                  sprite_cur_pixel[n] <= sprite_pixels_shifting[n][23:22];
                              sprite_pixels_shifting[n] <= {sprite_pixels_shifting[n][22:0], 1'b0};
                              sprite_mmc_ff[n] = !sprite_mmc_ff[n] & sprite_mmc[n];
                          end
                          sprite_xe_ff[n] = !sprite_xe_ff[n] & sprite_xe[n];
                       end
                   end
                   else begin
                       sprite_active[n] = `FALSE;
                   end
                end
            end
        end

        // s-access - This must be done here instead of bus_access because
        // this is where the shifting logic resides.
        if (!aec && phi_phase_start_dav) begin
          case (cycle_type)
              `VIC_HS1, `VIC_LS2, `VIC_HS3:
                  if (sprite_dma[sprite_cnt])
                      sprite_pixels_shifting[sprite_cnt] <=
                          {sprite_pixels_shifting[sprite_cnt][15:0], dbi[7:0]};
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
        if (phi_phase_start_1 && !clk_phi) begin
            // must use before m2m_clr is reset in registers
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
        if (phi_phase_start_1 && !clk_phi) begin
            // must use before m2d_clr is reset in registers
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
	if (dot_rising_1) begin
          for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
            if ((sprite_cur_pixel[n] != 0) &
                    !is_background_pixel & !(main_border)) begin
                sprite_m2d_pending[n] <= `TRUE;
                if (!m2d_triggered) begin
                    m2d_triggered <= `TRUE;
                    imbc_pending <= `TRUE;
                end
            end
          end
	end
    end

endmodule: sprites
