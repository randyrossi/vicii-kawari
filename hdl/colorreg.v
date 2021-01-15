`timescale 1ns / 1ps

`include "common.vh"

// Ram to hold 12-bit RGB values for 16 color registers and 2 palettes.
// Even though we only need 12 bits for RGB, we use 16 bit wide
// entries because that makes mapping our register space to mem
// address simple.
module COLOR_REGS
#(
    parameter addr_width = 5,
              data_width = 16
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

initial $readmemb ("colors.bin", ram_dual_port);

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
