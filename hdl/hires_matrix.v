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

// Additional matrix counters specifically for our hi res
// text mode (80x25).
// NOTE: badline flags does NOT take away CPU cycles in
// hi res mode.  It is only used to identify yscroll matches
// to begin vc increments again.  We could have just as easily
// passed in yscroll but we're keeping the badline condition
// from legacy vic.
module hires_matrix(
           input rst,
           input clk_phi,
           input clk_dot4x,
           input phi_phase_start_1,
           input phi_phase_start_14,
           input [6:0] cycle_num,
           input [8:0] raster_line,
           input hires_badline,
           output reg [10:0] hires_vc,
           output reg [2:0] hires_rc,
           output reg [14:0] hires_fvc // a fast counter for 16k or 32k bitmap modes
       );

reg [10:0] hires_vc_base;
reg idle; // I don't know if we ever need to advertise this
reg [7:0] badline_hist;
always @(posedge clk_dot4x)
    if (rst)
    begin
        //hires_vc_base <= 11'd0;
        //hires_vc <= 11'd0;
        hires_rc <= 3'd7;
        idle = `TRUE;
    end
    else begin
        // In this hi res version, we move our vc counter at twice
        // the rate as normal.  So do this on either hi or lo phase.
        // Must be on [1] for cycle_num to be valid.
        if (phi_phase_start_1) begin
            // Reset at start of frame
            if (clk_phi && cycle_num == 1 && raster_line == 9'd0) begin
                hires_vc_base <= 11'd0;
                hires_vc <= 11'd0;
                hires_fvc <= 15'd0;
            end

            // Increment within the same range (but this happens at 2x)
            // hires_vc increments by 80 every 8 rows (within the
            // visible region).  It repeats its count starting from base
            // for 8 lines before base is set higher. It is used to
            // fetch one byte per half PHI cycle for text mode.
            //
            // hires_fvc increments by 160 per raster line (within
            // the visible region). It can be used to fetch two
            // adjacent bytes per half cycle (PHI) for 32k of visible
            // pixel data.  If divided by 2, it can be used to fetch
            // one byte per half cycle (PHI) for 16k of visible pixel
            // data.
            if (cycle_num > 14 && cycle_num < 55) begin
                if (!idle)
                    hires_vc <= hires_vc + 1'b1;
                if (badline_hist != 0)
                    hires_fvc <= hires_fvc + 15'd2;
            end

            if (clk_phi && cycle_num == 13) begin
                hires_vc <= hires_vc_base;
                if (hires_badline) begin
                    hires_rc <= 3'd0;
                end
                badline_hist <= {badline_hist[6:0], hires_badline};
            end

            // Go to next row at the usual time (only on high phase tho)
            if (clk_phi && cycle_num == 57) begin
                if (hires_rc == 3'd7) begin
                    hires_vc_base <= hires_vc;
                    idle = `TRUE;
                end
                if (!idle | hires_badline) begin
                    hires_rc <= hires_rc + 1'b1;
                    idle = `FALSE;
                end
            end
        end

        if (clk_phi && phi_phase_start_14) begin
            if (hires_badline)
                idle = `FALSE;
        end
    end

endmodule
