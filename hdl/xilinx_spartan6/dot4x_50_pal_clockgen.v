`timescale 1ps/1ps

module dot4x_50_pal_clockgen
 (input         clk_in50mhz,
  output        clk_dot4x_pal,
  output        clk_dot4x_ntsc,
  output        clk_25mhz,
  input         reset,
  output        locked
 );


  // Clocking primitive
  //------------------------------------
  // Instantiation of the PLL primitive
  //    * Unused inputs are tied off
  //    * Unused outputs are labeled unused
  wire [15:0] do_unused;
  wire        drdy_unused;
  wire        clkfbout;
  wire        clkfbout_buf;
  wire        clkout0;
  wire        clkout1;
  wire        clkout2;
  wire        clkout3_unused;
  wire        clkout4_unused;
  wire        clkout5_unused;



  PLL_BASE
  #(.BANDWIDTH              ("OPTIMIZED"),
    .CLK_FEEDBACK           ("CLKFBOUT"),
    .COMPENSATION           ("SYSTEM_SYNCHRONOUS"),
    .DIVCLK_DIVIDE          (2),
    .CLKFBOUT_MULT          (29),
    .CLKFBOUT_PHASE         (0.000),
    .CLKOUT0_DIVIDE         (23),
    .CLKOUT0_PHASE          (0.000),
    .CLKOUT0_DUTY_CYCLE     (0.500),
    .CLKOUT1_DIVIDE         (22),
    .CLKOUT1_PHASE          (0.000),
    .CLKOUT1_DUTY_CYCLE     (0.500),
    .CLKOUT2_DIVIDE         (29),
    .CLKOUT2_PHASE          (0.000),
    .CLKOUT2_DUTY_CYCLE     (0.500),
    .CLKIN_PERIOD           (20.000),
    .REF_JITTER             (0.010))
  pll_base_inst
    // Output clocks
   (.CLKFBOUT              (clkfbout),
    .CLKOUT0               (clkout0),
    .CLKOUT1               (clkout1),
    .CLKOUT2               (clkout2),
    .CLKOUT3               (clkout3_unused),
    .CLKOUT4               (clkout4_unused),
    .CLKOUT5               (clkout5_unused),
    // Status and control signals
    .LOCKED                (locked),
    .RST                   (reset),
     // Input clock control
    .CLKFBIN               (clkfbout_buf),
    .CLKIN                 (clk_in50mhz));


  // Output buffering
  //-----------------------------------
  BUFG clkf_buf
   (.O (clkfbout_buf),
    .I (clkfbout));

  BUFG clkout1_buf
   (.O   (clk_dot4x_pal),
    .I   (clkout0));

  BUFG clkout2_buf
   (.O   (clk_dot4x_ntsc),
    .I   (clkout1));

  BUFG clkout3_buf
   (.O   (clk_25mhz),
    .I   (clkout2));

endmodule
