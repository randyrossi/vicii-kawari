`timescale 1ns/1ps

`include "common.vh"

// NOTE: Clock pins must be declared in constr.xdc to match
// selected configuration here.

// Chose one:
//`define USE_SYSCLOCK_PAL      // use on-board clock
//`define USE_SYSCLOCK_NTSC     // use on-board clock
`define USE_PALCLOCK_PAL      // use external clock
//`define USE_NTSCCLOCK_NTSC    // use external clock


// Top level module for the CMod A35t PDIP board.
module top(
    input sys_clock,
    output cpu_reset,    // reset for 6510 CPU
    output clk_colref,   // output color ref clock for CXA1545P
    output clk_phi,      // output phi clock for CPU
    output csync,        // composite sync signal for CXA1545P
    output [1:0] red,    // red out for CXA1545P
    output [1:0] green,  // green out for CXA1545P
    output [1:0] blue,   // blue out for CXA1545P
    inout tri [5:0] adl, // address (lower 6 bits)
    output tri [5:0] adh,// address (high 6 bits)
    inout tri [11:0] db, // data bus lines
    input ce,            // chip enable (LOW=enable, HIGH=disabled)
    input rw,            // read/write (LOW=write, HIGH=read)
    output irq,          // irq
    input lp,            // light pen
    output aec,          // aec
    output ba,           // ba
    output cas,          // column address strobe
    output ras,          // row address strobe
    output ls245_oe,     // OE line for bus transceiver
    output ls245_dir     // DIR for bus transceiver
);
    reg [1:0] chip;
    wire sys_clockb;
    wire locked;
    wire rst;
    assign cpu_reset = rst;

    reg [21:0] rstcntr = 0;
    wire internal_rst = !rstcntr[21];

    BUFG sysbuf2 (
      .O(sys_clockb),
      .I(sys_clock)
    );

    // Keep internel reset high for approx 150ms
    always @(posedge sys_clockb)
    if (internal_rst)
       rstcntr <= rstcntr + 4'd1;

`ifdef USE_SYSCLOCK_PAL

    assign chip = CHIP6569;

    // Generate the 4x dot clock. See vicii.v for values.
    dot4x_12_pal_clockgen dot4x_12_pal_clockgen(
        .clk_in12mhz(sys_clockb),    // external 12 Mhz clock
        .reset(internal_rst),
        .clk_dot4x(clk_dot4x),      // generated 4x dot clock
        .locked(locked)
    );
    // Generate a 4x color clock. See vicii.v for values.
    color4x_12_pal_clockgen color4x_12_pal_clockgen(
        .clk_in12mhz(sys_clockb),    // external 12 Mhz clock
        .reset(internal_rst),
        .clk_color4x(clk_col4x)     // generated 4x col clock
    );
`endif

`ifdef USE_SYSCLOCK_NTSC

    assign chip = CHIP6567R8;

    // Generate the 4x dot clock. See vicii.v for values.
    dot4x_12_ntsc_clockgen dot4x_12_ntsc_clockgen(
        .clk_in12mhz(sys_clockb),    // external 12 Mhz clock
        .reset(internal_rst),
        .clk_dot4x(clk_dot4x),      // generated 4x dot clock
        .locked(locked)
    );
    // Generate a 4x color clock. See vicii.v for values.
    color4x_12_ntsc_clockgen color4x_12_ntsc_clockgen(
        .clk_in12mhz(sys_clockb),    // external 12 Mhz clock
        .reset(internal_rst),
        .clk_color4x(clk_col4x)     // generated 4x col clock
    );
`endif

// Use an external clock for pal.
`ifdef USE_PALCLOCK_PAL
    assign chip = CHIP6569;
    dot4x_17_pal_clockgen dot4x_17_pal_clockgen(
        .clk_in17mhz(sys_clockb),
        .reset(internal_rst),
        .clk_col4x(clk_col4x),
        .clk_dot4x(clk_dot4x),
        .locked(locked)
    );
`endif

// Use an external clock for ntsc.
`ifdef USE_NTSCCLOCK_NTSC
    assign chip = CHIP6567R8;
    dot4x_14_ntsc_clockgen dot4x_14_ntsc_clockgen(
        .clk_in14mhz(sys_clockb),
        .reset(internal_rst),
        .clk_col4x(clk_col4x),
        .clk_dot4x(clk_dot4x),
        .locked(locked)
    );
`endif

    assign rst = !locked;

    wire [11:0] dbo;
    wire [11:0] ado;
    
    // When these are true, the VIC is writing to the data
    // or address bus so ab/db will be assigned from
    // ado/dbo respectively.  Otherwise, we tri-state
    // those lines and VIC can read from adi/dbi.
    // NOTE: The VIC only ever reads the lower 6 bits from
    // the address lines. This is the reason for the adl/adh
    // split below.
    wire vic_write_ab;
    wire vic_write_db;
    
    // Instantiate the vicii with our clocks and pins.
    vicii vic_inst(
        .chip(chip),
        .clk_dot4x(clk_dot4x),
        .clk_col4x(clk_col4x),
        .clk_colref(clk_colref),
        .clk_phi(clk_phi),
        .red(red),
        .green(green),
        .blue(blue),
        .rst(rst),
        .csync(csync),
        .adi(adl[5:0]),
        .ado(ado),
        .dbi(db),
        .dbo(dbo),
        .ce(ce),
        .rw(rw),
        .aec(aec),
        .irq(irq),
        .lp(lp),
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
