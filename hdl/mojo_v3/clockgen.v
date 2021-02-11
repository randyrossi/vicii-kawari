`timescale 1ns/1ps

`include "../common.vh"

// For the MojoV3 board.
// This module:
//     1) generates a 4x dot clock for both ntsc and pal clocks
//     2) uses the lower bit of chip to select ntsc/pal clocks
//     3) generates the reset signal and holds for approx 150ms at startup
module clockgen(
           input sys_clock,
           input [1:0] chip,
           output clk_dot4x,
           output rst
       ); 

// 22 = ~150ms
// 27 = ~4s for testing
reg [22:0] rstcntr = 0;
wire internal_rst = !rstcntr[22];

always @(posedge clk_dot4x)
    if (internal_rst)
        rstcntr <= rstcntr + 4'd1;

// Use sys_clock to single pulse the sstep register when we detect we
// are running NTSC.  This reconfigures the PLL_ADV to use different
// mult/div necessary to get as accurate a clock as possible with our
// 50mhz input clock.  If the CPU clock is too far off, some game or demo
// custom loaders will not work.
reg [1:0] set_clock_cntr = 0;
reg sstep;
always @(posedge sys_clock)
begin
    if (chip[0] == 1'b0) begin
       case (set_clock_cntr)
	       2'b00, 2'b01: begin
		       set_clock_cntr <= set_clock_cntr + 1'b1;
          end
		    2'b10: begin
   		    sstep <= 1'b1;
			    set_clock_cntr <= set_clock_cntr + 1'b1;
		    end
		    2'b11: begin
   		    sstep <= 1'b0;
          end
		  endcase
	 end
end

// Generate the 4x dot clock for both standards. See vicii.v for values.
dot4x_50_clockgen dot4x_50_clockgen(
                          .SSTEP(sstep),
                          .CLKIN(sys_clock),    // board 50 Mhz clock
								  .STATE(chip[0]),
                          .RST(1'b0),
                          .CLK0OUT(clk_dot4x),
                          .LOCKED(locked)
                      );

wire running;

// If we are locked and internal reset timer has been reached, then
// we are running.
assign running = locked & internal_rst;

// Synchronize reset to clock
RisingEdge_DFlipFlop_SyncReset ff1(1'b0, clk_dot4x, running, ff1_q);
RisingEdge_DFlipFlop_SyncReset ff2(ff1_q, clk_dot4x, running, rst);

endmodule : clockgen
