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

extern "C" {
#include "vicii_ipc.h"
}

#define LOG_NONE  0
#define LOG_ERROR 1
#define LOG_WARN  2
#define LOG_INFO  3

static const char* logLevelStr[4] = { "None","error","warn","info" };

int logLevel = LOG_ERROR;

#define LOG(minLevel, FORMAT, ...)  if (logLevel >= minLevel) { printf ("(%s) %s: " FORMAT "\n", __FUNCTION__, logLevelStr[logLevel], ##__VA_ARGS__); }

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
   IN_BA,
   IN_AEC,
   IN_IRQ,
};

#define NUM_SIGNALS 64

// Add new input/output here
const char *signal_labels[] = {
   "phi", "col", "rst", "r0", "r1", "g0", "g1", "b0", "b1" , "dot", "csync",
   "ao0", "ao1", "ao2", "ao3", "ao4", "ao5", "ao6", "ao7", "ao8", "ao9", "ao10", "ao11",
   "ai0", "ai1", "ai2", "ai3", "ai4", "ai5", "ai6", "ai7", "ai8", "ai9", "ai10", "ai11",
   "do0", "do1", "do2", "do3", "do4", "do5", "do6", "do7", "do8", "do9", "do10", "do11",
   "di0", "di1", "di2", "di3", "di4", "di5", "di6", "di7", "di8", "di9", "di10", "di11",
   "ce", "rw", "ba", "aec", "irq"
};
const char *signal_ids[] = {
   "p", "c", "r" ,  "r0", "r1", "g0", "g1", "b0", "b1" , "dot", "s",
   "ao0", "ao1", "ao2", "ao3", "ao4", "ao5", "ao6", "ao7", "ao8", "ao9", "ao10", "ao11",
   "ai0", "ai1", "ai2", "ai3", "ai4", "ai5", "ai6", "ai7", "ai8", "ai9", "ai10", "ai11",
   "do0", "do1", "do2", "do3", "do4", "do5", "do6", "do7", "do8", "do9", "do10", "do11",
   "di0", "di1", "di2", "di3", "di4", "di5", "di6", "di7", "di8", "di9", "di10", "di11",
   "ce", "rw", "ba", "aec", "irq"
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

static void STORE_PREV() {
  for (int i = 0; i < NUM_SIGNALS; i++) {
     prev_signal_values[i] = SGETVAL(i);
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
// will determine how many ticks(picoseconds) to advance our clock.
static vluint64_t nextTick(Vvicii* top) {
   vluint64_t diff1 = nextClk1 - ticks;

   nextClk1 += half4XDotPS;
   top->clk_dot4x = ~top->clk_dot4x;
   return ticks + diff1;
}

static void vcd_header(Vvicii* top, FILE* fp) {
   fprintf (fp, "$date\n");
   fprintf (fp, "   January 1, 1979.\n");
   fprintf (fp, "$end\n");
   fprintf (fp,"$version\n");
   fprintf (fp,"   1.0\n");
   fprintf (fp,"$end\n");
   fprintf (fp,"$comment\n");
   fprintf (fp,"   VCD vicii\n");
   fprintf (fp,"$end\n");

   fprintf (fp,VCD_TIMESCALE);
   fprintf (fp,"$scope module logic $end\n");

   for (int i=0;i<NUM_SIGNALS;i++)
      if (signal_monitor[i])
         fprintf (fp,"$var wire 1 %s %s $end\n", signal_ids[i], signal_labels[i]);
   fprintf (fp,"$upscope $end\n");

   fprintf (fp,"$enddefinitions $end\n");
   fprintf (fp,"$dumpvars\n");

   for (int i=0;i<NUM_SIGNALS;i++)
      if (signal_monitor[i])
         fprintf (fp,"x%s\n",signal_ids[i]);
   fprintf (fp,"$end\n");

   // Start time
   fprintf (fp,"#%" VL_PRI64 "d\n", startTicks/TICKS_TO_TIMESCALE);
   for (int i=0;i<NUM_SIGNALS;i++) {
      if (signal_monitor[i])
         fprintf (fp,"%x%s\n",SGETVAL(i), signal_ids[i]);
   }
   fflush(fp);
}

static void drawPixel(SDL_Renderer* ren, int x,int y) {
   SDL_RenderDrawPoint(ren, x*2,y*2);
   SDL_RenderDrawPoint(ren, x*2+1,y*2);
   SDL_RenderDrawPoint(ren, x*2,y*2+1);
   SDL_RenderDrawPoint(ren, x*2+1,y*2+1);
}

int main(int argc, char** argv, char** env) {

    struct vicii_state* state;
    bool capture = false;

    int chip = CHIP6569;
    bool isNtsc = false;

    bool captureByTime = true;
    bool outputVcd = false;
    bool showWindow = false;
    bool shadowVic = false;
    bool renderEachPixel = false;
    int prev_y = -1;
    struct vicii_ipc* ipc;

    // Default to 16.7us starting at 0
    startTicks = US_TO_TICKS(0);
    vluint64_t durationTicks;


    char *cvalue = nullptr;
    char c;
    char *token;
    regex_t regex;
    int reti, reti2;
    char regex_buf[32];
    FILE* outFile = NULL;

    while ((c = getopt (argc, argv, "c:hs:t:vwi:zbo:d:")) != -1)
    switch (c) {
      case 'd':
        logLevel = atoi(optarg);
        break;
      case 'c':
        chip = atoi(optarg);
        break;
      case 'i':
        token = strtok(optarg, ",");
        while (token != NULL) {
           strcpy (regex_buf, "^");
           strcat (regex_buf, token);
           strcat (regex_buf, "$");
           reti = regcomp(&regex, regex_buf, 0);
           for (int i = 0; i < NUM_SIGNALS; i++) {
              if (strcmp(signal_labels[i],token) == 0) {
                 signal_monitor[i] = true;
                 break;
              }
              if (!reti) {
                 reti2 = regexec(&regex, signal_labels[i], 0, NULL, 0);
                 if (!reti2) {
                    signal_monitor[i] = true;
                 }
              }
           }
           regfree(&regex);
           token = strtok(NULL, ",");
        }
        break;
      case 'o':
        outFile = fopen(optarg,"w");
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
        printf ("  -s [uS]   : start at uS\n");
        printf ("  -t [uS]   : run for uS\n");
        printf ("  -v        : generate vcd to file\n");
        printf ("  -o <file> : specify filename\n");
        printf ("  -w        : show SDL2 window\n");
        printf ("  -z        : single step eval for shadow vic via ipc\n");
        printf ("  -b        : render each pixel instead of each line\n");
        printf ("  -i        : list signals to include (phi, ce, csync, etc.) \n");
        printf ("  -c <chip> : 0=CHIP6567R8, 1=CHIP6567R56A 2=CHIP65669\n");
        
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

    if (outputVcd && outFile == NULL) {
       LOG(LOG_ERROR, "need out file with -o");
       exit(-1);
    }

    switch (chip) {
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

    if (isNtsc) {
       half4XDotPS = NTSC_HALF_4X_DOT_PS;
       half4XColorPS = NTSC_HALF_4X_COLOR_PS;
       switch (chip) {
          case CHIP6567R56A:
             maxDotX = NTSC_6567R56A_MAX_DOT_X;
             maxDotY = NTSC_6567R56A_MAX_DOT_Y;
             break;
          case CHIP6567R8:
             maxDotX = NTSC_6567R8_MAX_DOT_X;
             maxDotY = NTSC_6567R8_MAX_DOT_Y;
             break;
          default:
             LOG(LOG_ERROR, "wrong chip?");
             exit(-1);
       }
    } else {
       half4XDotPS = PAL_HALF_4X_DOT_PS;
       half4XColorPS = PAL_HALF_4X_COLOR_PS;
       switch (chip) {
          case CHIP6569:
             maxDotX = PAL_6569_MAX_DOT_X;
             maxDotY = PAL_6569_MAX_DOT_Y;
             break;
          default:
             LOG(LOG_ERROR, "wrong chip?");
             exit(-1);
       }
    }

    nextClk1 = half4XDotPS;
    nextClk2 = half4XColorPS;
    endTicks = startTicks + durationTicks;

    int sdl_init_mode = SDL_INIT_VIDEO;
    if (SDL_Init(sdl_init_mode) != 0) {
      LOG(LOG_ERROR, "SDL_Init %s", SDL_GetError());
      return 1;
    }

    SDL_Event event;
    SDL_Renderer* ren = nullptr;
    SDL_Window* win;

    if (showWindow) {
      SDL_DisplayMode current;
      int width = maxDotX*2;
      int height = maxDotY*2;

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
    Vvicii* top = new Vvicii;
    top->chip = chip;
    top->rst = 0;
    top->adi = 0;
    top->dbi = 0;
    top->aec = 1; // TODO
    top->vicii__DOT__b0c = 14;
    top->vicii__DOT__ec = 6;

    // Default all signals to bit 1 and include in monitoring.
    for (int i = 0; i < NUM_SIGNALS; i++) {
      signal_width[i] = 1;
      signal_bit[i] = 1;
    }

    signal_monitor[OUT_DOT] = true;

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
    signal_src8[OUT_DOT] = &top->vicii__DOT__clk_dot;
    signal_src8[OUT_CSYNC] = &top->cSync;
    signal_src8[IN_CE] = &top->ce;
    signal_src8[IN_RW] = &top->rw;
    signal_src8[IN_BA] = &top->ba;
    signal_src8[IN_AEC] = &top->aec;
    signal_src8[IN_IRQ] = &top->irq;

    int bt = 1;
    for (int i=OUT_A0; i<= OUT_A11; i++) {
       signal_width[i] = 12;
       signal_bit[i] = bt;
       signal_src16[i] = &top->ado;
       bt = bt * 2;
    }
    bt = 1;
    for (int i=IN_A0; i<= IN_A11; i++) {
       signal_width[i] = 12;
       signal_bit[i] = bt;
       signal_src16[i] = &top->adi;
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

    top->eval();

    if (outputVcd)
       vcd_header(top,outFile);

    // After this loop, the next tick will bring DOT high
    for (int t =0; t < 32; t++) {
       ticks = nextTick(top);
       top->eval();
       if (HASCHANGED(OUT_DOT) && RISING(OUT_DOT)) {
          LOG(LOG_INFO, "xpos=%03x, cycle=%d, bit=%d",top->vicii__DOT__xpos, top->vicii__DOT__cycle_num, top->vicii__DOT__bit_cycle);
       }
       STORE_PREV();
    }

    if (shadowVic) {
       ipc = ipc_init(IPC_RECEIVER);
       ipc_open(ipc);
       state = ((struct vicii_state*)ipc->dspOutBuf);
    }

    // This lets us iterate the eval loop until we see the
    // dot clock tick forward one half its period.
    bool needDotTick = false;

    int verifyNextDotXPos = -1;

    // IMPORTANT: Any and all state reads/writes MUST occur between ipc_receive
    // and ipc_send inside this loop.
    while (!Verilated::gotFinish()) {

        // Are we shadowing from VICE? Wait for sync data, then
        // step until next dot clock tick.
        if (shadowVic && !needDotTick) {
           if (ipc_receive(ipc))
              break;

           needDotTick = true;

           capture = (state->flags & VICII_OP_CAPTURE_START);

           if (state->flags & VICII_OP_SYNC_STATE) {
               // We sync state always when phi is high (2nd phase)
               assert(~top->clk_phi);
               // Add 3 because the next dot tick will increment x to bring us
               // to 2nd phase of phi within the cycle.
               top->vicii__DOT__raster_x = 8 * state->cycle_num + 3;
               top->vicii__DOT__xpos = state->xpos;
               top->vicii__DOT__raster_line = state->raster_line;

               // Add one because the next dot tick will increment xpos
               verifyNextDotXPos = state->xpos + 1;

               LOG(LOG_INFO, "syncing FPGA to cycle=%u, raster_line=%u, xpos=%03x",
                  state->cycle_num, state->raster_line, verifyNextDotXPos);
           }
           state->flags &= ~VICII_OP_SYNC_STATE;

           if (state->flags & VICII_OP_BUS_ACCESS) {
              assert(top->clk_phi);
           }

           top->adi = state->addr;
           top->ce = state->ce;
           top->rw = state->rw;

           if (top->ce == 0 && top->rw == 0) {
              // chip select and write, set data
              top->dbi = state->data;
           }
        }

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
                fprintf (outFile, "#%" VL_PRI64 "d\n", ticks/TICKS_TO_TIMESCALE);
             for (int i = 0; i < NUM_SIGNALS; i++) {
                if (HASCHANGED(i)) {
                   if (outputVcd)
                      fprintf (outFile, "%x%s\n", SGETVAL(i), signal_ids[i]);
                }
             }
          }

          // If rendering, draw current color on dot clock
          if (showWindow && HASCHANGED(OUT_DOT) && RISING(OUT_DOT)) {
             LOG(LOG_INFO, "xpos=%03x, cycle=%d, bit=%d",top->vicii__DOT__xpos, top->vicii__DOT__cycle_num, top->vicii__DOT__bit_cycle);
             if (verifyNextDotXPos >= 0) {
                // This is a check to make sure the next dot is what
                // we expected from the fpga sync step above.
                if (top->vicii__DOT__xpos != verifyNextDotXPos) {
                   LOG(LOG_ERROR, "expected next dot to have xpos=%03x but got xpos=%03x @ cycle=%d bit_cycle=%d",
                                   verifyNextDotXPos, top->vicii__DOT__xpos, top->vicii__DOT__cycle_num, top->vicii__DOT__bit_cycle);
                   exit(-1);
                } else {
                   LOG(LOG_INFO, "got expected next dot with xpos=%03x", top->vicii__DOT__xpos);
                }
                verifyNextDotXPos = -1;
             }

             // Make sure xpos is what we expect at key points
             if (top->vicii__DOT__cycle_num == 12 && top->vicii__DOT__bit_cycle == 4)
               assert (top->vicii__DOT__xpos == 0); // rollover

             if (top->vicii__DOT__cycle_num == 0 && top->vicii__DOT__bit_cycle == 0)
               if (chip == CHIP6569)
                  assert (top->vicii__DOT__xpos == 0x194); // reset
               else
                  assert (top->vicii__DOT__xpos == 0x19c); // reset

             if (chip == CHIP6567R8)
               if (top->vicii__DOT__cycle_num == 61 && (top->vicii__DOT__bit_cycle == 0 || top->vicii__DOT__bit_cycle == 4))
                  assert (top->vicii__DOT__xpos == 0x184); // repeat cases
               else if (top->vicii__DOT__cycle_num == 62 && top->vicii__DOT__bit_cycle == 0)
                  assert (top->vicii__DOT__xpos == 0x184); // repeat case

             SDL_SetRenderDrawColor(ren,
                top->red << 6,
                top->green << 6,
                top->blue << 6,
                255);
             drawPixel(ren,
                top->vicii__DOT__raster_x,
                top->vicii__DOT__raster_line
             );

             // Show updated pixels per raster line
             if (prev_y != top->vicii__DOT__raster_line) {
                SDL_RenderPresent(ren);
                prev_y = top->vicii__DOT__raster_line;

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

        if (shadowVic && HASCHANGED(OUT_DOT) && needDotTick) {
           // TODO : Report back any outputs like data, ba, aec, etc. here

           // 
           state->phi = top->clk_phi;

           if (top->ce == 0 && top->rw == 1) {
              // Chip selected and read, set data in state
              state->data = top->dbo;
           }

           bool needQuit = false;
           if (state->flags & VICII_OP_CAPTURE_END) {
              needQuit = true;
           }

           // After we have one full frame, exit the loop.
           if ((state->flags & VICII_OP_CAPTURE_ONE_FRAME) !=0 &&
              top->vicii__DOT__xpos == 0 && top->vicii__DOT__raster_line == 0) {
              needQuit = true;
           }

           if (ipc_send(ipc))
              break;
           needDotTick = false;

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

    if (outputVcd) {
        fclose(outFile);
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
