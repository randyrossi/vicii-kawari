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
   OUT_COLREF,
   IN_RST,
   OUT_R0, OUT_R1,
   OUT_G0, OUT_G1,
   OUT_B0, OUT_B1,
   OUT_DOT,
   OUT_CSYNC,
   OUT_A0, OUT_A1, OUT_A2, OUT_A3, OUT_A4, OUT_A5, OUT_A6, OUT_A7,
   OUT_A8, OUT_A9, OUT_A10, OUT_A11,
   IN_A0, IN_A1, IN_A2, IN_A3, IN_A4, IN_A5, IN_A6, IN_A7,
   IN_A8, IN_A9, IN_A10, IN_A11,
   OUT_D0, OUT_D1, OUT_D2, OUT_D3, OUT_D4, OUT_D5, OUT_D6, OUT_D7,
   OUT_D8, OUT_D9, OUT_D10, OUT_D11,
   IN_D0, IN_D1, IN_D2, IN_D3, IN_D4, IN_D5, IN_D6, IN_D7,
   IN_D8, IN_D9, IN_D10, IN_D11,
   IN_CE,
   IN_RW,
   OUT_BA,
   OUT_AEC,
   OUT_IRQ,
   OUT_RAS, OUT_CAS
};

#define NUM_SIGNALS 66

// Add new input/output here
const char *signal_labels[] = {
   "phi", "col", "rst", "r0", "r1", "g0", "g1", "b0", "b1" , "dot", "csync",
   "ao0", "ao1", "ao2", "ao3", "ao4", "ao5", "ao6", "ao7", "ao8", "ao9", "ao10", "ao11",
   "ai0", "ai1", "ai2", "ai3", "ai4", "ai5", "ai6", "ai7", "ai8", "ai9", "ai10", "ai11",
   "do0", "do1", "do2", "do3", "do4", "do5", "do6", "do7", "do8", "do9", "do10", "do11",
   "di0", "di1", "di2", "di3", "di4", "di5", "di6", "di7", "di8", "di9", "di10", "di11",
   "ce", "rw", "ba", "aec", "irq",
   "ras", "cas"
};
const char *signal_ids[] = {
   "p", "c", "r" ,  "r0", "r1", "g0", "g1", "b0", "b1" , "dot", "s",
   "ao0", "ao1", "ao2", "ao3", "ao4", "ao5", "ao6", "ao7", "ao8", "ao9", "ao10", "ao11",
   "ai0", "ai1", "ai2", "ai3", "ai4", "ai5", "ai6", "ai7", "ai8", "ai9", "ai10", "ai11",
   "do0", "do1", "do2", "do3", "do4", "do5", "do6", "do7", "do8", "do9", "do10", "do11",
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
   top->V_BIT_CYCLE,
   top->irq,
   top->ba,
   top->aec,
   cycleToChar(top->vicCycle),
   top->ras,
   top->mux,
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

   top->V_VC,
   top->V_VCBASE,
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
    bool renderEachPixel = false;
    bool startWithReset = false;
    bool tracing = false;
    int prevY = -1;
    int prevX = -1;
    struct vicii_ipc* ipc;

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

    while ((c = getopt (argc, argv, "c:hs:d:wi:zb:l:r:gjt")) != -1)
    switch (c) {
      case 't':
        tracing = true;
        break;
      case 'j':
        startWithReset = true;
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
        // Render after every pixel instead of after every line
        renderEachPixel = true;
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
        printf ("  -b        : render each pixel instead of each line\n");
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
    top->rw = 1;
    top->ce = 1;
    top->clk_phi = 0;
    top->rst = 0;
    top->adi = 0;
    top->dbi = 0;
    top->chip = chip;
    top->V_B0C = 6;
    top->V_EC = 14;
    top->V_VM = 1; // 0001
    top->V_CB = 2; //  010

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

    if (testDriver >= 0 && do_test_start(testDriver, top, setGolden) == TEST_FAIL) {
       STATE(top);
       LOG(LOG_ERROR, "test %d failed\n", testDriver);
       exit(-1);
    }

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
             break;
          case CHIP6567R8:
             screenWidth = NTSC_6567R8_MAX_DOT_X+1;
             screenHeight = NTSC_6567R8_MAX_DOT_Y+1;
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
    signal_src8[OUT_COLREF] = &top->clk_colref;
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
    signal_src8[OUT_CSYNC] = &top->cSync;
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
    for (int i=OUT_D0; i<= OUT_D11; i++) {
       signal_width[i] = 12;
       signal_bit[i] = bt;
       signal_src16[i] = &top->dbo;
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
    // it takes to load the bitstream at startup.

    if (startWithReset) {
       printf ("(RESET)\n");
       top->rst = 1;
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
    } else {
       nextClkCnt = 29;
    }

    if (shadowVic) {
       ipc = ipc_init(IPC_RECEIVER);
       ipc_open(ipc);
       state = ipc->state;
    }

    // IMPORTANT: Any and all state reads/writes MUST occur between ipc_receive
    // and ipc_receive_done inside this loop.
    int ticksUntilDone = 0;
    bool showState = true;
    while (!Verilated::gotFinish()) {

        // Are we shadowing from VICE? Wait for sync data, then
        // step until next dot clock tick.
        if (shadowVic && ticksUntilDone == 0) {
           // Do not change state before this line
           if (ipc_receive(ipc))
              break;

           ticksUntilDone = 4;
           capture = (state->flags & VICII_OP_CAPTURE_START);
           if (!captureByFrame) {
              captureByFrame = (state->flags & VICII_OP_CAPTURE_ONE_FRAME);
              captureByFrameStopXpos = 0x1f7;
              captureByFrameStopYpos = 311;
           }

           if (state->flags & VICII_OP_SYNC_STATE) {
               state->flags &= ~VICII_OP_SYNC_STATE;
               // Step forward until we get to the target xpos (which
               // will be xpos + 7 = one tick before we hit xpos + 8) and
               // rasterline and when dot4x just ticked low (we always tick into high
               // when beginning to step so we must leave dot4x low.
               while (top->V_XPOS != (state->xpos + 7) ||
                         top->V_RASTER_LINE != state->raster_line ||
                            top->clk_dot4x) {
                  top->eval();
#if VM_TRACE
	          if (tfp) tfp->dump(ticks / TICKS_TO_TIMESCALE);
#endif
                  STATE(top);
                  STORE_PREV();
                  ticks = nextTick(top);
               }

               // Now 6 more ticks so the next ipc_send will start on the
               // actual target we desire (xpos + 8)
               for (int i=0; i< 6; i++) {
                  top->eval();
#if VM_TRACE
	          if (tfp) tfp->dump(ticks / TICKS_TO_TIMESCALE);
#endif
                  STATE(top);
                  STORE_PREV();
                  ticks = nextTick(top);
               }

	       // Sync registers
	       unsigned char val = state->reg[0x11];
	       top->V_YSCROLL = val & 7;
	       top->V_RSEL = val & 8 ? 1 : 0;
	       top->V_DEN = val & 16 ? 1 : 0;
	       top->V_BMM = val & 32 ? 1 : 0;
	       top->V_ECM = val & 64 ? 1 : 0;
	       int rasterCmp8 = (val & 128) << 1;

	       val = state->reg[0x12];
	       top->V_RASTERCMP = val | rasterCmp8;

	       val = state->reg[0x16];
               top->V_XSCROLL = val & 7;
               top->V_CSEL = val & 8 ? 1 : 0;
               top->V_MCM = val & 16 ? 1 : 0;
               top->V_RES = val & 32 ? 1 : 0;

	       val = state->reg[0x18];
	       top->V_CB = (val & 14) >> 1;
	       top->V_VM = (val & 240) >> 4;

	       val = state->reg[0x19];
	       top->V_IRST_CLR =  val & 1;
               top->V_IMBC_CLR = val & 2 ? 1 : 0;
               top->V_IMMC_CLR = val & 4 ? 1 : 0;
               top->V_ILP_CLR =  val & 8 ? 1 : 0;

	       val = state->reg[0x1A];
	       top->V_ERST =  val & 1;
               top->V_EMBC = val & 2 ? 1 : 0;
               top->V_EMMC = val & 4 ? 1 : 0;
               top->V_ELP = val & 8 ? 1 : 0;

	       val = state->reg[0x20];
	       top->V_EC = val & 15;
	       val = state->reg[0x21];
               top->V_B0C = val & 15;
	       val = state->reg[0x22];
               top->V_B1C = val & 15;
	       val = state->reg[0x23];
               top->V_B2C = val & 15;
	       val = state->reg[0x24];
               top->V_B3C = val & 15;

               // We sync state always when phi is high (2nd phase)
               CHECK(top, ~top->clk_phi, __LINE__);

               LOG(LOG_INFO, "synced FPGA to cycle=%u, raster_line=%u, xpos=%03x, bmm=%d, mcm=%d, ecm=%d",
                  state->cycle_num, state->raster_line, state->xpos, top->V_BMM, top->V_MCM, top->V_ECM);
               LOG(LOG_INFO, "ec=%d, b0c=%d, b1c=%d, b2c=%d, b3c=%d",
                  top->V_EC, top->V_B0C, top->V_B1C, top->V_B2C, top->V_B3C);
           }

           if (state->flags & VICII_OP_BUS_ACCESS) {
              CHECK(top, top->clk_phi, __LINE__);
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

        prevX = top->V_RASTER_X;
        prevY = top->V_RASTER_LINE;

        // Evaluate model
        top->eval();
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
             // AEC should always be low in first phase
             if (top->V_BIT_CYCLE < 4) {
               CHECK(top, top->aec == 0, __LINE__);
             }

             // Make sure xpos is what we expect at key points
             if (top->V_CYCLE_NUM == 12 && top->V_BIT_CYCLE == 4)
               CHECK (top, top->V_XPOS == 0, __LINE__); // rollover

             if (top->V_CYCLE_NUM == 0 && top->V_BIT_CYCLE == 0)
               if (chip == CHIP6569)
                  CHECK (top, top->V_XPOS == 0x194, __LINE__); // reset
               else
                  CHECK (top, top->V_XPOS == 0x19c, __LINE__); // reset

             if (chip == CHIP6567R8)
               if (top->V_CYCLE_NUM == 61 && (top->V_BIT_CYCLE == 0 || top->V_BIT_CYCLE == 4))
                  CHECK (top, top->V_XPOS == 0x184, __LINE__); // repeat cases
               else if (top->V_CYCLE_NUM == 62 && top->V_BIT_CYCLE == 0)
                  CHECK (top, top->V_XPOS == 0x184, __LINE__); // repeat case

             // Refresh counter is supposed to reset at raster 0
             if (top->V_RASTER_X == 0 && top->V_RASTER_LINE == 0)
                CHECK (top, top->V_REFC == 0xff, __LINE__);

             if(top->V_BIT_CYCLE == 0 || top->V_BIT_CYCLE == 4) {
                // CAS & RAS should be high at the start of each phase
                // Timing and vicycle will determine when they fall if ever
                CHECK (top, top->cas != 0, __LINE__);
                CHECK (top, top->ras != 0, __LINE__);
             }
          }

          // If rendering, draw current color on dot clock
          if (showWindow && HASCHANGED(OUT_DOT) && RISING(OUT_DOT)) {
             SDL_SetRenderDrawColor(ren,
                top->red << 6,
                top->green << 6,
                top->blue << 6,
                255);
             drawPixel(ren,
                top->V_RASTER_X,
                top->V_RASTER_LINE
             );

             // Show updated pixels per raster line
             if (prevY != top->V_RASTER_LINE) {
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
             if (renderEachPixel) {
                SDL_RenderPresent(ren);
             }
          }
        }

        if (shadowVic) {
           state->ba = top->ba;
           state->aec = top->aec;
           state->phi = top->clk_phi;
	   state->addr_from_sim = top->V_VICADDR; // cheat
           if (top->ce == 0 && top->rw == 1) {
              // Chip selected and read, set data in state
              state->data_from_sim = top->dbo;
           }

           bool needQuit = false;
           if (state->flags & VICII_OP_CAPTURE_END) {
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

           if (ticksUntilDone == 0 || needQuit) {
              // Do not change state after this line
              if (ipc_receive_done(ipc))
                 break;
           }


           if (needQuit) {
              // Safe to quit now. We sent our response.
              break;
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
       while (!quit) {
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
