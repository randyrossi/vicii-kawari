`timescale 1ns / 1ps

// This intent of this module is to drive the CXA1545P to generate a
// display. It simply excercises the circuitry attached to the r,g,b
// sync and color clock signals. It is not meant to be a functioning
// vicii.  Only a test pattern is generated.
module vicii(
   input reset,
   input clk_dot,
   input clk_phi,
   output reg[1:0] red,
   output reg[1:0] green,
   output reg[1:0] blue,
   output cSync
);

  reg [9:0] x_pos;
  reg [8:0] y_pos;

  wire [2:0] bit_cycle;
  wire [5:0] line_cycle_num;
  wire visible_horizontal;
  wire visible_vertical;
  wire WE;
  reg [2:0] char_line_num;

  assign bit_cycle = x_pos[2:0];
  assign line_cycle_num = x_pos[8:3];
  // Stuff like this won't work in the real core. There is no comparitor controlling
  // when the border is visible like this.
  assign visible_vertical = (y_pos >= 51) & (y_pos < 251) ? 1 : 0;
  // Official datasheet says 28-348 but Christian's doc says 24-344
  assign visible_horizontal = (x_pos >= 24) & (x_pos < 344) ? 1 : 0;
  assign WE = visible_horizontal & visible_vertical & (bit_cycle == 2) & (char_line_num == 0);
          
  always @(posedge clk_dot)
  if (reset)
  begin
    x_pos <= 0;
    y_pos <= 0;
  end
  else if (x_pos < 520) // 64 cycles
    x_pos <= x_pos + 1;
  else
  begin
    x_pos <= 0;
    y_pos <= (y_pos < 262) ? y_pos + 1 : 0; 
  end

  reg [11:0] char_buffer [39:0];
  reg [11:0] char_buffer_out;
  reg [5:0] char_buf_pos;

 always @(posedge clk_dot)
  if (WE)
    begin
      char_buffer[char_buf_pos] <= 12'b000000000000;
      char_buffer_out <= 12'b000000000000;
    end
  else
    char_buffer_out <= char_buffer[char_buf_pos];

  always @(posedge clk_dot)
    if (!visible_vertical)
      char_line_num <= 0;
    else if (x_pos == 384)
      char_line_num <= char_line_num + 1;

  always @(posedge clk_dot)
    if (!visible_vertical)
      char_buf_pos <= 0;
    else if (bit_cycle == 0 & visible_horizontal)
    begin
      if (char_buf_pos < 39)
        char_buf_pos <= char_buf_pos + 1;
      else
        char_buf_pos <= 0;
    end
     
     
  reg [9:0] screen_mem_pos;
  always @(posedge clk_dot)
    if (!visible_vertical)
       screen_mem_pos <= 0;
    else if (bit_cycle == 0 & visible_horizontal & char_line_num == 0)
       screen_mem_pos <= screen_mem_pos + 1;
       
//  always @*
//    if (bit_cycle == 1)
//       addr = {4'b1, screen_mem_pos};     
     
//    always @*
//     if (bit_cycle == 1)
//       addr = {4'b1, screen_mem_pos};
//     else
//       addr = {3'b010,char_buffer_out[7:0],char_line_num};
     
  wire [3:0] out_color;
  wire [3:0] out_pixel;
  reg [7:0] pixel_shift_reg;
  reg [3:0] color_buffered_val;

  assign out_color = pixel_shift_reg[7] == 1 ? color_buffered_val : 4'd6;
  assign out_pixel = visible_vertical & visible_horizontal ? out_color : 4'd14;

  always @(posedge clk_dot)
  if (bit_cycle == 7)
    color_buffered_val <= char_buffer_out[11:8];

  always @(posedge clk_dot)
  if (bit_cycle == 7)
      pixel_shift_reg <= 8'b00000000;  //    pixel_shift_reg <= data[7:0];
  else
      pixel_shift_reg <= {pixel_shift_reg[6:0],1'b0};

   always @*
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
    
    sync vicsync(
       .rst(reset),
       .clk(clk_dot),
       .rasterX(x_pos),
       .rasterY(y_pos),
       .cSync(cSync)
    );
endmodule