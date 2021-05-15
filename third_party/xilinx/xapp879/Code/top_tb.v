///////////////////////////////////////////////////////////////////////////////
//    
//    Company:          Xilinx
//    Engineer:         Karl Kurbjun and Carl Ribbing
//    Date:             2/19/2009
//    Design Name:      PLL DRP
//    Module Name:      top_tb.v
//    Version:          1.0
//    Target Devices:   Spartan 6 Family
//    Tool versions:    L.68 (lin)
//    Description:      This is a basic demonstration that drives the PLL_DRP 
//                      ports to trigger two reconfiguration events, one for 
//                      each state.
// 
//    Disclaimer:  XILINX IS PROVIDING THIS DESIGN, CODE, OR
//                 INFORMATION "AS IS" SOLELY FOR USE IN DEVELOPING
//                 PROGRAMS AND SOLUTIONS FOR XILINX DEVICES.  BY
//                 PROVIDING THIS DESIGN, CODE, OR INFORMATION AS
//                 ONE POSSIBLE IMPLEMENTATION OF THIS FEATURE,
//                 APPLICATION OR STANDARD, XILINX IS MAKING NO
//                 REPRESENTATION THAT THIS IMPLEMENTATION IS FREE
//                 FROM ANY CLAIMS OF INFRINGEMENT, AND YOU ARE
//                 RESPONSIBLE FOR OBTAINING ANY RIGHTS YOU MAY
//                 REQUIRE FOR YOUR IMPLEMENTATION.  XILINX
//                 EXPRESSLY DISCLAIMS ANY WARRANTY WHATSOEVER WITH
//                 RESPECT TO THE ADEQUACY OF THE IMPLEMENTATION,
//                 INCLUDING BUT NOT LIMITED TO ANY WARRANTIES OR
//                 REPRESENTATIONS THAT THIS IMPLEMENTATION IS FREE
//                 FROM CLAIMS OF INFRINGEMENT, IMPLIED WARRANTIES
//                 OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
//                 PURPOSE.
// 
//                 (c) Copyright 2008 Xilinx, Inc.
//                 All rights reserved.
// 
///////////////////////////////////////////////////////////////////////////////

`timescale 1ps / 1ps

module top_tb  ();
   reg SSTEP, RST, CLKin, STATE;
   wire SRDY, clk0out, clk1out, clk2out, clk3out, clk4out, clk5out;

   top U1 
   (
      .SSTEP(SSTEP),
      .STATE(STATE),
      .RST(RST),
      .CLKIN(CLKin),
      .SRDY(SRDY),
      .CLK0OUT(clk0out),
      .CLK1OUT(clk1out),
      .CLK2OUT(clk2out),
      .CLK3OUT(clk3out),
      .CLK4OUT(clk4out),
      .CLK5OUT(clk5out)
   );
   
   localparam one_ns = 1000;

   always
      #(5*one_ns) CLKin = ~CLKin;

   // This is a demonstration testbench that toggles the necessary signals to 
   // trigger reconfiguration for each state.
      
   initial begin
      $display($time, "<< Begin Simulation >>");
      CLKin=1'b0;     // Initialize CLKin

      RST=1'b1;          // Activate Reset

      STATE=1'b0;
      SSTEP=1'b0;        // Don't Step Yet
      
      #(130*one_ns)

      RST=1'b0;

      #(500*one_ns)
      @(negedge CLKin);
      SSTEP=1'b1;
      @(negedge CLKin);
      SSTEP=1'b0;
      #(3500*one_ns)
      @(negedge CLKin);
      STATE=1'b1;
      SSTEP=1'b1;
      @(negedge CLKin);
      SSTEP=1'b0;
      #(3500*one_ns)

      $stop;
   end
endmodule
