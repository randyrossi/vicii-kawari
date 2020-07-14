#include <SDL2/SDL.h>

#include <iostream>

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <verilated.h>
#include <regex.h>

#include "Vvicii.h"
#include "constants.h"

#if VM_TRACE
#include <verilated_vcd_c.h>
#endif

extern "C" {
#include "vicii_ipc.h"
}
#include "log.h"
#include "test.h"
// Current simulation time (64-bit unsigned). See
// constants.h for how much each tick represents.
static vluint64_t ticks = 0;
static vluint64_t half4XDotPS;
static vluint64_t startTicks;
static vluint64_t endTicks;
static vluint64_t nextClk;
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
   OUT_PHI = 0,
   IN_RST,
   OUT_R0, OUT_R1,
   OUT_G0, OUT_G1,
   OUT_B0, OUT_B1,
   OUT_DOT,
   //OUT_CSYNC,
   OUT_A0, OUT_A1, OUT_A2, OUT_A3, OUT_A4, OUT_A5, OUT_A6, OUT_A7,
   OUT_A8, OUT_A9, OUT_A10, OUT_A11,
   IN_A0, IN_A1, IN_A2, IN_A3, IN_A4, IN_A5, IN_A6, IN_A7,
   IN_A8, IN_A9, IN_A10, IN_A11,
   OUT_D0, OUT_D1, OUT_D2, OUT_D3, OUT_D4, OUT_D5, OUT_D6, OUT_D7,
   IN_D0, IN_D1, IN_D2, IN_D3, IN_D4, IN_D5, IN_D6, IN_D7,
   IN_D8, IN_D9, IN_D10, IN_D11,
   IN_CE,
   IN_RW,
   OUT_BA,
   OUT_AEC,
   OUT_IRQ,
   OUT_RAS, OUT_CAS
};

#define NUM_SIGNALS 60

// Add new input/output here
const char *signal_labels[] = {
   "phi", "rst", "r0", "r1", "g0", "g1", "b0", "b1" , "dot", //"csync",
   "ao0", "ao1", "ao2", "ao3", "ao4", "ao5", "ao6", "ao7", "ao8", "ao9", "ao10", "ao11",
   "ai0", "ai1", "ai2", "ai3", "ai4", "ai5", "ai6", "ai7", "ai8", "ai9", "ai10", "ai11",
   "do0", "do1", "do2", "do3", "do4", "do5", "do6", "do7",
   "di0", "di1", "di2", "di3", "di4", "di5", "di6", "di7", "di8", "di9", "di10", "di11",
   "ce", "rw", "ba", "aec", "irq",
   "ras", "cas"
};
const char *signal_ids[] = {
   "p", "r" ,  "r0", "r1", "g0", "g1", "b0", "b1" , "dot", //"s",
   "ao0", "ao1", "ao2", "ao3", "ao4", "ao5", "ao6", "ao7", "ao8", "ao9", "ao10", "ao11",
   "ai0", "ai1", "ai2", "ai3", "ai4", "ai5", "ai6", "ai7", "ai8", "ai9", "ai10", "ai11",
   "do0", "do1", "do2", "do3", "do4", "do5", "do6", "do7",
   "di0", "di1", "di2", "di3", "di4", "di5", "di6", "di7", "di8", "di9", "di10", "di11",
   "ce", "rw", "ba", "aec", "irq",
   "ras", "cas"
};

static unsigned int signal_width[NUM_SIGNALS];
static unsigned char *signal_src8[NUM_SIGNALS];
static unsigned short *signal_src16[NUM_SIGNALS];
static unsigned int signal_bit[NUM_SIGNALS];
static unsigned char prev_signal_values[NUM_SIGNALS];

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

static int SGETVAL(int signum) {
  if (signal_width[signum] <= 8) {
     return (*signal_src8[signum] & signal_bit[signum] ? 1 : 0);
  } else if (signal_width[signum] > 8 && signal_width[signum] < 16) {
     return (*signal_src16[signum] & signal_bit[signum] ? 1 : 0);
  } else {
    abort();
  }
}

static void HEADER(Vvicii *top) {
   LOG(LOG_VERBOSE,
   "  "
   "D4X "
   "CNT "
   "POS "
   "CYC "
   "DOT "
   "PHI "
   "BIT "
   "IRQ "
   "BA "
   "AEC "
   "VCY "
   "RAS "
   "MUX "
   "CAS "
   " X  "
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

static void STATE(Vvicii *top) {
   if ((top->clk_dot4x & 1) == 0) return;

   if(HASCHANGED(OUT_DOT) && RISING(OUT_DOT))
      HEADER(top);

   LOG(LOG_VERBOSE,
   "%c "      /*DOT*/
   "%01d   "   /*D4x*/
   "%02d  "   /*CNT*/
   "%03x "   /*POS*/
   " %02d "  /*CYC*/
   " %01d  "   /*DOT*/
   " %01d  "   /*PHI*/
   " %01d  "   /*BIT*/
   " %01d  "   /*IRQ*/
   " %01d  "   /*BA */
   " %01d  "   /*AEC*/
   "%c  "     /*VCY*/
   " %01d  "   /*RAS*/
   " %01d  "   /*MUX*/
   " %01d  "   /*CAS*/
   "%03d "   /*  X*/
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

   top->rst ? 'R' : HASCHANGED(OUT_DOT) && RISING(OUT_DOT) ? '*' : ' ',
   top->clk_dot4x ? 1 : 0,
   nextClkCnt,
   top->V_XPOS,
   top->V_CYCLE_NUM,
   top->V_CLK_DOT,
   top->clk_phi,
   top->V_CYCLE_BIT,
   top->irq,
   top->ba,
   top->aec,
   cycleToChar(top->V_CYCLE_TYPE),
   top->ras,
   top->V_MUXR & 32768 ? 1 : 0,
   top->cas,
   top->V_RASTER_X,
   top->V_RASTER_LINE,
   top->adi,
   top->ado,
   top->dbi,
   top->dbo,
   top->rw,
   top->ce,
   top->V_REFC,

   //toBin(16, top->V_RASR),
   //toBin(16, top->V_MUXR),
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


static void CHECK(Vvicii *top, int cond, int line) {
  if (!cond) {
     printf ("FAIL line %d:", line);
     STATE(top);
     exit(-1);
  }
}

// We can drive our simulated clock gen every pico second but that would
// be a waste since nothing happens between clock edges. This function
// will determine how many ticks(picoseconds) to advance our clock.
static vluint64_t nextTick(Vvicii* top) {
   vluint64_t diff1 = nextClk - ticks;

   nextClk += half4XDotPS;
   top->clk_dot4x = ~top->clk_dot4x;
   nextClkCnt = (nextClkCnt + 1) % 32;
   return ticks + diff1;
}

static void drawPixel(SDL_Renderer* ren, int x,int y) {
   SDL_RenderDrawPoint(ren, x*2,y*2);
   SDL_RenderDrawPoint(ren, x*2+1,y*2);
   SDL_RenderDrawPoint(ren, x*2,y*2+1);
   SDL_RenderDrawPoint(ren, x*2+1,y*2+1);
}

static void regs_vice_to_fpga(Vvicii* top, struct vicii_state* state) {
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
       top->V_SPRITE_M2M_PENDING = state->vice_reg[0x1e];
       top->V_SPRITE_M2D = state->vice_reg[0x1f];
       top->V_SPRITE_M2D_PENDING = state->vice_reg[0x1f];

       top->V_SPRITE_MC0 = state->vice_reg[0x25];
       top->V_SPRITE_MC1 = state->vice_reg[0x26];

       for (int n=0;n<8;n++) {
          top->V_SPRITE_MC[n] = state->mc[n];
          top->V_SPRITE_MCBASE[n] = state->mcbase[n];
          top->V_SPRITE_YE_FF[n] = state->ye_ff[n];
	  top->V_SPRITE_DMA[n] = state->sprite_dma[n];
          top->V_SPRITE_COL[n] = state->vice_reg[0x27+n];
       }

       top->V_RASTER_IRQ_TRIGGERED = state->raster_irq_triggered;
       top->V_IRST = state->irst;
       top->V_IMBC = state->imbc;
       if (state->vice_reg[0x1f] != 0) top->V_M2D_TRIGGERED = 1;
       top->V_IMBC_PENDING = state->imbc;
       top->V_IMMC = state->immc;
       top->V_IMMC_PENDING = state->immc;
       if (state->vice_reg[0x1e] != 0) top->V_M2M_TRIGGERED = 1;
       top->V_ILP = state->ilp;

       top->V_TBBORDER = state->vborder;
       top->V_LRBORDER = state->main_border;

       // We need to populate our char buf from VICE's
       top->V_CHAR_BUF[38] = state->char_buf[0] | (state->color_buf[0] << 8);
       for (int i=37,j=1;i>=0;i--,j++) {
          top->V_CHAR_BUF[i] = state->char_buf[j] | (state->color_buf[j] << 8);
       }
       top->V_CHAR_NEXT = state->char_buf[39] | (state->color_buf[39] << 8);
}

static void regs_fpga_to_vice(Vvicii* top, struct vicii_state* state) {
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

       for (int n=0;n<8;n++) {
          state->mc[n] = top->V_SPRITE_MC[n];
          state->mcbase[n] = top->V_SPRITE_MCBASE[n];
          state->ye_ff[n] = top->V_SPRITE_YE_FF[n];
          state->sprite_dma[n] = top->V_SPRITE_DMA[n];
          state->fpga_reg[0x27+n] = top->V_SPRITE_COL[n] | 0xf0;
       }
}


int main(int argc, char** argv, char** env) {
    SDL_Event event;
    SDL_Renderer* ren = nullptr;
    SDL_Window* win;

    struct vicii_state* state;
    bool capture = false;

    int chip = CHIP6569;
    bool isNtsc = false;

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
    int testDriver = -1;
    int setGolden = 0;

    while ((c = getopt (argc, argv, "c:hs:d:wi:zbl:r:gt")) != -1)
    switch (c) {
      case 't':
        tracing = true;
        break;
      case 'g':
        setGolden = 1;
        break;
      case 'r':
        testDriver = atoi(optarg);
        if (testDriver < 1) testDriver = 1;
        captureByTime = false;
        captureByFrame = false;
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
        printf ("  -c <chip> : 0=CHIP6567R8, 1=CHIP6567R56A 2=CHIP65669\n");
        printf ("  -r <test> : run test driver #\n");
        printf ("  -g <test> : make golden master for test #\n");
        printf ("  -h        : start under reset\n");
        printf ("  -l        : log level\n");
        exit(0);
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
    Vvicii* top = new Vvicii;

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

    top->chip = chip;
    top->eval();

    switch (top->chip) {
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
       case CHIP6569:
          isNtsc = false;
          printf ("CHIP: 6569\n");
          printf ("VIDEO: PAL\n");
          break;
       default:
          LOG(LOG_ERROR, "unknown chip");
          exit(-1);
          break;
    }
    printf ("Log Level: %d\n", logLevel);

    if (userDurationUs == -1) {
       switch (top->chip) {
          case CHIP6567R8:
          case CHIP6567R56A:
             durationTicks = US_TO_TICKS(16700L);
             break;
          case CHIP6569:
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
       switch (top->chip) {
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
       switch (top->chip) {
          case CHIP6569:
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
    endTicks = startTicks + durationTicks;

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
    signal_src8[OUT_PHI] = &top->clk_phi;
    signal_src8[IN_RST] = &top->rst;
    signal_src8[OUT_R0] = &top->red;
    signal_src8[OUT_R1] = &top->red;
    signal_bit[OUT_R1] = 2;
    signal_src8[OUT_G0] = &top->green;
    signal_src8[OUT_G1] = &top->green;
    signal_bit[OUT_G1] = 2;
    signal_src8[OUT_B0] = &top->blue;
    signal_src8[OUT_B1] = &top->blue;
    signal_bit[OUT_B1] = 2;
    signal_src8[OUT_DOT] = &top->V_CLK_DOT;
    //signal_src8[OUT_CSYNC] = &top->V_CSYNC;
    signal_src8[IN_CE] = &top->ce;
    signal_src8[IN_RW] = &top->rw;
    signal_src8[OUT_BA] = &top->ba;
    signal_src8[OUT_AEC] = &top->aec;
    signal_src8[OUT_IRQ] = &top->irq;
    signal_src8[OUT_RAS] = &top->ras;
    signal_src8[OUT_CAS] = &top->cas;

    int bt = 1;
    for (int i=OUT_A0; i<= OUT_A11; i++) {
       signal_width[i] = 12;
       signal_bit[i] = bt;
       signal_src16[i] = &top->ado;
       bt = bt * 2;
    }
    bt = 1;
    for (int i=IN_A0; i<= IN_A11; i++) {
       signal_width[i] = 6;
       signal_bit[i] = bt;
       signal_src8[i] = &top->adi;
       bt = bt * 2;
    }
    bt = 1;
    for (int i=OUT_D0; i<= OUT_D7; i++) {
       signal_width[i] = 8;
       signal_bit[i] = bt;
       signal_src8[i] = &top->dbo;
       bt = bt * 2;
    }
    bt = 1;
    for (int i=IN_D0; i<= IN_D11; i++) {
       signal_width[i] = 12;
       signal_bit[i] = bt;
       signal_src16[i] = &top->dbi;
       bt = bt * 2;
    }

    HEADER(top);

    // Hold the design under reset, simulating the time
    // it takes to wait for phase lock from the clock.
    printf ("(RESET)\n");
    top->rst = 1;
    top->is_composite = 1;
    top->lp = 1;
    for (int i=0;i<32;i++) {
       top->eval();
       nextClkCnt = 0;
#if VM_TRACE
       if (tfp) tfp->dump(ticks / TICKS_TO_TIMESCALE);
#endif
       STATE(top);
       STORE_PREV();
       ticks = nextTick(top);
    }
    nextClkCnt = 31;
    top->rst = 0;
    top->rw = 1;
    top->ce = 1;
    top->adi = 0;
    top->dbi = 0;
    top->V_DEN = 1;
    top->V_B0C = 6;
    top->V_EC = 14;
    top->V_VM = 1; // 0001
    top->V_CB = 2; //  010
    top->V_YSCROLL = 3; //  011

    if (testDriver >= 0 && do_test_start(testDriver, top, setGolden) == TEST_FAIL) {
       STATE(top);
       LOG(LOG_ERROR, "test %d failed\n", testDriver);
       exit(-1);
    }

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
    while (!Verilated::gotFinish()) {

        // Are we shadowing from VICE? Wait for sync data, then
        // step until next dot clock tick.
        if (shadowVic && ticksUntilDone == 0) {
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
                  ticks = nextTick(top);
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
                  ticks = nextTick(top);
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
           top->adi = state->addr_to_sim;
           top->dbi = state->data_to_sim;
           top->ce = state->ce;
           top->rw = state->rw;
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

        // When driving a test, it's nice to only show what's being captured
        // by that test.
        if (testDriver >= 0) {
           int tst = do_test(testDriver, top, setGolden);
           if (tst == TEST_END) {
              if (showState) {
                 STATE(top);
              }
	      break;
	   }
           if (tst == TEST_FAIL) {
              STATE(top);
              LOG(LOG_ERROR, "test %d failed\n", testDriver);
              exit(-1);
           }
           showState = tst == TEST_CONTINUE_CAPTURING ? true : false;
        }

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
               if (chip == CHIP6569)
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

             if(top->V_CYCLE_BIT == 0 || top->V_CYCLE_BIT == 4) {
                // CAS & RAS should be high at the start of each phase
                // Timing and vicycle will determine when they fall if ever
                CHECK (top, top->cas != 0, __LINE__);
                CHECK (top, top->ras != 0, __LINE__);
             }
          }

          // If rendering, draw current color on dot clock
          if (showWindow && HASCHANGED(OUT_DOT) && RISING(OUT_DOT)) {
             SDL_SetRenderDrawColor(ren,
                top->red << 5,
                top->green << 5,
                top->blue << 5,
                255);
             drawPixel(ren,
                top->V_RASTER_X,
                top->V_RASTER_LINE
             );

             // Show updated pixels per raster line
             if (prevY != top->V_RASTER_LINE) {
                prevY = top->V_RASTER_LINE;

		for (int xx=0; xx < 504; xx++) {
                   SDL_SetRenderDrawColor(ren, 255, 255, 255, 255);
                   drawPixel(ren, xx, top->V_RASTER_LINE+1);
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
	   state->addr_from_sim = top->V_VICADDR; // cheat
	   state->cycle_num = top->V_CYCLE_NUM;
	   state->xpos = top->V_XPOS;
	   state->raster_line = top->V_RASTER_LINE;
           state->cycleByCycleStepping = cycleByCycle;
	   state->idle = top->V_IDLE;
	   state->allow_bad_lines = top->V_ALLOW_BAD_LINES;
	   state->reg11_delayed = top->V_REG11_DELAYED;
           if (top->ce == 0 && top->rw == 1) {
              // Chip selected and read, set data in state
              state->data_from_sim = top->dbo;
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
               printf ("FINISHED PHASE %d (now cycle=%d, line=%d, xpos=%03x) VC=%d VCBASE=%d RC=%d\n",
                     last_phase+1, top->V_CYCLE_NUM, top->V_RASTER_LINE, top->V_XPOS, top->V_VC, top->V_VCBASE, top->V_RC);
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
                                       printf ("%02x=%02x\n", n, tmp_state.fpga_reg[n]);
                                    }
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
        ticks = nextTick(top);
    }

    if (shadowVic) {
       ipc_close(ipc);
    }

    if (showWindow) {
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
