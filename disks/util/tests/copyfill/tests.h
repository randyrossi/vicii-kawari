int vmem_copy(int dir);
int vmem_copy_overlap(void);
int vmem_fill(void);

int test_copy_irq(void);


void fill(unsigned int addr,
          unsigned int size,
          unsigned int value,
          int poll_wait );
void box(unsigned int addr,
         int width, int height, int stride,
         int pix_per_byte, int c, int poll_wait);


void copy(int offset);
