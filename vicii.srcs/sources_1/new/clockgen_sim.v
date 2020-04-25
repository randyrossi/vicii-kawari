`timescale 1ns / 1ps

// Fake BUFG
module BUFG(input I, output O);
assign O = I;
endmodule

// Fake clockgens
// Clocks are driven from simulator. These do nothing.
module clockgen (input sys_clock, input reset, output reg clk_dot4x);
endmodule

module clock2gen (input sys_clock, input reset, output reg clk_col4x);
endmodule
