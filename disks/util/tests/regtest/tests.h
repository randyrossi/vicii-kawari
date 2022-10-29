
#define RUN_TEST(VAR) printf ("%s:", #VAR); if (VAR()) { printf (" FAIL\n"); } else { printf ("PASS\n"); }
#define RUN_TEST1(VAR,ARG) printf ("%s(%s):", #VAR,#ARG); if (VAR(ARG)) { printf (" FAIL\n"); } else { printf ("PASS\n"); }

#define EXPECT_EQ(have, need) if (have != need) {printf (#have "!=" #need); return 1; }

int auto_inc_vmem_a_16(void);
int auto_inc_vmem_a_wrap(void);
int auto_inc_vmem_b_16(void);
int auto_inc_vmem_b_wrap(void);

int auto_dec_vmem_a_16(void);
int auto_dec_vmem_a_wrap(void);
int auto_dec_vmem_b_16(void);
int auto_dec_vmem_b_wrap(void);

int noop_vmem_a(void);
int noop_vmem_b(void);

int vmem_a(void);
int vmem_b(void);
int vmem_idx_a(void);
int vmem_idx_b(void);

int vmem_copy(int dir);
int vmem_copy_overlap(void);
int vmem_fill(void);

int dma(void);
