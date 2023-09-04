// This file is part of the vicii-kawari distribution
// (https://github.com/randyrossi/vicii-kawari)
// Copyright (c) 2022 Randy Rossi.
// 
// This program is free software: you can redistribute it and/or modify  
// it under the terms of the GNU General Public License as published by  
// the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful, but 
// WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License 
// along with this program. If not, see <http://www.gnu.org/licenses/>.

#include <SDL2/SDL.h>

#include <iostream>

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <verilated.h>
#include <regex.h>

#include "Vtop.h"
#include "constants.h"

#if VM_TRACE
#include <verilated_vcd_c.h>
#endif

extern "C" {
#include "vicii_ipc.h"
}
#include "log.h"
// Current simulation time (64-bit unsigned). See
// constants.h for how much each tick represents.
static vluint64_t ticks = 0;
static vluint64_t half4XDotPS;
static vluint64_t half16XColPS;
static vluint64_t startTicks;
static vluint64_t endTicks;
static vluint64_t nextClk;
static vluint64_t next16XColClk;
static double col4xClk;
static double col16xClk;
static int nextClkCnt;
static int screenWidth;
static int screenHeight;
static int lastXPos;
static int numCycles;

// Some utility macros
// Use RISING/FALLING in combination with HASCHANGED

#define HASCHANGED(signum) \
   ( SGETVAL(signum) != prev_signal_values[signum] )
#define RISING(signum) \
   ( SGETVAL(signum))
#define FALLING(signum) \
   ( !SGETVAL(signum))

// Add new input/output here
enum {
   OUT_DOT = 0, OUT_DOT_RISING,
};

#define NUM_SIGNALS 2

static unsigned int signal_width[NUM_SIGNALS];
static unsigned char *signal_src8[NUM_SIGNALS];
static unsigned short *signal_src16[NUM_SIGNALS];
static unsigned int signal_bit[NUM_SIGNALS];
static unsigned char prev_signal_values[NUM_SIGNALS];

// Used when no RGB is avaiable (i.e. composite only)
int native_rgb[] = {
0,0,0,
63,63,63,
43,10,10,
24,54,51,
44,15,45,
18,49,18,
13,14,49,
57,59,19,
45,22,7,
26,14,2,
58,29,27,
19,19,19,
33,33,33,
41,62,39,
28,31,57,
45,45,45,
};


static char cycleToChar(int cycle){
  switch (cycle) {
    case VIC_LP   : return '#';
    case VIC_LPI2 : return 'i';
    case VIC_LS2  : return 's';
    case VIC_LR   : return 'r';
    case VIC_LG   : return 'g';
    case VIC_HS1  : return 'S';
    case VIC_HPI1 : return 'I';
    case VIC_HPI3 : return 'I';
    case VIC_HS3  : return 'S';
    case VIC_HRI  : return 'I';
    case VIC_HRC  : return 'C';
    case VIC_HGC  : return 'C';
    case VIC_HGI  : return 'I';
    case VIC_HI   : return 'I';
    case VIC_LI   : return 'i';
    case VIC_HRX  : return 'x';
    default:
       LOG(LOG_ERROR,"bad cycle");
       exit(-1);
  }
}

// TODO : Add a signal_shift so we can shift before we mask with signal
// bit in case we want to isolate higher bits of a signal?
static int SGETVAL(int signum) {
  if (signal_width[signum] == 1) {
     // When width is 1, we can pick out any bit
     return (*signal_src8[signum] & signal_bit[signum] ? 1 : 0);
  } else if (signal_width[signum] <= 8) {
     return (*signal_src8[signum] & signal_bit[signum]);
  } else if (signal_width[signum] > 8 && signal_width[signum] < 16) {
     return (*signal_src16[signum] & signal_bit[signum]);
  } else {
    abort();
  }
}

static void HEADER(Vtop *top) {
   LOG(LOG_VERBOSE,
   "  "
   "D4X "
   "CNT "
   "POS "
   "CYC "
   "DOTR "
   "PHI "
   "BIT "
   "IRQ "
   "BA "
   "AEC "
   "VCY "
   "RAS "
   "CAS "
   " X  "
   " Y  "
   " Y  "
   "ADI  "
   "ADO  "
   "DBI "
   "DBO "
   "RW "
   "CE "
   "RFC "
   "BIN"
  );
}

static void STATE(Vtop *top) {
   if ((top->V_DOT4X & 1) == 0) return;

   if(HASCHANGED(OUT_DOT) && RISING(OUT_DOT))
      HEADER(top);

   LOG(LOG_VERBOSE,
   "%c "      /*DOT*/
   "%01d   "   /*D4x*/
   "%02d  "   /*CNT*/
   "%03x "   /*POS*/
   " %02d "  /*CYC*/
   " %01d  "   /*DOTR*/
   " %01d  "   /*PHI*/
   " %01d  "   /*BIT*/
   " %01d  "   /*IRQ*/
   " %01d  "   /*BA */
   " %01d  "   /*AEC*/
   "%c  "     /*VCY*/
   " %01d  "   /*RAS*/
   " %01d  "   /*CAS*/
   "%03d "   /*  X*/
   "%03d "   /*  Y*/
   "%03d "   /*  Y*/
   "%04x "   /*ADI*/
   "%04x "   /*ADO*/
   " %02x "   /*DBI*/
   " %02x "   /*DBO*/
   " %01d "   /* RW*/
   " %01d "   /* CE*/
   "%02x "   /*RFC*/
   " %s"     /*BIN*/
   " %s"     /*BIN*/
   " %s"     /*BIN*/
   " %d"     /*badline*/

   " %03d"
   " %03d"
   " %01d"
   " %04x"
   " %01d"
   ,

   top->V_RST ? 'R' : HASCHANGED(OUT_DOT) && RISING(OUT_DOT) ? '*' : ' ',
   top->V_DOT4X ? 1 : 0,
   nextClkCnt,
   top->V_XPOS,
   top->V_CYCLE_NUM,
   top->V_CLK_DOT & 8 ? 1 : 0,
   top->clk_phi,
   top->V_CYCLE_BIT,
   top->irq,
   top->ba,
   top->aec,
   cycleToChar(top->V_CYCLE_TYPE),
   top->ras,
   top->cas,
   top->V_RASTER_X,
   top->V_RASTER_LINE,
   top->V_RASTER_LINE_D,
   top->adl,
   top->V_ADO,
   top->V_DBI,
   top->V_DBO,
   top->rw,
   top->ce,
   top->V_REFC,

   //toBin(16, top->V_RASR),
   //toBin(16, top->V_CASR),

   toBin(16, top->V_PPS),
   toBin(32, top->V_PHIR),
   " ",

   //toBin(16, top->V_DOTRISINGR),
   //toBin(32, top->V_DOTR),
   //" ",

   top->V_BADLINE,

   top->V_SPRITE_MC[0],
   top->V_SPRITE_MCBASE[0],
   top->V_RC,
   top->V_VICADDR,
   top->V_BMM
   //top->V_NEXTCHAR
   );
}



static void STORE_PREV() {
  for (int i = 0; i < NUM_SIGNALS; i++) {
     prev_signal_values[i] = SGETVAL(i);
  }
}


static void CHECK(Vtop *top, int cond, int line) {
  if (!cond) {
     printf ("FAIL line %d:", line);
     STATE(top);
     exit(-1);
  }
}

// We can drive our simulated clock gen every pico second but that would
// be a waste since nothing happens between clock edges. This function
// will determine how many ticks(picoseconds) to advance our clock.

// tick_scale_* simulates a clk_dvi signal that is slower in the right
// fraction of the master dot4x clock.  For efinix, we use a slower clock
// (13/16 for NTSC and 15/16 for PAL) and chop off some of the border area.
// For spartan, the full resolution is used so clk_dot4x = clk_dvi.

#ifdef EFINIX
#ifdef WITH_DVI
static long tc = 0;

// The fraction of dot4x to dviclk changes between our two
// alternate PAL clocks. The dot clock can be switched at build
// time between 29MHZ and 27MHZ (See c64_clock_finder.c)
#ifdef PAL_32MHZ
static int tick_scale_pal[] = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};
#endif
#ifdef PAL_15MHZ
static int tick_scale_pal[] = {1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0};
#endif
#ifdef PAL_29MHZ
static int tick_scale_pal[] = {1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1};
#endif
#ifdef PAL_27MHZ
static int tick_scale_pal[] = {1,1,1,1,1,0,1,1,1,1,1,0,1,1,1,1};
#endif

#ifdef NTSC_32MHZ
static int tick_scale_ntsc[] = {1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1};
#endif
#ifdef NTSC_16MHZ
static int tick_scale_ntsc[] = {1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0};
#endif
#ifdef NTSC_26MHZ
static int tick_scale_ntsc[] = {1,1,1,0,1,1,1,1,0,1,1,1,0,1,1,1};
#endif

#endif
#endif

double col16xtick = 0;

static vluint64_t nextTick(Vtop* top, VerilatedVcdC* tfp, int chip) {
   vluint64_t diff1 = nextClk - ticks;

   nextClk += half4XDotPS;

   top->V_DOT4X = ~top->V_DOT4X;
   
#ifdef EFINIX
#ifdef WITH_DVI
   // Emulate our dvi clock in the correct fraction of the dot4x clock
   if (chip & 1) {
      if (tick_scale_pal[tc])
         top->V_CLK_DVI = ~top->V_CLK_DVI;
   } else {
      if (tick_scale_ntsc[tc])
         top->V_CLK_DVI = ~top->V_CLK_DVI;
   }

   tc++;
   if (tc>=16) tc=0;
#endif
#endif

   top->V_COL4X = ~top->V_COL4X;

   // One tick of dot4x 
   // = 9/4 ticks of col16x for PAL, 7/4 ticks of col16x for NTSC

   if (chip & 1) {
       col16xtick += 9.0f/4.0d;
   } else {
       col16xtick += 7.0f/4.0d;
   }

   next16XColClk = nextClk;
   while (col16xtick >= 1) {
       top->V_COL16X = ~top->V_COL16X;
       top->eval();
#if VM_TRACE
       if (tfp) tfp->dump(next16XColClk / TICKS_TO_TIMESCALE);
#endif
       next16XColClk += half16XColPS;
       col16xtick -= 1;
   }

   nextClkCnt = (nextClkCnt + 1) % 32;
   return ticks + diff1;
}

static void drawPixel(SDL_Renderer* ren, int x,int y) {
   SDL_RenderDrawPoint(ren, x,y*2);
   SDL_RenderDrawPoint(ren, x,y*2+1);
}

// Initial sync
static void regs_vice_to_fpga(Vtop* top, struct vicii_state* state) {
       top->V_IDLE = state->idle;

       // Sync registers
       unsigned char val = state->vice_reg[0x11];
       top->V_YSCROLL = val & 7;
       top->V_RSEL = val & 8 ? 1 : 0;
       top->V_DEN = val & 16 ? 1 : 0;
       top->V_BMM = val & 32 ? 1 : 0;
       top->V_ECM = val & 64 ? 1 : 0;
       int rasterCmp8 = (val & 128) << 1;

       val = state->vice_reg[0x12];
       top->V_RASTERCMP = val | rasterCmp8;
       top->V_RASTERCMP_D = val | rasterCmp8;

       top->V_LPX = state->vice_reg[0x13];
       top->V_LPY = state->vice_reg[0x14];

       val = state->vice_reg[0x16];
       top->V_XSCROLL = val & 7;
       top->V_CSEL = val & 8 ? 1 : 0;
       top->V_MCM = val & 16 ? 1 : 0;
       top->V_RES = val & 32 ? 1 : 0;

       val = state->vice_reg[0x18];
       top->V_CB = (val & 14) >> 1;
       top->V_VM = (val & 240) >> 4;

       val = state->vice_reg[0x19];
       //top->V_IRST_CLR = val & 1;
       //top->V_IMBC_CLR = val & 2 ? 1 : 0;
       //top->V_IMMC_CLR = val & 4 ? 1 : 0;
       //top->V_ILP_CLR =  val & 8 ? 1 : 0;

       val = state->vice_reg[0x1A];
       top->V_ERST = val & 1;
       top->V_EMBC = val & 2 ? 1 : 0;
       top->V_EMMC = val & 4 ? 1 : 0;
       top->V_ELP = val & 8 ? 1 : 0;

       val = state->vice_reg[0x20];
       top->V_EC = val & 15 | 0x11110000;
       val = state->vice_reg[0x21];
       top->V_B0C = val & 15 | 0x11110000;
       val = state->vice_reg[0x22];
       top->V_B1C = val & 15 | 0x11110000;
       val = state->vice_reg[0x23];
       top->V_B2C = val & 15 | 0b11110000;
       val = state->vice_reg[0x24];
       top->V_B3C = val & 15 | 0b11110000;

       top->V_VC = state->vc;
       top->V_RC = state->rc;
       top->V_VCBASE = state->vc_base;

       top->V_ALLOW_BAD_LINES = state->allow_bad_lines;
       top->V_REG11_DELAYED = state->reg11_delayed;

       top->V_SPRITE_X[0] = state->vice_reg[0x00] | ((state->vice_reg[0x10] & 1) << 8);
       top->V_SPRITE_Y[0] = state->vice_reg[0x01];
       top->V_SPRITE_X[1] = state->vice_reg[0x02] | ((state->vice_reg[0x10] & 2) << 7);
       top->V_SPRITE_Y[1] = state->vice_reg[0x03];
       top->V_SPRITE_X[2] = state->vice_reg[0x04] | ((state->vice_reg[0x10] & 4) << 6);
       top->V_SPRITE_Y[2] = state->vice_reg[0x05];
       top->V_SPRITE_X[3] = state->vice_reg[0x06] | ((state->vice_reg[0x10] & 8) << 5);
       top->V_SPRITE_Y[3] = state->vice_reg[0x07];
       top->V_SPRITE_X[4] = state->vice_reg[0x08] | ((state->vice_reg[0x10] & 16) << 4);
       top->V_SPRITE_Y[4] = state->vice_reg[0x09];
       top->V_SPRITE_X[5] = state->vice_reg[0x0a] | ((state->vice_reg[0x10] & 32) << 3);
       top->V_SPRITE_Y[5] = state->vice_reg[0x0b];
       top->V_SPRITE_X[6] = state->vice_reg[0x0c] | ((state->vice_reg[0x10] & 64) << 2);
       top->V_SPRITE_Y[6] = state->vice_reg[0x0d];
       top->V_SPRITE_X[7] = state->vice_reg[0x0e] | ((state->vice_reg[0x10] & 128) << 1);
       top->V_SPRITE_Y[7] = state->vice_reg[0x0f];

       top->V_SPRITE_EN = state->vice_reg[0x15];
       top->V_SPRITE_YE = state->vice_reg[0x17];
       top->V_SPRITE_PRI = state->vice_reg[0x1b];
       top->V_SPRITE_MMC = state->vice_reg[0x1c];
       top->V_SPRITE_XE = state->vice_reg[0x1d];

       top->V_SPRITE_M2M = state->vice_reg[0x1e];
       top->V_SPRITE_M2D = state->vice_reg[0x1f];

       top->V_SPRITE_MC0 = state->vice_reg[0x25];
       top->V_SPRITE_MC1 = state->vice_reg[0x26];

       top->V_SPRITE_DMA = 0;
       for (int n=0, b=1;n<8;n++,b=b*2) {
          top->V_SPRITE_MC[n] = state->mc[n];
          top->V_SPRITE_MCBASE[n] = state->mcbase[n];
          top->V_SPRITE_YE_FF[n] = state->ye_ff[n];
	  top->V_SPRITE_DMA |= state->sprite_dma[n] ? b : 0;
          top->V_SPRITE_COL[n] = state->vice_reg[0x27+n];
       }

       top->V_RASTER_IRQ_TRIGGERED = state->raster_irq_triggered;
       top->V_IRST = state->irst;
       top->V_IMBC = state->imbc;
       if (state->vice_reg[0x1f] != 0) top->V_M2D_TRIGGERED = 1;
       top->V_IMMC = state->immc;
       if (state->vice_reg[0x1e] != 0) top->V_M2M_TRIGGERED = 1;
       top->V_ILP = state->ilp;

       top->V_VBORDER = state->vborder;
       top->V_MAIN_BORDER = state->main_border;
       top->V_SET_VBORDER = state->set_vborder;

       top->V_LIGHTPEN_TRIGGERED = state->light_pen_triggered;

       // We need to populate our char buf from VICE's
       for (int i=0;i < 40; i++) {
           top->V_CHAR_BUF[i] = state->char_buf[i] | (state->color_buf[i] << 8);
       }
}

static void regs_fpga_to_vice(Vtop* top, struct vicii_state* state) {
       state->fpga_reg[0x11] =
          (top->V_YSCROLL & 0x7) |
          (top->V_RSEL ? 8 : 0) |
          (top->V_DEN  ? 16 : 0) |
          (top->V_BMM  ? 32 : 0) |
          (top->V_ECM  ? 64 : 0) |
          ((top->V_RASTER_LINE_D & 256) ? 128 : 0);

       state->fpga_reg[0x12] =
          top->V_RASTER_LINE_D & 0xff;

       state->fpga_reg[0x13] = top->V_LPX;
       state->fpga_reg[0x14] = top->V_LPY;

       state->fpga_reg[0x16] =
          (top->V_XSCROLL & 0x7) |
          (top->V_CSEL ? 8 : 0) |
          (top->V_MCM ? 16 : 0) |
          (top->V_RES ? 32 : 0) |
          0b11000000;

       state->fpga_reg[0x18] = 1 |
          ((top->V_CB & 0x7) << 1) |
          ((top->V_VM & 0xf) << 4);

       state->fpga_reg[0x19] =
	  (top->V_IRQ ? 128 : 0) |
          (top->V_IRST ? 1 : 0) |
          (top->V_IMBC ? 2 : 0) |
          (top->V_IMMC ? 4 : 0) |
          (top->V_ILP ? 8 : 0) |
          0b01110000;

       state->fpga_reg[0x1A] =
          (top->V_ERST  ? 1 : 0) |
          (top->V_EMBC  ? 2 : 0) |
          (top->V_EMMC  ? 4 : 0) |
          (top->V_ELP   ? 8 : 0) |
          0b11110000;

       state->fpga_reg[0x20] =
          (top->V_EC & 15) | 0b11110000;
       state->fpga_reg[0x21] =
          (top->V_B0C & 15) | 0b11110000;
       state->fpga_reg[0x22] =
          (top->V_B1C & 15) | 0b11110000;
       state->fpga_reg[0x23] =
          (top->V_B2C & 15) | 0b11110000;
       state->fpga_reg[0x24] =
          (top->V_B3C & 15) | 0b11110000;

       state->vc = top->V_VC;
       state->vc_base = top->V_VCBASE;
       state->rc = top->V_RC;

       state->allow_bad_lines = top->V_ALLOW_BAD_LINES;
       state->reg11_delayed = top->V_REG11_DELAYED;

       state->fpga_reg[0x00] = top->V_SPRITE_X[0] & 0xff;
       state->fpga_reg[0x01] = top->V_SPRITE_Y[0];
       state->fpga_reg[0x02] = top->V_SPRITE_X[1] & 0xff;
       state->fpga_reg[0x03] = top->V_SPRITE_Y[1];
       state->fpga_reg[0x04] = top->V_SPRITE_X[2] & 0xff;
       state->fpga_reg[0x05] = top->V_SPRITE_Y[2];
       state->fpga_reg[0x06] = top->V_SPRITE_X[3] & 0xff;
       state->fpga_reg[0x07] = top->V_SPRITE_Y[3];
       state->fpga_reg[0x08] = top->V_SPRITE_X[4] & 0xff;
       state->fpga_reg[0x09] = top->V_SPRITE_Y[4];
       state->fpga_reg[0x0a] = top->V_SPRITE_X[5] & 0xff;
       state->fpga_reg[0x0b] = top->V_SPRITE_Y[5];
       state->fpga_reg[0x0c] = top->V_SPRITE_X[6] & 0xff;
       state->fpga_reg[0x0d] = top->V_SPRITE_Y[6];
       state->fpga_reg[0x0e] = top->V_SPRITE_X[7] & 0xff;
       state->fpga_reg[0x0f] = top->V_SPRITE_Y[7];
       state->fpga_reg[0x10] = ((top->V_SPRITE_X[0] & 256) >> 8) |
                               ((top->V_SPRITE_X[1] & 256) >> 7) |
                               ((top->V_SPRITE_X[2] & 256) >> 6) |
                               ((top->V_SPRITE_X[3] & 256) >> 5) |
                               ((top->V_SPRITE_X[4] & 256) >> 4) |
                               ((top->V_SPRITE_X[5] & 256) >> 3) |
                               ((top->V_SPRITE_X[6] & 256) >> 2) |
                               ((top->V_SPRITE_X[7] & 256) >> 1);

       state->fpga_reg[0x15] = top->V_SPRITE_EN;
       state->fpga_reg[0x17] = top->V_SPRITE_YE;
       state->fpga_reg[0x1b] = top->V_SPRITE_PRI;
       state->fpga_reg[0x1c] = top->V_SPRITE_MMC;
       state->fpga_reg[0x1d] = top->V_SPRITE_XE;
       state->fpga_reg[0x1e] = top->V_SPRITE_M2M;
       state->fpga_reg[0x1f] = top->V_SPRITE_M2D;
       state->fpga_reg[0x25] = top->V_SPRITE_MC0 | 0xf0;
       state->fpga_reg[0x26] = top->V_SPRITE_MC1 | 0xf0;

       for (int n=0,b=1;n<8;n++,b=b*2) {
          state->mc[n] = top->V_SPRITE_MC[n];
          state->mcbase[n] = top->V_SPRITE_MCBASE[n];
          state->ye_ff[n] = top->V_SPRITE_YE_FF[n];
          state->sprite_dma[n] = top->V_SPRITE_DMA & b ? 1 : 0;
          state->fpga_reg[0x27+n] = top->V_SPRITE_COL[n] | 0xf0;
       }

       // Tell VICE what our char buf looks like or comparison
       for (int i=0; i < 40; i++) {
	  state->fpga_char_buf[i] = top->V_CHAR_BUF[i];
       }
}


int main(int argc, char** argv, char** env) {
    SDL_Event event;
    SDL_Renderer* ren = nullptr;
    SDL_Window* win;

    struct vicii_state* state;
    bool capture = false;

    int chip = CHIP6569R3;
    bool hideSync = false;
    bool isNtsc = false;
    bool showActive = false;

    bool captureByTime = true;
    bool captureByFrame = false;
    int  captureByFrameStopXpos = 0;
    int  captureByFrameStopYpos = 0;
    bool showWindow = false;
    bool shadowVic = false;
    bool cycleByCycle = false;
    int cycleByCycleCount = 0;
    int last_phase = 0;
    bool tracing = false;
    int prevY = -1;
    struct vicii_ipc* ipc;
    bool keyPressToQuit = true;
    bool viceCapture = false;
    bool endCapture = false;
    bool scanline = true;

    // Default to 16.7us starting at 0
    startTicks = US_TO_TICKS(0);
    vluint64_t durationTicks;
    vluint64_t userDurationUs = -1;

    char *cvalue = nullptr;
    char c;
    char *token;
    regex_t regex;
    int reti, reti2;
    char regex_buf[32];

    while ((c = getopt (argc, argv, "akc:hs:d:wi:zbl:r:gtxqy")) != -1)
    switch (c) {
      case 'q':
        scanline = false;
      case 't':
        tracing = true;
        break;
      case 'l':
        logLevel = atoi(optarg);
        break;
      case 'c':
        chip = atoi(optarg);
        break;
      case 'b':
        cycleByCycle = true;
        break;
      case 'z':
        // IPC tells us when to start/stop capture
        captureByTime = false;
        shadowVic = true;
        break;
      case 'w':
        showWindow = true;
        break;
      case 'k':
        hideSync = true;
        break;
      case 'a':
        showActive = true;
        break;
      case 's':
        startTicks = US_TO_TICKS(atol(optarg));
        break;
      case 'd':
        userDurationUs = atol(optarg);
        break;
      case 'h':
        printf ("Usage\n");
        printf ("  -s [uS]   : start at uS\n");
        printf ("  -d [uS]   : run for uS\n");
        printf ("  -w        : show SDL2 window\n");
        printf ("  -z        : single step eval for shadow vic via ipc\n");
        printf ("  -b        : render each cycle, waiting for key press after each one\n");
        printf ("  -c <chip> : 0=CHIP6567R8, 1=CHIP6569R3 2=CHIP6567R56A 3=CHIP6569R1\n");
        printf ("  -l        : log level\n");
        printf ("  -q        : hide scanline\n");
        printf ("  -k        : hide sync lines\n");
        printf ("  -t        : enable tracing to session.vcd\n");
        printf ("  -x        : sync with VICE and save a frame before exiting\n");
        printf ("  -y        : save a frame before exiting\n");
        exit(0);
      case 'x':
	viceCapture = true;
	break;
      case 'y':
	endCapture = true;
	break;
      case '?':
        if (optopt == 't' || optopt == 's') {
          LOG(LOG_ERROR, "Option -%c requires an argument", optopt);
        } else if (isprint (optopt)) {
          LOG(LOG_ERROR, "Unknown option `-%c'", optopt);
        } else {
          LOG(LOG_ERROR, "Unknown option character `\\x%x'", optopt);
        }
        return 1;
      default:
        exit(-1);
    }

    int sdl_init_mode = SDL_INIT_VIDEO;
    if (SDL_Init(sdl_init_mode) != 0) {
      LOG(LOG_ERROR, "SDL_Init %s", SDL_GetError());
      return 1;
    }

    // Add new input/output here.
    Vtop* top = new Vtop;

#if VM_TRACE
    VerilatedVcdC* tfp = NULL;
    if (tracing) {
        Verilated::traceEverOn(true);  // Verilator must compute traced signals
        VL_PRINTF("verilog tracing into session.vcd\n");
        tfp = new VerilatedVcdC;
        top->trace(tfp, 99);  // Trace 99 levels of hierarchy
        tfp->open("session.vcd");  // Open the dump file
    }
#endif

    top->eval();

    switch (chip) {
       case CHIP6567R8:
          isNtsc = true;
          printf ("CHIP: 6567R8\n");
          printf ("VIDEO: NTSC\n");
          break;
       case CHIP6567R56A:
          isNtsc = true;
          printf ("CHIP: 6567R56A\n");
          printf ("VIDEO: NTSC\n");
          break;
       case CHIP6569R1:
          isNtsc = false;
          printf ("CHIP: 6569R1\n");
          printf ("VIDEO: PAL\n");
          break;
       case CHIP6569R3:
          isNtsc = false;
          printf ("CHIP: 6569R3\n");
          printf ("VIDEO: PAL\n");
          break;
       default:
          LOG(LOG_ERROR, "unknown chip");
          exit(-1);
          break;
    }
    printf ("Log Level: %d\n", logLevel);

#ifdef GEN_RGB
    printf ("Color: Using RGB/Sync output values\n");
#else
#ifdef NEED_RGB
    printf ("Color: Using internal RGB/Sync values\n");
#else
#ifdef GEN_LUMA_CHROMA
    printf ("Color: Using composite palette/sync\n");
#else
    printf ("Color: No color information available\n");
#endif
#endif
#endif

    if (userDurationUs == -1) {
       switch (chip) {
          case CHIP6567R8:
          case CHIP6567R56A:
             durationTicks = US_TO_TICKS(17000L);
             break;
          case CHIP6569R1:
          case CHIP6569R3:
             durationTicks = US_TO_TICKS(20000L);
             break;
          default:
             durationTicks = US_TO_TICKS(20000L);
       }
    } else {
       durationTicks = US_TO_TICKS(userDurationUs);
    }

    if (isNtsc) {
       half4XDotPS = NTSC_HALF_4X_DOT_PS;
       half16XColPS = NTSC_HALF_16X_COLOR_PS;
       switch (chip) {
          case CHIP6567R56A:
             screenWidth = NTSC_6567R56A_MAX_DOT_X+1;
             screenHeight = NTSC_6567R56A_MAX_DOT_Y+1;
             lastXPos = NTSC_6567R56A_LAST_XPOS;
	     numCycles = NTSC_6567R56A_NUM_CYCLES;
             break;
          case CHIP6567R8:
             screenWidth = NTSC_6567R8_MAX_DOT_X+1;
             screenHeight = NTSC_6567R8_MAX_DOT_Y+1;
             lastXPos = NTSC_6567R8_LAST_XPOS;
	     numCycles = NTSC_6567R8_NUM_CYCLES;
             break;
          default:
             LOG(LOG_ERROR, "wrong chip?");
             exit(-1);
       }
    } else {
       half4XDotPS = PAL_HALF_4X_DOT_PS;
       half16XColPS = PAL_HALF_16X_COLOR_PS;
       switch (chip) {
          case CHIP6569R1:
          case CHIP6569R3:
             screenWidth = PAL_6569_MAX_DOT_X+1;
             screenHeight = PAL_6569_MAX_DOT_Y+1;
             lastXPos = PAL_6569_LAST_XPOS;
	     numCycles = PAL_6569_NUM_CYCLES;
             break;
          default:
             LOG(LOG_ERROR, "wrong chip?");
             exit(-1);
       }
    }

    nextClk = half4XDotPS;

    if (showWindow) {
      SDL_DisplayMode current;

      win = SDL_CreateWindow("VICII",
                             SDL_WINDOWPOS_CENTERED,
                             SDL_WINDOWPOS_CENTERED,
                             screenWidth*2, screenHeight*2, SDL_WINDOW_SHOWN);
      if (win == nullptr) {
        std::cerr << "SDL_CreateWindow Error: " << SDL_GetError() << std::endl;
        SDL_Quit();
        return 1;
      }

      ren = SDL_CreateRenderer(
          win, -1, SDL_RENDERER_ACCELERATED | SDL_RENDERER_PRESENTVSYNC);
      if (ren == nullptr) {
        std::cerr << "SDL_CreateRenderer Error: "
           << SDL_GetError() << std::endl;
        SDL_DestroyWindow(win);
        SDL_Quit();
        return 1;
      }
    }

    // Default all signals to bit 1 and include in monitoring.
    for (int i = 0; i < NUM_SIGNALS; i++) {
      signal_width[i] = 1;
      signal_bit[i] = 1;
    }

    // Add new input/output here.
    signal_src8[OUT_DOT] = &top->V_CLK_DOT;
    signal_src8[OUT_DOT_RISING] = &top->V_CLK_DOT;
    signal_width[OUT_DOT_RISING] = 4; // 4 bit shif reg
    signal_bit[OUT_DOT_RISING] = 0b1111; // mask to get values

    HEADER(top);

    // Video standard toggle switch should be HIGH simulating PULLUP
    top->standard_sw = 1;
#if WITH_EXTENSIONS
    // cfg reset is held HIGH simulating pullup
#if HAVE_EEPROM
    top->cfg_reset = 1;
#endif
    // simulate SHORTED for config pins
    top->cfg1 = 0; // spi_lock
    top->cfg2 = 0; // extensions_lock
    top->cfg3 = 0; // persistence_lock
#endif
    // cpu_reset_i is held HIGH simulating pullup
#if HIRES_RESET
    top->cpu_reset_i = 1;
#endif
    
#if HAVE_EEPROM
    top->sim_chip = chip;
#else
    top->V_CHIP = chip;
#endif

    int cnt = 0;
    while (top->V_RST) {
       top->eval();
       nextClkCnt = 0;
#if VM_TRACE
       if (tfp) tfp->dump(ticks / TICKS_TO_TIMESCALE);
#endif
       STATE(top);
       STORE_PREV();
       ticks = nextTick(top, tfp, chip);
       cnt++;
    }

    // Not sure if this matters anymore
    nextClkCnt = 31;

    // Start counting from after reset
    startTicks = ticks;
    endTicks = startTicks + durationTicks;

    top->lp = 1;
    top->rw = 1;
    top->ce = 1;
    top->lp = 1;
    top->adl = 0;
    top->V_DBI = 0;
    top->V_DEN = 1;
    top->V_CSEL = 1;
    top->V_RSEL = 1;
    top->V_VBORDER = 1;
    top->V_MAIN_BORDER = 1;
    top->V_SET_VBORDER = 1;
    top->V_B0C = 6;
    top->V_EC = 14;
    top->V_VM = 1; // 0001
    top->V_CB = 2; //  010
    top->V_YSCROLL = 3; //  011
#ifdef NEED_RGB
    // NOTE: We are hard wired to do 2x and 1y. Any other
    // configuration will require some work to the
    // way rendering is done. If we have registers_eeprom, let
    // that module set is_native_y as if it came from a the
    // eeprom. Otherwise, just force it here.
#ifndef HAVE_EEPROM

#ifdef EFINIX
    // Efinix DVI doesn't support native y
    top->top__DOT__vic_inst__DOT__is_native_y = 0;
#else
    top->top__DOT__vic_inst__DOT__is_native_y = 1;
#endif

    top->top__DOT__vic_inst__DOT__is_native_x = 0;
#endif
#else
    // NO RGB? We will fallback to native res and we will use
    // the color index coming out of the pixel sequencer
    // (pixel_color3)
    ;
#endif

    if (shadowVic) {
       ipc = ipc_init(IPC_RECEIVER);
       ipc_open(ipc);
       state = ipc->state;
    }

    // IMPORTANT: Any and all state reads/writes MUST occur between ipc_receive
    // and ipc_receive_done inside this loop.
    int ticksUntilDone = 0;
    int ticksUntilPhase = 0;
    bool showState = true;
    bool viceCaptureWaitLine1 = true;
    bool endCaptureWaitLine1 = true;
    while (!Verilated::gotFinish()) {

        // Are we shadowing from VICE? Wait for sync data, then
        // step until next dot clock tick.
        if (shadowVic && ticksUntilDone == 0) {

           // This is technically a race condition. We might miss the
	   // first send...should really do this on another thread.
           if (viceCapture && (state->flags & VICII_OP_CAPTURE_START) == 0) {
               state->flags |= VICII_OP_CAPTURE_START;
	   }

           // Do not change state before this line
           if (ipc_receive(ipc))
              break;

           capture = (state->flags & VICII_OP_CAPTURE_START);
           if (!captureByFrame) {
              captureByFrame = (state->flags & VICII_OP_CAPTURE_ONE_FRAME);
              captureByFrameStopXpos = lastXPos;
              captureByFrameStopYpos = screenHeight-1;
           }

           if (state->flags & VICII_OP_SYNC_STATE) {
               state->flags &= ~VICII_OP_SYNC_STATE;
               // Step forward until we get to the target cycle/line/phase.
               // rasterline and when dot4x just ticked low (we always tick into high
               // when beginning to step so we must leave dot4x low. We
	       // don't have to worry about going over the last xpos or
	       // the repeats on the R8 because the VICE sync won't attempt
	       // a sync past xpos 0x17c.
               while (true) {
                  top->eval();

		  if (top->V_CYCLE_NUM == state->cycle_num &&
				  top->V_RASTER_LINE == state->raster_line &&
				  top->clk_phi) break;

#if VM_TRACE
	          if (tfp) tfp->dump(ticks / TICKS_TO_TIMESCALE);
#endif
                  ticks = nextTick(top, tfp, chip);
                  STATE(top);
                  STORE_PREV();
               }

               // Now 3 more ticks + 1 more from leaving this block
               // and we will land one 'step' into our target cycle.
               for (int i=0; i< 3; i++) {
                  top->eval();
#if VM_TRACE
	          if (tfp) tfp->dump(ticks / TICKS_TO_TIMESCALE);
#endif
                  ticks = nextTick(top, tfp, chip);
                  STATE(top);
                  STORE_PREV();
               }

	       regs_vice_to_fpga(top, state);

               // Our next tick will bring us high so we should be low right now.
               CHECK(top, ~top->clk_phi, __LINE__);

               LOG(LOG_INFO, "synced FPGA to cycle=%u, raster_line=%u, xpos=%03x, bmm=%d, mcm=%d, ecm=%d",
                  state->cycle_num, state->raster_line, state->xpos, top->V_BMM, top->V_MCM, top->V_ECM);

	      // Respond to IPC immediately after 1 more tick. This will land us 4 ticks into the
	      // high phase which is where VICE ipc hook expects us to be.
              ticksUntilDone = 1;
              ticksUntilPhase = 1;
	      last_phase = 0;
           } else {
              ticksUntilDone = 4;
	   }
        }

        if (shadowVic) {
           // Simulate cs and rw going back high. This is the same
           // timing as what vice hook does when it lowers ce for the
           // CPU writes on the phi high side.
           if (top->clk_phi == 0 && nextClkCnt == 4) {
              state->ce = 1;
              state->rw = 1;
           }

           // VICE -> SIM state sync
           top->adl = state->addr_to_sim;
           top->dbl = state->data_to_sim & 0xff;
           top->dbh = (state->data_to_sim >> 8) & 0xf;
           top->ce = state->ce;
           top->rw = state->rw;
	   top->lp = state->lp;

        }

        // Evaluate model
        top->eval();

        if (shadowVic) {
           if (state->flags & VICII_OP_BUS_ACCESS) {
              CHECK(top, top->clk_phi, __LINE__);
           }
	}

#if VM_TRACE
	if (tfp) tfp->dump(ticks / TICKS_TO_TIMESCALE);
#endif

        if (showState) {
           STATE(top);
        }

        if (captureByTime)
           capture = (ticks >= startTicks) && (ticks <= endTicks);

        if (capture) {
          // On dot clock...
          if (HASCHANGED(OUT_DOT) && RISING(OUT_DOT)) {
             // AEC should always be low in first phase. But AEC is
	     // slightly delayed so don't check this when bit cycle is 0
             if (top->V_CYCLE_BIT > 0 && top->V_CYCLE_BIT < 4) {
               CHECK(top, top->aec == 0, __LINE__);
             }

             // Make sure xpos is what we expect at key points
             if (top->V_CYCLE_NUM == 12 && top->V_CYCLE_BIT == 4)
               CHECK (top, top->V_XPOS == 0, __LINE__); // rollover

             if (top->V_CYCLE_NUM == 0 && top->V_CYCLE_BIT == 0)
               if (chip == CHIP6569R1 || chip == CHIP6569R3)
                  CHECK (top, top->V_XPOS == 0x194, __LINE__); // reset
               else
                  CHECK (top, top->V_XPOS == 0x19c, __LINE__); // reset

             if (chip == CHIP6567R8)
               if (top->V_CYCLE_NUM == 61 && (top->V_CYCLE_BIT == 0 || top->V_CYCLE_BIT == 4))
                  CHECK (top, top->V_XPOS == 0x184, __LINE__); // repeat cases
               else if (top->V_CYCLE_NUM == 62 && top->V_CYCLE_BIT == 0)
                  CHECK (top, top->V_XPOS == 0x184, __LINE__); // repeat case

             // Refresh counter is supposed to reset at raster 0
             //if (top->V_RASTER_X == 0 && top->V_RASTER_LINE == 0) TODO Put back
             //   CHECK (top, top->V_REFC == 0xff, __LINE__);

          }

          // If rendering, draw current color on dot clock
	  // Our simulator resolution is twice that of native so we can
	  // update every other dot clock tick.
	  // dot_rising[1] || dot_rising[3]
          if (showWindow && HASCHANGED(OUT_DOT_RISING) &&
			  (top->V_CLK_DOT == 2 || top->V_CLK_DOT == 8)) {
#ifdef GEN_RGB
            // Show h/v sync in red
            if (!hideSync && (!top->hsync || !top->vsync))
             SDL_SetRenderDrawColor(ren,
                0b11111111,
                0b0,
                0b0,
                255);
            else {
             double rr = top->red * 255.0/63.0;
             double gg = top->green * 255.0/63.0;
             double bb = top->blue * 255.0/63.0;
             SDL_SetRenderDrawColor(ren, rr, gg, bb, 255);
            }

            // PURPLE ACTIVE AREA - DEBUGGING
            if (showActive && (top->active))
             SDL_SetRenderDrawColor(ren,
                0b11111111,
                0b0,
                255,
                0b0);
#else 
#ifdef NEED_RGB
            // Show h/v sync in red
            if (!hideSync && (top->HSYNC || top->VSYNC))
             SDL_SetRenderDrawColor(ren,
                0b11111111,
                0b0,
                0b0,
                255);
            else {
             double rr = top->top__DOT__red * 255.0/63.0;
             double gg = top->top__DOT__green * 255.0/63.0;
             double bb = top->top__DOT__blue * 255.0/63.0;
             SDL_SetRenderDrawColor(ren, rr,gg,bb,255);
            }

            // PURPLE ACTIVE AREA - DEBUGGING
            if (showActive && (top->ACTIVE))
             SDL_SetRenderDrawColor(ren,
                0b11111111,
                0b0,
                255,
                0b0);

#else
#ifdef GEN_LUMA_CHROMA
            // Fallback to native pixel sequencer's pixel3 value
	    // and lookup colors.
            int hss = 10; // see comp_sync.v  top->top__DOT__vic_inst__DOT__vic_comp_sync__DOT__hsync_start;
            int hse = top->top__DOT__vic_inst__DOT__vic_comp_sync__DOT__hsync_end;
            int vss = top->top__DOT__vic_inst__DOT__vic_comp_sync__DOT__vblank_start;
            //int vse = top->top__DOT__vic_inst__DOT__vic_comp_sync__DOT__vblank_end;
            int vve = top->top__DOT__vic_inst__DOT__vic_comp_sync__DOT__vvisible_end;
            int vvs = top->top__DOT__vic_inst__DOT__vic_comp_sync__DOT__vvisible_start;
	    // This is the same condition in comp_sync.v
            int vsync = (top->V_RASTER_LINE >= vve && top->V_RASTER_LINE <= vvs);
            // If we're not in vsync or within native active range, show pixel colors
	    if ((!vsync && top->top__DOT__vic_inst__DOT__vic_comp_sync__DOT__native_active) || hideSync) {
	       int index = top->top__DOT__vic_inst__DOT__pixel_color3;
               SDL_SetRenderDrawColor(ren,
                (native_rgb[index*3] << 2) | 0b11,
                (native_rgb[index*3+1] << 2) | 0b11,
                (native_rgb[index*3+2] << 2) | 0b11,
                255);
	    } else {
               // NOTE: If we're in vsync show red color, except we omit vve and vss to match what comp_sync.v does
               // (special cases)
	       if ((top->V_RASTER_X >= hss && top->V_RASTER_X < hse) ||
                      (vsync && top->V_RASTER_LINE != vve && top->V_RASTER_LINE != vvs))
#ifdef HAVE_LUMA_SINK
                  SDL_SetRenderDrawColor(ren, 255*top->V_LUMA_SINK,0,0,255);
#else
                  // Only for old beta boards
                  SDL_SetRenderDrawColor(ren, 255,0,0,255);
#endif
	       else
                  SDL_SetRenderDrawColor(ren, 0,0,0,255);
	    }
#else
#warning "There are no video output options available. Simulator will show nothing"
#endif
#endif
#endif
             // top->V_CLK_DOT is 2 or 8
	     int hoffset = top->V_CLK_DOT == 2 ? 0 : 1;

             int rl = top->V_RASTER_LINE;

             // This shifts everything up for NTSC so we can see
             // the whole screen like on a monitor.  The value 25
             // here should be close to the vstart values for the chips.
             switch (chip) {
                case CHIP6567R8:
                   rl-= 25;
                   if (rl < 0) rl+=263;
                   break;
                case CHIP6567R56A:
                   rl-= 25;
                   if (rl < 0) rl+=262;
                   break;
                case CHIP6569R1:
                default:
                   break;
             }

             if (top->top__DOT__vic_inst__DOT__is_native_y) {
               drawPixel(ren,
                  top->V_RASTER_X*2+hoffset,
                  rl
               );
             } else {
               // Draw fatter pixels for double y
               drawPixel(ren,
                  top->V_RASTER_X*4+hoffset*2,
                  rl
               );
               drawPixel(ren,
                  top->V_RASTER_X*4+1+hoffset*2,
                  rl
               );
             }

             // Show updated pixels per raster line
             if (prevY != rl) {
                prevY = rl;

                if (scanline) {
                   for (int xx=0; xx < 504; xx++) {
                     SDL_SetRenderDrawColor(ren, 255, 255, 255, 255);
                     drawPixel(ren, xx*2, rl+1);
                   }
                }

                SDL_RenderPresent(ren);
                SDL_PollEvent(&event);
                switch (event.type) {
                   case SDL_QUIT:
                      state->flags |= VICII_OP_CAPTURE_END;
                      break;
                   default:
                      break;
                }
             }
          }
        }


        if (shadowVic) {
           state->irq = top->irq;
           state->irst = top->V_IRST;
           state->immc = top->V_IMMC;
           state->imbc = top->V_IMBC;
           state->ilp = top->V_ILP;
           state->ba = top->ba;
           state->badline = top->V_BADLINE;
           state->aec = top->aec;
           state->phi = top->clk_phi;
	   state->addr_from_sim = top->V_VICADDR;

           // We have to simulate the ROM glitch and keep VICE
           // happy with address comparisons.
           // See addressgen.v for the description of the glitch.
           if (top->V_CYCLE_TYPE == VIC_LG) {
               if (top->V_BMM_DELAYED != top->V_BMM) {
                  uint16_t from_addr = top->V_VICADDR + state->vice_vbank_phi1;
                  uint16_t to_addr = top->V_VICADDR_NOW + state->vice_vbank_phi1;
                  // This is the same cheat VICE uses. But we implement the glitch
                  // the 'real' way on the actual hardware.  This is just for VICE
                  // sync comparison to keep address match happy.
                  if ((from_addr & 0x7000) != 0x1000 && (to_addr & 0x7000) == 0x1000) {
                      state->addr_from_sim = (top->V_VICADDR & 0xff) | (top->V_VICADDR_NOW & 0xff00);
                  }
               }
           }

	   state->cycle_num = top->V_CYCLE_NUM;
	   state->xpos = top->V_XPOS;
	   state->raster_line = top->V_RASTER_LINE_D;
           state->cycleByCycleStepping = cycleByCycle;
	   state->idle = top->V_IDLE;
	   state->allow_bad_lines = top->V_ALLOW_BAD_LINES;
	   state->reg11_delayed = top->V_REG11_DELAYED;
	   state->vborder = top->V_VBORDER;
	   state->main_border = top->V_MAIN_BORDER;
	   state->pps = top->V_PPS;
	   state->dot4x = top->V_DOT4X ? 1 : 0;

           if (top->ce == 0 && top->rw == 1) {
              // Chip selected and read, set data in state
              state->data_from_sim = top->V_DBO;
           }
           regs_fpga_to_vice(top, state);

           bool needQuit = false;
           if (state->flags & VICII_OP_CAPTURE_END) {
              keyPressToQuit = false;
              needQuit = true;
           }

           // After we have one full frame, exit the loop.
           if (captureByFrame &&
              top->V_XPOS == captureByFrameStopXpos &&
                 top->V_RASTER_LINE == captureByFrameStopYpos) {
              state->flags &= ~VICII_OP_CAPTURE_START;
              ipc_receive_done(ipc);
              break;
           }
	   if (viceCapture) {
              if (viceCaptureWaitLine1) {
		     if (top->V_XPOS == 0 && top->V_RASTER_LINE == 0) {
		         viceCaptureWaitLine1 = false;
		     }
	      } else if (top->V_XPOS == lastXPos && top->V_RASTER_LINE == screenHeight - 1) {
               state->flags |= VICII_OP_CAPTURE_ABORT;
               ipc_receive_done(ipc);

               SDL_Surface *sshot = SDL_CreateRGBSurface(0, screenWidth*2, screenHeight*2,
                   32, 0x00ff0000, 0x0000ff00, 0x000000ff, 0xff000000);
               SDL_RenderReadPixels(ren, NULL, SDL_PIXELFORMAT_ARGB8888,
                                    sshot->pixels, sshot->pitch);
               SDL_SaveBMP(sshot, "screenshot.bmp");
               SDL_FreeSurface(sshot);
               exit(0);
	     }
	   }

           ticksUntilDone--;
           ticksUntilPhase--;

           if (ticksUntilDone == 0 || needQuit) {
              // Do not change state after this line
              if (ipc_receive_done(ipc))
                 break;
           }

           if (needQuit) {
              // Safe to quit now. We sent our response.
              break;
           }

	   if (cycleByCycle && top->clk_phi != last_phase) {
               printf ("FINISHED PHASE %d (now cycle=%d, line=%d, xpos=%03x)\n",
                     last_phase+1, top->V_CYCLE_NUM,
                           top->V_RASTER_LINE, top->V_XPOS);

               printf ("   VCBASE=%02d   VADDR=%04x\n", top->V_VCBASE, top->V_VICADDR);
               printf ("   VC=%03d     CTYPE=%d\n", top->V_VC, top->V_CYCLE_TYPE);
               printf ("   CB=%03d     CHARPTR=%02x\n", top->V_CB, top->V_NEXTCHAR);
               printf ("   XPOS=%04d   RC=%d\n", top->V_XPOS, top->V_RC);
               printf ("   BMM=%02d    SPRNUM=%d\n", top->V_BMM, top->V_SPRITE_CNT);
               printf ("   MCM=%d\n", top->V_MCM);
               printf ("   ECM=%d\n", top->V_ECM);
               printf ("\n");

	       last_phase = top->clk_phi;
	   }

           if (cycleByCycle && ticksUntilPhase == 0) {
                ticksUntilPhase = 4*8; // 8 sets of 4 dot4x ticks
		// Pause after first tick of next phase
		printf ("(PAUSE NEXT PHASE 1st tick)\n");

		if (showWindow && cycleByCycleCount == 0)
                   SDL_RenderPresent(ren);

		if (cycleByCycleCount == 0) {
                  bool quit = false;
                  while (!quit) {
                     while (SDL_PollEvent(&event)) {
			SDL_KeyboardEvent* ke = (SDL_KeyboardEvent*)&event;
			int n;
			struct vicii_state tmp_state;
                        switch (event.type) {
                           case SDL_QUIT:
                                 quit=true; break;
                           case SDL_KEYUP:
		  	    switch (ke->keysym.sym) {
				 // Next half cycle
                                 case SDLK_RIGHT:
                                    quit=true; break;
				 // Next 10 cycles
				 case SDLK_l:
		        	    cycleByCycleCount = 20;
                                    quit=true; break;
				 // Next lines
                                 case SDLK_SPACE:
		        	    cycleByCycleCount = numCycles * 2;
                                    quit=true; break;
				 // Next 10 lines
                                 case SDLK_n:
		        	    cycleByCycleCount = numCycles * 20;
                                    quit=true; break;
				 // Show regs
                                 case SDLK_r:
				    regs_fpga_to_vice(top, &tmp_state);
				    for (n=0;n<0x2f;n++) {
                                       printf ("%02x=%02x %s\n", n,
                                          tmp_state.fpga_reg[n],
					     toBin(8,tmp_state.fpga_reg[n]));
                                    }
                                    printf ("IDLE %d\n", top->V_IDLE);
                                    printf ("CYCLE_TYPE  %d\n", top->V_CYCLE_TYPE);
                                    printf ("CHAR NEXT  %x\n", top->V_CHAR_NEXT);
                                    printf ("CB %s\n", toBin(3,top->V_CB));
                                    printf ("VM %s\n", toBin(4,top->V_VM));
				    break;
			       default:
				  break;
		            }
                           default:
                              break;
                           }
                      }
                    }
                } else {
		   cycleByCycleCount--;
		}
           }
        }

        // End of eval. Remember current values for previous compares.
        STORE_PREV();

        // Is it time to stop?
        if (captureByTime && ticks >= endTicks)
           break;

        // Advance simulation time. Each tick represents 1 picosecond.
        ticks = nextTick(top, tfp, chip);
    }

    if (shadowVic) {
       ipc_close(ipc);
    }

    if (showWindow) {

       // Instead of waiting for a key, do the capture if requested
       if (endCapture) {
          SDL_Surface *sshot = SDL_CreateRGBSurface(0, screenWidth*2, screenHeight*2,
             32, 0x00ff0000, 0x0000ff00, 0x000000ff, 0xff000000);
          SDL_RenderReadPixels(ren, NULL, SDL_PIXELFORMAT_ARGB8888,
             sshot->pixels, sshot->pitch);
          SDL_SaveBMP(sshot, "screenshot.bmp");
          SDL_FreeSurface(sshot);
          exit(0);
       }

       bool quit = false;
       while (!quit && keyPressToQuit) {
          while (SDL_PollEvent(&event)) {
             switch (event.type) {
                case SDL_QUIT:
                case SDL_KEYUP:
                   quit=true; break;
                default:
                   break;
             }
           }
       }

       SDL_DestroyRenderer(ren);
       SDL_DestroyWindow(win);
       SDL_Quit();
    }

    // Final model cleanup
    top->final();

#if VM_TRACE
    if (tfp) { tfp->close(); tfp = NULL; }
#endif

    // Destroy model
    delete top;

    // Fin
    exit(0);
}
