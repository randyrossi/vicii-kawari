`timescale 1ns/1ps


// Given an indexed color in out_pixel, set red, green and blue values. 
module color(
    input chip_type chip,
    input wire [9:0] x_pos,
    input wire [8:0] y_pos,
    input vic_color out_pixel,
    input wire [9:0] hSyncStart,
    input wire [9:0] hVisibleStart,
    input wire [8:0] vBlankStart,
    input wire [8:0] vBlankEnd,
    output reg [1:0] red,
    output reg [1:0] green,
    output reg [1:0] blue);

    always @*
        if ((x_pos < hSyncStart || x_pos > hVisibleStart) &&
            (y_pos < vBlankStart || y_pos > vBlankEnd))
            case (out_pixel)
                BLACK: {red, green, blue} = {2'h00, 2'h00, 2'h00};
                WHITE: {red, green, blue} = {2'h03, 2'h03, 2'h03};
                RED: {red, green, blue} = {2'h02, 2'h00, 2'h00};
                CYAN: {red, green, blue} = {2'h02, 2'h03, 2'h03};
                PURPLE: {red, green, blue} = {2'h03, 2'h01, 2'h03};
                GREEN: {red, green, blue} = {2'h00, 2'h03, 2'h01};
                BLUE: {red, green, blue} = {2'h00, 2'h00, 2'h02};
                YELLOW: {red, green, blue} = {2'h03, 2'h03, 2'h01};
                ORANGE: {red, green, blue} = {2'h03, 2'h02, 2'h01};
                BROWN: {red, green, blue} = {2'h01, 2'h01, 2'h00};
                PINK: {red, green, blue} = {2'h03, 2'h01, 2'h01};
                DARK_GREY: {red, green, blue} = {2'h00, 2'h00, 2'h00};
                GREY: {red, green, blue} = {2'h01, 2'h01, 2'h01};
                LIGHT_GREEN: {red, green, blue} = {2'h02, 2'h03, 2'h01};
                LIGHT_BLUE: {red, green, blue} = {2'h00, 2'h02, 2'h03};
                LIGHT_GREY: {red, green, blue} = {2'h02, 2'h02, 2'h02};
            endcase
        else
            {red, green, blue} = {2'h00, 2'h00, 2'h00};

endmodule: color
