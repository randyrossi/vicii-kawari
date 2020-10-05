`timescale 1ns/1ps

`include "common.vh"

// Given an indexed color in out_pixel, set 3-bit red, green and blue values.
module color3(
           input [3:0] out_pixel,
           output reg [2:0] red,
           output reg [2:0] green,
           output reg [2:0] blue);

always @*
    case (out_pixel)
        `BLACK:{red, green, blue} = {3'h00, 3'h00, 3'h00 };
        `WHITE:{red, green, blue} = {3'h07, 3'h07, 3'h07 };
        `RED:{red, green, blue} = {3'h03, 3'h01, 3'h01 };
        `CYAN:{red, green, blue} = {3'h03, 3'h05, 3'h05 };
        `PURPLE:{red, green, blue} = {3'h03, 3'h01, 3'h04 };
        `GREEN:{red, green, blue} = {3'h02, 3'h04, 3'h02 };
        `BLUE:{red, green, blue} = {3'h01, 3'h01, 3'h03 };
        `YELLOW:{red, green, blue} = {3'h05, 3'h06, 3'h03 };
        `ORANGE:{red, green, blue} = {3'h03, 3'h02, 3'h01 };
        `BROWN:{red, green, blue} = {3'h02, 3'h01, 3'h00 };
        `PINK:{red, green, blue} = {3'h04, 3'h03, 3'h02 };
        `DARK_GREY:{red, green, blue} = {3'h02, 3'h02, 3'h02 };
        `GREY:{red, green, blue} = {3'h03, 3'h03, 3'h03 };
        `LIGHT_GREEN:{red, green, blue} = {3'h04, 3'h06, 3'h04 };
        `LIGHT_BLUE:{red, green, blue} = {3'h02, 3'h02, 3'h05 };
        `LIGHT_GREY:{red, green, blue} = {3'h04, 3'h04, 3'h04 };
    endcase

endmodule: color3

// Given an indexed color in out_pixel, set 4-bit red, green and blue values.
module color4(
           input [3:0] out_pixel,
           output reg [3:0] red,
           output reg [3:0] green,
           output reg [3:0] blue);

    always @*
        case (out_pixel)
        `BLACK:{red, green, blue} = {4'h00, 4'h00, 4'h00 };
        `WHITE:{red, green, blue} = {4'h0f, 4'h0f, 4'h0f };
        `RED:{red, green, blue} = {4'h06, 4'h03, 4'h02 };
        `CYAN:{red, green, blue} = {4'h07, 4'h0a, 4'h0b };
        `PURPLE:{red, green, blue} = {4'h06, 4'h03, 4'h08 };
        `GREEN:{red, green, blue} = {4'h05, 4'h08, 4'h04 };
        `BLUE:{red, green, blue} = {4'h03, 4'h02, 4'h07 };
        `YELLOW:{red, green, blue} = {4'h0b, 4'h0c, 4'h06 };
        `ORANGE:{red, green, blue} = {4'h06, 4'h04, 4'h02 };
        `BROWN:{red, green, blue} = {4'h04, 4'h03, 4'h00 };
        `PINK:{red, green, blue} = {4'h09, 4'h06, 4'h05 };
        `DARK_GREY:{red, green, blue} = {4'h04, 4'h04, 4'h04 };
        `GREY:{red, green, blue} = {4'h06, 4'h06, 4'h06 };
        `LIGHT_GREEN:{red, green, blue} = {4'h09, 4'h0d, 4'h08 };
        `LIGHT_BLUE:{red, green, blue} = {4'h06, 4'h05, 4'h0b };
        `LIGHT_GREY:{red, green, blue} = {4'h09, 4'h09, 4'h09 };
      endcase
    
endmodule: color4
