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

// ROM to hold sine wave tables.
// There are 7 sine waves of decreasing amplitude in sine.bin
// Each sine wave is 256 entries in length.
// The sine waves are 9 bits centered at 256.
module SINE_WAVES
       #(
           parameter addr_width = 12,
           data_width = 9
       )
       (
           input wire clk,
           input wire [addr_width-1:0] addr,
           output reg [data_width-1:0] dout
       );

`ifdef WITH_64K
(* ram_style = "distributed" *) reg [data_width-1:0] sine_rom[2**addr_width-1:0];
`else
(* ram_style = "block" *) reg [data_width-1:0] sine_rom[2**addr_width-1:0];
`endif

initial $readmemb ("sine.bin", sine_rom);

always @(posedge clk)
begin
    dout <= sine_rom[addr];
end

endmodule
