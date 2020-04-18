`timescale 1ns / 1ps

`define DOT_CLOCK_PERIOD_PS 30550
`define COL_CLOCK_PERIOD_PS 69841

`define DOT_CLOCK_PERIOD_DIV2_PS 15275
`define COL_CLOCK_PERIOD_DIV2_PS 34920

// These used to simulate the 4x dot and 4x col clocks
// using each sys_clock as 1 picosecond. Now, those clocks
// are driven by the verilator test harness instead. These
// modules have no effect anymore but keeping the code
// here anyway. 

module BUFG(input I, output O);
assign O = I;
endmodule

module clockgen (input sys_clock, input reset, output reg clk_dot4x);
/*
reg[15:0] c1;

   initial
   begin
      c1 = 'd0;
   end

   always @ (posedge sys_clock or negedge sys_clock or posedge reset)
   begin
      c1 = c1 + 'd1;

      if (reset == 'b1)
        c1 = 'd0;
      else if (c1 == `DOT_CLOCK_PERIOD_DIV2_PS)
      begin
        c1 = 'd0;
        clk_dot4x = ~clk_dot4x;
      end
   end
*/
endmodule

module clock2gen (input sys_clock, input reset, output reg clk_col4x);
/*
reg[15:0] c1;

   initial
   begin
      c1 = 'd0;
   end

   always @ (posedge sys_clock or negedge sys_clock or posedge reset)
   begin
      c1 = c1 + 'd1;

      if (reset == 'b1)
        c1 = 'd0;
      else if (c1 == `COL_CLOCK_PERIOD_DIV2_PS)
      begin
        c1 = 'd0;
        clk_col4x = ~clk_col4x;
      end
   end
*/
endmodule

