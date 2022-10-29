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

// --- BEGIN EXTENSIONS ----
module VIDEO_RAM
       #(
           parameter addr_width = `VIDEO_RAM_WIDTH,
           data_width = 8
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

(* ram_style = "block" *) reg [data_width-1:0] ram_dual_port[2**addr_width-1:0];

`ifdef SIMULATOR_BOARD
`ifdef HIRES_TEXT
initial $readmemh ("hires000.hex", ram_dual_port);
`endif
`ifdef HIRES_BITMAP1
initial $readmemh ("hires001.hex", ram_dual_port);
`endif
`ifdef HIRES_BITMAP2
initial $readmemh ("hires010.hex", ram_dual_port);
`endif
`ifdef HIRES_BITMAP3
initial $readmemh ("hires011.hex", ram_dual_port);
`endif
`ifdef HIRES_BITMAP4
initial $readmemh ("hires100.hex", ram_dual_port);
`endif
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
// --- END EXTENSIONS ----
