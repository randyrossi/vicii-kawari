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

(* ram_style = "block" *) reg [data_width-1:0] ram_dual_port[2**addr_width-1:0];

initial $readmemb ("luma.bin", ram_dual_port);

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
