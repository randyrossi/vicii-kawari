//Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
//--------------------------------------------------------------------------------
//Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
//Date        : Mon Apr 20 15:08:37 2020
//Host        : DESKTOP-GESG3JV running 64-bit major release  (build 9200)
//Command     : generate_target clockgen_wrapper.bd
//Design      : clockgen_wrapper
//Purpose     : IP block netlist
//--------------------------------------------------------------------------------
`timescale 1 ps / 1 ps

module clockgen_wrapper
   (clk_dot4x,
    reset,
    sys_clock);
  output clk_dot4x;
  input reset;
  input sys_clock;

  wire clk_dot4x;
  wire reset;
  wire sys_clock;

  clockgen clockgen_i
       (.clk_dot4x(clk_dot4x),
        .reset(reset),
        .sys_clock(sys_clock));
endmodule
