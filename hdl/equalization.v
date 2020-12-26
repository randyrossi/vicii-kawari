`timescale 1ns / 1ps

`include "common.vh"

module EqualizationPulse(
           input [9:0] raster_x,
           input [1:0] chip,
           output reg EQ);

always @*
case (chip)
    `CHIP6567R8:
        EQ =		//  4% tH equalization width
        (raster_x < 10'd21) ||
        (
            (raster_x >= 10'd260) &&	// 50%
            (raster_x < 10'd281)		// 54%
        )
        ;
    `CHIP6567R56A:
        EQ =           //  4% tH equalization width
        (raster_x < 10'd20) ||
        (
            (raster_x >= 10'd256) &&
            (raster_x < 10'd276)
        )
        ;
    `CHIP6569, `CHIPUNUSED:
        EQ =           //  4% tH equalization width
        (raster_x < 10'd20) ||   // 4%
        (
            (raster_x >= 10'd252) && // 50%
            (raster_x < 10'd272)             // 54%
        )
        ;
endcase
endmodule
