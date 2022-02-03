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
// 
// Serializer - does not use any vendor IP so there
// may be limits on how fast clk_pixel_x10 can be
// due to component switching limits.
module serializer
(
    input clk_pixel,
    input clk_pixel_x10,
    input reset,
    input [9:0] tmds_internal0,
    input [9:0] tmds_internal1,
    input [9:0] tmds_internal2,
    output reg [2:0] tmds,
    output reg tmds_clock
);

    reg [9:0] tmds_shift0;
    reg [9:0] tmds_shift1;
    reg [9:0] tmds_shift2;

    // We must capture the data from tmds_internal on every
    // positive edge of the slow clock.  The tmds_control flag
    // toggles each posedge and we will detect transitions on
    // the fast clock to signal load.
    reg tmds_control = 1'd0;
    always @(posedge clk_pixel)
        tmds_control <= !tmds_control;
        
    // Propagate the slow clock load signal onto a shift register
    // using the fast clock.
    reg [9:0] tmds_control_synchronizer_chain = 10'd0;
    always @(posedge clk_pixel_x10)
        tmds_control_synchronizer_chain <= {tmds_control,
            tmds_control_synchronizer_chain[9:1]};

    // Trigger load signal when we see a transition on the shift register.
    // This will latch the data from tmds_internal just as we shift
    // the last bit of the previous data.
    wire load;
    assign load = 
       tmds_control_synchronizer_chain[1] ^ tmds_control_synchronizer_chain[0];

    // Fast clock picks up the data on load signal, just as we finished
    // shifting out the last but from the previous load.
    always @(posedge clk_pixel_x10) begin
       tmds_shift0 <= load ? tmds_internal0 : tmds_shift0 >> 1;
       tmds_shift1 <= load ? tmds_internal1 : tmds_shift1 >> 1;
       tmds_shift2 <= load ? tmds_internal2 : tmds_shift2 >> 1;
    end

    // This is a fast clock generator signal
    reg [9:0] tmds_shift_clk_pixel = 10'b0000011111;
    always @(posedge clk_pixel_x10)
        tmds_shift_clk_pixel <= 
           load ? 10'b0000011111 :
              {tmds_shift_clk_pixel[0], tmds_shift_clk_pixel[9:1]};

    // Final output for both data and clock signals.
    always @(posedge clk_pixel_x10)
    begin
       tmds[0] <= tmds_shift0[0];
       tmds[1] <= tmds_shift1[0];
       tmds[2] <= tmds_shift2[0];
    end

    always @(posedge clk_pixel_x10)
    begin
        tmds_clock <= tmds_shift_clk_pixel[0];
    end
endmodule
