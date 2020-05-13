#ifndef VICII_TEST_H
#define VICII_TEST_H

#include "Vvicii.h"
#include "constants.h"

#define TEST_OK 0
#define TEST_FAIL 1

#define TEST_END -1

int do_test_start(int driver, Vvicii *top, int golden);
int do_test_pre(int driver, Vvicii* top, int golden);
int do_test_post(int driver, Vvicii* top, int golden);
int do_test_end(int driver, Vvicii* top, int golden);

#define TEST_BLOCK(name) \
int name##_start(Vvicii *top, int golden); \
int name##_pre(Vvicii* top, int golden); \
int name##_post(Vvicii* top, int golden); \
int name##_end(Vvicii* top, int golden);

FILE* do_start_file(const char* name, int golden);
int do_frame_end(Vvicii* top, int golden);

#endif
