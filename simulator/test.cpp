#include <stdio.h>

#include "log.h"
#include "test.h"

typedef int (*test_func)(Vtop*, int);

TEST_BLOCK(test1);
TEST_BLOCK(test2);
TEST_BLOCK(test3);
TEST_BLOCK(test4);
TEST_BLOCK(test5);
TEST_BLOCK(test6);
TEST_BLOCK(test7);
TEST_BLOCK(test8);

static int tickCount;

test_func test_start[] = {
   test1_start,
   test2_start,
   test3_start,
   test4_start,
   test5_start,
   test6_start,
   test7_start,
   test8_start,
};

test_func test_run[] = {
   test1_run,
   test2_run,
   test3_run,
   test4_run,
   test5_run,
   test6_run,
   test7_run,
   test8_run,
};

int do_test_start(int driver, Vtop* top, int golden) {
   return test_start[driver-1](top, golden);
}

int do_test(int driver, Vtop* top, int golden) {
   return test_run[driver-1](top, golden);
}

FILE* do_start_file(const char* name, int golden) {
   FILE* fp;
   if (golden)
      fp = fopen(name, "w");
   else
      fp = fopen(name, "r");
   return fp;
}

// post tester to see if we ran though one whole frame
int is_frame_end(Vtop* top) {
     if (top->V_CYCLE_BIT == 0 &&
            top->V_RASTER_X == 0 &&
               top->V_RASTER_LINE == 0 &&
                  top->V_PPS & 1)
         return 1;
   return 0;
}

int is_about_to_start_line(Vtop* top, int line) {
     line = line - 1;
     if (line < 0) {
        if (top->V_CHIP == CHIP6569) line = PAL_6569_MAX_DOT_Y;
        else if (top->V_CHIP == CHIP6567R56A) line = NTSC_6567R56A_MAX_DOT_Y;
        else if (top->V_CHIP == CHIP6567R8) line = NTSC_6567R8_MAX_DOT_Y;
        else exit(-1);
     }

     int max_x;
     if (top->V_CHIP == CHIP6569) max_x = PAL_6569_MAX_DOT_X;
     else if (top->V_CHIP == CHIP6567R56A) max_x = NTSC_6567R56A_MAX_DOT_X;
     else if (top->V_CHIP == CHIP6567R8) max_x = NTSC_6567R8_MAX_DOT_X;
     else exit(-1);

     if (top->V_CYCLE_BIT == 7 &&
            top->V_RASTER_X == max_x &&
               top->V_RASTER_LINE == line &&
                  top->V_PPS & 32768)
         return 1;
   return 0;
}

int is_about_to_start_cycle(Vtop* top, int cycle) {
     cycle = cycle - 1;
     if (cycle < 0) {
        if (top->V_CHIP == CHIP6569) cycle = PAL_6569_NUM_CYCLES-1;
        else if (top->V_CHIP == CHIP6567R56A) cycle = NTSC_6567R56A_NUM_CYCLES-1;
        else if (top->V_CHIP == CHIP6567R8) cycle = NTSC_6567R8_NUM_CYCLES-1;
        else exit(-1);
     }
     if (top->V_CYCLE_BIT == 7 &&
            top->V_CYCLE_NUM == cycle &&
               top->V_PPS & 32768)
         return 1;
   return 0;
}
