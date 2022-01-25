//////////////////////////////////////////////////////////////////////////////
//
//  Xilinx, Inc. 2008                 www.xilinx.com
//
//////////////////////////////////////////////////////////////////////////////
//
//  File name :       	serdes_n_to_1.v
//
//  Description :     	1-bit generic n:1 transmitter module
// 			Takes in n bits of data and serialises this to 1 bit
// 			data is transmitted LSB first
// 			0, 1, 2 ......
//
//  Date - revision : 	August 1st 2008 - v 1.0
//
//  Author :          	NJS
//
//  Disclaimer: LIMITED WARRANTY AND DISCLAMER. These designs are
//              provided to you "as is". Xilinx and its licensors make and you
//              receive no warranties or conditions, express, implied,
//              statutory or otherwise, and Xilinx specifically disclaims any
//              implied warranties of merchantability, non-infringement,or
//              fitness for a particular purpose. Xilinx does not warrant that
//              the functions contained in these designs will meet your
//              requirements, or that the operation of these designs will be
//              uninterrupted or error free, or that defects in the Designs
//              will be corrected. Furthermore, Xilinx does not warrantor
//              make any representations regarding use or the results of the
//              use of the designs in terms of correctness, accuracy,
//              reliability, or otherwise.
//
//              LIMITATION OF LIABILITY. In no event will Xilinx or its
//              licensors be liable for any loss of data, lost profits,cost
//              or procurement of substitute goods or services, or for any
//              special, incidental, consequential, or indirect damages
//              arising from the use or operation of the designs or
//              accompanying documentation, however caused and on any theory
//              of liability. This limitation will apply even if Xilinx
//              has been advised of the possibility of such damage. This
//              limitation shall apply not-withstanding the failure of the
//              essential purpose of any limited remedies herein.
//
//  Copyright © 2008 Xilinx, Inc.
//  All rights reserved
//
//////////////////////////////////////////////////////////////////////////////
//

`timescale 1ps/1ps

module serdes_n_to_1 (ioclk, serdesstrobe, reset, gclk, datain, iob_data_out) ;

parameter integer SF = 8 ;   		// Parameter to set the serdes factor 1..8

input 			ioclk ;		// IO Clock network
input 			serdesstrobe ;	// Parallel data capture strobe
input 			reset ;		// Reset
input 			gclk ;		// Global clock
input 	[SF-1 : 0]	datain ;  	// Data for output
output 			iob_data_out ;	// output data

wire		cascade_di ;		//
wire		cascade_do ;		//
wire		cascade_ti ;		//
wire		cascade_to ;		//
wire	[8:0]	mdatain ;		//

genvar i ;				// Pad out the input data bus with 0's to 8 bits to avoid errors
generate
for (i = 0 ; i <= (SF - 1) ; i = i + 1)
begin : loop0
assign mdatain[i] = datain[i] ;
end
endgenerate
generate
for (i = (SF) ; i <= 8 ; i = i + 1)
begin : loop1
assign mdatain[i] = 1'b0 ;
end
endgenerate

OSERDES2 #(
	.DATA_WIDTH     	(SF), 			// SERDES word width.  This should match the setting is BUFPLL
	.DATA_RATE_OQ      	("SDR"), 		// <SDR>, DDR
	.DATA_RATE_OT      	("SDR"), 		// <SDR>, DDR
	.SERDES_MODE    	("MASTER"), 		// <DEFAULT>, MASTER, SLAVE
	.OUTPUT_MODE 		("DIFFERENTIAL"))
oserdes_m (
	.OQ       		(iob_data_out),
	.OCE     		(1'b1),
	.CLK0    		(ioclk),
	.CLK1    		(1'b0),
	.IOCE    		(serdesstrobe),
	.RST     		(reset),
	.CLKDIV  		(gclk),
	.D4  			(mdatain[7]),
	.D3  			(mdatain[6]),
	.D2  			(mdatain[5]),
	.D1  			(mdatain[4]),
	.TQ  			(),
	.T1 			(1'b0),
	.T2 			(1'b0),
	.T3 			(1'b0),
	.T4 			(1'b0),
	.TRAIN    		(1'b0),
	.TCE	   		(1'b1),
	.SHIFTIN1 		(1'b1),			// Dummy input in Master
	.SHIFTIN2 		(1'b1),			// Dummy input in Master
	.SHIFTIN3 		(cascade_do),		// Cascade output D data from slave
	.SHIFTIN4 		(cascade_to),		// Cascade output T data from slave
	.SHIFTOUT1 		(cascade_di),		// Cascade input D data to slave
	.SHIFTOUT2 		(cascade_ti),		// Cascade input T data to slave
	.SHIFTOUT3 		(),			// Dummy output in Master
	.SHIFTOUT4 		()) ;			// Dummy output in Master

OSERDES2 #(
	.DATA_WIDTH     	(SF), 			// SERDES word width.  This should match the setting is BUFPLL
	.DATA_RATE_OQ      	("SDR"), 		// <SDR>, DDR
	.DATA_RATE_OT      	("SDR"), 		// <SDR>, DDR
	.SERDES_MODE    	("SLAVE"), 		// <DEFAULT>, MASTER, SLAVE
	.OUTPUT_MODE 		("DIFFERENTIAL"))
oserdes_s (
	.OQ       		(),
	.OCE     		(1'b1),
	.CLK0    		(ioclk),
	.CLK1    		(1'b0),
	.IOCE    		(serdesstrobe),
	.RST     		(reset),
	.CLKDIV  		(gclk),
	.D4  			(mdatain[3]),
	.D3  			(mdatain[2]),
	.D2  			(mdatain[1]),
	.D1  			(mdatain[0]),
	.TQ  			(),
	.T1 			(1'b0),
	.T2 			(1'b0),
	.T3  			(1'b0),
	.T4  			(1'b0),
	.TRAIN 			(1'b0),
	.TCE	 		(1'b1),
	.SHIFTIN1 		(cascade_di),		// Cascade input D from Master
	.SHIFTIN2 		(cascade_ti),		// Cascade input T from Master
	.SHIFTIN3 		(1'b1),			// Dummy input in Slave
	.SHIFTIN4 		(1'b1),			// Dummy input in Slave
	.SHIFTOUT1 		(),			// Dummy output in Slave
	.SHIFTOUT2 		(),			// Dummy output in Slave
	.SHIFTOUT3 		(cascade_do),   	// Cascade output D data to Master
	.SHIFTOUT4 		(cascade_to)) ; 	// Cascade output T data to Master

endmodule
