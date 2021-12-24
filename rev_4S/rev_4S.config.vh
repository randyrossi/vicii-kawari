`ifndef config_vh_
`define config_vh_

`define VERSION_MAJOR 8'd0
`define VERSION_MINOR 8'd8

// Pick a board.
// SIMULATOR_BOARD - For the verilator simulator only
// REV_3_BOARD     - Beta board sent to 11 person beta test group
// REV_4L_BOARD    - Large (final) full featured board with X16
// REV_4S_BOARD    - Small cost reduced (just a VICII) board with X4

`define REV_4S_BOARD 1
`define NO_CLOCK_MUX 1
`define VARIANT_SUFFIX_1 8'd53;
`define VARIANT_SUFFIX_2 8'd83;
`define VARIANT_SUFFIX_3 8'd66;
`define VARIANT_SUFFIX_4 8'd0;
`define WITH_EXTENSIONS 1
`define WITH_RAM 1
`define WITH_64K 1
`define GEN_LUMA_CHROMA 1
`define CONFIGURABLE_LUMAS 1
`define HAVE_FLASH 1
`define HIRES_MODES
`define WITH_MATH

`endif // config_vh_
