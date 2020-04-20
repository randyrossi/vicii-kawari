`define TRUE	1'b1
`define FALSE	1'b0

module sync(rst, clk, rasterX, rasterY, cSync);

input rst;
input clk;
input [9:0] rasterX;
input [8:0] rasterY;
output reg cSync;
reg vSync;
reg hSync;

always @(posedge clk)
if (rst)
	vSync <= `FALSE;
else begin
    if (rasterY >= 3 && rasterY < 6)
		vSync <= `TRUE;
	else
		vSync <= `FALSE;
end

always @(posedge clk)
begin
	hSync <= `FALSE;
	if (rasterX >= 10'd416 && rasterX <= 10'd453)  // TODO configure on chip
		hSync <= `TRUE;
end

// Compute Equalization pulses
wire EQ, SE;
EqualizationPulse ueqp1
(
	.rasterX(rasterX),
	.EQ(EQ)
);

// Compute Serration pulses
SerrationPulse usep1
(
	.rasterX(rasterX),
	.SE(SE)
);

always @(posedge clk)
    // TODO make configurable based on chip
    // Rob's code used 0-9 but datasheet says 14-22
	case(rasterY)
	9'd14:	cSync <= ~EQ;
	9'd15:	cSync <= ~EQ;
	9'd16:	cSync <= ~EQ;
	9'd17:	cSync <= ~SE;
	9'd18:	cSync <= ~SE;
	9'd19:	cSync <= ~SE;
	9'd20:	cSync <= ~EQ;
	9'd21:	cSync <= ~EQ;
	9'd22:	cSync <= ~EQ;
	default:
			cSync <= ~hSync;
	endcase

endmodule