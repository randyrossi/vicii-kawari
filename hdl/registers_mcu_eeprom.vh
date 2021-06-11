// Header for register_mcu_eeprom.v

`ifndef SIMULATOR_BOARD
// @ 14Mhz, 1/14000000*2^21 = ~ 149ms
`define RESET_CTR_TOP_BIT 20
`define RESET_CTR_INC 21'd1
`define RESET_CHIP_LATCH_POINT 21'b010000000000000000000
`define RESET_LIFT_POINT 21'b010000000000000000000
`else
// For simluator, have a much shorter reset period
`define RESET_CTR_TOP_BIT 7
`define RESET_CTR_INC 7'd1
`define RESET_CHIP_LATCH_POINT 8'b01000000
`define RESET_LIFT_POINT 8'b01111111
`endif

reg [`RESET_CTR_TOP_BIT:0] rstcntr = 0;
wire internal_rst = !rstcntr[`RESET_CTR_TOP_BIT];

reg [10:0] tx_new_data_ctr;
reg tx_new_data_start;
reg [7:0] tx_cfg_change_1;
reg [7:0] tx_cfg_change_2;
reg rx_new_data_ff;
reg [7:0] rx_cfg_change_1;
