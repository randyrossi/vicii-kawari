// This is a modified DVI encoder module originally
// written by Sameer Puri.  It is a verilog version
// with all HDMI logic removed, hard coded to
// 3 data channels and uses no vendor IP blocks. It
// also uses a 10x pixel to drive serialization rather
// than a 5x clock. It is expected the tmds and
// tmds_clock outputs will be passed to a differential
// buffer (vendor specific).
//
// https://github.com/sameer
module dvi 
#(
)
(
    input  clk_pixel,
    input  clk_pixel_x10,
    input  reset,
    input  [23:0] rgb,
    input  hsync,
    input  vsync,
    input  de,

    output wire [2:0] tmds,
    output wire tmds_clock
);

// We only do DVI, so we only have video/control data.
reg [23:0] video_data = 24'd0;
reg [5:0] control_data = 6'd0;

always @(posedge clk_pixel)
begin
   if (reset)
   begin
      video_data <= 24'd0;
      control_data <= 6'd0;
   end
   else begin
      video_data <= rgb;
      // ctrl3, ctrl2, ctrl1, ctrl0, vsync, hsync
      control_data <= {4'b0000, {vsync, hsync}};
   end
end

// All logic below relates to the production and output of the 10-bit TMDS code.
wire [9:0] tmds_internal0;
wire [9:0] tmds_internal1;
wire [9:0] tmds_internal2;

tmds_channel #(.CN(0)) tmds_channel0 (.clk_pixel(clk_pixel), .video_data(video_data[7:0]), .control_data(control_data[1:0]), .mode(de), .tmds(tmds_internal0));
tmds_channel #(.CN(1)) tmds_channel1 (.clk_pixel(clk_pixel), .video_data(video_data[15:8]), .control_data(control_data[3:2]), .mode(de), .tmds(tmds_internal1));
tmds_channel #(.CN(2)) tmds_channel2 (.clk_pixel(clk_pixel), .video_data(video_data[23:16]), .control_data(control_data[5:4]), .mode(de), .tmds(tmds_internal2));

serializer serializer(.clk_pixel(clk_pixel), .clk_pixel_x10(clk_pixel_x10), .reset(reset), .tmds_internal0(tmds_internal0), .tmds_internal1(tmds_internal1), .tmds_internal2(tmds_internal2), .tmds(tmds), .tmds_clock(tmds_clock));

endmodule
