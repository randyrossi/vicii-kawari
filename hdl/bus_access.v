`timescale 1ns/1ps

`include "common.vh"

// A modules that encapsulates data bus accesses for cycles
// that read from the data bus.
// c-access - character pointer reads
// g-access - bitmap graphics reads
// p-access - sprite pointer reads
// s-access - sprite bitmap graphics reads
module bus_access(
        input rst,
        input clk_dot4x,
        input vic_write_db,
        input phi_phase_start_dav,
        input [3:0] cycle_type,
        input [11:0] dbi,
        input idle,
        input [2:0] sprite_cnt,
        input sprite_dma[0:`NUM_SPRITES - 1],
        output reg [7:0] sprite_ptr[0:`NUM_SPRITES - 1],
        output reg [7:0] pixels_read,
        output reg [11:0] char_read,
        output reg [11:0] char_next,
        output reg [23:0] sprite_pixels [0:`NUM_SPRITES-1]
);

integer n;
// our character line buffer
reg [11:0] char_buf [38:0];

// c-access reads
always @(posedge clk_dot4x)
    if (rst) begin
        char_next <= 12'b0;
        for (n = 0; n < 39; n = n + 1) begin
            char_buf[n] <= 12'hff;
        end
    end else
    if (!vic_write_db && phi_phase_start_dav) begin
        case (cycle_type)
            VIC_HRC, VIC_HGC: // badline c-access
                char_next <= dbi;
            VIC_HRX, VIC_HGI: // not badline idle (char from cache)
                char_next <= char_buf[38];
            default: ;
        endcase

        case (cycle_type)
            VIC_HRC, VIC_HGC, VIC_HRX, VIC_HGI: begin
                for (n = 38; n > 0; n = n - 1) begin
                    char_buf[n] = char_buf[n-1];
                end
                char_buf[0] <= char_next;
            end
            default: ;
        endcase
    end

// g-access reads
always @(posedge clk_dot4x)
begin
     if (rst) begin
        pixels_read <= 8'd0;
        char_read <= 12'd0;
    end else
    if (!vic_write_db && phi_phase_start_dav) begin
        pixels_read <= 8'd0;
        if (cycle_type == VIC_LG) begin // g-access
            pixels_read <= dbi[7:0];
            char_read <= idle ? 12'd0 : char_next;
        end
    end
end

// p-access reads
always @(posedge clk_dot4x)
    if (rst) begin
        for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
            sprite_ptr[n] <= 8'd0;
        end
    end else
    begin
        if (!vic_write_db && phi_phase_start_dav) begin
            case (cycle_type)
                VIC_LP: // p-access
                    if (sprite_dma[sprite_cnt])
                        sprite_ptr[sprite_cnt] <= dbi[7:0];
                    else
                        sprite_ptr[sprite_cnt] <= 8'hff;
                default: ;
            endcase
        end
    end

// s-access reads
always @(posedge clk_dot4x)
//    if (rst) begin
//        for (n = 0; n < `NUM_SPRITES; n = n + 1) begin
//            sprite_pixels[sprite_cnt] <= 23'd0;
//        end
//    end else
    if (!vic_write_db && phi_phase_start_dav) begin
        case (cycle_type)
            VIC_HS1, VIC_LS2, VIC_HS3:
                if (sprite_dma[sprite_cnt])
                    sprite_pixels[sprite_cnt] <= {sprite_pixels[sprite_cnt][15:0], dbi[7:0]};
            default: ;
        endcase
    end

endmodule: bus_access
