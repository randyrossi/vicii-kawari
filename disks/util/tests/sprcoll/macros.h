#ifndef MACROS_H
#define MACROS_H

// Every test runs with hires enabled and both test sprites initialized
// but turned off. test_end() restores the registers we touch so the
// PASS/FAIL text is readable again on the 40 column screen.
#define RUN_TEST(VAR) \
   printf ("%s:", #VAR); \
   test_begin(); \
   res = VAR(); \
   test_end(); \
   printf (res ? " FAIL\n" : "PASS\n");

// Prints 'expr=have/need' on failure. The text lands on the 40 column
// screen which becomes visible when the test ends.
#define EXPECT_EQ(have, need) \
   { \
      unsigned int h_ = (have); \
      if (h_ != (unsigned int)(need)) { \
         printf ("%s=%u/%u", #have, h_, (unsigned int)(need)); \
         return 1; \
      } \
   }

#endif
