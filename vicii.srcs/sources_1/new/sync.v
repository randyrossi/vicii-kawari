`define TRUE	1'b1
`define FALSE	1'b0

module sync(chip, rst, clk, rasterX, rasterY, hSyncStart, hSyncEnd, cSync);

parameter CHIP6567R8   = 2'd0;
parameter CHIP6567R56A = 2'd1;
parameter CHIP6569     = 2'd2;
parameter CHIPUNUSED   = 2'd3;

input [1:0] chip;
input rst;
input clk;
input [9:0] rasterX;
input [8:0] rasterY;
input [9:0] hSyncStart;
input [9:0] hSyncEnd;
output reg cSync;
reg hSync;

always @(posedge clk)
begin
	hSync <= `FALSE;
	if (rasterX >= hSyncStart && rasterX <= hSyncEnd)  // TODO configure on chip
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
  case(chip)
  CHIP6567R8,CHIP6567R56A:
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
  CHIP6569,CHIPUNUSED:
	case(rasterY)
	9'd301:	cSync <= ~EQ;
	9'd302:	cSync <= ~EQ;
	9'd303:	cSync <= ~EQ;
	9'd304:	cSync <= ~SE;
	9'd305:	cSync <= ~SE;
	9'd306:	cSync <= ~SE;
	9'd307:	cSync <= ~EQ;
	9'd308:	cSync <= ~EQ;
	9'd309:	cSync <= ~EQ;
	default:
			cSync <= ~hSync;
	endcase
  endcase
endmodule