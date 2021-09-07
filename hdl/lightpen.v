`timescale 1ns/1ps

`include "common.vh"

module lightpen(
           input [1:0] chip,
           input clk_dot4x,
           input clk_phi,
           input phi_phase_start_sof,
           input ilp_clr,
           input [8:0] raster_line,
           input [8:0] raster_line_d,
           input [8:0] raster_y_max,
           input [6:0] cycle_num,
           input lp,
           input [7:0] xpos_div_2,
           output reg [7:0] lpx,
           output reg [7:0] lpy,
           output reg ilp
       );

wire start_of_frame;
assign start_of_frame = raster_line == 0 && clk_phi &&
                           phi_phase_start_sof && cycle_num == 1;

// This delay was found by trial and error using
// splittests/lightpen.prg.  If we 'process' the lp input too quickly,
// we trigger on the wrong xpos.
reg lp_delay_1;
reg lp_delay_2;
reg lp_delay_3;
reg lp_delay_4;

reg light_pen_triggered;
always @(posedge clk_dot4x)
begin
    begin
        lp_delay_1 <= lp;
        lp_delay_2 <= lp_delay_1;
        lp_delay_3 <= lp_delay_2;
        lp_delay_4 <= lp_delay_3;
 

        if (ilp_clr)
            ilp <= `FALSE;
        if (start_of_frame)
            light_pen_triggered <= `FALSE;
        if (!light_pen_triggered && lp_delay_4 == `FALSE) begin
            light_pen_triggered <= `TRUE;

            if (raster_line_d != raster_y_max || cycle_num == 0) 
            begin
              // Simulate lp irq bug on 6569r1/6567r56a. if lp is still
              // low during cycle 1 (and we're past the point where we
              // would have lifted the triggered flag), then we trigger
              // ilp.
              if (raster_line == 0 && clk_phi && cycle_num == 1) begin
                 if (chip == `CHIP6569R1 || chip == `CHIP6567R56A) begin
                    ilp <= `TRUE;
                 end
              end

              lpx <= xpos_div_2; // passes lp-trigger/test1.prg & test2.prg
              lpy <= raster_line[7:0]; // for some reason not _d

              // Simulate lp irq bug on 6569r1/6567r56a
              if (chip != `CHIP6569R1 && chip != `CHIP6567R56A)
                 ilp <= `TRUE;
            end
        end
    end
end


endmodule: lightpen
