//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
//Date        : Sat Apr 18 13:39:21 2020
//Host        : DESKTOP-GESG3JV running 64-bit major release  (build 9200)
//Command     : generate_target clock2gen_wrapper.bd
//Design      : clock2gen_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module clock2gen_wrapper
   (clk_col4x,
    reset,
    sys_clock);
  output clk_col4x;
  input reset;
  input sys_clock;

  wire clk_col4x;
  wire reset;
  wire sys_clock;

  clock2gen clock2gen_i
       (.clk_col4x(clk_col4x),
        .reset(reset),
        .sys_clock(sys_clock));
endmodule
