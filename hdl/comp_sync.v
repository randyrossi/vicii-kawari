`include "common.vh"

// A module that produces a luma/chroma signal and
// optionally a composite sync signal for a composite
// encoder IC. At least of HAVE_COMPOSITE_ENCODER or
// GEN_LUMA_CHROMA must be defined.
//
// Luma/Chroma was tested with these resistor values:
//
//     MSB                 LSB
//     499(1%) 1K 2K 4K 8K 16K
//
// Chroma can operate on 3.3V but Luma needs to be closer to 5V
// to match the brightness of the genuine chips. For luma,
// the signals were passed to an additional 74LVC4245 transceiver
// before being passed to the resistor ladder.
module comp_sync(
           input rst,
           input clk_dot4x,
           input clk_col16x,
           input [1:0] chip,
           input [9:0] raster_x,
           input [8:0] raster_y,
`ifdef HAVE_COMPOSITE_ENCODER
           output reg csync,
`endif
`ifdef GEN_LUMA_CHROMA
           input [3:0] pixel_color, // index of pixel color
           output reg [5:0] luma,
           output reg [5:0] chroma,
`endif
`ifdef CONFIGURABLE_LUMAS
			  input [95:0] lumareg_o,
			  input [127:0] phasereg_o,
			  input [47:0] amplitudereg_o,
           input [5:0] blanking_level,
           input [2:0] burst_amplitude,
`endif
           output reg native_active
);

reg [9:0] hsync_start;
reg [9:0] hsync_end;
reg [9:0] hvisible_start;
reg [9:0] burst_start;
reg [8:0] vblank_start;
reg [8:0] vblank_end;
wire hSync;
//wire vSync;

always @(posedge clk_dot4x)
begin
    if ((raster_x < hsync_start || raster_x >= hvisible_start) &&
            (raster_y < vblank_start || raster_y > vblank_end))
        native_active <= 1'b1;
    else
        native_active <= 1'b0;
end

assign hSync = raster_x >= hsync_start && raster_x < hsync_end;
//assign vSync = raster_y >= vblank_start && raster_y < vblank_end;

// NTSC: Each x is ~122.2 ns (.1222 us)
// PAL : Each x is ~126.8 ns (.1268 us)
always @(chip)
case(chip)
    `CHIP6567R8:
    begin
        hsync_start = 10'd409;
        hsync_end = 10'd446;       // +37*.1222 = ~4.52us after hsync_start
        hvisible_start = 10'd497;  // +88*.1222 = ~10.7us after hsync_start
        burst_start = 10'd451;     // +5*.1222  = ~.61us after hsync_end
        vblank_start = 9'd14;
        vblank_end = 9'd22;
    end
    `CHIP6567R56A:
    begin
        hsync_start = 10'd409;
        hsync_end = 10'd446;       // +37*.1222 = ~4.52us after hsync_start
        hvisible_start = 10'd497;  // +88*.1222 = ~10.7us after hsync_start
        burst_start = 10'd451;     // +5*.1222  = ~.61us after hsync_end
        vblank_start = 9'd14;
        vblank_end = 9'd22;
    end
    `CHIP6569, `CHIPUNUSED:
    begin
        hsync_start = 10'd408;
        hsync_end = 10'd444;        // +37*.1269 = ~4.69us after hsync_start
        hvisible_start = 10'd492;   // +84*.1269 = ~10.65us after hsync_start
        burst_start = 10'd449;      // +5*.1269  = ~.63us after hsync_end
        vblank_start = 9'd301;
        vblank_end = 9'd309;
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

// This is a composite sync signal for use by
// an exernal composite encoder.
`ifdef HAVE_COMPOSITE_ENCODER
always @(posedge clk_dot4x)
    if (rst)
        csync <= 1'b0;
    else
    case(raster_y)
        vblank_start:	csync <= ~EQ;
        vblank_start+1:	csync <= ~EQ;
        vblank_start+2:	csync <= ~EQ;
        vblank_start+3:	csync <= ~SE;
        vblank_start+4:	csync <= ~SE;
        vblank_start+5:	csync <= ~SE;
        vblank_start+6:	csync <= ~EQ;
        vblank_start+7:	csync <= ~EQ;
        vblank_start+8:	csync <= ~EQ;
        default:
            csync <= ~hSync;
    endcase
`endif

`ifdef GEN_LUMA_CHROMA

`ifdef AVERAGE_LUMAS
reg [7:0] add_luma;
reg [5:0] prev_luma;
reg [5:0] prev_luma2;
reg [5:0] prev_luma3;
reg [5:0] next_luma;
`endif

// 18 is blanking level - approx 1.29V
`ifdef CONFIGURABLE_LUMAS
`define BLANKING_LEVEL blanking_level
`else
`define BLANKING_LEVEL 6'b010010
`endif

always @(posedge clk_dot4x)
begin
    if (rst)
        luma <= 6'd0;
    else begin
    case(raster_y)
        vblank_start:	luma <= ~EQ ? `BLANKING_LEVEL : 6'd0;
        vblank_start+1:	luma <= ~EQ ? `BLANKING_LEVEL : 6'd0;
        vblank_start+2:	luma <= ~EQ ? `BLANKING_LEVEL : 6'd0;
        vblank_start+3:	luma <= ~SE ? `BLANKING_LEVEL : 6'd0;
        vblank_start+4:	luma <= ~SE ? `BLANKING_LEVEL : 6'd0;
        vblank_start+5:	luma <= ~SE ? `BLANKING_LEVEL : 6'd0;
        vblank_start+6:	luma <= ~EQ ? `BLANKING_LEVEL : 6'd0;
        vblank_start+7:	luma <= ~EQ ? `BLANKING_LEVEL : 6'd0;
        vblank_start+8:	luma <= ~EQ ? `BLANKING_LEVEL : 6'd0;
        default: begin
        `ifdef AVERAGE_LUMAS
            // Average luma over 4 ticks to smooth out transitions
            next_luma = ~hSync ? (~native_active ? `BLANKING_LEVEL : luma1) : 6'd0;
				add_luma = {2'b0,next_luma} + {2'b0,prev_luma} + {2'b0,prev_luma2} + {2'b0,prev_luma3}; // add them
				luma <= add_luma[7:2];  // div 4
				prev_luma <= next_luma;
				prev_luma2 <= prev_luma;
				prev_luma3 <= prev_luma2;
        `else
		      luma <= ~hSync ? (~native_active ? `BLANKING_LEVEL : luma1) : 6'd0;
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
// an additional 3 bits of amplitude.
wire [5:0] luma1;
reg [3:0] phaseCounter;
reg [8:0] prev_raster_y;
wire [2:0] amplitude;
reg [2:0] amplitude2;
reg [2:0] amplitude3;
reg [2:0] amplitude4;
wire [7:0] phaseOffset;

always @(posedge clk_col16x)
begin
    phaseCounter <= phaseCounter + 4'd1;
end

`ifdef CONFIGURABLE_LUMAS
`define BURST_AMPLITUDE burst_amplitude
`else
`define BURST_AMPLITUDE 3'b010 
`endif

reg [3:0] pixel_color_16_1;
reg [3:0] pixel_color_16;
reg [8:0] raster_y_16_1;
reg [8:0] raster_y_16;
reg [9:0] raster_x_16_1;
reg [9:0] raster_x_16;
reg native_active_16_1;
reg native_active_16;
wire vSync_16;

// Handle domain crossing for registers we need from dot4x in a co16x block.
always @(posedge clk_col16x) pixel_color_16_1 <= pixel_color;
always @(posedge clk_col16x) pixel_color_16 <= pixel_color_16_1;
always @(posedge clk_col16x) raster_y_16_1 <= raster_y;
always @(posedge clk_col16x) raster_y_16 <= raster_y_16_1;
always @(posedge clk_col16x) raster_x_16_1 <= raster_x;
always @(posedge clk_col16x) raster_x_16 <= raster_x_16_1;
always @(posedge clk_col16x) native_active_16_1 <= native_active;
always @(posedge clk_col16x) native_active_16 <= native_active_16_1;
assign vSync_16 = raster_y_16 >= vblank_start && raster_y_16 < vblank_end;

reg [7:0] burstCount;
reg [7:0] sineWaveAddr;
reg [10:0] sineROMAddr;
reg in_burst;
reg need_burst;
wire oddline;
assign oddline = raster_y_16[0];

always @(posedge clk_col16x)
begin
    if (raster_y_16 != prev_raster_y) begin
       need_burst = 1;
    end
    prev_raster_y <= raster_y_16;

    if (raster_x_16 >= burst_start && need_burst)
       in_burst = 1;

    if (in_burst)
    begin
       burstCount <= burstCount + 1'b1;
       if (burstCount == 144) begin // 9 periods * 16 samples for one period
          in_burst = 0;
			 need_burst = 0;
			 burstCount <= 0;
       end
    end

    // Use amplitude from table lookup inside active region.  For burst, use
    // 3'b010. Otherwise, amplitude should be 3'b111 representing no
    // amplitude.
    amplitude2 = vSync_16 ? 3'b111 : (native_active_16 ? amplitude : (in_burst ? `BURST_AMPLITUDE : 3'b111));
	 amplitude3 <= amplitude2;
	 amplitude4 <= amplitude3;
    // Figure out the entry within one of the sine wave tables.
	 // For NTSC: Burst phase is always 180 degrees (128 offset)
	 // For PAL: Burst phase alternates between 135 and -135 (96 & 160 offsets).
    sineWaveAddr = {phaseCounter, 4'b0} + (native_active_16 ? phaseOffset : (chip[0] == 0 ? 8'd128 : (oddline ? 8'd160 : 8'd96)));
    // Prefix with amplitude selector. This is our ROM address.
    sineROMAddr <= {amplitude2, sineWaveAddr };

    // Chroma is centered at 32 for no amplitude. (top 6 bits of 256 offset)
    // Make the decision to output chroma or zero level baseed on the amplitude that
    // was used to determine the chroma9 lookup (which was two ticks ago, one tick to set
    // the address and another to get the data)
    chroma <= (amplitude4 == 3'b111) ? 6'd32 : chroma9[8:3];
end

// Retrieve luma from pixel_color index
luma vic_luma(.index(pixel_color),
`ifdef CONFIGURABLE_LUMAS
              .lumareg_o(lumareg_o),
`endif
              .luma(luma1));

// Retrieve wave amplitude from pixel_color index
amplitude vic_amplitude(.clk_col16x(clk_col16x),
                        .index(pixel_color_16),
`ifdef CONFIGURABLE_LUMAS
                        .amplitudereg_o(amplitudereg_o),
`endif
                        .amplitude(amplitude));

// Retrieve wave phase from pixel_color index
phase vic_phase(.clk_col16x(clk_col16x),
                .index(pixel_color_16),
`ifdef CONFIGURABLE_LUMAS
                .phasereg_o(phasereg_o),
`endif
                .phase(phaseOffset),
                .oddline(chip[0] ? oddline : 1'b0));

// Retrieve wave value from addr calculated from amplitude, phaseCounter and
// phaseOffset.
wire [8:0] chroma9;
SINE_WAVES vic_sinewaves(.clk(clk_col16x),
          .addr(sineROMAddr),
			 .dout(chroma9));
`endif  // GEN_LUMA_CHROMA

endmodule : comp_sync
