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

// The Efinity synthesis tool seems to have a bug that prevents us
// from declaring an address width any greater than 13 (8K). It fails
// to synthesize with a cryptic error:
// [EFX-0680 ERROR] Dual Ported Memory 'ram__D$b3b0g1' has incompatible
// Read-Enable signal 'vcc'
// We need 64K of video ram, so to get around this, we will multiplex 8
// 8K banks using the upper 3 bits of the address.  (NOTE: When 32K is
// configured, only 4 banks are needed).
//
// The design files should replace videoram.v with videoram_efinix.v
module VIDEO_RAM_EF
       #(
           parameter addr_width = 13,
           parameter data_width = 8,
           parameter init_file = ""
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

reg [data_width-1:0] ram_dual_port[2**addr_width-1:0];

initial
begin
   if (init_file != "")
   begin
      $readmemh(init_file, ram_dual_port);
   end
end

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

module VIDEO_RAM
       #(
           parameter addr_width = `VIDEO_RAM_WIDTH,
           parameter data_width = 8
       )
       (
           input wire clk,
           input wire we_a,
           input wire [addr_width-1:0] addr_a,
           input wire [data_width-1:0] din_a,
           output [data_width-1:0] dout_a,
           input wire we_b,
           input wire [addr_width-1:0] addr_b,
           input wire [data_width-1:0] din_b,
           output [data_width-1:0] dout_b
       );

wire [data_width-1:0] dout_a0;
wire [data_width-1:0] dout_b0;
VIDEO_RAM_EF #(.init_file("")) video_ram_0 (
           clk,
           addr_a[`VIDEO_RAM_MUX] == 0 ? we_a : 0,
           addr_a,
           din_a,
           dout_a0,
           addr_b[`VIDEO_RAM_MUX] == 0 ? we_b : 0,
           addr_b,
           din_b,
           dout_b0
        );
wire [data_width-1:0] dout_a1;
wire [data_width-1:0] dout_b1;
VIDEO_RAM_EF #(.init_file("")) video_ram_1 (
           clk,
           addr_a[`VIDEO_RAM_MUX] == 1 ? we_a : 0,
           addr_a,
           din_a,
           dout_a1,
           addr_b[`VIDEO_RAM_MUX] == 1 ? we_b : 0,
           addr_b,
           din_b,
           dout_b1
        );

wire [data_width-1:0] dout_a2;
wire [data_width-1:0] dout_b2;
VIDEO_RAM_EF #(.init_file("")) video_ram_2 (
           clk,
           addr_a[`VIDEO_RAM_MUX] == 2 ? we_a : 0,
           addr_a,
           din_a,
           dout_a2,
           addr_b[`VIDEO_RAM_MUX] == 2 ? we_b : 0,
           addr_b,
           din_b,
           dout_b2
        );

wire [data_width-1:0] dout_a3;
wire [data_width-1:0] dout_b3;
VIDEO_RAM_EF #(.init_file("")) video_ram_3 (
           clk,
           addr_a[`VIDEO_RAM_MUX] == 3 ? we_a : 0,
           addr_a,
           din_a,
           dout_a3,
           addr_b[`VIDEO_RAM_MUX] == 3 ? we_b : 0,
           addr_b,
           din_b,
           dout_b3
        );

`ifdef WITH_64K

wire [data_width-1:0] dout_a4;
wire [data_width-1:0] dout_b4;
VIDEO_RAM_EF #(.init_file("")) video_ram_4 (
           clk,
           addr_a[`VIDEO_RAM_MUX] == 4 ? we_a : 0,
           addr_a,
           din_a,
           dout_a4,
           addr_b[`VIDEO_RAM_MUX] == 4 ? we_b : 0,
           addr_b,
           din_b,
           dout_b4
        );

wire [data_width-1:0] dout_a5;
wire [data_width-1:0] dout_b5;
VIDEO_RAM_EF #(.init_file("")) video_ram_5 (
           clk,
           addr_a[`VIDEO_RAM_MUX] == 5 ? we_a : 0,
           addr_a,
           din_a,
           dout_a5,
           addr_b[`VIDEO_RAM_MUX] == 5 ? we_b : 0,
           addr_b,
           din_b,
           dout_b5
        );

wire [data_width-1:0] dout_a6;
wire [data_width-1:0] dout_b6;
VIDEO_RAM_EF #(.init_file("")) video_ram_6 (
           clk,
           addr_a[`VIDEO_RAM_MUX] == 6 ? we_a : 0,
           addr_a,
           din_a,
           dout_a6,
           addr_b[`VIDEO_RAM_MUX] == 6 ? we_b : 0,
           addr_b,
           din_b,
           dout_b6
        );
wire [data_width-1:0] dout_a7;
wire [data_width-1:0] dout_b7;
VIDEO_RAM_EF #(.init_file("")) video_ram_7 (
           clk,
           addr_a[`VIDEO_RAM_MUX] == 7 ? we_a : 0,
           addr_a,
           din_a,
           dout_a7,
           addr_b[`VIDEO_RAM_MUX] == 7 ? we_b : 0,
           addr_b,
           din_b,
           dout_b7
        );
`endif

`ifdef WITH_64K
assign dout_a =
    (addr_a[`VIDEO_RAM_MUX] == 3'd0 ? dout_a0 :
      (addr_a[`VIDEO_RAM_MUX] == 3'd1 ? dout_a1 :
        (addr_a[`VIDEO_RAM_MUX] == 3'd2 ? dout_a2 :
          (addr_a[`VIDEO_RAM_MUX] == 3'd3 ? dout_a3 :
            (addr_a[`VIDEO_RAM_MUX] == 3'd4 ? dout_a4 :
              (addr_a[`VIDEO_RAM_MUX] == 3'd5 ? dout_a5 :
                (addr_a[`VIDEO_RAM_MUX] == 3'd6 ? dout_a6 : dout_a7)
              )
            )
          )
        )
      )
    );

assign dout_b =
    (addr_b[`VIDEO_RAM_MUX] == 3'd0 ? dout_b0 :
      (addr_b[`VIDEO_RAM_MUX] == 3'd1 ? dout_b1 :
        (addr_b[`VIDEO_RAM_MUX] == 3'd2 ? dout_b2 :
          (addr_b[`VIDEO_RAM_MUX] == 3'd3 ? dout_b3 :
            (addr_b[`VIDEO_RAM_MUX] == 3'd4 ? dout_b4 :
              (addr_b[`VIDEO_RAM_MUX] == 3'd5 ? dout_b5 :
                (addr_b[`VIDEO_RAM_MUX] == 3'd6 ? dout_b6 : dout_b7)
              )
            )
          )
        )
      )
    );
`else

assign dout_a =
    (addr_a[`VIDEO_RAM_MUX] == 2'd0 ? dout_a0 :
      (addr_a[`VIDEO_RAM_MUX] == 2'd1 ? dout_a1 :
        (addr_a[`VIDEO_RAM_MUX] == 2'd2 ? dout_a2 : dout_a3)
      )
    );

assign dout_b =
    (addr_b[`VIDEO_RAM_MUX] == 2'd0 ? dout_b0 :
      (addr_b[`VIDEO_RAM_MUX] == 2'd1 ? dout_b1 :
        (addr_b[`VIDEO_RAM_MUX] == 2'd2 ? dout_b2 : dout_b3)
      )
    );
`else
`endif
endmodule
