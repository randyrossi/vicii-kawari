// How much to divide our ticks down to our VCD timescale
#define TICKS_TO_TIMESCALE 1000L

// Convert microseconds to ticks
#define US_TO_TICKS(t) (t * 1000L * 1000L)

// Timescale for VCD output
#define VCD_TIMESCALE "$timescale 1ns $end"

#define NTSC_HALF_4X_DOT_PS 15277     // half the period of 32.727272Mhz
#define NTSC_HALF_4X_COLOR_PS 34921   // half the period of 14.318181Mhz

// Must match fpga design being simulated
#define NTSC_MAX_DOT_X 520                // 64 cycles per line
#define NTSC_MAX_DOT_Y 262

