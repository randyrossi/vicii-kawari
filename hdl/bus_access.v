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

`timescale 1ns/1ps

`include "common.vh"

// A modules that encapsulates data bus accesses for cycles
// that read from the data bus.
// c-access - character pointer reads
// g-access - bitmap graphics reads
// p-access - sprite pointer reads
// s-access - sprite bitmap graphics reads (see vic_sprites.v)
module bus_access(
           input clk_dot4x,
           input phi_phase_start_dav,
           input [3:0] cycle_type,
           input [11:0] dbi,
           input idle,
           input [2:0] sprite_cnt,
           input aec,
           input [`NUM_SPRITES - 1:0] sprite_dma,
           output [63:0] sprite_ptr_o,
           output reg [7:0] pixels_read,
           output reg [11:0] char_read,
           output reg [11:0] char_next
       );

integer n;

// 2D arrays that need to be flattened for output
reg [7:0] sprite_ptr[0:`NUM_SPRITES - 1];

// Internal regs
// our character line buffer
reg [11:0] char_buf [63:0];
reg [5:0] char_buf_counter;

// Handle flattening outputs here
assign sprite_ptr_o = {sprite_ptr[0], sprite_ptr[1], sprite_ptr[2], sprite_ptr[3], sprite_ptr[4], sprite_ptr[5], sprite_ptr[6], sprite_ptr[7]};

// c-access reads
always @(posedge clk_dot4x)
begin
        if (phi_phase_start_dav) begin
            case (cycle_type)
                `VIC_HRC, `VIC_HGC: begin // badline c-access
                    // Always read color and init data to 0xff
                    // - krestage 1st demo/starwars falcon cloud/comaland bee pic
                    char_next = { dbi[11:8], 8'b11111111 };
                    if (!aec) begin
                        char_next[7:0] = dbi[7:0];
                    end
                    char_buf[char_buf_counter] = char_next;
                end
                `VIC_HRX, `VIC_HGI: // not badline idle (char from cache)
                    char_next = char_buf[char_buf_counter];
                default: ;
            endcase
            case (cycle_type)
                `VIC_HRC, `VIC_HGC, `VIC_HRX, `VIC_HGI: begin
                    if (char_buf_counter < 39)
                        char_buf_counter <= char_buf_counter + 6'd1;
                    else
                        char_buf_counter <= 0;
                end
                default: ;
            endcase
        end
end

// g-access reads
always @(posedge clk_dot4x)
begin
    if (!aec && phi_phase_start_dav && cycle_type == `VIC_LG) begin
        pixels_read <= dbi[7:0];
        char_read <= idle ? 12'd0 : char_next;
    end
end

// p-access reads
always @(posedge clk_dot4x)
    begin
        if (!aec && phi_phase_start_dav) begin
            case (cycle_type)
                `VIC_LP: // p-access
                    if (sprite_dma[sprite_cnt])
                        sprite_ptr[sprite_cnt] <= dbi[7:0];
                    else
                        sprite_ptr[sprite_cnt] <= 8'hff;
                default: ;
            endcase
        end
    end

// s-access reads are performed in vic_sprites

endmodule
