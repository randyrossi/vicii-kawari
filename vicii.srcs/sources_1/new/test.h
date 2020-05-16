#ifndef VICII_TEST_H
#define VICII_TEST_H

#include "Vvicii.h"
#include "constants.h"

#define TEST_CONTINUE_NOT_CAPTURING 0
#define TEST_CONTINUE_CAPTURING     1
#define TEST_FAIL                   2
#define TEST_END                    3

int do_test_start(int driver, Vvicii *top, int golden);
int do_test(int driver, Vvicii* top, int golden);

#define TEST_BLOCK(name) \
int name##_start(Vvicii *top, int golden); \
int name##_run(Vvicii* top, int golden);

FILE* do_start_file(const char* name, int golden);

int is_frame_end(Vvicii* top);
int is_about_to_start_line(Vvicii* top, int line);
int is_about_to_start_cycle(Vvicii* top, int cycle);

#define TEST_START(name, test_id) \
int name##_start(Vvicii *top, int golden) { \
   LOG(LOG_INFO, test_id); \
   init(top); \
   return TEST_CONTINUE_NOT_CAPTURING; \
}

#define TEST_START_WITH_GOLDEN(name, test_id) \
int name##_start(Vvicii *top, int golden) { \
   LOG(LOG_INFO, test_id); \
   char format[64]; \
   char name[64]; \
   strcpy (format, "tests/"); \
   strcat (format, test_id); \
   strcat (format, "_chip%d.dat"); \
   sprintf (name, format, top->chip); \
   fp = do_start_file((const char*)name, golden); \
   if (!fp) {\
      LOG(LOG_ERROR,"Can't open goden for %s", golden ? "write" : "read");\
      return TEST_FAIL;\
   }\
   init(top); \
   return TEST_CONTINUE_NOT_CAPTURING; \
}

#define EXPECT(name, have, expected) \
   if (have != expected) { \
      LOG(LOG_ERROR,"Expected " #name "=%d but got %d\n", expected, have); \
      return TEST_FAIL; \
   }


#endif
