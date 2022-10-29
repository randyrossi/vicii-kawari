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

`ifdef TEST_PATTERN

`include "common.vh"

// ROM for a test pattern.
module TEST_PATTERN
       #(
           parameter addr_width = 14,
           data_width = 4
       )
       (
           input wire clk,
           input wire [addr_width-1:0] addr,
           output reg [data_width-1:0] dout
       );

`ifdef WITH_64K
(* ram_style = "distributed" *) reg [data_width-1:0] pattern[2**addr_width-1:0];
`else
(* ram_style = "block" *) reg [data_width-1:0] pattern[2**addr_width-1:0];
`endif

initial $readmemb ("testpattern.bin", pattern);

always @(posedge clk)
begin
    dout <= pattern[addr];
end

endmodule

`endif
