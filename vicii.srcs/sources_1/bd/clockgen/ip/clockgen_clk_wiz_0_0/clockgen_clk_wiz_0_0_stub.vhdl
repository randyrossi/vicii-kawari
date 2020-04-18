-- Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2019.2 (win64) Build 2708876 Wed Nov  6 21:40:23 MST 2019
-- Date        : Sat Apr 18 18:23:49 2020
-- Host        : DESKTOP-GESG3JV running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               C:/shared/Vivado/vicii/vicii.srcs/sources_1/bd/clockgen/ip/clockgen_clk_wiz_0_0/clockgen_clk_wiz_0_0_stub.vhdl
-- Design      : clockgen_clk_wiz_0_0
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7a35tcpg236-1
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clockgen_clk_wiz_0_0 is
  Port ( 
    clk_out1 : out STD_LOGIC;
    reset : in STD_LOGIC;
    locked : out STD_LOGIC;
    clk_in1 : in STD_LOGIC
  );

end clockgen_clk_wiz_0_0;

architecture stub of clockgen_clk_wiz_0_0 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "clk_out1,reset,locked,clk_in1";
begin
end;
