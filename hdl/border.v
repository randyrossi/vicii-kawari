`timescale 1ns / 1ps

`include "common.vh"

// border on/off logic
module border(
       input rst,
       input clk_dot4x,
	   input clk_phi,
	   input [6:0] cycle_num,
	   input [9:0] xpos,
	   input [8:0] raster_line,
	   input rsel,
	   input csel,
	   input den,
       output reg vborder,
	   output reg main_border
);

reg set_vborder;

always @(posedge clk_dot4x)
begin
    if (rst) begin
        set_vborder = `FALSE;
        main_border = `FALSE;
        vborder = `FALSE;
    end else begin
        if (!clk_phi) begin
           // check hborder
           if ((xpos == 31 && csel == `FALSE) || (xpos == 24 && csel == `TRUE)) begin
              // check vborder bottom
              if ((raster_line == 247 && rsel == `FALSE) || (raster_line == 251 && rsel == `TRUE))
                 set_vborder = 1;
              vborder = set_vborder;
              if (vborder == 0) begin
                 main_border = 0;
              end
           end
           else if ((xpos == 335 && csel == `FALSE) || (xpos == 344 && csel == `TRUE)) begin
              main_border = 1;
           end
        end
        else begin
          // check vborder top
          if (((raster_line == 55 && rsel == `FALSE) || (raster_line == 51 && rsel == `TRUE)) && den) begin
             vborder = 0;
             set_vborder = 0;
          end
          
          // check vborder bottom
          if ((raster_line == 247 && rsel == `FALSE) || (raster_line == 251 && rsel == `TRUE))
             set_vborder = 1;
        
          if (cycle_num == 0)
             vborder = set_vborder;
        end
    end
end

endmodule
