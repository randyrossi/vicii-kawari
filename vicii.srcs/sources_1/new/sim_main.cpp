#include <SDL2/SDL.h>

#include <iostream>

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <verilated.h>

#include "Vtop.h"
#include "constants.h"

extern "C" {
#include "vicii_ipc.h"
}

// Current simulation time (64-bit unsigned). See
// constants.h for how much each tick represents.
static vluint64_t ticks = 0;
static vluint64_t half4XDotPS;
static vluint64_t half4XColorPS;
static vluint64_t startTicks;
static vluint64_t endTicks;
static vluint64_t nextClk1;
static vluint64_t nextClk2;
static int maxDotX;
static int maxDotY;

// Add new input/output here
#define OUT_PHI 0
#define OUT_COLREF 1
#define IN_RST 2
#define OUT_R0 3
#define OUT_R1 4
#define OUT_G0 5
#define OUT_G1 6
#define OUT_B0 7
#define OUT_B1 8
#define OUT_DOT 9
#define OUT_CSYNC 10
#define INOUT_A0 11
#define INOUT_A1 12
#define INOUT_A2 13
#define INOUT_A3 14
#define INOUT_A4 15
#define INOUT_A5 16
#define INOUT_A6 17
#define INOUT_A7 18
#define INOUT_A8 19
#define INOUT_A9 20
#define INOUT_A10 21
#define INOUT_A11 22
#define INOUT_D0 23
#define INOUT_D1 24
#define INOUT_D2 25
#define INOUT_D3 26
#define INOUT_D4 27
#define INOUT_D5 28
#define INOUT_D6 29
#define INOUT_D7 30
#define INOUT_D8 31
#define INOUT_D9 32
#define INOUT_D10 33
#define INOUT_D11 34
#define NUM_SIGNALS 35

// Add new input/output here
const char *signal_labels[] = {
   "phi", "col", "rst", "r0", "r1", "g0", "g1", "b0", "b1" , "dot", "csync",
   "a0", "a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8", "a9", "a10", "a11",
   "d0", "d1", "d2", "d3", "d4", "d5", "d6", "d7", "d8", "d9", "d10", "d11",
};
const char *signal_ids[] = {
   "p", "c", "r" ,  "r0", "r1", "g0", "g1", "b0", "b1" , "dot", "s",
   "a0", "a1", "a2", "a3", "a4", "a5", "a6", "a7", "a8", "a9", "a10", "a11",
   "d0", "d1", "d2", "d3", "d4", "d5", "d6", "d7", "d8", "d9", "d10", "d11",
};

static unsigned int signal_width[NUM_SIGNALS];
static unsigned char *signal_src8[NUM_SIGNALS];
static unsigned short *signal_src16[NUM_SIGNALS];
static unsigned int signal_bit[NUM_SIGNALS];
static bool signal_monitor[NUM_SIGNALS];
static unsigned char prev_signal_values[NUM_SIGNALS];

// Some utility macros
// Use RISING/FALLING in combination with HASCHANGED

static int SGETVAL(int signum) {
  if (signal_width[signum] <= 8) {
     return (*signal_src8[signum] & signal_bit[signum] ? 1 : 0);
  } else if (signal_width[signum] > 8 && signal_width[signum] < 16) {
     return (*signal_src16[signum] & signal_bit[signum] ? 1 : 0);
  } else {
    abort();
  }
}

#define HASCHANGED(signum) \
   ( signal_monitor[signum] && SGETVAL(signum) != prev_signal_values[signum] )
#define RISING(signum) \
   ( signal_monitor[signum] && SGETVAL(signum))
#define FALLING(signum) \
   ( signal_monitor[signum] && !SGETVAL(signum))

// We can drive our simulated clock gen every pico second but that would
// be a waste since nothing happens between clock edges. This function
// will determine how many ticks(picoseconds) to advance our clock
// given our two periods.
static vluint64_t nextTick(Vtop* top) {
   vluint64_t diff1 = nextClk1 - ticks;
   vluint64_t diff2 = nextClk2 - ticks;

   if (diff1 < diff2) {
      nextClk1 += half4XDotPS;
      top->top__DOT__clk_dot4x = ~top->top__DOT__clk_dot4x;
      return ticks + diff1;
   } else if (diff2 < diff1) {
      nextClk2 += half4XColorPS;
      top->top__DOT__clk_col4x = ~top->top__DOT__clk_col4x;
      return ticks + diff2;
   } else {
      // Equal, both tick
      nextClk1 += half4XDotPS;
      nextClk2 += half4XColorPS;
      top->top__DOT__clk_dot4x = ~top->top__DOT__clk_dot4x;
      top->top__DOT__clk_col4x = ~top->top__DOT__clk_col4x;
      return ticks + diff1;
   }
}

static void vcd_header(Vtop* top) {
   printf ("$date\n");
   printf ("   January 1, 1979.\n");
   printf ("$end\n");
   printf ("$version\n");
   printf ("   1.0\n");
   printf ("$end\n");
   printf ("$comment\n");
   printf ("   VCD vicii\n");
   printf ("$end\n");

   printf (VCD_TIMESCALE);
   printf ("$scope module logic $end\n");

   for (int i=0;i<NUM_SIGNALS;i++)
      if (signal_monitor[i])
         printf ("$var wire 1 %s %s $end\n", signal_ids[i], signal_labels[i]);
   printf ("$upscope $end\n");

   printf ("$enddefinitions $end\n");
   printf ("$dumpvars\n");

   for (int i=0;i<NUM_SIGNALS;i++)
      if (signal_monitor[i])
         printf ("x%s\n",signal_ids[i]);
   printf ("$end\n");

   // Start time
   printf ("#%" VL_PRI64 "d\n", startTicks/TICKS_TO_TIMESCALE);
   for (int i=0;i<NUM_SIGNALS;i++) {
      if (signal_monitor[i])
         printf ("%x%s\n",SGETVAL(i), signal_ids[i]);
   }
   fflush(stdout);
}

// TODO : Do we really need two?
unsigned char ipc_out_buf[IPC_BUFSIZE];
unsigned char ipc_in_buf[IPC_BUFSIZE];

int main(int argc, char** argv, char** env) {

    struct vicii_state* state = ((struct vicii_state*)ipc_in_buf);
    bool capture = false;

    bool includeDataBus = true;
    bool includeAddressBus = true;
    bool includeColors = true;
    bool isNtsc = true;
    bool captureByTime = true;
    bool outputVcd = false;
    bool showWindow = false;
    bool shadowVic = false;
    bool renderEachPixel = false;
    int prev_y = -1;
    struct vicii_ipc* ipc;

    // Default to 16.7us starting at 0
    startTicks = US_TO_TICKS(0);
    vluint64_t durationTicks = US_TO_TICKS(16700L);

    char *cvalue = nullptr;
    char c;

    while ((c = getopt (argc, argv, "hs:t:vwnpa:d:c:zb")) != -1)
    switch (c) {
      case 'b':
        // Render after every pixel instead of after every line
        renderEachPixel = true;
        break;
      case 'z':
        // IPC tells us when to start/stop capture
        captureByTime = false;
        shadowVic = true;
        break;
      case 'c':
        includeColors = atoi(optarg) == 1 ? true: false;
        break;
      case 'a':
        includeAddressBus = atoi(optarg) == 1 ? true: false;
        break;
      case 'd':
        includeDataBus = atoi(optarg) == 1 ? true: false;
        break;
      case 'n':
        isNtsc = true;
        break;
      case 'p':
        isNtsc = false;
        break;
      case 'v':
        outputVcd = true;
        break;
      case 'w':
        showWindow = true;
        break;
      case 's':
        startTicks = US_TO_TICKS(atol(optarg));
        break;
      case 't':
        durationTicks = US_TO_TICKS(atol(optarg));
        break;
      case 'h':
        printf ("Usage\n");
        printf ("  -s [uS]  : start at uS\n");
        printf ("  -t [uS]  : run for uS\n");
        printf ("  -v       : generate vcd to stdout\n");
        printf ("  -p       : pal\n");
        printf ("  -n       : ntsc (default)\n");
        printf ("  -w       : show SDL2 window\n");
        printf ("  -a [0|1] : include/exclude address bus\n");
        printf ("  -d [0|1] : include/exclude data bus\n");
        printf ("  -c [0|1] : include/exclude colors\n");
        printf ("  -z       : single step eval for shadow vic via ipc\n");
        printf ("  -b       : render each pixel instead of each line\n");
        exit(0);
      case '?':
        if (optopt == 't' || optopt == 's')
          fprintf (stderr, "Option -%c requires an argument.\n", optopt);
        else if (isprint (optopt))
          fprintf (stderr, "Unknown option `-%c'.\n", optopt);
        else
          fprintf (stderr,
                   "Unknown option character `\\x%x'.\n",
                   optopt);
        return 1;
      default:
        exit(-1);
    }

    if (isNtsc) {
       half4XDotPS = NTSC_HALF_4X_DOT_PS;
       half4XColorPS = NTSC_HALF_4X_COLOR_PS;
       maxDotX = NTSC_MAX_DOT_X;
       maxDotY = NTSC_MAX_DOT_Y;
    } else {
       fprintf (stderr, "PAL not supported\n");
       exit(-1);
    }

    nextClk1 = half4XDotPS;
    nextClk2 = half4XColorPS;
    endTicks = startTicks + durationTicks;

    int sdl_init_mode = SDL_INIT_VIDEO;
    if (SDL_Init(sdl_init_mode) != 0) {
      std::cerr << "SDL_Init Error: " << SDL_GetError() << std::endl;
      return 1;
    }

    SDL_Event event;
    SDL_Renderer* ren = nullptr;
    SDL_Window* win;

    if (showWindow) {
      SDL_DisplayMode current;
      int width = maxDotX;
      int height = maxDotY;

      win = SDL_CreateWindow("VICII",
                             SDL_WINDOWPOS_CENTERED,
                             SDL_WINDOWPOS_CENTERED,
                             width, height, SDL_WINDOW_SHOWN);
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

    // Add new input/output here.
    Vtop* top = new Vtop;
    top->sys_clock = 0;
    top->clk_colref = 0;
    top->clk_phi = 0;
    top->rst = 0;
    top->red = 0;
    top->green = 0;
    top->blue = 0;
    top->cSync = 0;
    top->ad = 0;
    top->db = 0;

    // Default all signals to bit 1 and include in monitoring.
    for (int i = 0; i < NUM_SIGNALS; i++) {
      signal_width[i] = 1;
      signal_bit[i] = 1;
      signal_monitor[i] = true;
    }

    if (!includeColors) {
      signal_monitor[OUT_R0] = false;
      signal_monitor[OUT_R1] = false;
      signal_monitor[OUT_G0] = false;
      signal_monitor[OUT_G1] = false;
      signal_monitor[OUT_B0] = false;
      signal_monitor[OUT_B1] = false;
      signal_monitor[OUT_COLREF] = false;
    }

    if (!includeAddressBus) {
      for (int i=INOUT_A0; i<= INOUT_A11; i++) {
        signal_monitor[i] = false;
      }
    }

    if (!includeDataBus) {
      for (int i=INOUT_D0; i<= INOUT_D11; i++) {
        signal_monitor[i] = false;
      }
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
    signal_src8[OUT_DOT] = &top->top__DOT__clk_dot;
    signal_src8[OUT_CSYNC] = &top->cSync;

    int bt = 1;
    for (int i=INOUT_A0; i<= INOUT_A11; i++) {
       signal_width[i] = 12;
       signal_bit[i] = bt;
       signal_src16[i] = &top->ad;
       bt = bt * 2;
    }
    bt = 1;
    for (int i=INOUT_D0; i<= INOUT_D11; i++) {
       signal_width[i] = 12;
       signal_bit[i] = bt;
       signal_src16[i] = &top->db;
       bt = bt * 2;
    }

    for (int i = 0; i < NUM_SIGNALS; i++) {
       prev_signal_values[i] = SGETVAL(i);
    }

    if (outputVcd)
       vcd_header(top);

    if (shadowVic) {
       ipc = ipc_init(IPC_RECEIVER);
       ipc_open(ipc);
    }

    // This lets us iterate the eval loop until we see the
    // dot clock tick forward one half its period.
    bool needDotTick = false;

    // Simulate until $finish

    while (!Verilated::gotFinish()) {

        // Are we shadowing from VICE? Wait for sync data, then
        // step until next dot clock tick.
        if (shadowVic && !needDotTick) {
           if (ipc_receive(ipc, &ipc_in_buf[0]))
              break;
           needDotTick = true;

           capture = (state->flags & VICII_OP_CAPTURE);

           top->ad = state->addr;
           top->db = state->data;

           // TODO : Set ce, rw etc
        }

        // Advance simulation time. Each tick represents 1 picosecond.
        ticks = nextTick(top);

#ifdef TEST_RESET
        // Test reset between approx 7 and approx 8 us
        if (ticks >= US_TO_TICKS(7000L) && ticks <= US_TO_TICKS(8000L))
           top->rst = 1;
        else
           top->rst = 0;
#endif

        // Evaluate model
        top->eval();

        if (captureByTime)
           capture = (ticks >= startTicks) && (ticks <= endTicks);

        if (capture) {
          bool anyChanged = false;
          for (int i = 0; i < NUM_SIGNALS; i++) {
             if (HASCHANGED(i)) {
                anyChanged = true;
                break;
             }
          }

          if (anyChanged) {
             if (outputVcd)
                printf ("#%" VL_PRI64 "d\n", ticks/TICKS_TO_TIMESCALE);
             for (int i = 0; i < NUM_SIGNALS; i++) {
                if (HASCHANGED(i)) {
                   if (outputVcd)
                      printf ("%x%s\n", SGETVAL(i), signal_ids[i]);

                }
             }
          }

          // If rendering, draw current color on dot clock
          if (showWindow && HASCHANGED(OUT_DOT) && RISING(OUT_DOT)) {
             SDL_SetRenderDrawColor(ren,
                top->red << 6,
                top->green << 6,
                top->blue << 6,
                255);
             SDL_RenderDrawPoint(ren,
                top->top__DOT__vic_inst__DOT__x_pos,
                top->top__DOT__vic_inst__DOT__y_pos);

             // Show updated pixels per raster line
             if (prev_y != top->top__DOT__vic_inst__DOT__y_pos) {
                SDL_RenderPresent(ren);
                prev_y = top->top__DOT__vic_inst__DOT__y_pos;

                SDL_PollEvent(&event);
             }
             if (renderEachPixel) {
                SDL_RenderPresent(ren);
             }
          }
        }

        if (shadowVic && HASCHANGED(OUT_DOT) && needDotTick) {
           // TODO : Report back any outputs like data, ba, aec, etc. here
           if (ipc_send(ipc, &ipc_out_buf[0]))
              break;
           needDotTick = false;
        }

        // End of eval. Remember current values for previous compares.
        for (int i = 0; i < NUM_SIGNALS; i++) {
           prev_signal_values[i] = SGETVAL(i);
        }

        // Is it time to stop?
        if (captureByTime && ticks >= endTicks)
           break;

        // Did we get an end signal?
        // Must make sure we're not still waiting for a dot tick before
        // ending  because we need to send a response.
        if ((state->flags & VICII_OP_CAPTURE_END) && !needDotTick) {
           break;
        }
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

    // Destroy model
    delete top;

    // Fin
    exit(0);
}
