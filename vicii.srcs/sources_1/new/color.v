`timescale 1ns / 1ps

// Given an indexed color in out_pixel, set red, green and blue values. 
module color(input [1:0] chip,
             input [9:0] x_pos,
             input [8:0] y_pos,
             input [3:0] out_pixel,
             input [9:0] hSyncStart,
             input [9:0] hVisibleStart,
             input [8:0] vBlankStart,
             input [8:0] vBlankEnd,
             output reg[1:0] red,
             output reg[1:0] green,
             output reg[1:0] blue);

   always @*
   if ((x_pos < hSyncStart || x_pos > hVisibleStart) &&
       (y_pos < vBlankStart || y_pos > vBlankEnd))
     case (out_pixel)
      4'd0:
         begin
            red = 2'h00;
            green = 2'h00;
            blue = 2'h00;
         end
      4'd1:
         begin
            red = 2'h03;
            green = 2'h03;
            blue = 2'h03;
         end
      4'd2:
         begin
            red = 2'h02;
            green = 2'h00;
            blue = 2'h00;
         end
      4'd3:
         begin
            red = 2'h02;
            green = 2'h03;
            blue = 2'h03;
         end
      4'd4:
         begin
            red = 2'h03;
            green = 2'h01;
            blue = 2'h03;
         end
      4'd5:
         begin
            red = 2'h00;
            green = 2'h03;
            blue = 2'h01;
         end
      4'd6:
         begin
            red = 2'h00;
            green = 2'h00;
            blue = 2'h02;
         end
      4'd7:
         begin
            red = 2'h03;
            green = 2'h03;
            blue = 2'h01;
         end
      4'd8:
         begin
            red = 2'h03;
            green = 2'h02;
            blue = 2'h01;
         end
      4'd9:
         begin
            red = 2'h01;
            green = 2'h01;
            blue = 2'h00;
         end
      4'd10:
         begin
            red = 2'h03;
            green = 2'h01;
            blue = 2'h01;
         end
      4'd11:
         begin
            red = 2'h00;
            green = 2'h00;
            blue = 2'h00;
         end
      4'd12:
         begin
            red = 2'h01;
            green = 2'h01;
            blue = 2'h01;
         end
      4'd13:
         begin
            red = 2'h02;
            green = 2'h03;
            blue = 2'h01;
         end
      4'd14:
         begin
            red = 2'h00;
            green = 2'h02;
            blue = 2'h03;
         end
      4'd15:
         begin
            red = 2'h02;
            green = 2'h02;
            blue = 2'h02;
         end
    endcase
  else
    begin
       red = 2'h00;
       green = 2'h00;
       blue = 2'h00;
    end
    
endmodule
