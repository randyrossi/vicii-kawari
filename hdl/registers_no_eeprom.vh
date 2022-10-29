// This file is part of the vicii-kawari distribution
// (https://github.com/randyrossi/vicii-kawari)
// Copyright (c) 2022 Randy Rossi.
// 
// This program is free software: you can redistribute it and/or modify  
// it under the terms of the GNU General Public License as published by  
// the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful, but 
// WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License 
// along with this program. If not, see <http://www.gnu.org/licenses/>.

// Header for registers_no_eeprom.v

`ifndef SIMULATOR_BOARD
// @ 14Mhz, 1/14000000*2^21 = ~ 149ms
`define RESET_CTR_TOP_BIT 20
`define RESET_CTR_INC 21'd1
`define RESET_CHIP_SET_POINT 21'b001111111111111111111
`define RESET_LIFT_POINT 21'b011111111111111111111
`else
// For simluator, have a much shorter reset period
`define RESET_CTR_TOP_BIT 7
`define RESET_CTR_INC 7'd1
`define RESET_CHIP_SET_POINT 8'b00111111
`define RESET_LIFT_POINT 8'b01111111
`endif

reg [`RESET_CTR_TOP_BIT:0] rstcntr = 0;
wire internal_rst = !rstcntr[`RESET_CTR_TOP_BIT];
