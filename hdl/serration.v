module SerrationPulse(raster_x, SE);
input [9:0] raster_x;
output reg SE;

always @*
	SE =		// 93% tH (7%tH) (3051-427)
	(raster_x < 10'd224) ||	// 43%
	(	
		(raster_x >= 10'd260) &&	// 50%
	 	(raster_x < 10'd484)		// 93%
	)
	;

endmodule