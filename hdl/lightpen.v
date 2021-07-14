`timescale 1ns/1ps

`include "common.vh"

module lightpen(
           input [1:0] chip,
           input clk_dot4x,
           input ilp_clr,
           input [8:0] raster_line,
           input [8:0] raster_y_max,
           input [6:0] cycle_num,
           input start_of_frame,
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
        if (raster_line == raster_y_max && cycle_num > 0)
            light_pen_triggered <= `FALSE;
        else if (!light_pen_triggered && lp == `FALSE) begin
            light_pen_triggered <= `TRUE;
            lpy <= raster_line[7:0];

            // Simulate lp irq bug on 6569r1/6567r56a
            if (start_of_frame && cycle_num == 7'b0) begin
               if (chip == `CHIP6569R1 || chip == `CHIP6567R56A) begin
                  ilp <= `TRUE;
               end
            end

`ifdef SIMULATOR_BOARD
            lpx <= xpos_div_2 + 2; // 6567/6569 offset to keep VICE happy
`else
            lpx <= xpos_div_2; // passes lp-trigger/test1.prg & test2.prg
`endif

            // Simulate lp irq bug on 6569r1/6567r56a
            if (chip != `CHIP6569R1 && chip != `CHIP6567R56A)
               ilp <= `TRUE;
        end
    end
end


endmodule: lightpen
