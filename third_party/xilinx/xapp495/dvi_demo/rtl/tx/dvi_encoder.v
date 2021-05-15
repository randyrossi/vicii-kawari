//////////////////////////////////////////////////////////////////////////////
//
//  Xilinx, Inc. 2009                 www.xilinx.com
//
//  XAPP xyz
//
//////////////////////////////////////////////////////////////////////////////
//
//  File name :       dvi_encoder.v
//
//  Description :     dvi_encoder 
//
//  Date - revision : April 2009 - 1.0.0
//
//  Author :          Bob Feng
//
//  Disclaimer: LIMITED WARRANTY AND DISCLAMER. These designs are
//              provided to you "as is". Xilinx and its licensors makeand you
//              receive no warranties or conditions, express, implied,
//              statutory or otherwise, and Xilinx specificallydisclaims any
//              implied warranties of merchantability, non-infringement,or
//              fitness for a particular purpose. Xilinx does notwarrant that
//              the functions contained in these designs will meet your
//              requirements, or that the operation of these designswill be
//              uninterrupted or error free, or that defects in theDesigns
//              will be corrected. Furthermore, Xilinx does not warrantor
//              make any representations regarding use or the results ofthe
//              use of the designs in terms of correctness, accuracy,
//              reliability, or otherwise.
//
//              LIMITATION OF LIABILITY. In no event will Xilinx or its
//              licensors be liable for any loss of data, lost profits,cost
//              or procurement of substitute goods or services, or forany
//              special, incidental, consequential, or indirect damages
//              arising from the use or operation of the designs or
//              accompanying documentation, however caused and on anytheory
//              of liability. This limitation will apply even if Xilinx
//              has been advised of the possibility of such damage. This
//              limitation shall apply not-withstanding the failure ofthe
//              essential purpose of any limited remedies herein.
//
//  Copyright © 2009 Xilinx, Inc.
//  All rights reserved
//
//////////////////////////////////////////////////////////////////////////////
`timescale 1 ns / 1ps

module dvi_encoder (
input  wire       clkin,          // pixel clock
input  wire       clkx2in,        // pixel clock x2
input  wire       rstin,          // reset
input  wire [7:0] blue_din,       // Blue data in
input  wire [7:0] green_din,      // Green data in
input  wire [7:0] red_din,        // Red data in
input  wire       hsync,          // hsync data
input  wire       vsync,          // vsync data
input  wire       de,             // data enable
output wire [4:0] tmds_data0,
output wire [4:0] tmds_data1,
output wire [4:0]	tmds_data2);		// 5-bit busses converted from 10-bit
	
wire 	[9:0]	red ;
wire 	[9:0]	green ;
wire 	[9:0]	blue ;

encode encb (
	.clkin	(clkin),
	.rstin	(rstin),
	.din		(blue_din),
	.c0			(hsync),
	.c1			(vsync),
	.de			(de),
	.dout		(blue)) ;

encode encg (
	.clkin	(clkin),
	.rstin	(rstin),
	.din		(green_din),
	.c0			(1'b0),
	.c1			(1'b0),
	.de			(de),
	.dout		(green)) ;
	
encode encr (
	.clkin	(clkin),
	.rstin	(rstin),
	.din		(red_din),
	.c0			(1'b0),
	.c1			(1'b0),
	.de			(de),
	.dout		(red)) ;

wire [29:0] s_data = {red[9:5], green[9:5], blue[9:5],
                      red[4:0], green[4:0], blue[4:0]};

convert_30to15_fifo pixel2x (
  .rst     (rstin),
  .clk     (clkin),
  .clkx2   (clkx2in),
  .datain  (s_data),
  .dataout ({tmds_data2, tmds_data1, tmds_data0}));

endmodule
