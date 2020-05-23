module SerrationPulse(rasterX, SE);
input [9:0] rasterX;
output reg SE;

always @*
	SE =		// 93% tH (7%tH) (3051-427)
	(rasterX < 10'd224) ||	// 43%
	(	
		(rasterX >= 10'd260) &&	// 50%
	 	(rasterX < 10'd484)		// 93%
	)
	;

endmodule