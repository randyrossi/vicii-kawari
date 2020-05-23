module EqualizationPulse(rasterX, EQ);
input [9:0] rasterX;
output reg EQ;

always @*
	EQ =		//  4% tH equalization width
	(rasterX < 10'd21) ||
	(
		(rasterX >= 10'd260) &&	// 50%
		(rasterX < 10'd281)		// 54%
	)
	;

endmodule