`timescale 1ns / 1ps

`include "common.vh"

// For our hires 80 column mode, we don't need another cycle type
// counter.  We can re-use the VIC's by fetching chars, pixels and
// colors all within each half cycle of phi.  We can access
// our dedicated video ram at a much highr speed and we don't have to
// share it with the CPU.  So we will fetch these 3 pieces of info on
// C and G cycles regardless of their type.  So that means we fetch on:
// VIC_LG, VIC_HRC, VIC_HGC, VIC_HGI & VIC_HRX. Any other cycle type
// is unused (but could be used for other things later)
// This module not only generates the addresses, but it also handles
// fetching the data read from video memory. The data is then handed
// to the pixel sequencer.

module hires_addressgen
           #(
           parameter ram_width = `VIDEO_RAM_WIDTH
           )
           (
           input clk_dot4x,
           input clk_phi,
	   input [15:0] phi_phase_start,
           input [6:0] cycle_num,
           input [2:0] char_pixel_base,
           input [3:0] matrix_base,
           input [3:0] color_base,
           input [2:0] rc,
           input [10:0] vc,
           input [14:0] fvc,
           input char_case, // this comes from the existing cb[0]
           output reg [ram_width-1:0] video_mem_addr, // extended video ram address
	   input [7:0] video_mem_data,
	   input [1:0] hires_mode,
	   output reg [7:0] hires_pixel_data,
	   output reg [7:0] hires_color_data
       );

always @(posedge clk_dot4x)
begin
    if ((cycle_num == 14 && clk_phi) ||
	    (cycle_num > 14 && cycle_num < 54) ||
                    (cycle_num == 54 && ~clk_phi)) begin
            // Note, it takes 2 cycles from the time we set
	    // an address for block ram to have set our data.
            // On [2] set color addr for fetch on [4]
	    // On [4] set char ptr addr for fetch on [6]
            // On [6] set char pixel addr for fetch on [8]
	    if (phi_phase_start[2])
                case (hires_mode)
		2'b00:
		   // TEXT mode
                   video_mem_addr <= {`BIT_EXT_64K color_base, vc};
                2'b01:
                   // 16k Bitmap 2k color mode
                   video_mem_addr <= {`BIT_EXT_64K color_base, vc};
                2'b10, 2'b11:
                   // 32k Bitmap modes, 1st pixel data byte fetch
                   video_mem_addr <= {`BIT_EXT2_64K fvc};
                endcase
	    else if (phi_phase_start[4]) begin
                video_mem_addr <= {`BIT_EXT_64K matrix_base, vc};
                // For modes 10 and 11, this is pixel data
		hires_color_data <= video_mem_data;
            end else if (phi_phase_start[6]) begin
		case (hires_mode)
		2'b00:
		   // TEXT mode pixel fetch
                   // No need to store the char ptr. We fetch it every
		   // time anyway.
                   video_mem_addr <= {`BIT_EXT_64K char_pixel_base,
                                      char_case |
                                      hires_color_data[`HIRES_ALTC_BIT],
                                      video_mem_data, rc};
                2'b01:
                   // 16k Bitmap mode pixel fetch. Take 14:1 for 16k counter.
                   video_mem_addr <= {`BIT_EXT3_64K fvc[14:1]};
                2'b10, 2'b11:
                   // 32k Bitmap modes, 2nd byte pixel data fetch.
                   video_mem_addr <= {`BIT_EXT2_64K fvc | 15'b1};
                endcase
	    end else if (phi_phase_start[8])
		hires_pixel_data <= video_mem_data;  // ready by 10
        end
end

endmodule
