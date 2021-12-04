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

`define RAS_RISE 0
`define RAS_FALL 5
`define CAS_RISE_P 15 // See below for reason for _P and _N
`define CAS_FALL_P 7
`define CAS_RISE_N 0 // See below for reason for _P and _N
`define CAS_FALL_N 8
`define CAS_GLITCH 10
`define MUX_ROW 3
`define MUX_COL 6

// Address generation
module addressgen(
           //input rst,
           input clk_dot4x,
           input [3:0] cycle_type,
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
           output reg ras,
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
        end `VIC_LG: begin
            if (idle) begin
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
            vic_addr = 14'h3FFF;
            vic_addr_now = vic_addr;
        end
    endcase
end

always @(posedge clk_dot4x)
    if (phi_phase_start[`RAS_RISE])
        ras <= 1'b1;
    else if (phi_phase_start[`RAS_FALL])
        ras <= 1'b0;

// In order to get a better resolution on when
// CAS falls, we generate a CAS signal on both
// positive and negative edges of the clock. Then
// OR them together. This gets RAS to rise on
// the positive edge and fall on the negative edge
// which pushes out the fall by half of our
// 32x dot clock (~15.2ns NTSC, 15.8ns PAL). It
// seems if we move CAS rise away from where it
// is now, we get weird address bus contention
// issues with the CPU (maybe?). So this is done
// to keep CAS rise where it doesn't cause these
// issues but have CAS fall closer to where we
// want it.
reg cas_p;
reg cas_n;
always @(posedge clk_dot4x)
    if (phi_phase_start[`CAS_RISE_P])
        cas_p <= 1'b1;
    else if (phi_phase_start[`CAS_FALL_P])
        cas_p <= 1'b0;

always @(negedge clk_dot4x)
    if (phi_phase_start[`CAS_RISE_N])
        cas_n <= 1'b1;
    else if (phi_phase_start[`CAS_FALL_N])
        cas_n <= 1'b0;

assign cas = cas_p | cas_n;

// Address out
// ROW first, COL second
// Don't bother changing address for COL on refresh cycles
// because it makes no difference.
always @(posedge clk_dot4x) begin
    if (!aec) begin
        if (phi_phase_start[`MUX_ROW]) begin
            ado <= {vic_addr[11:8], vic_addr[7:0] };
        end else if (phi_phase_start[`MUX_COL] && cycle_type != `VIC_LR) begin
            ado <= {vic_addr[11:8], {2'b11, vic_addr[13:8]}};
        end else if (phi_phase_start[`CAS_GLITCH] && cycle_type != `VIC_LR) begin
            // This is the post CAS address change glitch. The 8565 would not
            // do this.  If you want to 'fix' the 6569 bug, remove this block.
            ado <= {vic_addr_now[11:8], {2'b11, vic_addr_now[13:8]}};
        end
    end
end

endmodule
