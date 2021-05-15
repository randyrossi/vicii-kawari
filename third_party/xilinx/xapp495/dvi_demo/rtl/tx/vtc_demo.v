//////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2009 Xilinx, Inc.
// This design is confidential and proprietary of Xilinx, All Rights Reserved.
//////////////////////////////////////////////////////////////////////////////
//   ____  ____
//  /   /\/   /
// /___/  \  /   Vendor:        Xilinx
// \   \   \/    Version:       1.0.0
//  \   \        Filename:      vtc_demo.v
//  /   /        Date Created:  April 8, 2009
// /___/   /\    Author:        Bob Feng   
// \   \  /  \
//  \___\/\___\
//
// Devices:   Spartan-6 Generation FPGA
// Purpose:   SP601 board demo top level
// Contact:   
// Reference: None
//
// Revision History:
// 
//
//////////////////////////////////////////////////////////////////////////////
//
// LIMITED WARRANTY AND DISCLAIMER. These designs are provided to you "as is".
// Xilinx and its licensors make and you receive no warranties or conditions,
// express, implied, statutory or otherwise, and Xilinx specifically disclaims
// any implied warranties of merchantability, non-infringement, or fitness for
// a particular purpose. Xilinx does not warrant that the functions contained
// in these designs will meet your requirements, or that the operation of
// these designs will be uninterrupted or error free, or that defects in the
// designs will be corrected. Furthermore, Xilinx does not warrant or make any
// representations regarding use or the results of the use of the designs in
// terms of correctness, accuracy, reliability, or otherwise.
//
// LIMITATION OF LIABILITY. In no event will Xilinx or its licensors be liable
// for any loss of data, lost profits, cost or procurement of substitute goods
// or services, or for any special, incidental, consequential, or indirect
// damages arising from the use or operation of the designs or accompanying
// documentation, however caused and on any theory of liability. This
// limitation will apply even if Xilinx has been advised of the possibility
// of such damage. This limitation shall apply not-withstanding the failure
// of the essential purpose of any limited remedies herein.
//
//////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2009 Xilinx, Inc.
// This design is confidential and proprietary of Xilinx, All Rights Reserved.
//////////////////////////////////////////////////////////////////////////////

`timescale 1 ps / 1 ps

module vtc_demo (
  input  wire RSTBTN,

  input  wire SYS_CLK,

  input  wire [3:0] SW,
  
  output wire [3:0] TMDS,
  output wire [3:0] TMDSB,
  output wire [3:0] LED,
  output wire [1:0] DEBUG
);

  //******************************************************************//
  // Create global clock and synchronous system reset.                //
  //******************************************************************//
  wire          locked;
  wire          reset;

  wire          clk50m, clk50m_bufg;

  wire          pwrup;

  IBUF sysclk_buf (.I(SYS_CLK), .O(sysclk));

  BUFIO2 #(.DIVIDE_BYPASS("FALSE"), .DIVIDE(2))
  sysclk_div (.DIVCLK(clk50m), .IOCLK(), .SERDESSTROBE(), .I(sysclk));

  BUFG clk50m_bufgbufg (.I(clk50m), .O(clk50m_bufg));

  wire pclk_lckd;

//`ifdef SIMULATION
//  assign pwrup = 1'b0;
//`else
  SRL16E #(.INIT(16'h1)) pwrup_0 (
    .Q(pwrup),
    .A0(1'b1),
    .A1(1'b1),
    .A2(1'b1),
    .A3(1'b1),
    .CE(pclk_lckd),
    .CLK(clk50m_bufg),
    .D(1'b0)
  );
//`endif

  //////////////////////////////////////
  /// Switching screen formats
  //////////////////////////////////////
  wire busy;
  wire  [3:0] sws_sync; //synchronous output

  synchro #(.INITIALIZE("LOGIC0"))
  synchro_sws_3 (.async(SW[3]),.sync(sws_sync[3]),.clk(clk50m_bufg));

  synchro #(.INITIALIZE("LOGIC0"))
  synchro_sws_2 (.async(SW[2]),.sync(sws_sync[2]),.clk(clk50m_bufg));

  synchro #(.INITIALIZE("LOGIC0"))
  synchro_sws_1 (.async(SW[1]),.sync(sws_sync[1]),.clk(clk50m_bufg));

  synchro #(.INITIALIZE("LOGIC0"))
  synchro_sws_0 (.async(SW[0]),.sync(sws_sync[0]),.clk(clk50m_bufg));

  reg [3:0] sws_sync_q;
  always @ (posedge clk50m_bufg)
  begin
    sws_sync_q <= sws_sync;
  end

  wire sw0_rdy, sw1_rdy, sw2_rdy, sw3_rdy;

  debnce debsw0 (
    .sync(sws_sync_q[0]),
    .debnced(sw0_rdy),
    .clk(clk50m_bufg));

  debnce debsw1 (
    .sync(sws_sync_q[1]),
    .debnced(sw1_rdy),
    .clk(clk50m_bufg));

  debnce debsw2 (
    .sync(sws_sync_q[2]),
    .debnced(sw2_rdy),
    .clk(clk50m_bufg));

  debnce debsw3 (
    .sync(sws_sync_q[3]),
    .debnced(sw3_rdy),
    .clk(clk50m_bufg));

  reg switch = 1'b0;
  always @ (posedge clk50m_bufg)
  begin
    switch <= pwrup | sw0_rdy | sw1_rdy | sw2_rdy | sw3_rdy;
  end

  wire gopclk;
  SRL16E SRL16E_0 (
    .Q(gopclk),
    .A0(1'b1),
    .A1(1'b1),
    .A2(1'b1),
    .A3(1'b1),
    .CE(1'b1),
    .CLK(clk50m_bufg),
    .D(switch)
  );
  // The following defparam declaration 
  defparam SRL16E_0.INIT = 16'h0;

  parameter SW_VGA       = 4'b0000;
  parameter SW_SVGA      = 4'b0001;
  parameter SW_XGA       = 4'b0011;
  parameter SW_HDTV720P  = 4'b0010;
  parameter SW_SXGA      = 4'b1000;

  reg [7:0] pclk_M, pclk_D;
  always @ (posedge clk50m_bufg)
  begin
    if(switch) begin
      case (sws_sync_q)
        SW_VGA: //25 MHz pixel clock
        begin
          pclk_M <= 8'd2 - 8'd1;
          pclk_D <= 8'd4 - 8'd1;
        end

        SW_SVGA: //40 MHz pixel clock
        begin
         pclk_M <= 8'd4 - 8'd1;
         pclk_D <= 8'd5 - 8'd1;
        end

        SW_XGA: //65 MHz pixel clock
        begin
          pclk_M <= 8'd13 - 8'd1;
          pclk_D <= 8'd10 - 8'd1;
        end

        SW_SXGA: //108 MHz pixel clock
        begin
          pclk_M <= 8'd54 - 8'd1;
          pclk_D <= 8'd25 - 8'd1;
        end

        default: //74.25 MHz pixel clock
        begin
          pclk_M <= 8'd37 - 8'd1;
          pclk_D <= 8'd25 - 8'd1;
        end
       endcase
    end
  end

  //
  // DCM_CLKGEN SPI controller
  //
  wire progdone, progen, progdata;
  dcmspi dcmspi_0 (
    .RST(switch),          //Synchronous Reset
    .PROGCLK(clk50m_bufg), //SPI clock
    .PROGDONE(progdone),   //DCM is ready to take next command
    .DFSLCKD(pclk_lckd),
    .M(pclk_M),            //DCM M value
    .D(pclk_D),            //DCM D value
    .GO(gopclk),           //Go programme the M and D value into DCM(1 cycle pulse)
    .BUSY(busy),
    .PROGEN(progen),       //SlaveSelect,
    .PROGDATA(progdata)    //CommandData
  );

  //
  // DCM_CLKGEN to generate a pixel clock with a variable frequency
  //
  wire          clkfx, pclk;
  DCM_CLKGEN #(
    .CLKFX_DIVIDE (21),
    .CLKFX_MULTIPLY (31),
    .CLKIN_PERIOD(20.000)
  )
  PCLK_GEN_INST (
    .CLKFX(clkfx),
    .CLKFX180(),
    .CLKFXDV(),
    .LOCKED(pclk_lckd),
    .PROGDONE(progdone),
    .STATUS(),
    .CLKIN(clk50m),
    .FREEZEDCM(1'b0),
    .PROGCLK(clk50m_bufg),
    .PROGDATA(progdata),
    .PROGEN(progen),
    .RST(1'b0)
  );


  wire pllclk0, pllclk1, pllclk2;
  wire pclkx2, pclkx10, pll_lckd;
  wire clkfbout;

  //
  // Pixel Rate clock buffer
  //
  BUFG pclkbufg (.I(pllclk1), .O(pclk));

  //////////////////////////////////////////////////////////////////
  // 2x pclk is going to be used to drive OSERDES2
  // on the GCLK side
  //////////////////////////////////////////////////////////////////
  BUFG pclkx2bufg (.I(pllclk2), .O(pclkx2));

  //////////////////////////////////////////////////////////////////
  // 10x pclk is used to drive IOCLK network so a bit rate reference
  // can be used by OSERDES2
  //////////////////////////////////////////////////////////////////
  PLL_BASE # (
    .CLKIN_PERIOD(13),
    .CLKFBOUT_MULT(10), //set VCO to 10x of CLKIN
    .CLKOUT0_DIVIDE(1),
    .CLKOUT1_DIVIDE(10),
    .CLKOUT2_DIVIDE(5),
    .COMPENSATION("INTERNAL")
  ) PLL_OSERDES (
    .CLKFBOUT(clkfbout),
    .CLKOUT0(pllclk0),
    .CLKOUT1(pllclk1),
    .CLKOUT2(pllclk2),
    .CLKOUT3(),
    .CLKOUT4(),
    .CLKOUT5(),
    .LOCKED(pll_lckd),
    .CLKFBIN(clkfbout),
    .CLKIN(clkfx),
    .RST(~pclk_lckd)
  );

  wire serdesstrobe;
  wire bufpll_lock;
  BUFPLL #(.DIVIDE(5)) ioclk_buf (.PLLIN(pllclk0), .GCLK(pclkx2), .LOCKED(pll_lckd),
           .IOCLK(pclkx10), .SERDESSTROBE(serdesstrobe), .LOCK(bufpll_lock));

  synchro #(.INITIALIZE("LOGIC1"))
  synchro_reset (.async(!pll_lckd),.sync(reset),.clk(pclk));

///////////////////////////////////////////////////////////////////////////
// Video Timing Parameters
///////////////////////////////////////////////////////////////////////////
  //1280x1024@60HZ
  parameter HPIXELS_SXGA = 11'd1280; //Horizontal Live Pixels
  parameter  VLINES_SXGA = 11'd1024;  //Vertical Live ines
  parameter HSYNCPW_SXGA = 11'd112;  //HSYNC Pulse Width
  parameter VSYNCPW_SXGA = 11'd3;    //VSYNC Pulse Width
  parameter HFNPRCH_SXGA = 11'd48;   //Horizontal Front Portch
  parameter VFNPRCH_SXGA = 11'd1;    //Vertical Front Portch
  parameter HBKPRCH_SXGA = 11'd248;  //Horizontal Front Portch
  parameter VBKPRCH_SXGA = 11'd38;   //Vertical Front Portch

  //1280x720@60HZ
  parameter HPIXELS_HDTV720P = 11'd1280; //Horizontal Live Pixels
  parameter VLINES_HDTV720P  = 11'd720;  //Vertical Live ines
  parameter HSYNCPW_HDTV720P = 11'd80;  //HSYNC Pulse Width
  parameter VSYNCPW_HDTV720P = 11'd5;    //VSYNC Pulse Width
  parameter HFNPRCH_HDTV720P = 11'd72;   //Horizontal Front Portch
  parameter VFNPRCH_HDTV720P = 11'd3;    //Vertical Front Portch
  parameter HBKPRCH_HDTV720P = 11'd216;  //Horizontal Front Portch
  parameter VBKPRCH_HDTV720P = 11'd22;   //Vertical Front Portch

  //1024x768@60HZ
  parameter HPIXELS_XGA = 11'd1024; //Horizontal Live Pixels
  parameter VLINES_XGA  = 11'd768;  //Vertical Live ines
  parameter HSYNCPW_XGA = 11'd136;  //HSYNC Pulse Width
  parameter VSYNCPW_XGA = 11'd6;    //VSYNC Pulse Width
  parameter HFNPRCH_XGA = 11'd24;   //Horizontal Front Portch
  parameter VFNPRCH_XGA = 11'd3;    //Vertical Front Portch
  parameter HBKPRCH_XGA = 11'd160;  //Horizontal Front Portch
  parameter VBKPRCH_XGA = 11'd29;   //Vertical Front Portch

  //800x600@60HZ
  parameter HPIXELS_SVGA = 11'd800; //Horizontal Live Pixels
  parameter VLINES_SVGA  = 11'd600; //Vertical Live ines
  parameter HSYNCPW_SVGA = 11'd128; //HSYNC Pulse Width
  parameter VSYNCPW_SVGA = 11'd4;   //VSYNC Pulse Width
  parameter HFNPRCH_SVGA = 11'd40;  //Horizontal Front Portch
  parameter VFNPRCH_SVGA = 11'd1;   //Vertical Front Portch
  parameter HBKPRCH_SVGA = 11'd88;  //Horizontal Front Portch
  parameter VBKPRCH_SVGA = 11'd23;  //Vertical Front Portch

  //640x480@60HZ
  parameter HPIXELS_VGA = 11'd640; //Horizontal Live Pixels
  parameter VLINES_VGA  = 11'd480; //Vertical Live ines
  parameter HSYNCPW_VGA = 11'd96;  //HSYNC Pulse Width
  parameter VSYNCPW_VGA = 11'd2;   //VSYNC Pulse Width
  parameter HFNPRCH_VGA = 11'd16;  //Horizontal Front Portch
  parameter VFNPRCH_VGA = 11'd11;  //Vertical Front Portch
  parameter HBKPRCH_VGA = 11'd48;  //Horizontal Front Portch
  parameter VBKPRCH_VGA = 11'd31;  //Vertical Front Portch

  reg [10:0] tc_hsblnk;
  reg [10:0] tc_hssync;
  reg [10:0] tc_hesync;
  reg [10:0] tc_heblnk;
  reg [10:0] tc_vsblnk;
  reg [10:0] tc_vssync;
  reg [10:0] tc_vesync;
  reg [10:0] tc_veblnk;

  wire  [3:0] sws_clk;      //clk synchronous output

  synchro #(.INITIALIZE("LOGIC0"))
  clk_sws_3 (.async(SW[3]),.sync(sws_clk[3]),.clk(pclk));
 
  synchro #(.INITIALIZE("LOGIC0"))
  clk_sws_2 (.async(SW[2]),.sync(sws_clk[2]),.clk(pclk));

  synchro #(.INITIALIZE("LOGIC0"))
  clk_sws_1 (.async(SW[1]),.sync(sws_clk[1]),.clk(pclk));
 
  synchro #(.INITIALIZE("LOGIC0"))
  clk_sws_0 (.async(SW[0]),.sync(sws_clk[0]),.clk(pclk));

  reg  [3:0] sws_clk_sync; //clk synchronous output
  always @ (posedge pclk)
  begin
    sws_clk_sync <= sws_clk;
  end

  reg hvsync_polarity; //1-Negative, 0-Positive
  always @ (*)
  begin
    case (sws_clk_sync)
      SW_VGA:
      begin
        hvsync_polarity = 1'b1;

        tc_hsblnk = HPIXELS_VGA - 11'd1;
        tc_hssync = HPIXELS_VGA - 11'd1 + HFNPRCH_VGA;
        tc_hesync = HPIXELS_VGA - 11'd1 + HFNPRCH_VGA + HSYNCPW_VGA;
        tc_heblnk = HPIXELS_VGA - 11'd1 + HFNPRCH_VGA + HSYNCPW_VGA + HBKPRCH_VGA;
        tc_vsblnk =  VLINES_VGA - 11'd1;
        tc_vssync =  VLINES_VGA - 11'd1 + VFNPRCH_VGA;
        tc_vesync =  VLINES_VGA - 11'd1 + VFNPRCH_VGA + VSYNCPW_VGA;
        tc_veblnk =  VLINES_VGA - 11'd1 + VFNPRCH_VGA + VSYNCPW_VGA + VBKPRCH_VGA;
      end

      SW_SVGA:
      begin
        hvsync_polarity = 1'b0;

        tc_hsblnk = HPIXELS_SVGA - 11'd1;
        tc_hssync = HPIXELS_SVGA - 11'd1 + HFNPRCH_SVGA;
        tc_hesync = HPIXELS_SVGA - 11'd1 + HFNPRCH_SVGA + HSYNCPW_SVGA;
        tc_heblnk = HPIXELS_SVGA - 11'd1 + HFNPRCH_SVGA + HSYNCPW_SVGA + HBKPRCH_SVGA;
        tc_vsblnk =  VLINES_SVGA - 11'd1;
        tc_vssync =  VLINES_SVGA - 11'd1 + VFNPRCH_SVGA;
        tc_vesync =  VLINES_SVGA - 11'd1 + VFNPRCH_SVGA + VSYNCPW_SVGA;
        tc_veblnk =  VLINES_SVGA - 11'd1 + VFNPRCH_SVGA + VSYNCPW_SVGA + VBKPRCH_SVGA;
      end

      SW_XGA:
      begin
        hvsync_polarity = 1'b1;

        tc_hsblnk = HPIXELS_XGA - 11'd1;
        tc_hssync = HPIXELS_XGA - 11'd1 + HFNPRCH_XGA;
        tc_hesync = HPIXELS_XGA - 11'd1 + HFNPRCH_XGA + HSYNCPW_XGA;
        tc_heblnk = HPIXELS_XGA - 11'd1 + HFNPRCH_XGA + HSYNCPW_XGA + HBKPRCH_XGA;
        tc_vsblnk =  VLINES_XGA - 11'd1;
        tc_vssync =  VLINES_XGA - 11'd1 + VFNPRCH_XGA;
        tc_vesync =  VLINES_XGA - 11'd1 + VFNPRCH_XGA + VSYNCPW_XGA;
        tc_veblnk =  VLINES_XGA - 11'd1 + VFNPRCH_XGA + VSYNCPW_XGA + VBKPRCH_XGA;
      end

      SW_SXGA:
      begin
        hvsync_polarity = 1'b0; // positive polarity

        tc_hsblnk = HPIXELS_SXGA - 11'd1;
        tc_hssync = HPIXELS_SXGA - 11'd1 + HFNPRCH_SXGA;
        tc_hesync = HPIXELS_SXGA - 11'd1 + HFNPRCH_SXGA + HSYNCPW_SXGA;
        tc_heblnk = HPIXELS_SXGA - 11'd1 + HFNPRCH_SXGA + HSYNCPW_SXGA + HBKPRCH_SXGA;
        tc_vsblnk =  VLINES_SXGA - 11'd1;
        tc_vssync =  VLINES_SXGA - 11'd1 + VFNPRCH_SXGA;
        tc_vesync =  VLINES_SXGA - 11'd1 + VFNPRCH_SXGA + VSYNCPW_SXGA;
        tc_veblnk =  VLINES_SXGA - 11'd1 + VFNPRCH_SXGA + VSYNCPW_SXGA + VBKPRCH_SXGA;
      end

      default: //SW_HDTV720P:
      begin
        hvsync_polarity = 1'b0;

        tc_hsblnk = HPIXELS_HDTV720P - 11'd1;
        tc_hssync = HPIXELS_HDTV720P - 11'd1 + HFNPRCH_HDTV720P;
        tc_hesync = HPIXELS_HDTV720P - 11'd1 + HFNPRCH_HDTV720P + HSYNCPW_HDTV720P;
        tc_heblnk = HPIXELS_HDTV720P - 11'd1 + HFNPRCH_HDTV720P + HSYNCPW_HDTV720P + HBKPRCH_HDTV720P;
        tc_vsblnk =  VLINES_HDTV720P - 11'd1;
        tc_vssync =  VLINES_HDTV720P - 11'd1 + VFNPRCH_HDTV720P;
        tc_vesync =  VLINES_HDTV720P - 11'd1 + VFNPRCH_HDTV720P + VSYNCPW_HDTV720P;
        tc_veblnk =  VLINES_HDTV720P - 11'd1 + VFNPRCH_HDTV720P + VSYNCPW_HDTV720P + VBKPRCH_HDTV720P;
      end
    endcase
  end

  wire VGA_HSYNC_INT, VGA_VSYNC_INT;
  wire   [10:0] bgnd_hcount;
  wire          bgnd_hsync;
  wire          bgnd_hblnk;
  wire   [10:0] bgnd_vcount;
  wire          bgnd_vsync;
  wire          bgnd_vblnk;

  timing timing_inst (
    .tc_hsblnk(tc_hsblnk), //input
    .tc_hssync(tc_hssync), //input
    .tc_hesync(tc_hesync), //input
    .tc_heblnk(tc_heblnk), //input
    .hcount(bgnd_hcount), //output
    .hsync(VGA_HSYNC_INT), //output
    .hblnk(bgnd_hblnk), //output
    .tc_vsblnk(tc_vsblnk), //input
    .tc_vssync(tc_vssync), //input
    .tc_vesync(tc_vesync), //input
    .tc_veblnk(tc_veblnk), //input
    .vcount(bgnd_vcount), //output
    .vsync(VGA_VSYNC_INT), //output
    .vblnk(bgnd_vblnk), //output
    .restart(reset),
    .clk(pclk));

  /////////////////////////////////////////
  // V/H SYNC and DE generator
  /////////////////////////////////////////
  assign active = !bgnd_hblnk && !bgnd_vblnk;

  reg active_q;
  reg vsync, hsync;
  reg VGA_HSYNC, VGA_VSYNC;
  reg de;

  always @ (posedge pclk)
  begin
    hsync <= VGA_HSYNC_INT ^ hvsync_polarity ;
    vsync <= VGA_VSYNC_INT ^ hvsync_polarity ;
    VGA_HSYNC <= hsync;
    VGA_VSYNC <= vsync;

    active_q <= active;
    de <= active_q;
  end

  ///////////////////////////////////
  // Video pattern generator:
  //   SMPTE HD Color Bar
  ///////////////////////////////////
  wire [7:0] red_data, green_data, blue_data;

`ifdef SIMULATION
  reg [23:0] pixel_buffer [1279:0];
  reg [23:0] active_pixel;
  integer i;
  initial begin
    for (i = 0; i < 1280; i = i + 1) begin
      pixel_buffer[i] = $random(dvi_tb.rx0_seed);
    end

    i = 0;
  end

  always @ (posedge pclk) begin
    if(active_q) begin
      active_pixel = pixel_buffer[i];
      i = i + 1;
    end else begin
      i = 0;
      active_pixel = 24'hx;
    end
  end

  assign {red_data, green_data, blue_data} = active_pixel;
`else
  hdcolorbar clrbar(
    .i_clk_74M(pclk),
    .i_rst(reset),
    .i_hcnt(bgnd_hcount),
    .i_vcnt(bgnd_vcount),
    .baronly(1'b0),
    .i_format(2'b00),
    .o_r(red_data),
    .o_g(green_data),
    .o_b(blue_data)
  );
`endif
  ////////////////////////////////////////////////////////////////
  // DVI Encoder
  ////////////////////////////////////////////////////////////////
  wire [4:0] tmds_data0, tmds_data1, tmds_data2;

  dvi_encoder enc0 (
    .clkin      (pclk),
    .clkx2in    (pclkx2),
    .rstin      (reset),
    .blue_din   (blue_data),
    .green_din  (green_data),
    .red_din    (red_data),
    .hsync      (VGA_HSYNC),
    .vsync      (VGA_VSYNC),
    .de         (de),
    .tmds_data0 (tmds_data0),
    .tmds_data1 (tmds_data1),
    .tmds_data2 (tmds_data2));


  wire [2:0] tmdsint;

  wire serdes_rst = RSTBTN | ~bufpll_lock;

//`define DEBUG

`ifdef DEBUG

  wire [4:0] pattern = 5'b00011;

  serdes_n_to_1 #(.SF(5)) oserdes0 (
             .ioclk(pclkx10),
             .serdesstrobe(serdesstrobe),
             .reset(serdes_rst),
             .gclk(pclkx2),
             .datain(pattern),
             .iob_data_out(tmdsint[0])) ;

  serdes_n_to_1 #(.SF(5)) oserdes1 (
             .ioclk(pclkx10),
             .serdesstrobe(serdesstrobe),
             .reset(serdes_rst),
             .gclk(pclkx2),
             .datain(pattern),
             .iob_data_out(tmdsint[1])) ;

  serdes_n_to_1 #(.SF(5)) oserdes2 (
             .ioclk(pclkx10),
             .serdesstrobe(serdesstrobe),
             .reset(serdes_rst),
             .gclk(pclkx2),
             .datain(pattern),
             .iob_data_out(tmdsint[2])) ;

  OBUFDS TMDS0 (.I(tmdsint[0]), .O(TMDS[0]), .OB(TMDSB[0])) ;
  OBUFDS TMDS1 (.I(tmdsint[1]), .O(TMDS[1]), .OB(TMDSB[1])) ;
  OBUFDS TMDS2 (.I(tmdsint[2]), .O(TMDS[2]), .OB(TMDSB[2])) ;
  
`else                             
  serdes_n_to_1 #(.SF(5)) oserdes0 (
             .ioclk(pclkx10),
             .serdesstrobe(serdesstrobe),
             .reset(serdes_rst),
             .gclk(pclkx2),
             .datain(tmds_data0),
             .iob_data_out(tmdsint[0])) ;

  serdes_n_to_1 #(.SF(5)) oserdes1 (
             .ioclk(pclkx10),
             .serdesstrobe(serdesstrobe),
             .reset(serdes_rst),
             .gclk(pclkx2),
             .datain(tmds_data1),
             .iob_data_out(tmdsint[1])) ;

  serdes_n_to_1 #(.SF(5)) oserdes2 (
             .ioclk(pclkx10),
             .serdesstrobe(serdesstrobe),
             .reset(serdes_rst),
             .gclk(pclkx2),
             .datain(tmds_data2),
             .iob_data_out(tmdsint[2])) ;

  OBUFDS TMDS0 (.I(tmdsint[0]), .O(TMDS[0]), .OB(TMDSB[0])) ;
  OBUFDS TMDS1 (.I(tmdsint[1]), .O(TMDS[1]), .OB(TMDSB[1])) ;
  OBUFDS TMDS2 (.I(tmdsint[2]), .O(TMDS[2]), .OB(TMDSB[2])) ;
`endif

  reg [4:0] tmdsclkint = 5'b00000;
  reg toggle = 1'b0;

  always @ (posedge pclkx2 or posedge serdes_rst) begin
    if (serdes_rst)
      toggle <= 1'b0;
    else
      toggle <= ~toggle;
  end

  always @ (posedge pclkx2) begin
    if (toggle)
      tmdsclkint <= 5'b11111;
    else
      tmdsclkint <= 5'b00000;
  end

  wire tmdsclk;

  serdes_n_to_1 #(
    .SF           (5))
  clkout (
    .iob_data_out (tmdsclk),
    .ioclk        (pclkx10),
    .serdesstrobe (serdesstrobe),
    .gclk         (pclkx2),
    .reset        (serdes_rst),
    .datain       (tmdsclkint));

  OBUFDS TMDS3 (.I(tmdsclk), .O(TMDS[3]), .OB(TMDSB[3])) ;// clock

  //
  // Debug Ports
  //

 assign DEBUG[0] = VGA_HSYNC;
 assign DEBUG[1] = VGA_VSYNC;

 // LEDs
 assign LED = {bufpll_lock, RSTBTN, VGA_HSYNC, VGA_VSYNC} ;
endmodule
