#ifndef TESTS_H
#define TESTS_H

int test_160x200x16(void);
int test_320x200x16(void);
int test_640x200x4(void);
int test_640x200x16(void);

void fill(unsigned int addr,
          unsigned int size,
          unsigned int value );

#endif
