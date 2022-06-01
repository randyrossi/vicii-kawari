`timescale 1ns / 1ps

`include "common.vh"

// Ram to hold 18-bit RGB values for 16 color registers.
// Even though we only need 16 bits for RGB, we use 24 bit wide
// entries because that makes mapping our register space to mem
// address simple.  The least significant bits (0-5) are unused.
module COLOR_REGS
       #(
           parameter addr_width = 4,
           data_width = 24
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

`ifndef SIMULATOR_BOARD
  initial $readmemb ("colors.bin", ram_dual_port);
`else
  `ifdef HIRES_BITMAP3
    initial $readmemb ("640colors.bin", ram_dual_port);
  `else
    `ifdef HIRES_BITMAP2
      initial $readmemb ("320colors.bin", ram_dual_port);
    `else
      `ifdef HIRES_BITMAP4
        initial $readmemb ("160colors.bin", ram_dual_port);
      `else
        initial $readmemb ("colors.bin", ram_dual_port);
      `endif
    `endif
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
