`include "common.vh"

// NOTE: We reproduce the offscreen white pixel at hvisible_start
// that the real VICII's produces.  You can't see it on CRTs but it
// will show up on upscalers. It can be removed by getting rid of
// the three raster_x == hvisible_start conditions below for luma,
// phase and amplitude.

// Rev 4+ boards have luma sink capabilities to properly
// sink most current during h/v sync periods. Rev 3 board
// couldn't do this and the sync period was too 'hot' but
// still worked on most monitors.
`ifndef REV_3_BOARD
`define HAVE_LUMA_SINK 1
`endif

// A module that produces a luma/chroma signals.
module comp_sync(
           input clk_dot4x,
           input clk_col16x,
           input [9:0] raster_x,
           input [8:0] raster_y,
`ifdef GEN_LUMA_CHROMA
           input white_line,
`ifdef HAVE_LUMA_SINK
           output reg luma_sink,
`endif
           output [5:0] luma_out,
           output reg [5:0] chroma_out,
           input [5:0] lumareg_o, // from registers base on pixel_color3
           input [7:0] phasereg_o, // from registers base on pixel_color3
           input [3:0] amplitudereg_o, // from registers base on pixel_color3
`ifdef CONFIGURABLE_LUMAS
           input [5:0] blanking_level,
           input [3:0] burst_amplitude,
`endif
`endif
           input [1:0] chip
       );

reg [5:0] luma;
reg [9:0] hvisible_end;
reg [9:0] hsync_start;
reg [9:0] hsync_end;
reg [9:0] hvisible_start;
reg [8:0] vvisible_end;
reg [8:0] vblank_start;
reg [8:0] vblank_end;
reg [8:0] vvisible_start;
reg hSync;
reg vSync;
reg native_active;

`ifdef GEN_LUMA_CHROMA
`ifdef HAVE_LUMA_SINK
assign luma_out = ~luma;
`else
assign luma_out = luma;
`endif
`endif

always @(posedge clk_dot4x)
begin
    hSync <= raster_x >= hsync_start && raster_x < hsync_end;
    vSync <= (
              ((raster_y == vblank_start & raster_x >= hsync_start) | raster_y > vblank_start) &
              (raster_y < vblank_end | (raster_y == vblank_end & raster_x < hsync_end))
          );
    native_active <= ~(
                      (raster_x >= hvisible_end & raster_x < hvisible_start) |
                      (
                          ((raster_y == vvisible_end & raster_x >= hvisible_end) | raster_y > vvisible_end) &
                          ((raster_y == vvisible_start & raster_x <= hvisible_start) | raster_y < vvisible_start)
                      )
                  );
end

// NTSC: Each x is ~122.2 ns (.1222 us)
// PAL : Each x is ~126.8 ns (.1268 us)
always @(chip)
case(chip)
    `CHIP6567R8:
    begin
        hvisible_end = 10'd0;
        hsync_start = 10'd8; // hvisible_end+8*.1222 = ~1us
        hsync_end = 10'd45;    // hsync_start+37*.1222 = ~4.52us
        hvisible_start = 10'd96; // hsync_start+88*.1222 = ~10.7us
        vvisible_end = 9'd13;
        vblank_start = 9'd14; // visible_end +9'd1
        vblank_end = 9'd22; // vblank_start + 9'd8;
        vvisible_start = 9'd23; // vblank_end + 9'd1;
    end
    `CHIP6567R56A:
    begin
        hvisible_end = 10'd0;
        hsync_start = 10'd8; // hvisible_end+8*.1222 = ~1us
        hsync_end = 10'd45;    // hsync_start+37*.1222 = ~4.52us
        hvisible_start = 10'd96; // hsync_start+88*.1222 = ~10.7us
        vvisible_end = 9'd13;
        vblank_start = 9'd14; // visible_end +9'd1
        vblank_end = 9'd22; // vblank_start + 9'd8;
        vvisible_start = 9'd23; // vblank_end + 9'd1;
    end
    `CHIP6569R1, `CHIP6569R3:
    begin
        hvisible_end = 10'd0;
        hsync_start = 10'd7;  // hvisible_end+7*.1269 = ~1us
        hsync_end = 10'd44;      // hsync_start+37*.1269 = ~4.69us
        hvisible_start =  10'd91; // hsync_start+84*.1269 = ~10.65us
        vvisible_end = 9'd300;
        vblank_start = 9'd301; // visible_end +9'd1
        vblank_end = 9'd309; // vblank_start + 9'd8;
        vvisible_start = 9'd310; // vblank_end + 9'd1;
    end
endcase

// NTSC
// 2.69us = 2690 ns
// 3.579545 Mhz = 279.3 ns period
// 2690 / 279.3 = 9.6 (need only 9 cycles of color clock)
//
// PAL
// 2.97us = 2970 ns
// 4.43361875 Mhz = 225.5 ns period
// 2970 / 225.5 = 13.1 (need only 9 cycles of color clock)

// Compute Equalization pulses
wire EQ, SE;
EqualizationPulse ueqp1
                  (
                      .raster_x(raster_x),
                      .chip(chip),
                      .EQ(EQ)
                  );

// Compute Serration pulses
SerrationPulse usep1
               (
                   .raster_x(raster_x),
                   .chip(chip),
                   .SE(SE)
               );

`ifdef GEN_LUMA_CHROMA

// Luma level of white burst on first visible pixel
`define WHITE_BURST 6'h3b

// If configurable, use register value.
// Otherwise, hard coded values.
`ifdef CONFIGURABLE_LUMAS
`define BLANKING_LEVEL blanking_level
`else
`ifdef REV_3_BOARD
`define BLANKING_LEVEL 6'd12
`else
`define BLANKING_LEVEL (chip[0] ? 6'h08 : 6'h18)
`endif
`endif

always @(posedge clk_dot4x)
begin
    begin
        case(raster_y)
            vblank_start: begin
               luma <= ~EQ ? `BLANKING_LEVEL : 6'd0;
`ifdef HAVE_LUMA_SINK
               luma_sink <= EQ;
`endif
            end
            vblank_start+1: begin
               luma <= ~EQ ? `BLANKING_LEVEL : 6'd0;
`ifdef HAVE_LUMA_SINK
               luma_sink <= EQ;
`endif
            end
            vblank_start+2: begin
               luma <= ~EQ ? `BLANKING_LEVEL : 6'd0;
`ifdef HAVE_LUMA_SINK
               luma_sink <= EQ;
`endif
            end
            vblank_start+3: begin
               luma <= ~SE ? `BLANKING_LEVEL : 6'd0;
`ifdef HAVE_LUMA_SINK
               luma_sink <= SE;
`endif
            end
            vblank_start+4: begin
               luma <= ~SE ? `BLANKING_LEVEL : 6'd0;
`ifdef HAVE_LUMA_SINK
               luma_sink <= SE;
`endif
            end
            vblank_start+5: begin
               luma <= ~SE ? `BLANKING_LEVEL : 6'd0;
`ifdef HAVE_LUMA_SINK
               luma_sink <= SE;
`endif
            end
            vblank_start+6: begin
               luma <= ~EQ ? `BLANKING_LEVEL : 6'd0;
`ifdef HAVE_LUMA_SINK
               luma_sink <= EQ;
`endif
            end
            vblank_start+7: begin
               luma <= ~EQ ? `BLANKING_LEVEL : 6'd0;
`ifdef HAVE_LUMA_SINK
               luma_sink <= EQ;
`endif
            end
            vblank_start+8: begin
               luma <= ~EQ ? `BLANKING_LEVEL : 6'd0;
`ifdef HAVE_LUMA_SINK
               luma_sink <= EQ;
`endif
            end
            default: begin
                luma <= ~hSync ? (~native_active ? `BLANKING_LEVEL : ((raster_x == hvisible_start && white_line) ? `WHITE_BURST : lumareg_o)) : 6'd0;
`ifdef HAVE_LUMA_SINK
                luma_sink <= hSync;
`endif
            end
        endcase
    end
end

// Phase counter forms the first 4 bits of the index into our
// sine table of 256 entries.  Hence, it takes 16 samples from
// the sine table for every period of our 16x color clock and
// produces a 1x color clock wave.  The wave phase can be shifted
// by applying a phase offset of 8 bits.  The amplitude is selected
// out of the sine wave table rom by prefixing the 8 bits with
// an additional 4 bits of amplitude.
reg [3:0] phaseCounter;
reg [8:0] prev_raster_y;
reg [3:0] amplitude2;
reg [3:0] amplitude3;
reg [3:0] amplitude4;

always @(posedge clk_col16x)
begin
    phaseCounter <= phaseCounter + 4'd1;
end

`define NO_MODULATION 4'b0000

`ifdef CONFIGURABLE_LUMAS
`define BURST_AMPLITUDE burst_amplitude_16
`else
`define BURST_AMPLITUDE 4'd12
`endif
`define BURST_START (chip0_16 ? 10'd49 : 10'd50)

(* async_reg = "true" *) reg [8:0] raster_y_16_1;
(* async_reg = "true" *) reg [8:0] raster_y_16;
(* async_reg = "true" *) reg [9:0] raster_x_16_1;
(* async_reg = "true" *) reg [9:0] raster_x_16;
(* async_reg = "true" *) reg native_active_16_1;
(* async_reg = "true" *) reg native_active_16;
(* async_reg = "true" *) reg vSync_16_1;
(* async_reg = "true" *) reg vSync_16;

// Handle domain crossing for registers we need from dot4x in a co16x block.
always @(posedge clk_col16x) raster_y_16_1 <= raster_y;
always @(posedge clk_col16x) raster_y_16 <= raster_y_16_1;
always @(posedge clk_col16x) raster_x_16_1 <= raster_x;
always @(posedge clk_col16x) raster_x_16 <= raster_x_16_1;
always @(posedge clk_col16x) native_active_16_1 <= native_active;
always @(posedge clk_col16x) native_active_16 <= native_active_16_1;
always @(posedge clk_col16x) vSync_16_1 <= vSync;
always @(posedge clk_col16x) vSync_16 <= vSync_16_1;

reg [7:0] burstCount;
reg [7:0] sineWaveAddr;
reg [11:0] sineROMAddr;
reg in_burst;
reg need_burst;
wire oddline;
assign oddline = raster_y_16[0];

// Handle domain crossing from dot4x to col16x
(* async_reg = "true" *) reg [7:0] phasereg_o2;
(* async_reg = "true" *) reg [7:0] phasereg_16;
always @(posedge clk_col16x) phasereg_o2 <= phasereg_o;
always @(posedge clk_col16x) phasereg_16 <= (raster_x_16 == hvisible_start && white_line_16) ? 8'h0 : phasereg_o2;

(* async_reg = "true" *) reg [3:0] amplitudereg_o2;
(* async_reg = "true" *) reg [3:0] amplitudereg_16;
always @(posedge clk_col16x) amplitudereg_o2 <=  amplitudereg_o;
always @(posedge clk_col16x) amplitudereg_16 <= (raster_x_16 == hvisible_start && white_line_16) ? 4'h0 : amplitudereg_o2;

`ifdef CONFIGURABLE_LUMAS
(* async_reg = "true" *) reg [3:0] burst_amplitude_ms;
(* async_reg = "true" *) reg [3:0] burst_amplitude_16;
always @(posedge clk_col16x) burst_amplitude_ms <=  burst_amplitude;
always @(posedge clk_col16x) burst_amplitude_16 <= burst_amplitude_ms;
`endif

(* async_reg = "true" *) reg chip0_o2;
(* async_reg = "true" *) reg chip0_16;
always @(posedge clk_col16x) chip0_o2 <= chip[0];
always @(posedge clk_col16x) chip0_16 <= chip0_o2;

(* async_reg = "true" *) reg white_line_ms;
(* async_reg = "true" *) reg white_line_16;
always @(posedge clk_col16x) white_line_ms <= white_line;
always @(posedge clk_col16x) white_line_16 <= white_line_ms;

wire [8:0] chroma9;

always @(posedge clk_col16x)
begin
    if (raster_y_16 != prev_raster_y) begin
        need_burst <= 1;
    end
    prev_raster_y <= raster_y_16;

    if (raster_x_16 >= `BURST_START && need_burst)
        in_burst <= 1;

    if (in_burst)
    begin
        burstCount <= burstCount + 1'b1;
        if (burstCount == 144) begin // 9 periods * 16 samples for one period
            in_burst <= 0;
            need_burst <= 0;
            burstCount <= 0;
        end
    end

    // Use amplitude from table lookup inside active region.  For burst, use
    // 4'b0100. Otherwise, amplitude should be 4'b0000 representing no
    // modulation.
    amplitude2 = vSync_16 ?
               `NO_MODULATION :
               (native_active_16 ?
                amplitudereg_16 :
                (in_burst ? `BURST_AMPLITUDE : `NO_MODULATION));

    amplitude3 <= amplitude2;
    amplitude4 <= amplitude3;
    // Figure out the entry within one of the sine wave tables.
    // For NTSC: Burst phase is always 180 degrees (128 offset)
    // For PAL: Burst phase alternates between 135 and -135 (96 & 160 offsets).
    /* verilator lint_off WIDTH */
    sineWaveAddr = {phaseCounter, 4'b0} +
                 (
                     native_active_16 ?
                     (chip0_16 ?
                      (oddline ? 8'd255 - phasereg_16 :  phasereg_16) : /* pal */
                      phasereg_16) :                                    /* ntsc */
                     (chip0_16 ?
                      (oddline ? 8'd160 : 8'd96) :                      /* pal */
                      8'd128                                            /* ntsc */
                     )
                 );
    /* verilator lint_on WIDTH */
    // Prefix with amplitude selector. This is our ROM address.
    sineROMAddr <= {amplitude2, sineWaveAddr };

    // Chroma is centered at 32 for no amplitude. (top 6 bits of 256 offset)
    // Make the decision to output chroma or zero level baseed on the amplitude that
    // was used to determine the chroma9 lookup (which was two ticks ago, one tick to set
    // the address and another to get the data)
    chroma_out <= (amplitude4 == `NO_MODULATION) ? 6'd32 : chroma9[8:3];
end

// Retrieve wave value from addr calculated from amplitude, phaseCounter and
// phaseOffset.
SINE_WAVES vic_sinewaves(.clk(clk_col16x),
                         .addr(sineROMAddr),
                         .dout(chroma9));
`endif  // GEN_LUMA_CHROMA

endmodule
