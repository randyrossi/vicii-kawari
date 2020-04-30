`timescale 1ns / 1ps

// Divides clk_in by 4.
module clk_div4(input clk_in, input reset, output reg clk_out);

    reg [1:0] counter;    // for div by 4
    initial
    begin
       counter = 'd2;     // start high
    end

    always @ (posedge clk_in, posedge reset)
    begin
       if (reset == 1'b1)
          counter <= 'd2;     // start high
       else
          counter <= counter + 1'd1;
       clk_out <= counter[1];  // clk / 4
    end

endmodule

// Divides clk_in by 32.
module clk_div32(input clk_in, input reset, output reg clk_out);

    reg [4:0] counter;    // for div by 32

    initial
    begin
       counter = 'd16;     // start high
    end

    always @ (posedge clk_in, posedge reset)
    begin
       if (reset == 1'b1)
          counter <= 'd16;     // start high
       else
          counter <= counter + 1'd1;
       clk_out <= counter[4];    // clk / 32
    end

endmodule
