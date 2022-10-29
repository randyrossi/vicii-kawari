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
           input [9:0] raster_x,
           input [1:0] chip,
           output reg SE);

always @*
case (chip)
    `CHIP6567R8:
        SE =  // 93% tH (7%tH) (3051-427)
        (raster_x < 10'd224) ||	// 43%
        (
            (raster_x >= 10'd260) &&	// 50%
            (raster_x < 10'd484)		// 93%
        )
        ;
    `CHIP6567R56A:
        SE =  // 93% tH (7%tH) (3051-427)
        (raster_x < 10'd220) ||  // 43%
        (
            (raster_x >= 10'd256) &&
            (raster_x < 10'd476)
        )
        ;
    `CHIP6569R1, `CHIP6569R3:
        SE = // 93% tH (7%tH) (3051-427)
        (raster_x < 10'd217) ||
        (
            (raster_x >= 10'd252) &&
            (raster_x < 10'd469)
        )
        ;
endcase
endmodule
