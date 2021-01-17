`timescale 1ns / 1ps

`include "common.vh"

// --- BEGIN EXTENSIONS ----
// This is one 32k bank. Think about upping to 64k if we need it
// but then all our block ran would be exhausted.
module VIDEO_RAM
#(
    parameter addr_width = 15,
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

`ifdef IS_SIMULATOR
initial $readmemh ("mem.hex", ram_dual_port);
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
