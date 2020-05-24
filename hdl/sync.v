`include "common.vh"

module sync(
	input chip_type chip,
	input wire rst,
	input wire clk,
	input wire [9:0] rasterX,
	input wire [8:0] rasterY,
	input wire [9:0] hSyncStart,
	input wire [9:0] hSyncEnd,
	output reg cSync);

reg hSync;

always @(posedge clk)
begin
    if (rst)
       hSync <= `FALSE;
    else begin
       hSync <= `FALSE;
       if (rasterX >= hSyncStart && rasterX <= hSyncEnd)
           hSync <= `TRUE;
    end
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
  if (rst)
     cSync <= 1'b0;
  else
  case(chip)
  CHIP6567R8,CHIP6567R56A:
	case(rasterY)
	9'd11:	cSync <= ~EQ;
	9'd12:	cSync <= ~EQ;
	9'd13:	cSync <= ~EQ;
	9'd14:	cSync <= ~SE;
	9'd15:	cSync <= ~SE;
	9'd16:	cSync <= ~SE;
	9'd17:	cSync <= ~EQ;
	9'd18:	cSync <= ~EQ;
	9'd19:	cSync <= ~EQ;
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
endmodule : sync