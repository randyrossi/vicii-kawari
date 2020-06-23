`timescale 1ns / 1ps

module EqualizationPulse(raster_x, EQ);
input [9:0] raster_x;
output reg EQ;

always @*
	EQ =		//  4% tH equalization width
	(raster_x < 10'd21) ||
	(
		(raster_x >= 10'd260) &&	// 50%
		(raster_x < 10'd281)		// 54%
	)
	;

endmodule