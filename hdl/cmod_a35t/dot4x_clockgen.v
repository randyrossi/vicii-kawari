`timescale 1ns/1ps

module dot4x_clockgen
    (output wire clk_dot4x,
        input wire reset,
        input wire clk_in12mhz,
        output locked
    );
    // Input buffering
    wire clk_in1_clk_wiz_0;
    wire clk_in2_clk_wiz_0;
    IBUF clkin1_ibufg
         (.O(clk_in1_clk_wiz_0),
             .I(clk_in12mhz));

    wire clk_dot4x_clk_wiz_0;

    wire [15:0] do_unused;
    wire drdy_unused;
    wire psdone_unused;
    wire clkfbout_clk_wiz_0;
    wire clkfbout_buf_clk_wiz_0;
    wire clkfboutb_unused;
    wire clkfbstopped_unused;
    wire clkinstopped_unused;
    wire reset_high;

    // TODO: Make clock configurable for PAL / NTSC switching
    // based on CHIP.
    //
    // TODO: 6567R56A timing produces a 15.980khz horizontal frequency
    // which some monitors won't like.  MULT 59.625 and DIV 22.250
    // will produce a 15.701khz frequency which is closer but still
    // has a 'shimmering' effect.

    MMCME2_ADV
    #(.BANDWIDTH("HIGH"),
    .CLKOUT4_CASCADE("FALSE"),
    .COMPENSATION("ZHOLD"),
    .STARTUP_WAIT("FALSE"),
    .DIVCLK_DIVIDE(1),
    .CLKFBOUT_MULT_F(63.750),
    .CLKFBOUT_PHASE(0.000),
    .CLKFBOUT_USE_FINE_PS("FALSE"),
    .CLKOUT0_DIVIDE_F(23.375),
    .CLKOUT0_PHASE(0.000),
    .CLKOUT0_DUTY_CYCLE(0.500),
    .CLKOUT0_USE_FINE_PS("FALSE"),
    .CLKIN1_PERIOD(83.333))
    mmcm_adv_inst
    // Output clocks
    (
        .CLKFBOUT(clkfbout_clk_wiz_0),
        .CLKFBOUTB(clkfboutb_unused),
        .CLKOUT0(clk_dot4x_clk_wiz_0),
        .CLKOUT0B(clkout0b_unused),
        // Input clock control
        .CLKFBIN(clkfbout_buf_clk_wiz_0),
        .CLKIN1(clk_in1_clk_wiz_0),
        .CLKIN2(1'b0),
        // Tied to always select the primary input clock
        .CLKINSEL(1'b1),
        // Ports for dynamic reconfiguration
        .DADDR(7'h0),
        .DCLK(1'b0),
        .DEN(1'b0),
        .DI(16'h0),
        .DO(do_unused),
        .DRDY(drdy_unused),
        .DWE(1'b0),
        // Ports for dynamic phase shift
        .PSCLK(1'b0),
        .PSEN(1'b0),
        .PSINCDEC(1'b0),
        .PSDONE(psdone_unused),
        // Other control and status signals
        .LOCKED(locked),
        .CLKINSTOPPED(clkinstopped_unused),
        .CLKFBSTOPPED(clkfbstopped_unused),
        .PWRDWN(1'b0),
        .RST(reset_high));
    assign reset_high = reset;


    BUFG clkf_buf
         (.O(clkfbout_buf_clk_wiz_0),
             .I(clkfbout_clk_wiz_0));

    BUFG clkout_buf
         (.O(clk_dot4x),
             .I(clk_dot4x_clk_wiz_0));

endmodule
