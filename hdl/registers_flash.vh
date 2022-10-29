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

// Header for register_flash.v

// Current video memory addr for flash op
reg [ram_width-1:0] flash_vmem_addr;

// Current flash memory addr
reg [23:0] flash_addr;

// Shifting flash memory addr
reg [23:0] flash_addr_s;

// Byte shift register for data when writing to flash
reg [7:0] flash_byte;

// Byte to hold what we read from video memory for verify
reg [7:0] mem_byte;

// clk_div divides dot4x by 4 to give us approx 8Mhz clock
// for FLASH access.
reg [3:0] flash_clk_div = 4'b0001;

// Register for an internal 8Mhz clock that is sometimes
// 'exported' to C
reg flash_clk8 = 1'b1;

reg [1:0] flash_state = `FLASH_IDLE;
reg flash_busy;
reg flash_verify_error;

// Instruction shift register
reg [7:0] flash_instr;

// A counter to keep track of what command we are
// working on within a sequence of commands issued to
// the flash device.
reg [1:0] flash_command_ctr;

// What command to go to after WAIT state.
reg [1:0] flash_next_command;

// A counter to mark which bit we are working on inside
// one command to flash.
reg [5:0] flash_bit_ctr;

// A counter to keep track of how many bytes we have
// written or verified in a page command.
reg [7:0] flash_byte_ctr;

// A counter to keep track of which page number we are
// currently writing. For 64k or 32k builds, we write
// 64 pages of 256 bytes (16k) but when we only have
// 4k we are reduced to 16 pages. The flash program
// must know based on the variant id.
reg [`FLASH_PAGE_RANGE] flash_page_ctr;

// Flip this register to 1 to start bulk flash
// commands.
reg [1:0] flash_begin = `FLASH_IDLE;

reg delayed_flash_c = 1'b1;
