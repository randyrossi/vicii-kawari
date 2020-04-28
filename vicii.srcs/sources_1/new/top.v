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
   input rw            // read/write (LOW=write, HIGH=read)
);

wire sys_clockb;

BUFG sysbuf1 (
.O(sys_clockb),
.I(sys_clock)
);

wire clk_dot4x;    // 32.272768 Mhz NTSC
wire clk_col4x;    // 14.381818 Mhz NTSC
wire clk_dot;      // 8.18181 Mhz NTSC
// clk_colref         3.579545 Mhz NTSC
// clk_phi            1.02272 Mhz NTSC

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

clk_div4 clk_colorgen (
   .clk_in(clk_col4x),     // from 4x color clock
   .reset(rst),
   .clk_out(clk_colref)    // create color ref clock
);

clk_div32 clk_phigen (
   .clk_in(clk_dot4x),     // from 4x dot clock
   .reset(rst),
   .clk_out(clk_phi)       // create phi clock
);

clk_div4 clk_dotgen (
   .clk_in(clk_dot4x),    // from 4x dot clock
   .reset(rst),
   .clk_out(clk_dot)      // create dot clock
);

vicii vic_inst(
   .clk_dot(clk_dot),
   .clk_phi(clk_phi),
   .red(red),
   .green(green),
   .blue(blue),
   .reset(rst),
   .cSync(cSync),
   .ad(ad),
   .db(db),
   .ce(ce),
   .rw(rw)
);

endmodule