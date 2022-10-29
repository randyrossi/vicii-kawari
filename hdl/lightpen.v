// This file is part of the vicii-kawari distribution
// (https://github.com/randyrossi/vicii-kawari)
// Copyright (c) 2022 Randy Rossi.
// 
// This program is free software: you can redistribute it and/or modify  
// it under the terms of the GNU General Public License as published by  
// the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful, but 
// WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License 
// along with this program. If not, see <http://www.gnu.org/licenses/>.

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
reg lp_delay_1 = 1'b1;
reg lp_delay_2 = 1'b1;
reg lp_delay_3 = 1'b1;

`ifdef SIMULATOR_BOARD
reg lp_delay_4 = 1'b1;
reg lp_delay_5 = 1'b1;
reg lp_delay_6 = 1'b1;
reg lp_delay_7 = 1'b1;
reg lp_delay_8 = 1'b1;
reg lp_delay_9 = 1'b1;
reg lp_delay_10 = 1'b1;
reg lp_delay_11 = 1'b1;
reg lp_delay_12 = 1'b1;
`endif

// Simualtor and real hardware use different delays.
// This is just because the simulator hook drops lp
// earlier than in the real universe and I'm too lazy
// to change the simulator hooks.
`ifdef SIMULATOR_BOARD
`define LP_DELAY_REG lp_delay_12
`else
`define LP_DELAY_REG lp_delay_3
`endif

reg light_pen_triggered;
always @(posedge clk_dot4x)
begin
    begin
        lp_delay_1 <= lp;
        lp_delay_2 <= lp_delay_1;
        lp_delay_3 <= lp_delay_2;
 
`ifdef SIMULATOR_BOARD
        lp_delay_4 <= lp_delay_3;
        lp_delay_5 <= lp_delay_4;
        lp_delay_6 <= lp_delay_5;
        lp_delay_7 <= lp_delay_6;
        lp_delay_8 <= lp_delay_7;
        lp_delay_9 <= lp_delay_8;
        lp_delay_10 <= lp_delay_9;
        lp_delay_11 <= lp_delay_10;
        lp_delay_12 <= lp_delay_11;
`endif

        if (ilp_clr)
            ilp <= `FALSE;
        if (start_of_frame)
            light_pen_triggered <= `FALSE;
        if (!light_pen_triggered && `LP_DELAY_REG == `FALSE) begin
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

endmodule
