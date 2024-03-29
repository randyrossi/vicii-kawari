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

// Header for register_eeprom.v

// We need a 'warm up' flag so we don't try to
// talk to the EEPROM immediately after the bistream
// has landed. When warm_up cycle is HIGH, the first
// EEPROM_READ iteration over all 256 addresses of the
// EEPROM will do no operations.  This take about
// 5ms which makes the entire reset about 10ms.
reg eeprom_warm_up_cycle = 1;

// Every 64 ticks of state_ctr cycles through all 256
// EEPROM addresses and performs the operation as indicated
// by eeprom_state (READ, WRITE)
reg [14:0] state_ctr = 15'b0;

reg state_ctr_reset_for_write;
// Start off reading existing eeprom data
reg state_ctr_reset_for_read = 1'b1;

// clk_div divides dot4x by 4 to give us approx 8Mhz clock
// for EEPROM access.
reg [3:0] clk_div = 4'b0001;

// Register for an internal 8Mhz clock that is sometimes
// 'exported' to C
reg clk8 = 1'b1;

// Bits 13-6 represent the address in EEPROM we are reading
// (0-256). The first thing we read are the magic bytes.  If we
// don't find them within the first 4 reads, none of the data gets
// assigned to any registers. This prevents blank EEPROM from
// setting registers to garbage.
wire [5:0] state_val = state_ctr[5:0];

// We start at 0x00 so we read the magic bytes first
wire [7:0] addr_lo = state_ctr[13:6];

reg [7:0] instr; // Instruction shift register
reg [15:0] addr; // Address shift register
reg [7:0] data; // Data shift reigster

reg [1:0] eeprom_bank;

reg [2:0] magic = 3'd0;

reg [1:0] eeprom_state = `EEPROM_IDLE;

// When in EEPROM_WRITE mode, what addr are we writing
// to?
reg [9:0] eeprom_w_addr = 10'd0;
reg [7:0] eeprom_w_value;
reg eeprom_busy = 1'b0;
reg delayed_c = 1'b1;
