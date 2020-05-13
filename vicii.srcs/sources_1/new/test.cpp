#include <stdio.h>

#include "log.h"
#include "test.h"
#include "tests/test1.h"

typedef int (*test_func)(Vvicii*, int);

static int tickCount;

test_func test_start[] = {
   test1_start,
};

test_func test_post[] = {
   test1_post,
};

int do_test_start(int driver, Vvicii* top, int golden) {
   return test_start[driver-1](top, golden);
}

int do_test_post(int driver, Vvicii* top, int golden) {
   if (top->clk_dot4x)
      return test_post[driver-1](top, golden);
   return TEST_CONTINUE;
}

FILE* do_start_file(const char* name, int golden) {
   FILE* fp;
   if (golden) {
      fp = fopen(name,"w");
      if (!fp) LOG(LOG_ERROR,"Can't open goden for write"); 
   } else {
      fp = fopen(name,"r");
      if (!fp) LOG(LOG_ERROR,"Can't open golden data");
   }
   return fp;
}

// post tester to see if we ran though one whole frame
int is_frame_end(Vvicii* top) {
     if (top->V_BIT_CYCLE == 0 &&
            top->V_RASTER_X == 0 &&
               top->V_RASTER_LINE == 0 &&
                  top->V_PPS & 1)
         return 1;
   return 0;
}

int is_about_to_start_line(Vvicii* top, int line) {
     line = line - 1;
     if (line < 0) {
        if (top->chip == CHIP6569) line = PAL_6569_MAX_DOT_Y;
        else if (top->chip == CHIP6567R56A) line = NTSC_6567R56A_MAX_DOT_Y;
        else if (top->chip == CHIP6567R8) line = NTSC_6567R8_MAX_DOT_Y;
        else exit(-1);
     }

     int max_x;
     if (top->chip == CHIP6569) max_x = PAL_6569_MAX_DOT_X;
     else if (top->chip == CHIP6567R56A) max_x = NTSC_6567R56A_MAX_DOT_X;
     else if (top->chip == CHIP6567R8) max_x = NTSC_6567R8_MAX_DOT_X;
     else exit(-1);

     if (top->V_BIT_CYCLE == 7 &&
            top->V_RASTER_X == max_x &&
               top->V_RASTER_LINE == line &&
                  top->V_PPS & 32768)
         return 1;
   return 0;
}

int is_about_to_start_cycle(Vvicii* top, int cycle) {
     cycle = cycle - 1;
     if (cycle < 0) {
        if (top->chip == CHIP6569) cycle = PAL_6569_NUM_CYCLES-1;
        else if (top->chip == CHIP6567R56A) cycle = NTSC_6567R56A_NUM_CYCLES-1;
        else if (top->chip == CHIP6567R8) cycle = NTSC_6567R8_NUM_CYCLES-1;
        else exit(-1);
     }
     if (top->V_BIT_CYCLE == 7 &&
            top->V_CYCLE_NUM == cycle &&
               top->V_PPS & 32768)
         return 1;
   return 0;
}
