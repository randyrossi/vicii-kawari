`timescale 1ns/1ps

`include "common.vh"

module lightpen(
   input clk_dot4x,
   input rst,
   input ilp_clr,
   input [8:0] raster_line,
   input [8:0] raster_y_max,
   input lp,
   input [7:0] xpos_div_2,
   output reg [7:0] lpx,
   output reg [7:0] lpy,
   output reg ilp
);

reg light_pen_triggered;
always @(posedge clk_dot4x)
begin
    if (rst) begin
        //lpx <= 'h00;
        //lpy <= 'h00;
        ilp <= `FALSE;
        light_pen_triggered <= `FALSE;
    end else begin
        if (ilp_clr)
            ilp <= `FALSE;
        if (raster_line == raster_y_max)
            light_pen_triggered <= `FALSE;
        else if (!light_pen_triggered && lp == `FALSE) begin
            light_pen_triggered <= `TRUE;
            ilp <= `TRUE;
            lpx <= xpos_div_2;
            lpy <= raster_line[7:0];
        end
    end
end


endmodule: lightpen
