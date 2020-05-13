#include <stdio.h>

#include "../test.h"
#include "../log.h"

static FILE* fp;
static int tickCount;

int test1_start(Vvicii *top, int golden) {
   LOG(LOG_INFO, "Cycles Test");
   char name[32];
   sprintf (name,"tests/test1_c%d.dat", top->chip);
   
   fp = do_start_file((const char*)name, golden);
   if (!fp) {
      LOG(LOG_ERROR,"Can't open goden for %s", golden ? "write" : "read"); 
      return TEST_FAIL; 
   } 
    
   return TEST_OK;
}

int test1_pre(Vvicii* top, int golden) {
   return TEST_OK;
}

int test1_post(Vvicii* top, int golden) {
   int cycle = -1;
   if (golden) {
      fprintf (fp, "%d\n", top->vicCycle);
   } else {
      fscanf (fp, "%d\n", &cycle);
      if (top->vicCycle != cycle) {
         LOG(LOG_ERROR,"Expected vicCycle=%d but got %d\n", cycle, top->vicCycle);
         return TEST_FAIL;
      }
   }
   return TEST_OK;
}

int test1_end(Vvicii* top, int golden) {
   if (do_frame_end(top, golden)) { fclose(fp); return TEST_END; }
   return TEST_OK;
}
