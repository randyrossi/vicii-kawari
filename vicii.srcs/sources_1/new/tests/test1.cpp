#include <stdio.h>

#include "../test.h"
#include "../log.h"

static FILE* fp;
bool quit;
bool enabled;

int test1_start(Vvicii *top, int golden) {
   LOG(LOG_INFO, "cycles_no_sprites_no_badlines");
   char format[64];
   char name[64];
   strcpy (format, "tests/");
   strcat (format, "cycles_no_sprites_no_badlines");
   strcat (format, "_chip%d.dat");
   
   sprintf (name, format, top->chip);
   
   fp = do_start_file((const char*)name, golden);
   if (!fp) {
      LOG(LOG_ERROR,"Can't open goden for %s", golden ? "write" : "read"); 
      return TEST_FAIL; 
   } 
    
   return TEST_CONTINUE_NOT_CAPTURING;
}

int test1_post(Vvicii* top, int golden) {
   if (is_about_to_start_line(top, 1)) {
      enabled = true;
   } else if (is_about_to_start_line(top, 2)) {
      enabled = false;
      return TEST_END;
   }

   if (enabled) {
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
      return TEST_CONTINUE_CAPTURING;
   }
   return TEST_CONTINUE_NOT_CAPTURING;
}
