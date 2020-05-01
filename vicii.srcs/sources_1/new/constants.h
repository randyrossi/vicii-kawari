// How much to divide our ticks down to our VCD timescale
#define TICKS_TO_TIMESCALE 1000L

// Convert microseconds to ticks
#define US_TO_TICKS(t) (t * 1000L * 1000L)

// Timescale for VCD output
#define VCD_TIMESCALE "$timescale 1ns $end"

#define CHIP6567R8   0
#define CHIP6567R56A 1
#define CHIP6569     2
#define CHIPUNUSED   3

// Dot 8.1818181
// Color 3.579545
#define NTSC_HALF_4X_DOT_PS 15277     // half the period of 32.727272Mhz
#define NTSC_HALF_4X_COLOR_PS 34921   // half the period of 14.318181Mhz

// Dot 7.8819888
// Color 4.43361875
#define PAL_HALF_4X_DOT_PS 15859     // half the period of 31.527955Mhz
#define PAL_HALF_4X_COLOR_PS 28194   // half the period of 17.734475Mhz

// Must match fpga design being simulated
#define NTSC_6567R56A_MAX_DOT_X 520   // 64 cycles per line
#define NTSC_6567R56A_MAX_DOT_Y 262

#define NTSC_6567R8_MAX_DOT_X 512     // 63 cycles per line
#define NTSC_6567R8_MAX_DOT_Y 261

#define NTSC_6569_MAX_DOT_X 504       // 62 cycles per line
#define NTSC_6569_MAX_DOT_Y 312
