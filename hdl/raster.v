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

// Update raster x,y position
module raster(
           input clk_phi,
           input clk_dot4x,
           input rst,
           input phi_phase_start_sof,
           input dot_rising_0,
           input [1:0] chip,
           input [6:0] cycle_num,
           input[9:0] raster_x_max,
           input[8:0] raster_y_max,
`ifdef HIRES_MODES
           output reg [5:0] blink_ctr,
           output reg [10:0] hires_raster_x,
           input dot_rising_2,
`endif
           output reg [9:0] xpos,
           output reg [9:0] raster_x,
           output reg [9:0] sprite_raster_x,
           output reg [8:0] raster_line,
           output reg [8:0] raster_line_d
       );

// sprite_raster_x is positioned such that the first cycle for
// sprite #0 where ba should go low (if the sprite is enabled)
// has sprite_raster_x==0.  This lets us do a simple interval
// comparison without having to worry about wrap around conditions.
reg start_of_line;

// cycle_bit : The pixel number within the cycle.
// 0-7
// NOTE: similar to above, cycle_bit not valid until 2nd tick within low phase of phi
wire [2:0] cycle_bit;

// The cycle_bit (0-7) is taken from the raster_x
assign cycle_bit = raster_x[2:0];

always @(posedge clk_dot4x)
    if (rst)
    begin
        //raster_x <= 10'b0;
//`ifdef HIRES_MODES
//        hires_raster_x <= 11'b0;
//`endif
        //raster_line <= 9'b0;
        //raster_line_d <= 9'b0;
        //start_of_line = 0;
        case(chip)
            `CHIP6567R56A: begin
                xpos <= 10'h19c;
                sprite_raster_x <= 72; // 512 - 55*8
            end `CHIP6567R8: begin
                xpos <= 10'h19c;
                sprite_raster_x <= 80; // 520 - 55*8
            end `CHIP6569R1, `CHIP6569R3: begin
                xpos <= 10'h194;
                sprite_raster_x <= 72; // 504 - 54*8
            end
        endcase
    end
    else begin

        if (clk_phi && start_of_line) begin
            raster_line_d <= raster_line_d + 9'd1;
            start_of_line = 0;
        end

        if (raster_line == 0 &&
                clk_phi && phi_phase_start_sof && cycle_num == 1) begin
            raster_line_d <= 9'd0;
        end

        if (dot_rising_0) begin
            if (raster_x < raster_x_max)
            begin
                // Can advance to next pixel
                raster_x <= raster_x + 10'd1;
`ifdef HIRES_MODES
                hires_raster_x <= hires_raster_x + 10'd1;
`endif

                // Handle xpos move but deal with special cases
                case(chip)
                    `CHIP6567R8:
                        if (cycle_num == 7'd0 && cycle_bit == 3'd0)
                            xpos <= 10'h19d;
                        else if (cycle_num == 7'd60 && cycle_bit == 3'd7)
                            xpos <= 10'h184;
                        else if (cycle_num == 7'd61 && (cycle_bit == 3'd3 || cycle_bit == 3'd7))
                            xpos <= 10'h184;
                        else if (cycle_num == 7'd12 && cycle_bit == 3'd3)
                            xpos <= 10'h0;
                        else
                            xpos <= xpos + 10'd1;
                    `CHIP6567R56A:
                        if (cycle_num == 7'd0 && cycle_bit == 3'd0)
                            xpos <= 10'h19d;
                        else if (cycle_num == 7'd12 && cycle_bit == 3'd3)
                            xpos <= 10'h0;
                        else
                            xpos <= xpos + 10'd1;
                    `CHIP6569R1, `CHIP6569R3:
                        if (cycle_num == 7'd0 && cycle_bit == 3'd0)
                            xpos <= 10'h195;
                        else if (cycle_num == 7'd12 && cycle_bit == 3'd3)
                            xpos <= 10'h0;
                        else
                            xpos <= xpos + 10'd1;
                endcase
            end else
            begin
                // Time to go back to x coord 0
                raster_x <= 10'd0;

`ifdef HIRES_MODES
                hires_raster_x <= 11'd0;
`endif

                // xpos also goes back to start value
                case(chip)
                    `CHIP6567R56A, `CHIP6567R8:
                        xpos <= 10'h19c;
                    `CHIP6569R1, `CHIP6569R3:
                        xpos <= 10'h194;
                endcase

                if (raster_line < raster_y_max) begin
                    raster_line <= raster_line + 9'd1;
                    start_of_line = 1;
                end else begin
                    raster_line <= 9'd0;

`ifdef HIRES_MODES
                    // Used for hires blinking attribute
                    blink_ctr <= blink_ctr + 6'd1;
`endif
                end
            end

            if (sprite_raster_x < raster_x_max)
                sprite_raster_x <= sprite_raster_x + 10'd1;
            else
                sprite_raster_x <= 10'd0;
        end

`ifdef HIRES_MODES
        if (dot_rising_2) begin
            hires_raster_x <= hires_raster_x + 11'b1;
        end
`endif
    end

endmodule
