`include "common.vh"

// A module to prouce horizontal and vertical sync pulses for VGA output.
// Timings are not standard and may not work on all monitors.

reg [9:0] screen_width;
reg [9:0] screen_height;
reg [9:0] hs_sta;
reg [9:0] hs_end;
reg [9:0] ha_sta;
reg [9:0] vs_sta;
reg [9:0] vs_end;
reg [9:0] va_end;
reg [9:0] hoffset;

// TODO : add voffset that sets vcount to height - offset when rasterx/line first hits 0
                              
module vga_sync(
    input wire clk_dot4x,
    input wire rst,
    input [1:0] chip,
    input dot_rising_0,
    input [9:0] raster_x,
    //input [8:0] raster_y,
    input vic_color pixel_color3,
    output reg hsync,             // horizontal sync
    output reg vsync,             // vertical sync
    output vic_color pixel_color4
 );

    reg vga_active;
    vic_color vga_color;
    reg [9:0] h_count;  // line position
    reg [9:0] v_count;  // screen position
    reg ff = 1'b1;
    
    // generate sync signals active low
    assign hsync = ~((h_count >= hs_sta) & (h_count < hs_end));
    assign vsync = ~((v_count >= vs_sta) & (v_count < vs_end));

    // active: high during active pixel drawing
    assign vga_active = ~((h_count < ha_sta) | (v_count > va_end - 1)); 

    assign pixel_color4 = vga_active ? vga_color : BLACK;

    always @ (posedge clk_dot4x)
    begin
        if (rst)
        begin
            h_count <= 0;
            case (chip)
            CHIP6569, CHIPUNUSED: begin
               screen_width = 503;
               screen_height = 623;
               hs_sta = 16;
               hs_end = 48;
               ha_sta = 65;
               vs_sta = 569 + 11;
               vs_end = 569 + 11 + 3;
               va_end = 569;
               v_count <= 623 - 63; // TODO make adjustable
            end 
            CHIP6567R8: begin
               screen_width = 519;
               screen_height = 525;
               hs_sta = 16;
               hs_end = 48;
               ha_sta = 65;
               vs_sta = 502 + 10;
               vs_end = 502 + 10 + 3;
               va_end = 502;
               v_count <= 525 - 40; // TODO make adjustable
            end
            CHIP6567R56A: begin
               screen_width = 511;
               screen_height = 523;
               hs_sta = 16;
               hs_end = 48;
               ha_sta = 65;
               vs_sta = 502 + 10;
               vs_end = 502 + 10 + 3;
               va_end = 502;
               v_count <= 523 - 40; // TODO make adjustable
            end
            endcase
        end else begin
            ff = ~ff;
            // Increment x/y every other clock for a 2x dot clock in which
            // only our Y dimension is doubled.  Each line from the line
            // buffer is drawn twice.
            if (ff) begin
                if (h_count < screen_width) begin
                   h_count <= h_count + 1;
                end else begin
                   h_count <= 0;
                   if (v_count < screen_height) begin
                      v_count <= v_count + 1;
                   end else begin
                      v_count <= 0;
                   end
                end
            end
        end
    end

// Double buffer, while active_buf is being filled, we draw from filled_buf
// for output.
reg active_buf;

//  Fill active buf while producing pixels from previous line from filled_buf

// Cover the max possible here. Not all may be used depending on chip.
(* ram_style = "block" *) reg [3:0] line_buf_0[519:0];
(* ram_style = "block" *) reg [3:0] line_buf_1[519:0];

always @(posedge clk_dot4x)
begin
   if (!rst) begin
      if (dot_rising_0) begin
         if (raster_x == 0)
            active_buf = ~active_buf;

         // Store pixels into line buf
         if (active_buf)
           line_buf_0[raster_x[9:0]] = pixel_color3;
         else
           line_buf_1[raster_x[9:0]] = pixel_color3;
      end
   end
end

always @(posedge clk_dot4x)
begin
   if (rst) begin
        case (chip)
            CHIP6569, CHIPUNUSED: hoffset = 29;
            CHIP6567R8: hoffset = 32;
            CHIP6567R56A: hoffset = 32;
        endcase
   end else begin
       if (h_count >= hoffset) begin
           vga_color = !active_buf ? vic_color'(line_buf_0[h_count - hoffset]) :
                                     vic_color'(line_buf_1[h_count - hoffset]);
       end else
           vga_color = BLACK;
   end
end

endmodule : vga_sync
