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
initial $readmemh ("hires00.hex", ram_dual_port);
`endif
`ifdef HIRES_BITMAP1
initial $readmemh ("hires01.hex", ram_dual_port);
`endif
`ifdef HIRES_BITMAP2
initial $readmemh ("hires10.hex", ram_dual_port);
`endif
`ifdef HIRES_BITMAP3
initial $readmemh ("hires11.hex", ram_dual_port);
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
