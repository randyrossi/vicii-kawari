`timescale 1ps/1ps

module dot4x_50_clockgen 
   (
      // Pulse for one cycle to reconfigure the PLL
      input    SSTEP,
      input    STATE,  // 0= NTSC, 1=PAL
      input    RST,
      input    CLKIN,
      output   SRDY,
      output   CLK0OUT,
		output   LOCKED
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
	
   // These signals are used for the BUFG's necessary for the design.
   wire           clkin_bufgout;
   
   wire           clkfb_bufgout;
   wire           clkfb_bufgin;
   
   wire           clk0_bufgin;

   // This primitive causes a routing issue due to the DCLK input
	// into the PLL_ADV.  It seems to not be placed optimlally for
	// the clock pin being used in the MojoV3.  This is the reason
	// for the CLOCK_DEDICATED_ROUTE = FALSE in top.ucf for the
   // sys_clock net.  This seems to have no impact to the operation
   // of the design but it's something that should be fixed for the
   // real board.	
   // If this needs to be loc'd, use this: (* LOC = "BUFGMUX_X3Y6" *)
   BUFG BUFG_CLKIN (
     .O(clkin_bufgout),
     .I(CLKIN) 
   );
  
   BUFG BUFG_FB (
      .O(clkfb_bufgout),
      .I(clkfb_bufgin) 
   );
   
   BUFG BUFG_CLK0 (
      .O(CLK0OUT),
      .I(clk0_bufgin) 
   );
  
   // Default config is for PAL timing
	// 50 / 2 * 29 / 23 = 31.521739 = dot 4x
	// 31.521739 /32 = .985054 (actual) 
	// 31.527955 /32 = .985248 (desired)
	//                 .000194 (difference)
	//
	// Second config is for NTSC timing
	// 50 * 19 / 29 = 32.758620 = dot4x
	// 32.758620 /32 = 1.023706 (actual)
	// 32.727272 /32 = 1.022727 (desired)
	//                  .000979 (difference)
   PLL_ADV #(
	  .SIM_DEVICE("SPARTAN6"),
      .DIVCLK_DIVIDE(2), // 1 to 52
      
      .BANDWIDTH("LOW"), // "HIGH", "LOW" or "OPTIMIZED"
      
      // CLKFBOUT stuff
      .CLKFBOUT_MULT(29), 
      .CLKFBOUT_PHASE(0.0),
      
      // Set the clock period (ns) of input clocks and reference jitter
      .REF_JITTER(0.100),
      .CLKIN1_PERIOD(20.000),
      //.CLKIN2_PERIOD(20.000), 

      // CLKOUT parameters:
      // DIVIDE: (1 to 128)
      // DUTY_CYCLE: (0.01 to 0.99) - This is dependent on the divide value.
      // PHASE: (0.0 to 360.0) - This is dependent on the divide value.
      .CLKOUT0_DIVIDE(23),
      .CLKOUT0_DUTY_CYCLE(0.5),
      .CLKOUT0_PHASE(0.0), 

      //.CLKOUT1_DIVIDE(23),
      //.CLKOUT1_DUTY_CYCLE(0.5),
      //.CLKOUT1_PHASE(0.0), 
      
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
      .CLKOUT1(clk1_unused),
      .CLKOUT2(clk2_unused),
      .CLKOUT3(clk3_unused),
      .CLKOUT4(clk4_unused),
      .CLKOUT5(clk5_unused),
      
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
      
      .LOCKED(LOCKED),
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
      .S1_CLKFBOUT_MULT(19),
      .S1_CLKFBOUT_PHASE(0),
      .S1_BANDWIDTH("LOW"),
      .S1_DIVCLK_DIVIDE(1),
      .S1_CLKOUT0_DIVIDE(29),
      .S1_CLKOUT0_PHASE(0),
      .S1_CLKOUT0_DUTY(50000),
      
      //***********************************************************************
      // State 2 Parameters - These are for the second reconfiguration state.
      //***********************************************************************
      .S2_CLKFBOUT_MULT(29),
      .S2_CLKFBOUT_PHASE(0),
      .S2_BANDWIDTH("LOW"),
      .S2_DIVCLK_DIVIDE(2),
      .S2_CLKOUT0_DIVIDE(23),
      .S2_CLKOUT0_PHASE(0),
      .S2_CLKOUT0_DUTY(50000)
	  
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
      .LOCKED(LOCKED),
      .DWE(dwe),
      .DEN(den),
      .DADDR(daddr),
      .DI(di),
      .DCLK(dclk),
      .RST_PLL(rst_pll)
   );
endmodule

`ifdef WITH_DVI
module dvi_clockgen (
      input    clkin,
		output   tx0_pclkx10,
		output   tx0_pclkx2,
		output   tx0_serdesstrobe
		);
			
  wire tx0_clkfbout, tx0_clkfbin, tx0_plllckd;
  wire tx0_pllclk0, tx0_pllclk2;

  PLL_BASE # (
    // CLKIN_PERIOD is used for timing analysis. This is the value for PAL but
	 // should be okay for NTSC too.  The tool complains this value does not
	 // match the period constraint! (NgdBuild:1440) WHY???
    .CLKIN_PERIOD(31.724138),
    .CLKFBOUT_MULT(20),   // 10x CLKIN
    .CLKOUT0_DIVIDE(2),   // 10x
    .CLKOUT1_DIVIDE(20),  // 1x
    .CLKOUT2_DIVIDE(10),  // 2x
    .COMPENSATION("SOURCE_SYNCHRONOUS")
  ) PLL_OSERDES_0 (
    .CLKFBOUT(tx0_clkfbout),
    .CLKOUT0(tx0_pllclk0),
    .CLKOUT1(),
    .CLKOUT2(tx0_pllclk2),
    .CLKOUT3(),
    .CLKOUT4(),
    .CLKOUT5(),
    .LOCKED(tx0_plllckd),
    .CLKFBIN(tx0_clkfbin),
    .CLKIN(clkin),     // Pixel clock
    .RST(tx0_pll_reset)
  );

  BUFG tx0_clkfb_buf (.I(tx0_clkfbout), .O(tx0_clkfbin));
  BUFG tx0_pclkx2_buf (.I(tx0_pllclk2), .O(tx0_pclkx2));

  wire tx0_bufpll_lock;
  BUFPLL #(.DIVIDE(5)) tx0_ioclk_buf (.PLLIN(tx0_pllclk0), .GCLK(tx0_pclkx2), .LOCKED(tx0_plllckd),
         .IOCLK(tx0_pclkx10), .SERDESSTROBE(tx0_serdesstrobe), .LOCK(tx0_bufpll_lock));

endmodule`endif