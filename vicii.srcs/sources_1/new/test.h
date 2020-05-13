#ifndef VICII_TEST_H
#define VICII_TEST_H

#include "Vvicii.h"
#include "constants.h"

#define TEST_CONTINUE 0
#define TEST_FAIL     1
#define TEST_END      2 

int do_test_start(int driver, Vvicii *top, int golden);
int do_test_post(int driver, Vvicii* top, int golden);

#define TEST_BLOCK(name) \
int name##_start(Vvicii *top, int golden); \
int name##_post(Vvicii* top, int golden);

FILE* do_start_file(const char* name, int golden);

int is_frame_end(Vvicii* top);
int is_about_to_start_line(Vvicii* top, int line);
int is_about_to_start_cycle(Vvicii* top, int cycle);

#endif
