
#define RUN_TEST(VAR) printf ("%s:", #VAR); if (VAR()) { printf (" FAIL\n"); } else { printf ("PASS\n"); }
#define RUN_TEST1(VAR,ARG) printf ("%s(%s):", #VAR,#ARG); if (VAR(ARG)) { printf (" FAIL\n"); } else { printf ("PASS\n"); }

#define EXPECT_EQ(have, need) if ((have) != (need)) {printf (#have "!=" #need); return 1; }

int umult_1(void);
int smult_1(void);
int udiv_1(void);
int sdiv_1(void);

#define NUM_RAND_RUNS 256
