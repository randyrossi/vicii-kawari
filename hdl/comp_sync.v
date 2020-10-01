`include "common.vh"

// A module that produces a composite sync signal for the
// Sony CXA1645P composite encoder IC.  Also outputs
// last stage pixel color for display and a color reference
// clock for the CXA1645P.
module comp_sync(
           input wire rst,
           input wire clk_dot4x,
           input wire clk_col4x,
           input [1:0] chip,
           input vic_color pixel_color3,
           input wire [9:0] raster_x,
           input wire [8:0] raster_y,
           output reg csync,
           output vic_color pixel_color4,
           output clk_colref);

reg [9:0] hsync_start;
reg [9:0] hsync_end;
reg [9:0] hvisible_start;
reg [8:0] vblank_start;
reg [8:0] vblank_end;
reg composite_active;
reg hSync;

// Divides the color4x clock by 4 to get color reference clock
clk_div4 clk_colorgen (
          .clk_in(clk_col4x),     // from 4x color clock
          .reset(rst),
          .clk_out(clk_colref));  // create color ref clock

always @(*)
begin
       if ((raster_x < hsync_start || raster_x > hvisible_start) &&
           (raster_y < vblank_start || raster_y > vblank_end))
           composite_active = 1'b1;
       else
           composite_active = 1'b0;

       pixel_color4 = composite_active ? pixel_color3 : BLACK;
end

always @(chip)
case(chip)
    `CHIP6567R8:
    begin
        hsync_start = 10'd409;
        hsync_end = 10'd446;       // ~4.6us
        hvisible_start = 10'd497;  // ~10.7us after hsync_start seems to work
        vblank_start = 9'd14;
        vblank_end = 9'd22;
    end
    `CHIP6567R56A:
    begin
        hsync_start = 10'd409;
        hsync_end = 10'd446;       // ~4.6us
        hvisible_start = 10'd497;  // ~10.7us after hsync_start seems to work
        vblank_start = 9'd14;
        vblank_end = 9'd22;
    end
    `CHIP6569, `CHIPUNUSED:
    begin
        hsync_start = 10'd408;
        hsync_end = 10'd444;        // ~4.6us
        hvisible_start = 10'd492;   // ~10.7 after hsync_start
        vblank_start = 9'd301;
        vblank_end = 9'd309;
    end
endcase

always @(posedge clk_dot4x)
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
                      .chip(chip),
                      .EQ(EQ)
                  );

// Compute Serration pulses
SerrationPulse usep1
               (
                   .raster_x(raster_x),
                   .chip(chip),
                   .SE(SE)
               );

always @(posedge clk_dot4x)
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
endmodule : comp_sync
