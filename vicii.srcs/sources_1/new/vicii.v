`timescale 1ns / 1ps

module vicii(
   input [1:0] chip,
   input rst,
   input clk_dot4x,
   input clk_col4x,
   output clk_phi,
   output clk_colref,
   output[1:0] red,
   output[1:0] green,
   output[1:0] blue,
   output cSync,
   inout [11:0] ad,
   output reg [11:0] dbo,
   input [11:0] dbi,
   input ce,
   input rw,
   output irq,
   output aec,
   output reg ba,
   
   // xpos is exposed for simulation verification
   output reg [9:0] xpos
);

parameter CHIP6567R8   = 2'd0;
parameter CHIP6567R56A = 2'd1;
parameter CHIP6569     = 2'd2;
parameter CHIPUNUSED   = 2'd3;

// Limits for different chips
reg [9:0] rasterXMax;
reg [8:0] rasterYMax;
reg [9:0] hSyncStart;
reg [9:0] hSyncEnd;
reg [9:0] hVisibleStart;
reg [8:0] vBlankStart;
reg [8:0] vBlankEnd;

//clk_dot4x;     32.272768 Mhz NTSC
//clk_col4x;     14.381818 Mhz NTSC
wire clk_dot;  // 8.18181 Mhz NTSC
// clk_colref     3.579545 Mhz NTSC
// clk_phi        1.02272 Mhz NTSC

// Set Limits
always @(chip)
case(chip)
CHIP6567R8:
   begin
      rasterXMax = 10'd519;     // 520 pixels 
      rasterYMax = 9'd261;      // 262 lines
      hSyncStart = 10'd416;
      hSyncEnd = 10'd453;      // 4.6us
      hVisibleStart = 10'd504; // 10.7us after hSyncStart seems to work
      vBlankStart = 9'd14;
      vBlankEnd = 9'd22;
   end
CHIP6567R56A:
   begin
      rasterXMax = 10'd511;    // 512 pixels
      rasterYMax = 9'd260;     // 261 lines
      hSyncStart = 10'd416;
      hSyncEnd = 10'd453;      // 4.6us
      hVisibleStart = 10'd504; // 10.7us after hSyncStart seems to work
      vBlankStart = 9'd14;
      vBlankEnd = 9'd22;
   end
CHIP6569,CHIPUNUSED:
   begin
      rasterXMax = 10'd503;    // 504 pixels
      rasterYMax = 9'd311;     // 312
      hSyncStart = 10'd408;
      hSyncEnd = 10'd444;      // ~4.6us
      hVisibleStart = 10'd492; // ~10.7 after hSyncStart
      vBlankStart = 9'd301;
      vBlankEnd = 9'd309;
   end
endcase

  clk_div4 clk_colorgen (
     .clk_in(clk_col4x),     // from 4x color clock
     .reset(rst),
     .clk_out(clk_colref)    // create color ref clock
  );

  clk_div32 clk_phigen (
     .clk_in(clk_dot4x),     // from 4x dot clock
     .reset(rst),
     .clk_out(clk_phi)       // create phi clock
  );

  clk_div4 clk_dotgen (
     .clk_in(clk_dot4x),    // from 4x dot clock
     .reset(rst),
     .clk_out(clk_dot)      // create dot clock
  );

  // current raster x and line position
  reg [9:0] raster_x;
  reg [8:0] raster_line;

  // cycle_num : Each cycle is 8 pixels.
  // 6567R56A : 0-63
  // 6567R8   : 0-64
  // 6569     : 0-62
  wire [6:0] cycle_num;

  // bit_cycle : The pixel number within the line cycle.
  // 0-7
  wire [2:0] bit_cycle;

  // char_line_num : For text mode, what character line are we on.
  reg [2:0] char_line_num;

  // ec : border (edge) color
  reg [3:0] ec;
  // b#c : background color registers
  reg [3:0] b0c,b1c,b2c,b3c;
  reg [3:0] mm0,mm1;
  
  // Temporary
  wire visible_horizontal;
  wire visible_vertical;
  wire WE;

  initial
  begin
    raster_x = 0;
    raster_line = 0;
  end

  // The bit_cycle (0-7) is taken from the raster_x
  assign bit_cycle = raster_x[2:0];
  // This is simply raster_x divided by 8.
  assign cycle_num = raster_x[9:3];

  // We have to calc out xpos (see below)
  wire [9:0] raster_xpos;
  cycles cycle_to_xpos(
     .chip(chip),
     .super_cycle({cycle_num, raster_x[2]}),
     .xpos(raster_xpos)
  );
  
  // the raster x relative to raster IRQ
  wire [9:0] raster_x_rel;  
  assign raster_x_rel = {raster_xpos[9:2], bit_cycle[1:0]};
  
  // Stuff like this won't work in the real core. There is no comparitor controlling
  // when the border is visible like this.
  assign visible_vertical = (raster_line >= 51) & (raster_line < 251) ? 1 : 0;
  // Official datasheet says 28-348 but Christian's doc says 24-344
  assign visible_horizontal = (raster_x_rel >= 24) & (raster_x_rel < 344) ? 1 : 0;
  assign WE = visible_horizontal & visible_vertical & (bit_cycle == 2) & (char_line_num == 0);

  // xpos is the xposition at the start of either a high or low
  // phi phase.  There are 4 positions between each
  // xpos position.  It is used to construct the raster_x_rel
  // which is the x position relative to raster irq.  raster_x_rel
  // is not simply raster_x with an offset, it does not increment
  // on certain cycles for one of the chips.
  // We expose xpos for debugging/verification from sim_main.cpp
  always @(posedge clk_dot)
  begin
     xpos <= raster_xpos;
  end

  // Update x,y position
  always @(posedge clk_dot)
  if (rst)
  begin
    raster_x <= 0;
    raster_line <= 0;
  end
  else if (raster_x < rasterXMax)
  begin
    raster_x <= raster_x + 1;
  end
  else
  begin
    raster_x <= 0;
    raster_line <= (raster_line < rasterYMax) ? raster_line + 1 : 0;
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
    else if (raster_x == 384)
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

  assign out_color = pixel_shift_reg[7] == 1 ? color_buffered_val : b0c; // 4'd6
  assign out_pixel = visible_vertical & visible_horizontal ? out_color : ec; // 4'd14

  always @(posedge clk_dot)
  if (bit_cycle == 7)
    color_buffered_val <= char_buffer_out[11:8];

  always @(posedge clk_dot)
  if (bit_cycle == 7)
      pixel_shift_reg <= 8'b00000000;  //    pixel_shift_reg <= data[7:0];
  else
      pixel_shift_reg <= {pixel_shift_reg[6:0],1'b0};

  // Translate out_pixel (indexed) to RGB values
  color viccolor(
     .chip(chip),
     .x_pos(raster_x_rel),
     .y_pos(raster_line),
     .out_pixel(out_pixel),
     .hSyncStart(hSyncStart),
     .hVisibleStart(hVisibleStart),
     .vBlankStart(vBlankStart),
     .vBlankEnd(vBlankEnd),
     .red(red),
     .green(green),
     .blue(blue)
  );

  // Generate cSync signal
  sync vicsync(
     .chip(chip),
     .rst(rst),
     .clk(clk_dot),
     .rasterX(raster_x_rel),
     .rasterY(raster_line),
     .hSyncStart(hSyncStart),
     .hSyncEnd(hSyncEnd),
     .cSync(cSync)
  );
  
// Register Read/Write
always @(posedge clk_dot)
if (rst) begin
end
else begin
 if (!ce) begin
   // READ
   if (clk_phi && rw) begin
      dbo <= 12'hFF;
      case(ad[5:0])
      6'h20:  dbo[3:0] <= ec;
      6'h21:  dbo[3:0] <= b0c;
      default:  dbo <= 12'hFF;
      endcase
   end
   // WRITE
   else if (!rw) begin
      case(ad[5:0])
      6'h20:  ec = dbi[3:0];
      6'h21:  b0c = dbi[3:0];
      default: ec = ec;
      endcase
   end
 end
end
  
endmodule