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
module dvi 
(
    input  clk_pixel,
    input  clk_pixel_x10,
    input  reset,
    input  [23:0] rgb,
    input  hsync,
    input  vsync,
    input  de,

    output wire [2:0] tmds,
    output wire tmds_clock
);

// We only do DVI, so we only have video/control data.
reg [23:0] video_data = 24'd0;
reg [5:0] control_data = 6'd0;

always @(posedge clk_pixel) video_data <= rgb;
always @(posedge clk_pixel) control_data <= {4'b0000, {vsync, hsync}};

// All logic below relates to the production and output of the 10-bit TMDS code.
wire [9:0] tmds_b;
wire [9:0] tmds_g;
wire [9:0] tmds_r;

tmds_channel #(.CN(0)) tmds_channel0 (.clk_pixel(clk_pixel), .video_data(video_data[7:0]), .control_data(control_data[1:0]), .mode(de), .tmds(tmds_b));
tmds_channel #(.CN(1)) tmds_channel1 (.clk_pixel(clk_pixel), .video_data(video_data[15:8]), .control_data(control_data[3:2]), .mode(de), .tmds(tmds_g));
tmds_channel #(.CN(2)) tmds_channel2 (.clk_pixel(clk_pixel), .video_data(video_data[23:16]), .control_data(control_data[5:4]), .mode(de), .tmds(tmds_r));

serializer serializer(.clk_pixel(clk_pixel), .clk_pixel_x10(clk_pixel_x10), .reset(reset), .tmds_internal0(tmds_b), .tmds_internal1(tmds_r), .tmds_internal2(tmds_g), .tmds(tmds), .tmds_clock(tmds_clock));

endmodule
