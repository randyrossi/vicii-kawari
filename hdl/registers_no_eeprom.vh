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

`define RESET_CTR_TOP_BIT 3
`define RESET_CTR_INC 4'd1
`define RESET_CHIP_SET_POINT 4'b0011
`define RESET_LIFT_POINT 4'b0111

reg [`RESET_CTR_TOP_BIT:0] rstcntr = 0;
wire internal_rst = !rstcntr[`RESET_CTR_TOP_BIT];
