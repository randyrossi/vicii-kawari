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

// This is a modified DVI encoder module originally
// written by Sameer Puri.  It is a verilog version
// with all HDMI logic removed, hard coded to
// 3 data channels and uses no vendor IP blocks. It
// also uses a 10x pixel to drive serialization rather
// than a 5x clock. It is expected the tmds and
// tmds_clock outputs will be passed to a differential
// buffer (vendor specific).
//
// https://github.com/sameer
// https://github.com/hdl-util/hdmi
// 
// Serializer - does not use any vendor IP so there
// may be limits on how fast clk_pixel_x10 can be
// due to component switching limits.
module serializer
(
    input clk_pixel,
    input clk_pixel_x10,
    input reset,
    input [9:0] tmds_internal0,
    input [9:0] tmds_internal1,
    input [9:0] tmds_internal2,
    output reg [2:0] tmds,
    output reg tmds_clock
);

    reg [9:0] tmds_shift0;
    reg [9:0] tmds_shift1;
    reg [9:0] tmds_shift2;

    // We must capture the data from tmds_internal on every
    // positive edge of the slow clock.  The tmds_control flag
    // toggles each posedge and we will detect transitions on
    // the fast clock to signal load.
    reg[9:0] tmds_control;
    always @(posedge clk_pixel_x10)
      if (reset)
         tmds_control <= 10'b0000000001;
      else
         tmds_control <= { tmds_control[0], tmds_control[9:1] };

    // Trigger load signal when we see a transition on the shift register.
    // This will latch the data from tmds_internal just as we shift
    // the last bit of the previous data.
    wire load;
    assign load = tmds_control[0];

    // Clock domain crossing
    reg[9:0] tmds_internal0_1;
    reg[9:0] tmds_internal0_2;
    reg[9:0] tmds_internal1_1;
    reg[9:0] tmds_internal1_2;
    reg[9:0] tmds_internal2_1;
    reg[9:0] tmds_internal2_2;
    always @(posedge clk_pixel_x10) tmds_internal0_1 <= tmds_internal0;
    always @(posedge clk_pixel_x10) tmds_internal0_2 <= tmds_internal0_1;
    always @(posedge clk_pixel_x10) tmds_internal1_1 <= tmds_internal1;
    always @(posedge clk_pixel_x10) tmds_internal1_2 <= tmds_internal1_1;
    always @(posedge clk_pixel_x10) tmds_internal2_1 <= tmds_internal2;
    always @(posedge clk_pixel_x10) tmds_internal2_2 <= tmds_internal2_1;

    // Fast clock picks up the data on load signal, just as we finished
    // shifting out the last but from the previous load.
    always @(posedge clk_pixel_x10) tmds_shift0 <= load ? tmds_internal0_2 : tmds_shift0 >> 1;
    always @(posedge clk_pixel_x10) tmds_shift1 <= load ? tmds_internal1_2 : tmds_shift1 >> 1;
    always @(posedge clk_pixel_x10) tmds_shift2 <= load ? tmds_internal2_2 : tmds_shift2 >> 1;

    // This is a fast clock generator signal
    //reg [9:0] tmds_shift_clk_pixel;
    (* async_reg="true" *) reg [9:0] tmds_shift_clk_pixel;
    always @(posedge clk_pixel_x10) begin
       if (reset)
          tmds_shift_clk_pixel <= 10'b0000011111;
       else
          tmds_shift_clk_pixel <= 
              load ? 10'b0000011111 : tmds_shift_clk_pixel >> 1;
    end

    // Final output for both data and clock signals.
    always @(posedge clk_pixel_x10) tmds[0] <= tmds_shift0[0];
    always @(posedge clk_pixel_x10) tmds[1] <= tmds_shift1[0];
    always @(posedge clk_pixel_x10) tmds[2] <= tmds_shift2[0];
    always @(posedge clk_pixel_x10) tmds_clock <= tmds_shift_clk_pixel[0];
endmodule
