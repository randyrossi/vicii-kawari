`timescale 1ns / 1ps

// The div4 clock is used to get dot from dot4x.
// We start dot high so that rising edge of the
// slower clock aligns with the rising edge of
// the faster clock.

// F=fast clock high, f = fast clock low
// S=slow clock high, s = slow clocl low
// FfFfFfFfFfFfFfFf
// SSssSSssSSssSSss

// Divides clk_in by 4.
module clk_div4(input clk_in, input reset, output reg clk_out);

    reg [1:0] counter;    // for div by 4
    initial
    begin
       counter = 'b10;
    end

    always @ (posedge clk_in, posedge reset)
    begin
       if (reset == 1'b1)
          counter <= 'b10;
       else
          counter <= counter + 1'd1;
       clk_out <= counter[1];  // clk / 4
    end

endmodule

// The div32 clock is used to get phi from dot4x.
// We start phi LOW and since our first tick brings
// our state machine to pixel 1 (not 0), we need to
// start 1/4 the way through that first LOW phase.
// So we start the counter at 00100 (8 / 32). So
// 24 ticks is expected (or 3 more dot pixels) until
// phi goes HIGH.

// Divides clk_in by 32.
module clk_div32(input clk_in, input reset, output reg clk_out);

    reg [4:0] counter;    // for div by 32

    initial
    begin
       counter = 'b00100;
    end

    always @ (posedge clk_in, posedge reset)
    begin
       if (reset == 1'b1)
          counter <= 'b00100;
       else
          counter <= counter + 1'd1;
       clk_out <= counter[4];    // clk / 32
    end

endmodule
