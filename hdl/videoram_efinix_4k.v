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
           parameter addr_width = 12,
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
           we_a,
           addr_a,
           din_a,
           dout_a0,
           we_b,
           addr_b,
           din_b,
           dout_b0
        );

assign dout_a = dout_a0;

endmodule
