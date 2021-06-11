`timescale 1ns/1ps

`include "common.vh"

// Additional matrix counters specifically for our hi res
// text mode (80x25).
// NOTE: badline flags does NOT take away CPU cycles in
// hi res mode.  It is only used to identify yscroll matches
// to begin vc increments again.  We could have just as easily
// passed in yscroll but we're keeping the badline condition
// from legacy vic.
module hires_matrix(
           input rst,
           input clk_phi,
           input clk_dot4x,
           input phi_phase_start_1,
           input phi_phase_start_14,
           input [6:0] cycle_num,
           input [8:0] raster_line,
           input hires_badline,
           output reg [10:0] hires_vc,
           output reg [2:0] hires_rc,
           output reg [13:0] hires_fvc // a fast counter for 16k bitmap mode
       );

reg [10:0] hires_vc_base;
reg idle; // I don't know if we ever need to advertise this
reg [7:0] badline_hist;
always @(posedge clk_dot4x)
    if (rst)
    begin
        hires_vc_base <= 11'd0;
        hires_vc <= 11'd0;
        hires_rc <= 3'd7;
        idle = `TRUE;
    end
    else begin
        // In this hi res version, we move our vc counter at twice
        // the rate as normal.  So do this on either hi or lo phase.
        // Must be on [1] for cycle_num to be valid.
        if (phi_phase_start_1) begin
            // Reset at start of frame
            if (clk_phi && cycle_num == 1 && raster_line == 9'd0) begin
                hires_vc_base <= 11'd0;
                hires_vc <= 11'd0;
                hires_fvc <= 14'd0;
            end

            // Increment within the same range (but this happens at 2x)
            // So hires_vc only increments by 80 every 8 rows (within the
            // visible region) while fvc increments by 80 per raster line
            // (within the visible region)
            if (cycle_num > 14 && cycle_num < 55) begin
                if (!idle)
                    hires_vc <= hires_vc + 1'b1;
                if (badline_hist != 0)
                    hires_fvc <= hires_fvc + 1'b1;
            end

            if (clk_phi && cycle_num == 13) begin
                hires_vc <= hires_vc_base;
                if (hires_badline) begin
                    hires_rc <= 3'd0;
                end
                badline_hist <= {badline_hist[6:0], hires_badline};
            end

            // Go to next row at the usual time (only on high phase tho)
            if (clk_phi && cycle_num == 57) begin
                if (hires_rc == 3'd7) begin
                    hires_vc_base <= hires_vc;
                    idle = `TRUE;
                end
                if (!idle | hires_badline) begin
                    hires_rc <= hires_rc + 1'b1;
                    idle = `FALSE;
                end
            end
        end

        if (clk_phi && phi_phase_start_14) begin
            if (hires_badline)
                idle = `FALSE;
        end
    end

endmodule: hires_matrix
