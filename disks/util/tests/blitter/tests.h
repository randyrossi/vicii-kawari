int test_160x200x16_blit(void);
int test_320x200x16_blit(void);
int test_640x200x4_blit(void);
int test_blit_irq(void);
int test_blit_op(void);

void fill(unsigned int addr,
          unsigned int size,
          unsigned int value );

void box(unsigned int addr, int width, int height, int stride, int pixperbyte, int c);

void wait_blitter(void);

void blit(int width, int height, long src_ptr, int sx, int sy,
          int src_stride, long dst_ptr, int dx, int dy,
          int dst_stride, unsigned char raster_flags, int wait);
