#include <SDL2/SDL.h>

#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <iostream>

// Include common routines
#include <verilated.h>

// Include model header, generated from Verilating "top.v"
#include "Vtop.h"

// Current simulation time (64-bit unsigned)
static vluint64_t ticks = 0;

// How much to divide our ticks (which is always picoseconds) down to our VCD
// timescale
#define PICOSECONDS_TO_TIMESCALE 1000L

// Add new input/output here
#define NUM_SIGNALS 11
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

// Add new input/output here
const char *signal_labels[] = {
   "phi", "col", "rst", "r0", "r1", "g0", "g1", "b0", "b1" , "dot", "csync"};
const char *signal_ids[] = {
   "p", "c", "r" ,  "r0", "r1", "g0", "g1", "b0", "b1" , "dot", "s" };

unsigned char *signal_src[NUM_SIGNALS];
unsigned int signal_bit[NUM_SIGNALS];
bool signal_monitor[NUM_SIGNALS];
unsigned char prev_signal_values[NUM_SIGNALS];

#define GETVAL(signum) \
   (*signal_src[signum] & signal_bit[signum] ? 1 : 0)
#define HASCHANGED(signum) \
   ( signal_monitor[signum] && GETVAL(signum) != prev_signal_values[signum] )
#define RISING(signum) \
   ( signal_monitor[signum] && GETVAL(signum))

// Convert microseconds to ticks (picoseconds)
#define US_TO_TICKS(t) (t * 1000L * 1000L)

vluint64_t startTicks;
vluint64_t endTicks;

// We can drive our simulated clock gen every pico second but that would
// be a waste since nothing happens between clock edges. This function
// will determine how many ticks(picoseconds) to advance our clock
// given our two periods.
static vluint64_t nextClk1 = 15275;
static vluint64_t nextClk2 = 34920;

static vluint64_t nextTick(Vtop* top) {
   vluint64_t diff1 = nextClk1 - ticks;
   vluint64_t diff2 = nextClk2 - ticks;

   if (diff1 < diff2) {
      nextClk1 += 15275;
      top->top__DOT__clk_dot4x = ~top->top__DOT__clk_dot4x;
      return ticks + diff1;
   }
   nextClk2 += 34920;
   top->top__DOT__clk_col4x = ~top->top__DOT__clk_col4x;
   return ticks + diff2;
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

   // Use 1ns timescale. Required PICOSECONDS_TO_TIMESCALE to be 1000L
   printf ("$timescale 1ns $end\n");
   printf ("$scope module logic $end\n");

   for (int i=0;i<NUM_SIGNALS;i++)
      printf ("$var wire 1 %s %s $end\n", signal_ids[i], signal_labels[i]);
   printf ("$upscope $end\n");

   printf ("$enddefinitions $end\n");
   printf ("$dumpvars\n");

   for (int i=0;i<NUM_SIGNALS;i++)
      printf ("x%s\n",signal_ids[i]);
   printf ("$end\n");

   // Start time
   printf ("#%" VL_PRI64 "d\n", startTicks/PICOSECONDS_TO_TIMESCALE);
   for (int i=0;i<NUM_SIGNALS;i++)
      printf ("%x%s\n",GETVAL(i), signal_ids[i]);
   fflush(stdout);
}

int main(int argc, char** argv, char** env) {
    bool capture = false;
    bool show_vcd = false;
    bool show_window = false;
    int prev_y = -1;

    // Default to 16.7us starting at 0
    startTicks = US_TO_TICKS(0);
    vluint64_t durationTicks = US_TO_TICKS(16700L);

    char *cvalue = nullptr;
    char c;

    while ((c = getopt (argc, argv, "s:t:vw")) != -1)
    switch (c) {
      case 'v':
        show_vcd = true;
        break;
      case 'w':
        show_window = true;
        break;
      case 's':
        startTicks = US_TO_TICKS(atol(optarg));
        break;
      case 't':
        durationTicks = US_TO_TICKS(atol(optarg));
        break;
      case 'h':
        printf ("Usage\n");
        printf ("  -s [uS] : start at uS\n");
        printf ("  -t [uS] : run for uS\n");
        printf ("  -v      : generate vcd to stdout\n");
        printf ("  -w      : show SDL2 window\n");
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
        abort ();
    }

    endTicks = startTicks + durationTicks;

    int sdl_init_mode = SDL_INIT_VIDEO;
    if (SDL_Init(sdl_init_mode) != 0) {
      std::cerr << "SDL_Init Error: " << SDL_GetError() << std::endl;
      return 1;
    }

    SDL_Event event;
    SDL_Renderer* ren = nullptr;
    SDL_Window* win;

    if (show_window) {
      SDL_DisplayMode current;
      int width = 520; // NTSC
      int height = 262; // NTSC

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

    // Default all signals to bit 1 and include in monitoring.
    for (int i = 0; i < NUM_SIGNALS; i++) {
      signal_bit[i] = 1;
      signal_monitor[i] = true;
    }

    // Add new input/output here.
    signal_src[OUT_PHI] = &top->clk_phi;
    signal_src[OUT_COLREF] = &top->clk_colref;
    signal_src[IN_RST] = &top->rst;
    signal_src[OUT_R0] = &top->red;
    signal_src[OUT_R1] = &top->red;
    signal_bit[OUT_R1] = 2;
    signal_src[OUT_G0] = &top->green;
    signal_src[OUT_G1] = &top->green;
    signal_bit[OUT_G1] = 2;
    signal_src[OUT_B0] = &top->blue;
    signal_src[OUT_B1] = &top->blue;
    signal_bit[OUT_B1] = 2;
    signal_src[OUT_DOT] = &top->top__DOT__clk_dot;
    signal_src[OUT_CSYNC] = &top->cSync;

    for (int i = 0; i < NUM_SIGNALS; i++) {
       prev_signal_values[i] = GETVAL(i);
    }

    if (show_vcd)
       vcd_header(top);

    // Simulate until $finish
    while (!Verilated::gotFinish()) {
        // Advance simulation time. Each tick represents 1 picosecond.
        ticks = nextTick(top);

#ifdef TEST_RESET
        // Test reset between approx 30 and approx 40 us
        if (ticks >= US_TO_TICKS(30L) && ticks <= US_TO_TICKS(40L))
           top->rst = 1;
        else
           top->rst = 0;
#endif

        // Evaluate model
        top->eval();

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
             if (show_vcd)
                printf ("#%" VL_PRI64 "d\n", ticks/PICOSECONDS_TO_TIMESCALE);
             for (int i = 0; i < NUM_SIGNALS; i++) {
                if (HASCHANGED(i)) {
                   if (show_vcd)
                      printf ("%x%s\n", GETVAL(i), signal_ids[i]);

                }
             }
          }

        // If rendering, draw current color on dot clock
        if (show_window && HASCHANGED(OUT_DOT) && RISING(OUT_DOT)) {
           SDL_SetRenderDrawColor(ren,
              top->red << 6,
              top->green << 6,
              top->blue << 6,
              255);
           SDL_RenderDrawPoint(ren,
              top->top__DOT__vic_inst__DOT__x_pos,
              top->top__DOT__vic_inst__DOT__y_pos);

           if (prev_y != top->top__DOT__vic_inst__DOT__y_pos) {
              SDL_RenderPresent(ren);
              prev_y = top->top__DOT__vic_inst__DOT__y_pos;

              SDL_PollEvent(&event);
           }
        }
        }


        for (int i = 0; i < NUM_SIGNALS; i++) {
           prev_signal_values[i] = GETVAL(i);
        }

        if (ticks >= endTicks)
           break;

    }

    if (show_window) {
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
