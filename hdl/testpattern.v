`timescale 1ns / 1ps

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

(* ram_style = "block" *) reg [data_width-1:0] pattern[2**addr_width-1:0];

initial $readmemb ("testpattern.bin", pattern);

always @(posedge clk)
begin
    dout <= pattern[addr];
end

endmodule
