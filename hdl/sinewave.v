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

(* ram_style = "block" *) reg [data_width-1:0] sine_rom[2**addr_width-1:0];

initial $readmemb ("sine.bin", sine_rom);

always @(posedge clk)
begin
    dout <= sine_rom[addr];
end

endmodule
