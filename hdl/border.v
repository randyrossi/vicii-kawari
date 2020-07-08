`timescale 1ns / 1ps

`include "common.vh"

// border on/off logic
module border(
       input rst,
       input clk_dot4x,
	   input dot_rising_0,
	   input [9:0] xpos,
	   input [8:0] raster_line,
	   input rsel,
	   input csel,
	   input den,
       output reg top_bot_border,
	   output reg left_right_border
);

reg new_top_bot_border = `FALSE;

always @(raster_line, rsel, den, top_bot_border)
begin
    new_top_bot_border = top_bot_border;
    if (raster_line == 55 && den == `TRUE)
        new_top_bot_border = `FALSE;

    if (raster_line == 51 && rsel == `TRUE && den == `TRUE)
        new_top_bot_border = `FALSE;

    if (raster_line == 247 && rsel == `FALSE)
        new_top_bot_border = `TRUE;

    if (raster_line == 251 && rsel == `TRUE)
        new_top_bot_border = `TRUE;
end

always @(posedge clk_dot4x)
begin
    if (rst) begin
        left_right_border <= `FALSE;
        top_bot_border <= `FALSE;
    end else if (dot_rising_0) begin
        if (xpos == 32 && csel == `FALSE) begin
            left_right_border <= new_top_bot_border;
            top_bot_border <= new_top_bot_border;
        end
        if (xpos == 25 && csel == `TRUE) begin
            left_right_border <= new_top_bot_border;
            top_bot_border <= new_top_bot_border;
        end

        if (xpos == 336 && csel == `FALSE)
            left_right_border <= `TRUE;

        if (xpos == 345 && csel == `TRUE)
            left_right_border <= `TRUE;
    end
end

endmodule
