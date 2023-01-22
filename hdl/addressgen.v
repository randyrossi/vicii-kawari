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

`timescale 1ns / 1ps

`include "common.vh"

// The 6569 has a glitch whereby a bmm change on the CPU's half cycle
// prior to a bitmap fetch will result in the wrong address put to
// the address bus for a CHARROM address. This implementation is my best
// guess as to what is really going in in the VIC, as opposed to
// VICE implementation which simulates the eventual outcome but
// not the actual cause.  Since we don't have 'global' information
// like an emulator, we have to glitch in the same way the actual
// hardware does.  What's interesting is that the glitch only happens
// when a BMM transition would result in a CHARROM read.  It does
// not affect RAM reads.
//
// U26 is a 74LS373 which will latch the lower 8 bits of the address
// bus multiplexed by the VIC. Its output pins are wired to the lower
// 8 bits of ROM chips.  When RAS falls, the outputs of this chip
// latch the address pins A0/A8->A5/A13 and A6, A7 from
// the VIC. At the same time, the RAM chips will also latch the
// same lower 8 bts as the row address.
//
// After RAS falls, the address lines change to the upper 8 bits
// of the address (6 come from the VIC, the other 2 from the CIA
// chip), Then CAS falls and the RAM chips latch the column
// address.
//
// The glitch happens because after CAS falls, the VIC changes
// its address to the what the new value of BMM would dictate for
// the cycle. That instantly affects the memory the ROM chips
// are addressing, but remember that the lower 8 bits have already
// been latched to the 'previous bmm' address values.  So we get
// a mix of lower 8 bits = old and upper 4 bits (ROMs only have
// 12 bits address) being the new bmm value.
//
// The reason this glitch doesn't affect RAM is because RAM has
// already latched the old bmm generated address value.  The
// address change happens after CAS so RAM always delivers the
// first (old bmm) address. (The glitch can't happen too soon after
// CAS falls because it is delayed to RAM.)

// PAL CAS/RAS rise/fall times based on PAL col16x clock
`define PAL_RAS_RISE 1
`define PAL_RAS_FALL 10
`define PAL_CAS_RISE 0
`define PAL_CAS_FALL 13

// NTSC CAS/RAS rise/fall times based on NTSC col16x clock
`define NTSC_RAS_RISE 1
`define NTSC_RAS_FALL 10
`define NTSC_CAS_RISE 0
`define NTSC_CAS_FALL 13

// When do we set row address? (NTSC/PAL)
`define MUX_ROW 2
// When do we set col address? (NTSC)
`define NTSC_MUX_COL 6
// When do we set col address? (PAL)
`define PAL_MUX_COL 5
// When to apply post CAS fall bmm glitch (see above)
`define CAS_GLITCH 10


// Address generation
module addressgen(
           input rst,
           input clk_dot4x,
           input clk_col16x,
           input [1:0] chip,
           input [3:0] cycle_type,
`ifdef WITH_RAM
           input dma_done,
           input [15:0] dma_addr,
`endif
           input [2:0] cb,
           input [9:0] vc,
           input [3:0] vm,
           input [2:0] rc,
           input bmm_now,
           input bmm_old,
           input ecm_now,
           input ecm_old,
           input idle,
           input [7:0] refc,
           input [7:0] char_ptr,
           input aec,
           input [2:0] sprite_cnt,
           input [63:0] sprite_ptr_o,
           input [47:0] sprite_mc_o,
           input [15:0] phi_phase_start,
           output reg [11:0] ado,
           output ras,
           output cas
       );

// Destinations for flattened inputs that need to be sliced back into an array
wire [7:0] sprite_ptr[0:`NUM_SPRITES - 1];
wire [5:0] sprite_mc[0:`NUM_SPRITES - 1];

// VIC read address
reg [13:0] vic_addr;
// Used to implement the post CAS bmm transition glitch. See above.
reg [13:0] vic_addr_now;

reg [35:0] pal_cas_ras;
reg [27:0] ntsc_cas_ras;

// Handle un-flattening inputs here
assign sprite_ptr[0] = sprite_ptr_o[63:56];
assign sprite_ptr[1] = sprite_ptr_o[55:48];
assign sprite_ptr[2] = sprite_ptr_o[47:40];
assign sprite_ptr[3] = sprite_ptr_o[39:32];
assign sprite_ptr[4] = sprite_ptr_o[31:24];
assign sprite_ptr[5] = sprite_ptr_o[23:16];
assign sprite_ptr[6] = sprite_ptr_o[15:8];
assign sprite_ptr[7] = sprite_ptr_o[7:0];

assign sprite_mc[0] = sprite_mc_o[47:42];
assign sprite_mc[1] = sprite_mc_o[41:36];
assign sprite_mc[2] = sprite_mc_o[35:30];
assign sprite_mc[3] = sprite_mc_o[29:24];
assign sprite_mc[4] = sprite_mc_o[23:18];
assign sprite_mc[5] = sprite_mc_o[17:12];
assign sprite_mc[6] = sprite_mc_o[11:6];
assign sprite_mc[7] = sprite_mc_o[5:0];

always @(posedge clk_dot4x)
begin
    case(cycle_type)
        `VIC_LR: begin
            vic_addr = {6'b111111, refc};
            vic_addr_now = vic_addr;
        end
        `VIC_LG: begin
            if (idle) begin
`ifdef WITH_RAM
                // We can use idle cycles for DMA transfers.
                if (!dma_done)
                  vic_addr = dma_addr[13:0];
                else
`endif
                  vic_addr = ecm_now ? 14'h39FF : 14'h3FFF;
                vic_addr_now = vic_addr;
            end else begin
                // This is a wierd calculation for the address using
                // old/new bmm value but that seems to be how things
                // work. I would have though this section should use
                // old exclusively. But then we don't match VICE addresses
                // in the sync and we're assuming VICE is right.
                if (bmm_old | bmm_now) // bmm at start of half cycle
                    vic_addr = {cb[2], vc, rc}; // bitmap data
                else
                    vic_addr = {cb, char_ptr, rc}; // character pixels
                if (ecm_now) // ecm at start of half cycle
                    vic_addr[10:9] = 2'b00;

                // This section determines the address that the new
                // bmm value (if it changed) determines and will be placed
                // on the address bus shortly after CAS falls.
                if (bmm_now) // bmm we transitioned to during the half cycle
                    vic_addr_now = {cb[2], vc, rc}; // bitmap data
                else
                    vic_addr_now = {cb, char_ptr, rc}; // character pixels
                if (ecm_now) // current ecm
                    vic_addr_now[10:9] = 2'b00;
            end
        end
        `VIC_HRC, `VIC_HGC: begin
            vic_addr = {vm, vc}; // video matrix c-access
            vic_addr_now = vic_addr;
        end `VIC_LP: begin
            vic_addr = {vm, 7'b1111111, sprite_cnt}; // p-access
            vic_addr_now = vic_addr;
        end `VIC_HS1, `VIC_LS2, `VIC_HS3:
            if (!aec) begin
                vic_addr = {sprite_ptr[sprite_cnt], sprite_mc[sprite_cnt]}; // s-access
                vic_addr_now = vic_addr;
            end else begin
                if (ecm_old) begin// ecm
                    vic_addr = 14'h39FF;
                end else begin
                    vic_addr = 14'h3FFF;
                end
                vic_addr_now = vic_addr;
            end
        default: begin
`ifdef WITH_RAM
            // We can use idle cycles for DMA transfers.
            if (!dma_done && cycle_type == `VIC_LI)
               vic_addr = dma_addr[13:0];
            else
`endif
               vic_addr = 14'h3FFF;
            vic_addr_now = vic_addr;
        end
    endcase

    // Address out
    // ROW first, COL second
    // This makes ado valid as early as MUX_ROW + 1
    if (!aec) begin
        if (phi_phase_start[`MUX_ROW]) begin
            ado <= {vic_addr[11:8], vic_addr[7:0] };
        end else if (chip[0] && phi_phase_start[`PAL_MUX_COL]) begin
            ado <= {vic_addr[11:8], {2'b11, vic_addr[13:8]}};
        end else if (~chip[0] && phi_phase_start[`NTSC_MUX_COL]) begin
            ado <= {vic_addr[11:8], {2'b11, vic_addr[13:8]}};
        end else if (phi_phase_start[`CAS_GLITCH]) begin
            // This is the post CAS address change glitch. The 8565 would not
            // do this.  If you want to 'fix' the 6569 bug, remove this block.
            ado <= {vic_addr_now[11:8], {2'b11, vic_addr_now[13:8]}};
        end
    end
    else begin
        // Apparently, if we don't do this at the beginning of our low AEC
        // cycles, we get a lot of noisy address lines near the time the
        // MK2 board wants to pick up the row address. It's not clear why
        // this noise is present in the first place as we should own the
        // bus at the time AEC goes low. So there should be no contention
        // from any other device (i.e. CPU).
        if (phi_phase_start[1])
            ado <= 12'b0;
    end
end

assign cas = chip[0] ? pal_cas : ntsc_cas;
assign ras = chip[0] ? pal_ras : (ntsc_ras_n | ntsc_ras_p);

reg pal_cas;
reg pal_ras;
reg ntsc_cas;
reg ntsc_ras_n;
reg ntsc_ras_p;

always @(posedge clk_col16x)
    if (rst) begin
       pal_cas_ras <= 36'b000000000000000000000000000001000000;
       ntsc_cas_ras <= 28'b0000000000000000000000100000;
    end
    else begin
       pal_cas_ras <= {pal_cas_ras[34:0], pal_cas_ras[35]};
       ntsc_cas_ras <= {ntsc_cas_ras[26:0], ntsc_cas_ras[27]};

       if (pal_cas_ras[`PAL_RAS_RISE])
           pal_ras <= 1'b1;
       else if (pal_cas_ras[`PAL_RAS_FALL])
           pal_ras <= 1'b0;

       if (pal_cas_ras[`PAL_CAS_RISE])
           pal_cas <= 1'b1;
       else if (pal_cas_ras[`PAL_CAS_FALL])
           pal_cas <= 1'b0;

       if (ntsc_cas_ras[`NTSC_RAS_RISE])
           ntsc_ras_p <= 1'b1;
       else if (ntsc_cas_ras[`NTSC_RAS_FALL])
           ntsc_ras_p <= 1'b0;

       if (ntsc_cas_ras[`NTSC_CAS_RISE])
           ntsc_cas <= 1'b1;
       else if (ntsc_cas_ras[`NTSC_CAS_FALL])
           ntsc_cas <= 1'b0;
    end

// We need RAS to rise just after CAS but the NTSC col16x clock is not
// fast enough. One full period (tick) is too long of a delay and
// static ram modules start to fail. So we use the negative edge of the
// clock and or the _p / _n signals to get the delay we need.
always @(negedge clk_col16x)
begin
   if (ntsc_cas_ras[`NTSC_CAS_RISE+1])
           ntsc_ras_n <= 1'b1;
   else if (ntsc_cas_ras[`NTSC_CAS_RISE+3])
           ntsc_ras_n <= 1'b0;
end

endmodule
