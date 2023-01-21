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

module SerrationPulse(
           input clk_dot4x,
           input [9:0] raster_x,
           input [1:0] chip,
           output reg SE);

// NOTE: Ranges here need to be shifted up by 10'd10 which is the
// hsync_start x position.  If this ever changes, these values need
// to also change.
always @(posedge clk_dot4x)
case (chip)
    `CHIP6567R8:
        SE <=  // 93% tH (7%tH) (3051-427)
        (raster_x >= 10'd10 && raster_x < 10'd234) ||	// 43%
        (
            (raster_x >= 10'd270) &&	// 50%
            (raster_x < 10'd494)		// 93%
        )
        ;
    `CHIP6567R56A:
        SE <=  // 93% tH (7%tH) (3051-427)
        (raster_x >= 10'd10 && raster_x < 10'd230) ||  // 43%
        (
            (raster_x >= 10'd266) &&    // 50%
            (raster_x < 10'd486)               // 93%
        )
        ;
    `CHIP6569R1, `CHIP6569R3:
        SE <= // 93% tH (7%tH) (3051-427)
        (raster_x >= 10'd10 && raster_x < 10'd227) ||  // 43%
        (
            (raster_x >= 10'd262) &&    // 50%
            (raster_x < 10'd479)               // 93%
        )
        ;
endcase
endmodule
