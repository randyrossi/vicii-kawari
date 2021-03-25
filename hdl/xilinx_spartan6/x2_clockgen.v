`timescale 1ps/1ps

module x2_clockgen
 (// Clock in ports
  input         clk_in,
  // Clock out ports
  output        clk_out_x2,
  output        clk_out_x4,
  // Status and control signals
  input         reset
 );



  // Clocking primitive
  //------------------------------------

  // Instantiation of the DCM primitive
  //    * Unused inputs are tied off
  //    * Unused outputs are labeled unused
  wire        psdone_unused;
  wire [7:0]  status_int;
  wire clkfb;
  wire clkfx;

  DCM_SP
  #(.CLKDV_DIVIDE          (2.000),
    .CLKFX_DIVIDE          (1),
    .CLKFX_MULTIPLY        (4),
    .CLKIN_DIVIDE_BY_2     ("FALSE"),
    .CLKIN_PERIOD          (56.387), // pal 4x color clock
    .CLKOUT_PHASE_SHIFT    ("NONE"),
    .CLK_FEEDBACK          ("2X"),
    .DESKEW_ADJUST         ("SYSTEM_SYNCHRONOUS"),
    .PHASE_SHIFT           (0),
    .STARTUP_WAIT          ("FALSE"))
  dcm_sp_inst
    // Input clock
   (.CLKIN                 (clk_in),
    .CLKFB                 (clkfb),
    // Output clocks
    .CLK0                  (),
    .CLK90                 (),
    .CLK180                (),
    .CLK270                (),
    .CLK2X                 (clk_out_x2),  // CLKIN x 2
    .CLK2X180              (),
    .CLKFX                 (clkfx), // CLKIN x 4
    .CLKFX180              (),
    .CLKDV                 (),
    // Ports for dynamic phase shift
    .PSCLK                 (1'b0),
    .PSEN                  (1'b0),
    .PSINCDEC              (1'b0),
    .PSDONE                (),
    // Other control and status signals
    .STATUS                (status_int),
 
    .RST                   (reset),
    // Unused pin- tie low
    .DSSEN                 (1'b0));

  // Output buffering
  //-----------------------------------
  BUFG clkf_buf
   (.O (clkfb),
    .I (clk_out_x2));

  BUFG clkf_buf2
   (.O (clk_out_x4),
    .I (clkfx));

  // This is headed for a PLL so no BUFG.
  //BUFG clkout1_buf
  // (.O   (clk_in_x2),
  //  .I   (clk_out_x2));

endmodule
