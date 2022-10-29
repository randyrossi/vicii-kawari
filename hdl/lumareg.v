// This file is part of the vicii-kawari distribution
// (https://github.com/randyrossi/vicii-kawari)
// Copyright (c) 2022 Randy Rossi.
// 
// This program is free software: you can redistribute it and/or modify  
// it under the terms of the GNU General Public License as published by  
// the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful, but 
// WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License 
// along with this program. If not, see <http://www.gnu.org/licenses/>.

`timescale 1ns / 1ps

`include "common.vh"

// Ram to hold 6-bit luma, 8-bit phase and 4-bit amplitude values for
// 16 color registers.
module LUMA_REGS
       #(
           parameter addr_width = 4,
           data_width = 18
       )
       (
           input wire clk,
           input wire we_a,
           input wire [addr_width-1:0] addr_a,
           input wire [data_width-1:0] din_a,
           output reg [data_width-1:0] dout_a,
           input wire we_b,
           input wire [addr_width-1:0] addr_b,
           input wire [data_width-1:0] din_b,
           output reg [data_width-1:0] dout_b
       );

`ifdef WITH_64K
(* ram_style = "distributed" *) reg [data_width-1:0] ram_dual_port[2**addr_width-1:0];
`else
(* ram_style = "block" *) reg [data_width-1:0] ram_dual_port[2**addr_width-1:0];
`endif

`ifdef REV_3_BOARD
initial $readmemb ("luma_rev3.bin", ram_dual_port);
`else
initial $readmemb ("luma_rev4.bin", ram_dual_port);
`endif

always @(posedge clk)
begin
    if (we_a)
        ram_dual_port[addr_a] <= din_a;
    dout_a <= ram_dual_port[addr_a];
end

always @(posedge clk)
begin
    if (we_b)
        ram_dual_port[addr_b] <= din_b;
    dout_b <= ram_dual_port[addr_b];
end

endmodule
