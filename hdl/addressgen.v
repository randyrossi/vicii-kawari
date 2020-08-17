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
           input mux,
           input bmm,
           input ecm,
           input idle,
           input [7:0] refc,
           input [7:0] char_ptr,
           input aec,
           input [2:0] sprite_cnt,
           input [7:0] sprite_ptr[0:`NUM_SPRITES - 1],
           input [5:0] sprite_mc[0:`NUM_SPRITES - 1],
           output reg [11:0] ado
       );

// VIC read address
reg [13:0] vic_addr;
// the lower 8 bits of ado are muxed
reg [7:0] ado8;
always @*
begin
    case(cycle_type)
        VIC_LR:
            vic_addr = {6'b111111, refc};
        VIC_LG: begin
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
        VIC_HRC, VIC_HGC:
            vic_addr = {vm, vc}; // video matrix c-access
        VIC_LP:
            vic_addr = {vm, 7'b1111111, sprite_cnt}; // p-access
        VIC_HS1, VIC_LS2, VIC_HS3:
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

// Address out
// ROW first, COL second
always @(posedge clk_dot4x) begin
    //if (rst)
    //    ado8 <= 8'hFF;
    //else
    ado8 <= mux ? vic_addr[7:0] : {2'b11, vic_addr[13:8]};
end

assign ado = {vic_addr[11:8], ado8};
endmodule
