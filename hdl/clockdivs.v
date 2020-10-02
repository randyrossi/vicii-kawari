`timescale 1ns / 1ps

// Divides clk_in by 4.
module clk_div4(input clk_in, input reset, output reg clk_out);

reg [1:0] counter;    // for div by 4
initial
begin
    counter = 'b0;
end

always @ (posedge clk_in)
begin
    if (reset == 1'b1)
        counter <= 'b0;
    else
        counter <= counter + 1'd1;
    clk_out <= counter[1];  // clk / 4
end

endmodule
