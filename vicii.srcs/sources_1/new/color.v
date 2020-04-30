`timescale 1ns / 1ps

// Given an indexed color in out_pixel, set red, green and blue values. 
module color(input[9:0] x_pos,
             input [8:0] y_pos,
             input [3:0] out_pixel,
             output reg[1:0] red,
             output reg[1:0] green,
             output reg[1:0] blue);

  // TODO: These ranges are different for PAL and the x_pos limit
  // must match the value in sync.v. Make constants.
  // 416 is start of hsync, give at least 10.9us after hsync for
  // color burst and black level to be output by the composite encoder
  // before outputting pixel changes. Also, 14-22 is vertical sync so
  // don't output during that interval either.
   always @*
   if ((x_pos < 416 || x_pos > 504) && (y_pos < 14 || y_pos > 22))
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
