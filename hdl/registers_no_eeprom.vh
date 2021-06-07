// Header for registers_no_eeprom.v

`ifndef SIMULATOR_BOARD
// @ 14Mhz, 1/14000000*2^21 = ~ 149ms
`define RESET_CTR_TOP_BIT 20
`define RESET_CTR_INC 21'd1
`define RESET_LIFT_POINT 21'b011111111111111111111
`else
// For simluator, have a much shorter reset period 
`define RESET_CTR_TOP_BIT 7
`define RESET_CTR_INC 7'd1
`define RESET_LIFT_POINT 8'b01111111
`endif

reg [`RESET_CTR_TOP_BIT:0] rstcntr = 0;
wire internal_rst = !rstcntr[`RESET_CTR_TOP_BIT];
