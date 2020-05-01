`timescale 1ns / 1ps

// sys_clock comes from the on board 12Mhz clock circuit connected
// to L3 on the CMod-A7
module top(
   input sys_clock,    // external 12Mhz clock
   input rst,          // reset
   output clk_colref,  // output color ref clock 3.579545 Mhz NTSC for CXA1545P 
   output clk_phi,     // output phi clock 1.022727 Mhz NTSC
   output cSync,       // composite sync signal for CXA1545P 
   output[1:0] red,    // red out for CXA1545P
   output[1:0] green,  // green out for CXA1545P
   output[1:0] blue,   // blue out for CXA1545P
   inout [11:0] ad,    // address lines
   inout tri [11:0] db,// data bus lines
   input ce,           // chip enable (LOW=enable, HIGH=disabled)
   input rw,           // read/write (LOW=write, HIGH=read)
   output irq,         // irq
   output aec,         // aec
   output ba           // ba
);

wire sys_clockb;

BUFG sysbuf1 (
.O(sys_clockb),
.I(sys_clock)
);

// From clocking wizard.
clockgen gclock(
   .sys_clock(sys_clock),    // external 12 Mhz clock
   .reset(rst),
   .clk_dot4x(clk_dot4x)     // generated 4x dot clock
);

// From clocking wizard.
clock2gen g2clock(
   .sys_clock(sys_clockb),    // external 12 Mhz clock
   .reset(rst),
   .clk_col4x(clk_col4x)     // generated 4x col clock
);

reg[11:0] dbo;

vicii vic_inst(
   .chip(2'd1), // for now, not wired to jumpers
   .clk_dot4x(clk_dot4x),
   .clk_col4x(clk_col4x),
   .clk_colref(clk_colref),
   .clk_phi(clk_phi),
   .red(red),
   .green(green),
   .blue(blue),
   .reset(rst),
   .cSync(cSync),
   .ad(ad),
   .dbi(db),
   .dbo(dbo),
   .ce(ce),
   .rw(rw),
   .aec(aec),
   .irq(irq),
   .ba(ba)
);

// Write to bus condition, else tri state.
assign db = (aec && ~rw && !ce) ? dbo : 12'bz;

endmodule