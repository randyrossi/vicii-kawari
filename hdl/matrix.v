`timescale 1ns/1ps

`include "common.vh"

// Update matrix counters
module matrix(
   input rst,
   input clk_phi,
   input clk_dot4x,
   input phi_phase_start_1,
   input phi_phase_start_14,
   input [6:0] cycle_num,
   input [8:0] raster_line,
   input badline,
   output reg idle,
   output reg [9:0] vc_base,
   output reg [9:0] vc,
   output reg [2:0] rc
);

// Update rc/vc/vc_base
always @(posedge clk_dot4x)
    if (rst)
    begin
        vc_base <= 10'd0;
        vc <= 10'd0;
        rc <= 3'd7;
        idle = `TRUE;
    end
    else begin
        // This needs to be checked next 4x tick within the phase because
        // badline does not trigger until after raster line has incremented
        // which is after start of line which happens on tick 0 and due to
        // delayed assignment raster line yscroll comparison won't happen until
        // tick 1.
        if (clk_phi && phi_phase_start_1) begin
            // Reset at start of frame
            if (cycle_num == 1 && raster_line == 9'd0) begin
                vc_base <= 10'd0;
                vc <= 10'd0;
            end

            if (cycle_num > 14 && cycle_num < 55 && idle == `FALSE)
                vc <= vc + 1'b1;

            if (cycle_num == 13) begin
                vc <= vc_base;
                if (badline)
                    rc <= 3'd0;
            end

            if (cycle_num == 57) begin
                if (rc == 3'd7) begin
                    vc_base <= vc;
                    idle = `TRUE;
                end
                if (!idle | badline) begin
                    rc <= rc + 1'b1;
                    idle = `FALSE;
                end
            end
        end

        if (clk_phi && phi_phase_start_14) begin
            if (badline)
                idle = `FALSE;
        end
    end

endmodule: matrix
