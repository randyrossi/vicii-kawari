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
#define NTSC_6567R56A_NUM_CYCLES 63
#define NTSC_6567R56A_MAX_DOT_X 511   // 63 cycles per line
#define NTSC_6567R56A_MAX_DOT_Y 261

#define NTSC_6567R8_NUM_CYCLES 65
#define NTSC_6567R8_MAX_DOT_X 519     // 65 cycles per line
#define NTSC_6567R8_MAX_DOT_Y 262

#define PAL_6569_NUM_CYCLES 63
#define PAL_6569_MAX_DOT_X 503       // 63 cycles per line
#define PAL_6569_MAX_DOT_Y 311

#define VIC_LP    0
#define VIC_LPI2  1
#define VIC_LS2   2
#define VIC_LR    3
#define VIC_LG    4
#define VIC_HS1   5
#define VIC_HPI1  6
#define VIC_HPI2  7
#define VIC_HS3   8
#define VIC_HRI   9
#define VIC_HRC   10
#define VIC_HGC   11
#define VIC_HGI   12
#define VIC_HI    13
#define VIC_LI    14
#define VIC_HRX   15

#define V_PPS          vicii__DOT__phi_phase_start
#define V_XPOS         vicii__DOT__xpos
#define V_CYCLE_NUM    vicii__DOT__cycle_num
#define V_CLK_DOT      clk_dot
#define V_BIT_CYCLE    vicii__DOT__bit_cycle
#define V_RASTER_X     vicii__DOT__raster_x
#define V_RASTER_LINE  vicii__DOT__raster_line
#define V_B0C          vicii__DOT__b0c
#define V_EC           vicii__DOT__ec
#define V_DMAEN        vicii__DOT__spriteDmaEn
#define V_DOTRISINGR   vicii__DOT__dot_risingr
#define V_PHIR         vicii__DOT__phir
#define V_DOTR         vicii__DOT__dotr
#define V_RASR         vicii__DOT__rasr
#define V_CASR         vicii__DOT__casr
#define V_MUXR         vicii__DOT__muxr
#define V_REFC         vicii__DOT__refc
#define V_ERST         vicii__DOT__erst
#define V_IRST         vicii__DOT__irst
#define V_IRST_CLR     vicii__DOT__irst_clr
#define V_RASTERCMP    vicii__DOT__rasterCmp
#define V_VICADDR      vicii__DOT__vicAddr
#define V_CB           vicii__DOT__cb
#define V_VM           vicii__DOT__vm
#define V_NEXTCHAR     vicii__DOT__nextChar
#define V_BADLINE      vicii__DOT__badline
#define V_VC           vicii__DOT__vc
#define V_VCBASE       vicii__DOT__vcBase
#define V_RC           vicii__DOT__rc
