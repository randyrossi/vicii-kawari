`timescale 1ns/1ps

`include "common.vh"

// Top level module for the CMod A35t PDIP board.
module top(
// sys_clock comes from the on board 12Mhz clock circuit connected
// to L3 on the CMod-A7
    input sys_clock,    // external 12Mhz clock
    input rst,          // reset
    output clk_colref,  // output color ref clock 3.579545 Mhz NTSC for CXA1545P
    output clk_phi,     // output phi clock 1.022727 Mhz NTSC
    output cSync,       // composite sync signal for CXA1545P
    output [1:0] red,    // red out for CXA1545P
    output [1:0] green,  // green out for CXA1545P
    output [1:0] blue,   // blue out for CXA1545P
    inout [11:0] ad,    // address lines
    inout tri [11:0] db,// data bus lines
    input ce,           // chip enable (LOW=enable, HIGH=disabled)
    input rw,           // read/write (LOW=write, HIGH=read)
    output irq,         // irq
    output aec,         // aec
    output ba,          // ba
    output cas,         // column address strobe
    output ras,         // row address strobe
    output den_n,         // data enable for bus transceiver
    output dir          // dir for bus transceiver
);

    wire sys_clockb;

    // Generate a 32.727272mhz dot clock.
    dot4x_clockgen dot4x_clockgen(
        .clk_in12mhz(sys_clock),    // external 12 Mhz clock
        .reset(rst),
        .clk_dot4x(clk_dot4x)     // generated 4x dot clock
    );

    // Generate a 14.318mhz color clock.
    color4x_clockgen color4x_clockgen(
        .clk_in12mhz(sys_clock),    // external 12 Mhz clock
        .reset(rst),
        .clk_color4x(clk_col4x)     // generated 4x col clock
    );

    wire [11:0] dbo;
    wire [11:0] ado;

    // Instantiate the vicii with our clocks and pins.
    vicii vic_inst(
        .chip(CHIP6567R56A), // for now, not wired to jumpers
        .clk_dot4x(clk_dot4x),
        .clk_col4x(clk_col4x),
        .clk_colref(clk_colref),
        .clk_phi(clk_phi),
        .red(red),
        .green(green),
        .blue(blue),
        .rst(rst),
        .cSync(cSync),
        .adi(ad),
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
        .den_n(den_n),
        .dir(dir)
    );

    // Write to bus condition, else tri state.
    assign db = (aec && ~rw && !ce) ? dbo:12'bz;
    assign ad = aec ? 12'bz:ado;

endmodule : top
