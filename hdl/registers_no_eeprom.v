// Init sequence code for board with no EEPROM.

`ifndef SIMULATOR_BOARD
// @ 14Mhz, 1/14000000*2^21 = ~ 149ms
`define RESET_CTR_TOP_BIT 20
`define RESET_CTR_INC 21'd1
`define RESET_LATCH_POINT 21'b010000000000000000000
`else
// For simluator, have a much shorter reset period 
`define RESET_CTR_TOP_BIT 7
`define RESET_CTR_INC 7'd1
`define RESET_LATCH_POINT 8'b01000000
`endif

reg [`RESET_CTR_TOP_BIT:0] rstcntr = 0;
wire internal_rst = !rstcntr[`RESET_CTR_TOP_BIT];

always @(posedge clk_dot4x)
begin
    if (internal_rst)
        rstcntr <= rstcntr + `RESET_CTR_INC;
end

// Take design out of reset when internal_rst is high
always @(posedge clk_dot4x) rst <= internal_rst;
