`include "common.vh"

module sync(
	input chip_type chip,
	input wire rst,
	input wire clk,
	input wire [9:0] raster_x,
	input wire [8:0] raster_y,
	input wire [9:0] hsync_start,
	input wire [9:0] hsync_end,
	output reg csync);

reg hSync;

always @(posedge clk)
begin
    if (rst)
       hSync <= `FALSE;
    else begin
       hSync <= `FALSE;
       if (raster_x >= hsync_start && raster_x <= hsync_end)
           hSync <= `TRUE;
    end
end

// Compute Equalization pulses
wire EQ, SE;
EqualizationPulse ueqp1
(
	.raster_x(raster_x),
	.EQ(EQ)
);

// Compute Serration pulses
SerrationPulse usep1
(
	.raster_x(raster_x),
	.SE(SE)
);

always @(posedge clk)
  if (rst)
     csync <= 1'b0;
  else
  case(chip)
  CHIP6567R8,CHIP6567R56A:
	case(raster_y)
	9'd11:	csync <= ~EQ;
	9'd12:	csync <= ~EQ;
	9'd13:	csync <= ~EQ;
	9'd14:	csync <= ~SE;
	9'd15:	csync <= ~SE;
	9'd16:	csync <= ~SE;
	9'd17:	csync <= ~EQ;
	9'd18:	csync <= ~EQ;
	9'd19:	csync <= ~EQ;
	default:
			csync <= ~hSync;
	endcase
  CHIP6569,CHIPUNUSED:
	case(raster_y)
	9'd301:	csync <= ~EQ;
	9'd302:	csync <= ~EQ;
	9'd303:	csync <= ~EQ;
	9'd304:	csync <= ~SE;
	9'd305:	csync <= ~SE;
	9'd306:	csync <= ~SE;
	9'd307:	csync <= ~EQ;
	9'd308:	csync <= ~EQ;
	9'd309:	csync <= ~EQ;
	default:
			csync <= ~hSync;
	endcase
  endcase
endmodule : sync