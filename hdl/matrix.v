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

// Update matrix counters
module matrix(
           input rst,
           input clk_phi,
           input clk_dot4x,
           input phi_phase_start_1,
           input phi_phase_start_14,
           input [6:0] cycle_num,
           input [8:0] raster_line,
           input badline,
           output reg idle,
           output reg [9:0] vc,
           output reg [2:0] rc
       );

reg [9:0] vc_base;

// Update rc/vc/vc_base
always @(posedge clk_dot4x)
    if (rst)
    begin
        //vc_base <= 10'd0;
        //vc <= 10'd0;
        rc <= 3'd7;
        idle = `TRUE;
    end
    else begin
        // Must be on [1] for cycle_num to be valid
        if (clk_phi && phi_phase_start_1) begin
            // Reset at start of frame
            if (cycle_num == 1 && raster_line == 9'd0) begin
                vc_base <= 10'd0;
                vc <= 10'd0;
            end

            if (cycle_num > 14 && cycle_num < 55 && idle == `FALSE)
                vc <= vc + 1'b1;

            if (cycle_num == 13) begin
                vc <= vc_base;
                if (badline)
                    rc <= 3'd0;
            end

            if (cycle_num == 57) begin
                if (rc == 3'd7) begin
                    vc_base <= vc;
                    idle = `TRUE;
                end
                if (!idle | badline) begin
                    rc <= rc + 1'b1;
                    idle = `FALSE;
                end
            end
        end

        if (clk_phi && phi_phase_start_14) begin
            if (badline)
                idle = `FALSE;
        end
    end

endmodule
