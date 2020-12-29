`timescale 1ns / 1ps

`include "common.vh"

// Address generation
module addressgen(
           //input rst,
           input clk_dot4x,
           input [3:0] cycle_type,
           input [2:0] cb,
           input [9:0] vc,
           input [3:0] vm,
           input [2:0] rc,
           input bmm,
           input ecm,
           input idle,
           input [7:0] refc,
           input [7:0] char_ptr,
           input aec,
           input [2:0] sprite_cnt,
           input [63:0] sprite_ptr_o,
           input [47:0] sprite_mc_o,
           input phi_phase_start_rlh,
           input phi_phase_start_rhl,
           input phi_phase_start_clh,
           input phi_phase_start_chl,
           input phi_phase_start_row,
           input phi_phase_start_col,
           output reg [11:0] ado,
           output reg ras,
           output reg cas
       );

// Destinations for flattened inputs that need to be sliced back into an array
wire [7:0] sprite_ptr[0:`NUM_SPRITES - 1];
wire [5:0] sprite_mc[0:`NUM_SPRITES - 1];

// VIC read address
reg [13:0] vic_addr;

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

always @*
begin
    case(cycle_type)
        `VIC_LR:
            vic_addr = {6'b111111, refc};
        `VIC_LG: begin
            if (idle)
                if (ecm) // ecm
                    vic_addr = 14'h39FF;
                else
                    vic_addr = 14'h3FFF;
            else begin
                if (bmm) // bmm
                    vic_addr = {cb[2], vc, rc}; // bitmap data
                else
                    vic_addr = {cb, char_ptr, rc}; // character pixels
                if (ecm) // ecm
                    vic_addr[10:9] = 2'b00;
            end
        end
        `VIC_HRC, `VIC_HGC:
            vic_addr = {vm, vc}; // video matrix c-access
        `VIC_LP:
            vic_addr = {vm, 7'b1111111, sprite_cnt}; // p-access
        `VIC_HS1, `VIC_LS2, `VIC_HS3:
            if (!aec)
                vic_addr = {sprite_ptr[sprite_cnt], sprite_mc[sprite_cnt]}; // s-access
            else begin
                if (ecm) // ecm
                    vic_addr = 14'h39FF;
                else
                    vic_addr = 14'h3FFF;
            end
        default: begin
            vic_addr = 14'h3FFF;
        end
    endcase
end

// Timing observed
// NTSC:
//       CAS/RAS separated by ~52ns
//       RAS falls ~167ns after PHI edge
//       ADDR mux @ ~38ns after RAS edge

always @(posedge clk_dot4x)
    if (phi_phase_start_rlh)
        ras <= 1'b1;
    else if (phi_phase_start_rhl)
        ras <= 1'b0;

always @(posedge clk_dot4x)
    if (phi_phase_start_clh)
        cas <= 1'b1;
    else if (phi_phase_start_chl)
        cas <= 1'b0;

// Address out
// ROW first, COL second
always @(posedge clk_dot4x) begin
    // a6/a7 on COL is usually 2'b11 because it doesn't matter what we set.
    // The 74LS258 will use VA14 and VA15 when AEC and CAS are low.
    // So instead of a6/a12 and a7/a13 switching, we keep them
    // steady by repeating a6/a7 for col address.  This seems to have no
    // ill effects and might cut down on switching noise.
    if (!aec)
        if (phi_phase_start_row)
            ado <= {vic_addr[11:8], vic_addr[7:0] };
        else if (phi_phase_start_col)
            ado <= {vic_addr[11:8], {vic_addr[7:6], vic_addr[13:8]}};
end

endmodule
