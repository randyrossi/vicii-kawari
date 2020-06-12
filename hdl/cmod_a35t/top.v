`timescale 1ns/1ps

`include "common.vh"

// Top level module for the CMod A35t PDIP board.
module top(
// sys_clock comes from the on board 12Mhz clock circuit connected
// to L3 on the CMod-A7
    input sys_clock,    // external 12Mhz clock
    output cpu_reset,   // reset for 6510 CPU
    output clk_colref,  // output color ref clock 3.579545 Mhz NTSC for CXA1545P
    output clk_phi,     // output phi clock 1.022727 Mhz NTSC
    output cSync,       // composite sync signal for CXA1545P
    output [1:0] red,    // red out for CXA1545P
    output [1:0] green,  // green out for CXA1545P
    output [1:0] blue,   // blue out for CXA1545P
    inout tri [5:0] adl, // address low
    output tri [5:0] adh, // address high
    inout tri [11:0] db,// data bus lines
    input ce,           // chip enable (LOW=enable, HIGH=disabled)
    input rw,           // read/write (LOW=write, HIGH=read)
    output irq,         // irq
    output aec,         // aec
    output ba,          // ba
    output cas,         // column address strobe
    output ras,         // row address strobe
    output ls245_oe,    // OE line for bus transceiver
    output ls245_dir    // DIR for bus transceiver
);

    wire sys_clockb;
    wire locked;
    wire rst;
    assign cpu_reset = rst;

    reg [21:0] rstcntr = 0;
    wire internal_rst = !rstcntr[21];
    
    BUFG sysbuf1 (
      .O(sys_clockb),
      .I(sys_clock)
    );

    // Keep internel reset high for approx 150ms
    always @(posedge sys_clock)
    if (internal_rst)
       rstcntr <= rstcntr + 4'd1;

    // Generate a 32.727272mhz dot clock.
    dot4x_clockgen dot4x_clockgen(
        .clk_in12mhz(sys_clockb),    // external 12 Mhz clock
        .reset(internal_rst),
        .clk_dot4x(clk_dot4x),      // generated 4x dot clock
        .locked(locked)
    );

    assign rst = !locked;
    
    // Generate a 14.318mhz color clock.
    color4x_clockgen color4x_clockgen(
        .clk_in12mhz(sys_clockb),    // external 12 Mhz clock
        .reset(internal_rst),
        .clk_color4x(clk_col4x)     // generated 4x col clock
    );

    wire [11:0] dbo;
    wire [11:0] ado;
    
    wire vic_write_ab;
    wire vic_write_db;
    
    // Instantiate the vicii with our clocks and pins.
    vicii vic_inst(
        .chip(CHIP6567R8), // for now, not wired to jumpers
        .clk_dot4x(clk_dot4x),
        .clk_col4x(clk_col4x),
        .clk_colref(clk_colref),
        .clk_phi(clk_phi),
        .red(red),
        .green(green),
        .blue(blue),
        .rst(rst),
        .cSync(cSync),
        .adi(adl[5:0]),
        .ado(ado),
        .dbi(db),
        .dbo(dbo),
        .ce(ce),
        .rw(rw),
        .aec(aec),
        .irq(irq),
        .ba(ba),
        .cas(cas),
        .ras(ras),
        .ls245_oe(ls245_oe),
        .ls245_dir(ls245_dir),
        .vic_write_db(vic_write_db),
        .vic_write_ab(vic_write_ab)
    );

    // Write to bus condition, else tri state.
    assign db = vic_write_db ? dbo : 12'bz; // CPU reading
    assign adl = vic_write_ab ? ado[5:0] : 6'bz; // vic or stollen cycle
    assign adh = vic_write_ab ? ado[11:6] : 6'bz;

endmodule : top
