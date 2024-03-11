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

// PAL CAS/RAS rise/fall times based on PAL clocks
`define PAL_D4X_RAS_RISE_P 0
`define PAL_D4X_CAS_RISE_P 15
`define PAL_D4X_CAS_RISE_N 1
`define PAL_D4X_RAS_FALL_P 4
`define PAL_D4X_CAS_FALL_P 6
`define PAL_D4X_CAS_FALL_N 7

`define PAL_C16X_RAS_RISE_N 0
`define PAL_C16X_RAS_FALL_N 3
`define PAL_C16X_CAS_RISE_P 1
`define PAL_C16X_CAS_FALL_P 2

`define PAL_D4X_MUX_COL_P 5

// NTSC CAS/RAS rise/fall times based on NTSC clocks
`define NTSC_D4X_RAS_RISE_P 0
`define NTSC_D4X_CAS_RISE_P 15
`define NTSC_D4X_CAS_RISE_N 1
`define NTSC_D4X_RAS_FALL_P 4
`define NTSC_D4X_CAS_FALL_P 6
`define NTSC_D4X_CAS_FALL_N 7

`define NTSC_C16X_RAS_RISE_N 0
`define NTSC_C16X_RAS_FALL_N 3
`define NTSC_C16X_CAS_RISE_P 1
`define NTSC_C16X_CAS_FALL_P 2

`define NTSC_D4X_MUX_COL_P 5

// Other:
// NOTE: CAS_GLITCH [9] has worked the best for emulamer demos. Works well on
// both DRAM and static RAM. [10] starts to miss pixels on static RAM.  With
// [11] the characters will completely disappear.
`define D4X_CAS_GLITCH_P 9
// This can be this early because we calculate vic_addr in the same process
// block as where ado is set.  It can't be earlier because cycle type needs
// to be valid and it doesn't become valid until at least [2].
`define D4X_MUX_ROW_P 2

// Address generation
module addressgen(
           input rst,
           input [1:0] chip,
           input clk_dot4x,
           input clk_col16x,
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
           output ras_registers,
           output cas
       );

// Destinations for flattened inputs that need to be sliced back into an array
wire [7:0] sprite_ptr[0:`NUM_SPRITES - 1];
wire [5:0] sprite_mc[0:`NUM_SPRITES - 1];

// VIC read address
reg [13:0] vic_addr;
// Used to implement the post CAS bmm transition glitch. See above.
reg [13:0] vic_addr_now;


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
        if (phi_phase_start[`D4X_MUX_ROW_P]) begin
            ado <= {vic_addr[11:8], vic_addr[7:0] };
        end else if (chip[0] && phi_phase_start[`PAL_D4X_MUX_COL_P]) begin
            ado <= {vic_addr[11:8], {2'b11, vic_addr[13:8]}};
        end else if (~chip[0] && phi_phase_start[`NTSC_D4X_MUX_COL_P]) begin
            ado <= {vic_addr[11:8], {2'b11, vic_addr[13:8]}};
        end else if (phi_phase_start[`D4X_CAS_GLITCH_P]) begin
            // This is the post CAS address change glitch. The 8565 would not
            // do this.  If you want to 'fix' the 6569 bug, remove this block.
            ado <= {vic_addr_now[11:8], {2'b11, vic_addr_now[13:8]}};
        end
    end
    else begin
        // Apparently, if we don't do this at the beginning of our low AEC
        // cycles, we get a lot of noisy address lines near the beginning
        // of the cycle. Not sure why this noise is present in the first place
        // as we should own the bus at the time AEC goes low. So there should
        // be no contention from any other device (i.e. CPU).
        if (phi_phase_start[1])
            ado <= 12'b0;
    end
end

reg pal_cas_d4x_p;
reg pal_cas_d4x_n;
reg pal_ras_d4x_p;
reg ntsc_cas_d4x_p;
reg ntsc_cas_d4x_n;
reg ntsc_ras_d4x_p;

reg pal_cas_c16x_p;
reg pal_ras_c16x_n;
reg ntsc_cas_c16x_p;
reg ntsc_ras_c16x_n;

reg [35:0] pal_sr;
reg [27:0] ntsc_sr;

// See CAS_RAS_CLOCKS.txt for an explanation of what this is.
always @(posedge clk_col16x)
begin
    if (rst) begin
       pal_sr <= 36'b000000000000000000000000000001000000;
    end
    else begin
       pal_sr <= {pal_sr[34:0], pal_sr[35]};
    end
end

always @(posedge clk_col16x)
begin
    if (rst) begin
       ntsc_sr <= 28'b0000000000000000000000100000;
    end
    else begin
       ntsc_sr <= {ntsc_sr[26:0], ntsc_sr[27]};
    end
end

// Use dot4x and handle CAS/RAS rise/fall points.
always @(posedge clk_dot4x)
begin
       if (phi_phase_start[`PAL_D4X_RAS_RISE_P])
           pal_ras_d4x_p <= 1'b1;
       else if (phi_phase_start[`PAL_D4X_RAS_FALL_P])
           pal_ras_d4x_p <= 1'b0;

       if (phi_phase_start[`PAL_D4X_CAS_RISE_P])
           pal_cas_d4x_p <= 1'b1;
       else if (phi_phase_start[`PAL_D4X_CAS_FALL_P])
           pal_cas_d4x_p <= 1'b0;

       if (phi_phase_start[`NTSC_D4X_RAS_RISE_P])
           ntsc_ras_d4x_p <= 1'b1;
       else if (phi_phase_start[`NTSC_D4X_RAS_FALL_P])
           ntsc_ras_d4x_p <= 1'b0;

       if (phi_phase_start[`NTSC_D4X_CAS_RISE_P])
           ntsc_cas_d4x_p <= 1'b1;
       else if (phi_phase_start[`NTSC_D4X_CAS_FALL_P])
           ntsc_cas_d4x_p <= 1'b0;
end

always @(negedge clk_dot4x)
begin
    if (phi_phase_start[`NTSC_D4X_CAS_RISE_N])
        ntsc_cas_d4x_n <= 1'b1;
    else if (phi_phase_start[`NTSC_D4X_CAS_FALL_N])
        ntsc_cas_d4x_n <= 1'b0;

    if (phi_phase_start[`PAL_D4X_CAS_RISE_N])
        pal_cas_d4x_n <= 1'b1;
    else if (phi_phase_start[`PAL_D4X_CAS_FALL_N])
        pal_cas_d4x_n <= 1'b0;
end


// The rise times from above are not sufficient to
// accurately reproduce the timing of the real chip.
// We need to use a higher resolution clock and use
// it's positive and negative edges to shape our
// rise times a bit.  These two process blocks
// calculate a higher resolution pulse that we then
// OR with the ones above to get the rise times
// we want.  NOTE: If ras rises too far after cas,
// static ram modules barf.  DRAM doesn't seem to
// care though.


always @(negedge clk_col16x)
begin
   if (pal_sr[`PAL_C16X_RAS_RISE_N])
           pal_ras_c16x_n <= 1'b1;
   else if (pal_sr[`PAL_C16X_RAS_FALL_N])
           pal_ras_c16x_n <= 1'b0;
   if (ntsc_sr[`NTSC_C16X_RAS_RISE_N])
           ntsc_ras_c16x_n <= 1'b1;
   else if (ntsc_sr[`NTSC_C16X_RAS_FALL_N])
           ntsc_ras_c16x_n <= 1'b0;
end

always @(posedge clk_col16x)
begin
   if (pal_sr[`PAL_C16X_CAS_RISE_P])
           pal_cas_c16x_p <= 1'b1;
   else if (pal_sr[`PAL_C16X_CAS_FALL_P])
           pal_cas_c16x_p <= 1'b0;
   if (ntsc_sr[`NTSC_C16X_CAS_RISE_P])
           ntsc_cas_c16x_p <= 1'b1;
   else if (ntsc_sr[`NTSC_C16X_CAS_FALL_P])
           ntsc_cas_c16x_p <= 1'b0;
end

// Use the trick above to OR the two signals together. This results
// in the first pulse of the faster clock 'extending' the cas/ras signals
// on the rising edges to what we want them to look like.

assign cas = chip[0] ? (pal_cas_d4x_p | pal_cas_d4x_n | pal_cas_c16x_p) : (ntsc_cas_d4x_p | ntsc_cas_d4x_n | ntsc_cas_c16x_p);
assign ras = chip[0] ? (pal_ras_d4x_p | pal_ras_c16x_n) : (ntsc_ras_d4x_p | ntsc_ras_c16x_n);

// This goes to the registers module and is only driven by dot4x. Avoids having
// to use a synchronizer chain.
assign ras_registers = chip[0] ? pal_ras_d4x_p : ntsc_ras_d4x_p;

endmodule
