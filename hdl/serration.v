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
