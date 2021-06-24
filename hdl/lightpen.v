`timescale 1ns/1ps

`include "common.vh"

module lightpen(
           input clk_dot4x,
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
    begin
        if (ilp_clr)
            ilp <= `FALSE;
        if (raster_line == raster_y_max)
            light_pen_triggered <= `FALSE;
        else if (!light_pen_triggered && lp == `FALSE) begin
            light_pen_triggered <= `TRUE;
            ilp <= `TRUE;
`ifdef SIMULATOR_BOARD
            lpx <= xpos_div_2 + 2; // 6567/6569 offset to keep VICE happy
`else
            lpx <= xpos_div_2; // passes lp-trigger/test1.prg & test2.prg
`endif
            lpy <= raster_line[7:0];
        end
    end
end


endmodule: lightpen
