`timescale 1ns/1ps

module RisingEdge_DFlipFlop_SyncReset(input D,input clk,input SR,output reg Q);
always @(posedge clk)
begin
    if (SR==1'b1)
        Q <= 1'b1;
    else
        Q <= D;
end
endmodule
