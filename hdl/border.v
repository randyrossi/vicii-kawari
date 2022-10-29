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

// border on/off logic
module border(
           input clk_dot4x,
           input clk_phi,
           input [6:0] cycle_num,
           input [9:0] xpos,
           input [8:0] raster_line,
           input rsel,
           input csel,
           input den,
           input dot_rising,
           output reg vborder,
           output reg main_border
       );

reg set_vborder;

always @(posedge clk_dot4x)
begin
    if (dot_rising) begin
        // check hborder - lands on 16 & 17 at the right pixels
        if ((xpos == 38 && csel == `FALSE) ||
                (xpos == 31 && csel == `TRUE)) begin
            // check vborder bottom
            if ((raster_line == 247 && rsel == `FALSE) ||
                    (raster_line == 251 && rsel == `TRUE))
                set_vborder = 1;
            vborder = set_vborder;
            if (vborder == 0) begin
                main_border = 0;
            end
        end
        // check hborder - lands on 56 & 57 at the right pixels
        else if ((xpos == 351 && csel == `TRUE) ||
                 (xpos == 342 && csel == `FALSE)) begin
            main_border = 1;
        end

        if (clk_phi) begin
            // check vborder top
            if (((raster_line == 55 && rsel == `FALSE) ||
                    (raster_line == 51 && rsel == `TRUE)) && den) begin
                vborder = 0;
                set_vborder = 0;
            end

            // check vborder bottom
            if ((raster_line == 247 && rsel == `FALSE) ||
                    (raster_line == 251 && rsel == `TRUE))
                set_vborder = 1;

            if (cycle_num == 0)
                vborder = set_vborder;
        end
    end
end

endmodule
