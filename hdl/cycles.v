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

// Update matrix counters
module cycles(
           input rst,
           input clk_dot4x,
           input clk_phi,
           input [1:0] chip,
           input phi_phase_start_1,
           input [`NUM_SPRITES - 1:0] sprite_dma,
           input badline,
           input [6:0] cycle_num,
           output reg [3:0] cycle_type,
           output reg [2:0] sprite_cnt
       );

// Counters for sprite, refresh and idle 'stretches' for
// the cycle_type state machine.
reg [2:0] refresh_cnt;
reg [2:0] idle_cnt;

// cycle_type state machine
//
// LP --dmaEn?-> HS1 -> LS2 -> HS3  --<7?--> LP
//                                  --else-> LR
//    --else---> HPI1 -> LPI2-> HPI3 --<7>--> LP
//                                   --else-> LR
//
// LR --5th&bad?--> HRC -> LG
// LR --5th&!bad?-> HRX -> LG
// LR --else--> HRI --> LR
//
// LG --55?--> HI
//    --bad?--> HGC
//    --else-> HGI
//
// HGC -> LG
// HGI -> LG
// HI --2|3|4?--> LP
//      --else--> LI
// LI -> HI
always @(posedge clk_dot4x)
    if (rst) begin
        if (chip == `CHIP6567R8) begin
            cycle_type <= `VIC_LS2;
            idle_cnt <= 3'd4;
        end else begin
            cycle_type <= `VIC_LP;
            idle_cnt <= 3'd3;
        end
        sprite_cnt <= 3'd3;
        //refresh_cnt <= 3'd0;
    end else if (phi_phase_start_1) begin
        if (clk_phi == `TRUE) begin
            case (cycle_type)
                `VIC_LP: begin
                    if (sprite_dma[sprite_cnt])
                        cycle_type <= `VIC_HS1;
                    else
                        cycle_type <= `VIC_HPI1;
                end
                `VIC_LPI2:
                    cycle_type <= `VIC_HPI3;
                `VIC_LS2:
                    cycle_type <= `VIC_HS3;
                `VIC_LR: begin
                    if (refresh_cnt == 4) begin
                        if (badline == `TRUE)
                            cycle_type <= `VIC_HRC;
                        else
                            cycle_type <= `VIC_HRX;
                    end else
                        cycle_type <= `VIC_HRI;
                end
                `VIC_LG: begin
                    if (cycle_num == 54) begin
                        cycle_type <= `VIC_HI;
                        idle_cnt <= 0;
                    end else
                        if (badline == `TRUE)
                            cycle_type <= `VIC_HGC;
                        else
                            cycle_type <= `VIC_HGI;
                end
                `VIC_LI: cycle_type <= `VIC_HI;
                default: ;
            endcase
        end else begin
            case (cycle_type)
                `VIC_HS1: cycle_type <= `VIC_LS2;
                `VIC_HPI1: cycle_type <= `VIC_LPI2;
                `VIC_HS3, `VIC_HPI3: begin
                    if (sprite_cnt == 7) begin
                        // The R8's extra idle cycle comes after
                        // Sprite 7.
                        if (chip == `CHIP6567R8)
                            cycle_type <= `VIC_LI;
                        else
                            cycle_type <= `VIC_LR;
                        sprite_cnt <= 0;
                        refresh_cnt <= 0;
                    end else begin
                        cycle_type <= `VIC_LP;
                        sprite_cnt <= sprite_cnt + 1'd1;
                    end
                end
                `VIC_HRI: begin
                    cycle_type <= `VIC_LR;
                    refresh_cnt <= refresh_cnt + 1'd1;
                end
                `VIC_HRC, `VIC_HRX:
                    cycle_type <= `VIC_LG;
                `VIC_HGC, `VIC_HGI: cycle_type <= `VIC_LG;
                `VIC_HI: begin
                    if (chip == `CHIP6567R56A && idle_cnt == 3)
                        cycle_type <= `VIC_LP;
                    // The R8's extra idle cycle is deferred until
                    // after sprite 7. See above.
                    else if (chip == `CHIP6567R8 && idle_cnt == 3) begin
                        idle_cnt <= idle_cnt + 1'd1;
                        cycle_type <= `VIC_LP;
                        // This is the extra idle cycle after Sprite 7. Now
                        // go to refresh.
                    end else if (chip == `CHIP6567R8 && idle_cnt == 4)
                        cycle_type <= `VIC_LR;
                    else if (chip[0] /* 6569Rx */ && idle_cnt == 2)
                        cycle_type <= `VIC_LP;
                    else begin
                        idle_cnt <= idle_cnt + 1'd1;
                        cycle_type <= `VIC_LI;
                    end
                end
                default: ;
            endcase
        end
    end
    // NOTE: If we need address lines set earlier in the phase, we could
    // move the logic in addressgen.v right here and make cycle_type a blocking
    // assignment.  Provided there is enough time in one tick to do all this
    // work, that would get ado set ~30ns earlier. However, there seems to be
    // a lot instability early in the phase for some unknown reason and not
    // sure we can set ado any earlier.  It might be due to the transceivers
    // just having switched direction from input to output.
endmodule
