///////////////////////////////////////////////////////////////////////////////
//    
//    Company:          Xilinx
//    Engineer:         Karl Kurbjun and Carl Ribbing
//    Date:             2/19/2009
//    Design Name:      PLL DRP
//    Module Name:      top.v
//    Version:          1.0
//    Target Devices:   Spartan 6 Family
//    Tool versions:    L.68 (lin)
//    Description:      This is a basic demonstration of the PLL_DRP 
//                      connectivity to the PLL_ADV.
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

`timescale 1ps/1ps

module top 
   (
      // SSTEP is the input to start a reconfiguration.  It should only be
      // pulsed for one clock cycle.
      input    SSTEP,
      // STATE determines which state the PLL_ADV will be reconfigured to.  A 
      // value of 0 correlates to state 1, and a value of 1 correlates to state 
      // 2.
      input    STATE,

      // RST will reset the entire reference design including the PLL_ADV
      input    RST,
      // CLKIN is the input clock that feeds the PLL_ADV CLKIN as well as the
      // clock for the PLL_DRP module
      input    CLKIN,

      // SRDY pulses for one clock cycle after the PLL_ADV is locked and the 
      // PLL_DRP module is ready to start another re-configuration
      output   SRDY,
      
      // These are the clock outputs from the PLL_ADV.
      output   CLK0OUT,
      output   CLK1OUT,
      output   CLK2OUT,
      output   CLK3OUT,
      output   CLK4OUT,
      output   CLK5OUT
   );
   
   // These signals are used as direct connections between the PLL_ADV and the
   // PLL_DRP.
   wire [15:0]    di;
   wire [6:0]     daddr;
   wire [15:0]    dout;
   wire           den;
   wire           dwe;
   wire           dclk;
   wire           rst_pll;
   wire           drdy;
   wire           locked;
   
   // These signals are used for the BUFG's necessary for the design.
   wire           clkin_bufgout;
   
   wire           clkfb_bufgout;
   wire           clkfb_bufgin;
   
   wire           clk0_bufgin;
   wire           clk0_bufgout;
   
   wire           clk1_bufgin;
   wire           clk1_bufgout;
   
   wire           clk2_bufgin;
   wire           clk2_bufgout;
   
   wire           clk3_bufgin;
   wire           clk3_bufgout;
   
   wire           clk4_bufgin;
   wire           clk4_bufgout;
   
   wire           clk5_bufgin;
   wire           clk5_bufgout;

   // Global buffers used in design
   BUFG BUFG_IN (
      .O(clkin_bufgout),
      .I(CLKIN) 
   );
   
   BUFG BUFG_FB (
      .O(clkfb_bufgout),
      .I(clkfb_bufgin) 
   );
   
   BUFG BUFG_CLK0 (
      .O(clk0_bufgout),
      .I(clk0_bufgin) 
   );
   
   BUFG BUFG_CLK1 (
      .O(clk1_bufgout),
      .I(clk1_bufgin) 
   );
   
   BUFG BUFG_CLK2 (
      .O(clk2_bufgout),
      .I(clk2_bufgin) 
   );
   
   BUFG BUFG_CLK3 (
      .O(clk3_bufgout),
      .I(clk3_bufgin) 
   );
   
   BUFG BUFG_CLK4 (
      .O(clk4_bufgout),
      .I(clk4_bufgin) 
   );
   
   BUFG BUFG_CLK5 (
      .O(clk5_bufgout),
      .I(clk5_bufgin) 
   );
   
   // ODDR registers used to output clocks
   
   ODDR2 #(
	.DDR_ALIGNMENT("NONE"), // Sets output alignment to "NONE", "C0" or "C1"
	.INIT(1'b0), // Sets initial state of the Q output to 1’b0 or 1’b1
	.SRTYPE("SYNC") // Specifies "SYNC" or "ASYNC" set/reset
	) ODDR2_CLK0 (
		.Q(CLK0OUT), // 1-bit DDR output data
		.C0(clk0_bufgout), // 1-bit clock input
		.C1(~clk0_bufgout), // 1-bit clock input
		.CE(1'b1), // 1-bit clock enable input
		.D0(1'b1), // 1-bit data input (associated with C0)
		.D1(1'b0), // 1-bit data input (associated with C1)
		.R(RST), // 1-bit reset input
		.S(1'b0) // 1-bit set input
	);
   
   ODDR2 #(
	.DDR_ALIGNMENT("NONE"), // Sets output alignment to "NONE", "C0" or "C1"
	.INIT(1'b0), // Sets initial state of the Q output to 1’b0 or 1’b1
	.SRTYPE("SYNC") // Specifies "SYNC" or "ASYNC" set/reset
	) ODDR2_CLK1 (
		.Q(CLK1OUT), // 1-bit DDR output data
		.C0(clk1_bufgout), // 1-bit clock input
		.C1(~clk1_bufgout), // 1-bit clock input
		.CE(1'b1), // 1-bit clock enable input
		.D0(1'b1), // 1-bit data input (associated with C0)
		.D1(1'b0), // 1-bit data input (associated with C1)
		.R(RST), // 1-bit reset input
		.S(1'b0) // 1-bit set input
	);
	
   ODDR2 #(
	.DDR_ALIGNMENT("NONE"), // Sets output alignment to "NONE", "C0" or "C1"
	.INIT(1'b0), // Sets initial state of the Q output to 1’b0 or 1’b1
	.SRTYPE("SYNC") // Specifies "SYNC" or "ASYNC" set/reset
	) ODDR2_CLK2 (
		.Q(CLK2OUT), // 1-bit DDR output data
		.C0(clk2_bufgout), // 1-bit clock input
		.C1(~clk2_bufgout), // 1-bit clock input
		.CE(1'b1), // 1-bit clock enable input
		.D0(1'b1), // 1-bit data input (associated with C0)
		.D1(1'b0), // 1-bit data input (associated with C1)
		.R(RST), // 1-bit reset input
		.S(1'b0) // 1-bit set input
	);
	
   ODDR2 #(
	.DDR_ALIGNMENT("NONE"), // Sets output alignment to "NONE", "C0" or "C1"
	.INIT(1'b0), // Sets initial state of the Q output to 1’b0 or 1’b1
	.SRTYPE("SYNC") // Specifies "SYNC" or "ASYNC" set/reset
	) ODDR2_CLK3 (
		.Q(CLK3OUT), // 1-bit DDR output data
		.C0(clk3_bufgout), // 1-bit clock input
		.C1(~clk3_bufgout), // 1-bit clock input
		.CE(1'b1), // 1-bit clock enable input
		.D0(1'b1), // 1-bit data input (associated with C0)
		.D1(1'b0), // 1-bit data input (associated with C1)
		.R(RST), // 1-bit reset input
		.S(1'b0) // 1-bit set input
	);

   ODDR2 #(
	.DDR_ALIGNMENT("NONE"), // Sets output alignment to "NONE", "C0" or "C1"
	.INIT(1'b0), // Sets initial state of the Q output to 1’b0 or 1’b1
	.SRTYPE("SYNC") // Specifies "SYNC" or "ASYNC" set/reset
	) ODDR2_CLK4 (
		.Q(CLK4OUT), // 1-bit DDR output data
		.C0(clk4_bufgout), // 1-bit clock input
		.C1(~clk4_bufgout), // 1-bit clock input
		.CE(1'b1), // 1-bit clock enable input
		.D0(1'b1), // 1-bit data input (associated with C0)
		.D1(1'b0), // 1-bit data input (associated with C1)
		.R(RST), // 1-bit reset input
		.S(1'b0) // 1-bit set input
	);
	
   ODDR2 #(
	.DDR_ALIGNMENT("NONE"), // Sets output alignment to "NONE", "C0" or "C1"
	.INIT(1'b0), // Sets initial state of the Q output to 1’b0 or 1’b1
	.SRTYPE("SYNC") // Specifies "SYNC" or "ASYNC" set/reset
	) ODDR2_CLK5 (
		.Q(CLK5OUT), // 1-bit DDR output data
		.C0(clk5_bufgout), // 1-bit clock input
		.C1(~clk5_bufgout), // 1-bit clock input
		.CE(1'b1), // 1-bit clock enable input
		.D0(1'b1), // 1-bit data input (associated with C0)
		.D1(1'b0), // 1-bit data input (associated with C1)
		.R(RST), // 1-bit reset input
		.S(1'b0) // 1-bit set input
	);
   
   // PLL_ADV that reconfiguration will take place on
   PLL_ADV #(
	  .SIM_DEVICE("SPARTAN6"),
      .DIVCLK_DIVIDE(1), // 1 to 52
      
      .BANDWIDTH("LOW"), // "HIGH", "LOW" or "OPTIMIZED"
      
      // CLKFBOUT stuff
      .CLKFBOUT_MULT(8), 
      .CLKFBOUT_PHASE(0.0),
      
      // Set the clock period (ns) of input clocks and reference jitter
      .REF_JITTER(0.100),
      .CLKIN1_PERIOD(10.000),
      .CLKIN2_PERIOD(10.000), 

      // CLKOUT parameters:
      // DIVIDE: (1 to 128)
      // DUTY_CYCLE: (0.01 to 0.99) - This is dependent on the divide value.
      // PHASE: (0.0 to 360.0) - This is dependent on the divide value.
      .CLKOUT0_DIVIDE(8),
      .CLKOUT0_DUTY_CYCLE(0.5),
      .CLKOUT0_PHASE(0.0), 
      
      .CLKOUT1_DIVIDE(8), 
      .CLKOUT1_DUTY_CYCLE(0.5),
      .CLKOUT1_PHASE(0.0), 
      
      .CLKOUT2_DIVIDE(8),
      .CLKOUT2_DUTY_CYCLE(0.5),
      .CLKOUT2_PHASE(0.0),
      
      .CLKOUT3_DIVIDE(8),
      .CLKOUT3_DUTY_CYCLE(0.5),
      .CLKOUT3_PHASE(0.0),
      
      .CLKOUT4_DIVIDE(8),
      .CLKOUT4_DUTY_CYCLE(0.5),
      .CLKOUT4_PHASE(0.0), 
      
      .CLKOUT5_DIVIDE(8),
      .CLKOUT5_DUTY_CYCLE(0.5),
      .CLKOUT5_PHASE(0.0),
      
      // Set the compensation
      .COMPENSATION("SYSTEM_SYNCHRONOUS"),
      
      // PMCD stuff (not used)
      .EN_REL("FALSE"),
      .PLL_PMCD_MODE("FALSE"),
      .RST_DEASSERT_CLK("CLKIN1")
   ) PLL_ADV_inst (
      .CLKFBDCM(),
      .CLKFBOUT(clkfb_bufgin),
      
      // CLK outputs
      .CLKOUT0(clk0_bufgin),
      .CLKOUT1(clk1_bufgin),
      .CLKOUT2(clk2_bufgin),
      .CLKOUT3(clk3_bufgin),
      .CLKOUT4(clk4_bufgin),
      .CLKOUT5(clk5_bufgin),
      
      // CLKOUTS to DCM
      .CLKOUTDCM0(),
      .CLKOUTDCM1(),
      .CLKOUTDCM2(), 
      .CLKOUTDCM3(),
      .CLKOUTDCM4(),
      .CLKOUTDCM5(), 
      
      // DRP Ports
      .DO(dout),
      .DRDY(drdy), 
      .DADDR(daddr), 
      .DCLK(dclk),
      .DEN(den),
      .DI(di),
      .DWE(dwe),
      
      .LOCKED(locked),
      .CLKFBIN(clkfb_bufgout),
      
      // Clock inputs
      .CLKIN1(CLKIN), 
      .CLKIN2(),
      .CLKINSEL(1'b1),
      
      .REL(1'b0),
      .RST(rst_pll)
   );
   
   // PLL_DRP instance that will perform the reconfiguration operations
   pll_drp #(
      //***********************************************************************
      // State 1 Parameters - These are for the first reconfiguration state.
      //***********************************************************************
      // Set the multiply to 4 with 0 deg phase offset, low bandwidth, input
      // divide of 1
      .S1_CLKFBOUT_MULT(8),
      .S1_CLKFBOUT_PHASE(0),
      .S1_BANDWIDTH("LOW"),
      .S1_DIVCLK_DIVIDE(1),
      
      // Set clock out 0 to a divide of 4, 0deg phase offset, 50/50 duty cycle
      .S1_CLKOUT0_DIVIDE(4),
      .S1_CLKOUT0_PHASE(0),
      .S1_CLKOUT0_DUTY(50000),
      
      // Set clock out 1 to a divide of 4, 90deg phase offset, 50/50 duty cycle
      .S1_CLKOUT1_DIVIDE(4),
      .S1_CLKOUT1_PHASE(45000),
      .S1_CLKOUT1_DUTY(50000),
      
      // Set clock out 2 to a divide of 4, 180deg phase offset, 50/50 duty cycle
      .S1_CLKOUT2_DIVIDE(4),
      .S1_CLKOUT2_PHASE(90000),
      .S1_CLKOUT2_DUTY(50000),
      
      // Set clock out 3 to a divide of 4, 270deg phase offset, 50/50 duty cycle
      .S1_CLKOUT3_DIVIDE(4),
      .S1_CLKOUT3_PHASE(135000),
      .S1_CLKOUT3_DUTY(50000),
      
      // Set clock out 4 to a divide of 5, 0deg phase offset, 50/50 duty cycle
      .S1_CLKOUT4_DIVIDE(4),
      .S1_CLKOUT4_PHASE(180000),
      .S1_CLKOUT4_DUTY(50000),
      
      // Set clock out 5 to a divide of 6, 0deg phase offset, 50/50 duty cycle
      .S1_CLKOUT5_DIVIDE(4),
      .S1_CLKOUT5_PHASE(0),
      .S1_CLKOUT5_DUTY(50000),
      
      //***********************************************************************
      // State 2 Parameters - These are for the second reconfiguration state.
      //***********************************************************************
      .S2_CLKFBOUT_MULT(8),
      .S2_CLKFBOUT_PHASE(0),
      .S2_BANDWIDTH("LOW"),
      .S2_DIVCLK_DIVIDE(1),

      // Set clock out 0 to a divide of 8, 0deg phase offset, 50/50 duty cycle
      .S2_CLKOUT0_DIVIDE(8),
      .S2_CLKOUT0_PHASE(0),
      .S2_CLKOUT0_DUTY(50000),
      
      // Set clock out 0 to a divide of 9, 0deg phase offset, 50/50 duty cycle
      .S2_CLKOUT1_DIVIDE(8),
      .S2_CLKOUT1_PHASE(90000),
      .S2_CLKOUT1_DUTY(50000),
      
      // Set clock out 0 to a divide of 10, 0deg phase offset, 50/50 duty cycle
      .S2_CLKOUT2_DIVIDE(8),
      .S2_CLKOUT2_PHASE(135000),
      .S2_CLKOUT2_DUTY(12500),
      
      // Set clock out 0 to a divide of 11, 0deg phase offset, 50/50 duty cycle
      .S2_CLKOUT3_DIVIDE(8),
      .S2_CLKOUT3_PHASE(180000),
      .S2_CLKOUT3_DUTY(25000),
      
      // Set clock out 0 to a divide of 12, 0deg phase offset, 50/50 duty cycle
      .S2_CLKOUT4_DIVIDE(8),
      .S2_CLKOUT4_PHASE(0),
      .S2_CLKOUT4_DUTY(75000),
      
      // Set clock out 0 to a divide of 13, 0deg phase offset, 50/50 duty cycle
      .S2_CLKOUT5_DIVIDE(8),
      .S2_CLKOUT5_PHASE(0),
      .S2_CLKOUT5_DUTY(93750)
	  
   ) PLL_DRP_inst (
      // Top port connections
      .SADDR(STATE),
      .SEN(SSTEP),
      .RST(RST),
      .SRDY(SRDY),
      
      // Input from IBUFG
      .SCLK(clkin_bufgout),
      
      // Direct connections to the PLL_ADV
      .DO(dout),
      .DRDY(drdy),
      .LOCKED(locked),
      .DWE(dwe),
      .DEN(den),
      .DADDR(daddr),
      .DI(di),
      .DCLK(dclk),
      .RST_PLL(rst_pll)
   );
endmodule
