// How much to divide our ticks down to our VCD timescale
#define TICKS_TO_TIMESCALE 1000L

// Convert microseconds to ticks
#define US_TO_TICKS(t) (t * 1000L * 1000L)

// Timescale for VCD output
#define VCD_TIMESCALE "$timescale 1ns $end"

#define CHIP6567R8   0
#define CHIP6569     1
#define CHIP6567R56A 2
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
#define NTSC_6567R56A_NUM_CYCLES 64
#define NTSC_6567R56A_MAX_DOT_X 511   // 64 cycles per line
#define NTSC_6567R56A_MAX_DOT_Y 261
#define NTSC_6567R56A_LAST_XPOS 0x1ff

#define NTSC_6567R8_NUM_CYCLES 65
#define NTSC_6567R8_MAX_DOT_X 519     // 65 cycles per line
#define NTSC_6567R8_MAX_DOT_Y 262
#define NTSC_6567R8_LAST_XPOS 0x1ff

#define PAL_6569_NUM_CYCLES 63
#define PAL_6569_MAX_DOT_X 503       // 63 cycles per line
#define PAL_6569_MAX_DOT_Y 311
#define PAL_6569_LAST_XPOS 0x1f7

#define VIC_LP    0
#define VIC_LPI2  1
#define VIC_LS2   2
#define VIC_LR    3
#define VIC_LG    4
#define VIC_HS1   5
#define VIC_HPI1  6
#define VIC_HPI3  7
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
#define V_CYCLE_BIT    vicii__DOT__cycle_bit
#define V_RASTER_X     vicii__DOT__raster_x
#define V_RASTER_LINE  vicii__DOT__raster_line
#define V_RASTER_LINE_D vicii__DOT__raster_line_d
#define V_NEXT_RASTER_LINE  vicii__DOT__next_raster_line
#define V_B0C          vicii__DOT__b0c
#define V_B1C          vicii__DOT__b1c
#define V_B2C          vicii__DOT__b2c
#define V_B3C          vicii__DOT__b3c
#define V_EC           vicii__DOT__ec
#define V_DOTRISINGR   vicii__DOT__dot_risingr
#define V_PHIR         vicii__DOT__phi_gen
#define V_DOTR         vicii__DOT__dot_gen
#define V_RASR         vicii__DOT__ras_gen
#define V_CASR         vicii__DOT__cas_gen
#define V_MUXR         vicii__DOT__mux_gen
#define V_REFC         vicii__DOT__refc
#define V_ERST         vicii__DOT__erst
#define V_EMBC         vicii__DOT__embc
#define V_EMMC         vicii__DOT__emmc
#define V_ELP          vicii__DOT__elp
#define V_IRST         vicii__DOT__irst
#define V_IMBC         vicii__DOT__imbc
#define V_IMBC_PENDING         vicii__DOT__imbc_pending
#define V_IMMC         vicii__DOT__immc
#define V_IMMC_PENDING         vicii__DOT__immc_pending
#define V_ILP          vicii__DOT__ilp
#define V_IRST_CLR     vicii__DOT__irst_clr
#define V_IMBC_CLR     vicii__DOT__imbc_clr
#define V_IMMC_CLR     vicii__DOT__immc_clr
#define V_ILP_CLR      vicii__DOT__ilp_clr
#define V_RASTERCMP    vicii__DOT__raster_irq_compare
#define V_VICADDR      vicii__DOT__vic_addr
#define V_CB           vicii__DOT__cb
#define V_VM           vicii__DOT__vm
#define V_NEXTCHAR     vicii__DOT__next_char
#define V_BADLINE      vicii__DOT__badline
#define V_VC           vicii__DOT__vc
#define V_VCBASE       vicii__DOT__vc_base
#define V_RC           vicii__DOT__rc
#define V_YSCROLL      vicii__DOT__yscroll
#define V_XSCROLL      vicii__DOT__xscroll
#define V_RSEL         vicii__DOT__rsel
#define V_CSEL         vicii__DOT__csel
#define V_DEN          vicii__DOT__den
#define V_BMM          vicii__DOT__bmm
#define V_ECM          vicii__DOT__ecm
#define V_MCM          vicii__DOT__mcm
#define V_RES          vicii__DOT__res
#define V_ALLOW_BAD_LINES    vicii__DOT__allow_bad_lines
#define V_CYCLE_FINE_CTR     vicii__DOT__cycle_fine_ctr
#define V_IDLE               vicii__DOT__idle
#define V_REG11_DELAYED      vicii__DOT__reg11_delayed
#define V_CYCLE_TYPE         vicii__DOT__cycle_type
#define V_SPRITE_DMA         vicii__DOT__sprite_dma
#define V_SPRITE_EN          vicii__DOT__sprite_en
#define V_SPRITE_OFF         vicii__DOT__sprite_off
#define V_SPRITE_PTR         vicii__DOT__sprite_ptr
#define V_SPRITE_X           vicii__DOT____Vcellout__vicregisters__sprite_x
#define V_SPRITE_Y           vicii__DOT____Vcellout__vicregisters__sprite_y
#define V_SPRITE_XE          vicii__DOT__sprite_xe
#define V_SPRITE_YE          vicii__DOT__sprite_ye
#define V_SPRITE_M2M          vicii__DOT__sprite_m2m
#define V_SPRITE_M2M_PENDING          vicii__DOT__sprite_m2m_pending
#define V_SPRITE_M2D          vicii__DOT__sprite_m2d
#define V_SPRITE_M2D_PENDING          vicii__DOT__sprite_m2d_pending
#define V_SPRITE_PRI          vicii__DOT__sprite_pri
#define V_SPRITE_MMC          vicii__DOT__sprite_mmc
#define V_SPRITE_MC0          vicii__DOT__sprite_mc0
#define V_SPRITE_MC1          vicii__DOT__sprite_mc1
#define V_SPRITE_COL          vicii__DOT____Vcellout__vicregisters__sprite_col
#define V_SPRITE_YE_FF        vicii__DOT__sprite_ye_ff
#define V_SPRITE_XE_FF        vicii__DOT__sprite_ye_ff
#define V_SPRITE_MC           vicii__DOT__sprite_mc
#define V_SPRITE_MCBASE       vicii__DOT__sprite_mcbase
#define V_SPRITE_RASTER_X     vicii__DOT__sprite_raster_x
#define V_RASTER_IRQ_TRIGGERED   vicii__DOT__raster_irq_triggered
#define V_TBBORDER            vicii__DOT__top_bot_border
#define V_LRBORDER            vicii__DOT__left_right_border
#define V_COLLISION           vicii__DOT__collision
#define V_CSYNC               csync
#define V_CHAR_NEXT           vicii__DOT__char_next
#define V_CHAR_BUF            vicii__DOT__char_buf
#define V_M2D_TRIGGERED       vicii__DOT__m2d_triggered
#define V_M2M_TRIGGERED       vicii__DOT__m2m_triggered
#define V_LPX                 vicii__DOT__lpx
#define V_LPY                 vicii__DOT__lpy
