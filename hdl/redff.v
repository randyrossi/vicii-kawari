`timescale 1ns/1ps
//
// https://www.fpga4student.com/2017/02/verilog-code-for-d-flip-flop.html
//
module RisingEdge_DFlipFlop_SyncReset(input D,input clk,input SR,output reg Q);
always @(posedge clk)
begin
    if (SR==1'b1)
        Q <= 1'b1;
    else
        Q <= D;
end
endmodule

module RisingEdge_DFlipFlop(input D, input clk,output reg Q);
always @(posedge clk) 
begin
 Q <= D; 
end 
endmodule 