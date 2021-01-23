// How much to divide our ticks down to our VCD timescale
#define TICKS_TO_TIMESCALE 1000L

// Convert microseconds to ticks
#define US_TO_TICKS(t) (t * 1000L * 1000L)

// Timescale for VCD output
#define VCD_TIMESCALE "$timescale 1ns $end"

#define CHIP6567R8 0
#define CHIP6569 1
#define CHIP6567R56A 2
#define CHIPUNUSED 3

#define BORDER_DELAY 2

// Dot 8.1818181
// Color 3.579545
#define NTSC_HALF_4X_DOT_PS 15277   // half the period of 32.727272Mhz
#define NTSC_HALF_4X_COLOR_PS 34921 // half the period of 14.318181Mhz

// Dot 7.8819888
// Color 4.43361875
#define PAL_HALF_4X_DOT_PS 15859   // half the period of 31.527955Mhz
#define PAL_HALF_4X_COLOR_PS 28194 // half the period of 17.734475Mhz

// Must match fpga design being simulated
#define NTSC_6567R56A_NUM_CYCLES 64
#define NTSC_6567R56A_MAX_DOT_X 511 // 64 cycles per line
#define NTSC_6567R56A_MAX_DOT_Y 261
#define NTSC_6567R56A_LAST_XPOS 0x1ff

#define NTSC_6567R8_NUM_CYCLES 65
#define NTSC_6567R8_MAX_DOT_X 519 // 65 cycles per line
#define NTSC_6567R8_MAX_DOT_Y 262
#define NTSC_6567R8_LAST_XPOS 0x1ff

#define PAL_6569_NUM_CYCLES 63
#define PAL_6569_MAX_DOT_X 503 // 63 cycles per line
#define PAL_6569_MAX_DOT_Y 311
#define PAL_6569_LAST_XPOS 0x1f7

#define VIC_LP 0
#define VIC_LPI2 1
#define VIC_LS2 2
#define VIC_LR 3
#define VIC_LG 4
#define VIC_HS1 5
#define VIC_HPI1 6
#define VIC_HPI3 7
#define VIC_HS3 8
#define VIC_HRI 9
#define VIC_HRC 10
#define VIC_HGC 11
#define VIC_HGI 12
#define VIC_HI 13
#define VIC_LI 14
#define VIC_HRX 15

#define V_RST top__DOT__rst
#define V_DBO top__DOT__dbo
#define V_DBI top__DOT____Vcellinp__vic_inst__dbi
#define V_ADO ado_sim
#define V_PPS top__DOT__vic_inst__DOT__phi_phase_start
#define V_XPOS top__DOT__vic_inst__DOT__xpos
#define V_CYCLE_NUM top__DOT__vic_inst__DOT__cycle_num
#define V_CLK_DOT top__DOT__vic_inst__DOT__dot_rising
#define V_CYCLE_BIT top__DOT__vic_inst__DOT__vic_raster__DOT__cycle_bit
#define V_RASTER_X top__DOT__vic_inst__DOT__raster_x
#define V_RASTER_LINE top__DOT__vic_inst__DOT__raster_line
#define V_RASTER_LINE_D top__DOT__vic_inst__DOT__raster_line_d
#define V_NEXT_RASTER_LINE top__DOT__next_raster_line
#define V_B0C top__DOT__vic_inst__DOT__b0c
#define V_B1C top__DOT__vic_inst__DOT__b1c
#define V_B2C top__DOT__vic_inst__DOT__b2c
#define V_B3C top__DOT__vic_inst__DOT__b3c
#define V_EC top__DOT__vic_inst__DOT__ec
#define V_PHIR top__DOT__vic_inst__DOT__phi_gen
#define V_DOTR top__DOT__vic_inst__DOT__dot_gen
#define V_REFC top__DOT__vic_inst__DOT__refc
#define V_ERST top__DOT__vic_inst__DOT__erst
#define V_EMBC top__DOT__vic_inst__DOT__embc
#define V_EMMC top__DOT__vic_inst__DOT__emmc
#define V_ELP top__DOT__vic_inst__DOT__elp
#define V_IRST top__DOT__vic_inst__DOT__irst
#define V_IMBC top__DOT__vic_inst__DOT__imbc
#define V_IMMC top__DOT__vic_inst__DOT__immc
#define V_ILP top__DOT__vic_inst__DOT__ilp
#define V_IRST_CLR top__DOT__vic_inst__DOT__irst_clr
#define V_IMBC_CLR top__DOT__vic_inst__DOT__imbc_clr
#define V_IMMC_CLR top__DOT__vic_inst__DOT__immc_clr
#define V_ILP_CLR top__DOT__vic_inst__DOT__ilp_clr
#define V_RASTERCMP top__DOT__vic_inst__DOT__raster_irq_compare
#define V_RASTERCMP_D top__DOT__vic_inst__DOT__raster_irq_compare_d
#define V_VICADDR top__DOT__vic_inst__DOT__vic_addressgen__DOT__vic_addr
#define V_CB top__DOT__vic_inst__DOT__cb
#define V_VM top__DOT__vic_inst__DOT__vm
#define V_NEXTCHAR top__DOT__next_char
#define V_BADLINE top__DOT__vic_inst__DOT__badline
#define V_VC top__DOT__vic_inst__DOT__vc
#define V_VCBASE top__DOT__vic_inst__DOT__vic_matrix__DOT__vc_base
#define V_RC top__DOT__vic_inst__DOT__rc
#define V_YSCROLL top__DOT__vic_inst__DOT__yscroll
#define V_XSCROLL top__DOT__vic_inst__DOT__xscroll
#define V_RSEL top__DOT__vic_inst__DOT__rsel
#define V_CSEL top__DOT__vic_inst__DOT__csel
#define V_DEN top__DOT__vic_inst__DOT__den
#define V_BMM top__DOT__vic_inst__DOT__bmm
#define V_ECM top__DOT__vic_inst__DOT__ecm
#define V_MCM top__DOT__vic_inst__DOT__mcm
#define V_RES top__DOT__vic_inst__DOT__vic_registers__DOT__res
#define V_ALLOW_BAD_LINES top__DOT__vic_inst__DOT__allow_bad_lines
#define V_CYCLE_FINE_CTR top__DOT__cycle_fine_ctr
#define V_IDLE top__DOT__vic_inst__DOT__idle
#define V_CYCLE_TYPE top__DOT__vic_inst__DOT__cycle_type
#define V_SPRITE_DMA top__DOT__vic_inst__DOT__sprite_dma
#define V_SPRITE_EN top__DOT__vic_inst__DOT__sprite_en
#define V_SPRITE_OFF top__DOT__vic_inst__DOT__sprite_off
#define V_SPRITE_PTR top__DOT__vic_inst__DOT__sprite_ptr
#define V_SPRITE_X top__DOT__vic_inst__DOT__vic_registers__DOT__sprite_x
#define V_SPRITE_Y top__DOT__vic_inst__DOT__vic_registers__DOT__sprite_y
#define V_SPRITE_XE top__DOT__vic_inst__DOT__sprite_xe
#define V_SPRITE_YE top__DOT__vic_inst__DOT__sprite_ye
#define V_SPRITE_M2M top__DOT__vic_inst__DOT__sprite_m2m
#define V_SPRITE_M2D top__DOT__vic_inst__DOT__sprite_m2d
#define V_SPRITE_PRI top__DOT__vic_inst__DOT__sprite_pri
#define V_SPRITE_MMC top__DOT__vic_inst__DOT__sprite_mmc
#define V_SPRITE_MC0 top__DOT__vic_inst__DOT__sprite_mc0
#define V_SPRITE_MC1 top__DOT__vic_inst__DOT__sprite_mc1
#define V_SPRITE_COL top__DOT__vic_inst__DOT__vic_registers__DOT__sprite_col
#define V_SPRITE_YE_FF top__DOT__vic_inst__DOT__vic_sprites__DOT__sprite_ye_ff
#define V_SPRITE_XE_FF top__DOT__vic_inst__DOT__vic_sprites__DOT__sprite_xe_ff
#define V_SPRITE_MC top__DOT__vic_inst__DOT__vic_sprites__DOT__sprite_mc
#define V_SPRITE_MCBASE top__DOT__vic_inst__DOT__vic_sprites__DOT__sprite_mcbase
#define V_SPRITE_RASTER_X top__DOT__sprite_raster_x
#define V_RASTER_IRQ_TRIGGERED top__DOT__vic_inst__DOT__raster_irq_triggered
#define V_VBORDER top__DOT__vic_inst__DOT__top_bot_border
#define V_MAIN_BORDER top__DOT__vic_inst__DOT__main_border
#define V_SET_VBORDER top__DOT__vic_inst__DOT__vic_border__DOT__set_vborder
#define V_COLLISION top__DOT__collision
#define V_CHAR_NEXT top__DOT__vic_inst__DOT__char_next
#define V_CHAR_BUF top__DOT__vic_inst__DOT__vic_bus_access__DOT__char_buf
#define V_M2D_TRIGGERED top__DOT__vic_inst__DOT__vic_sprites__DOT__m2d_triggered
#define V_M2M_TRIGGERED top__DOT__vic_inst__DOT__vic_sprites__DOT__m2m_triggered
#define V_LPX top__DOT__vic_inst__DOT__lpx
#define V_LPY top__DOT__vic_inst__DOT__lpy
#define V_CHIP top__DOT__chip
#define V_LOAD_PIXELS top__DOT__vic_inst__DOT__vic_pixel_sequencer__DOT__load_pixels
#define V_IRQ irq
#define V_DOT4X top__DOT__clk_dot4x
#define V_REG11_DELAYED top__DOT__vic_inst__DOT__reg11_delayed
#define V_LIGHTPEN_TRIGGERED top__DOT__vic_inst__DOT__vic_lightpen__DOT__light_pen_triggered
