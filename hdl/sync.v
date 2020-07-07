`include "common.vh"

module sync(
           input wire rst,
           input wire clk,
           input wire [9:0] raster_x,
           input wire [8:0] raster_y,
           input wire [9:0] hsync_start,
           input wire [9:0] hsync_end,
           input wire [8:0] vblank_start,
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
    case(raster_y)
        vblank_start:	csync <= ~EQ;
        vblank_start+1:	csync <= ~EQ;
        vblank_start+2:	csync <= ~EQ;
        vblank_start+3:	csync <= ~SE;
        vblank_start+4:	csync <= ~SE;
        vblank_start+5:	csync <= ~SE;
        vblank_start+6:	csync <= ~EQ;
        vblank_start+7:	csync <= ~EQ;
        vblank_start+8:	csync <= ~EQ;
        default:
            csync <= ~hSync;
    endcase
endmodule : sync
