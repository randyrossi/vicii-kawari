// DESCRIPTION: Verilator: Verilog example module
//
// This file ONLY is placed into the Public Domain, for any use,
// without warranty, 2017 by Wilson Snyder.
//======================================================================

// Include common routines
#include <verilated.h>

// Include model header, generated from Verilating "top.v"
#include "Vtop.h"

// Current simulation time (64-bit unsigned)
static vluint64_t ticks = 0;

// How much to divide our ticks (which is always picoseconds) down to our VCD timescale
#define PICOSECONDS_TO_TIMESCALE 1000L

// Add new input/output here
#define NUM_SIGNALS 10
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

// Add new input/output here
const char *signal_labels[] = { "phi", "col", "rst", "r0", "r1", "g0", "g1", "b0", "b1" , "dot"};
const char *signal_ids[] = { "p", "c", "r" ,  "r0", "r1", "g0", "g1", "b0", "b1" , "dot" };

unsigned char *signal_src[NUM_SIGNALS];
unsigned int signal_bit[NUM_SIGNALS];
bool signal_monitor[NUM_SIGNALS];
unsigned char prev_signal_values[NUM_SIGNALS];

#define GETVAL(signum) (*signal_src[signum] & signal_bit[signum] ? 1 : 0)
#define HASCHANGED(signum) ( signal_monitor[signum] && GETVAL(signum) != prev_signal_values[signum] )

// Convert microseconds to ticks (picoseconds)
#define US_TO_TICKS(t) (t * 1000L * 1000L)

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

   // Time zero
   printf ("#0\n");
   for (int i=0;i<NUM_SIGNALS;i++)
      printf ("%x%s\n",GETVAL(i), signal_ids[i]);
   fflush(stdout);
}

int main(int argc, char** argv, char** env) {
    bool capture = true;
    vluint64_t endTicks = US_TO_TICKS(20000);

    // Prevent unused variable warnings
    if (0 && argc && argv && env) {}

    // Add new input/output here.
    Vtop* top = new Vtop;
    top->sys_clock = 0;
    top->clk_colref = 0;
    top->clk_phi = 0;
    top->rst = 0;
    top->red = 0;
    top->green = 0;
    top->blue = 0;

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

    for (int i = 0; i < NUM_SIGNALS; i++) {
       prev_signal_values[i] = GETVAL(i);
    }

    vcd_header(top);

    // Simulate until $finish
    while (!Verilated::gotFinish()) {
        // Advance simulation time. Each tick represents 1 picosecond.
        ticks = nextTick(top);

        // Toggle simulated system clock. One sys_clock
        // period represents 2 picoseconds duration.
        //top->sys_clock = !top->sys_clock;

#ifdef TEST_RESET
        // Test reset between approx 30 and approx 40 us
        if (ticks >= US_TO_TICKS(30L) && ticks <= US_TO_TICKS(40L))
           top->rst = 1;
        else
           top->rst = 0;
#endif

        // Evaluate model
        top->eval();

        if (capture) {
          bool anyChanged = false;
          for (int i = 0; i < NUM_SIGNALS; i++) {
             if (HASCHANGED(i)) {
                anyChanged = true;
                break;
             }
          }      

          if (anyChanged) {
             printf ("#%" VL_PRI64 "d\n", ticks/PICOSECONDS_TO_TIMESCALE);
             for (int i = 0; i < NUM_SIGNALS; i++) {
                if (HASCHANGED(i))
                   printf ("%x%s\n", GETVAL(i), signal_ids[i]);
             }
          }
        }

        for (int i = 0; i < NUM_SIGNALS; i++) {
           prev_signal_values[i] = GETVAL(i);
        }

        if (ticks >= endTicks)
           break;
    }

    // Final model cleanup
    top->final();

    // Destroy model
    delete top;

    // Fin
    exit(0);
}
