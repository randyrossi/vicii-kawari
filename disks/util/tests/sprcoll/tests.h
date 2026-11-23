#ifndef TESTS_H
#define TESTS_H

// Sprite coordinates of the top left pixel of the display window.
#define SPR_X0 24
#define SPR_Y0 50

// Sprite to background collision register / irq bits
#define M2D_REG 0xd01fL
#define IRQ_MBC 2

// Hires text mode layout used by the text tests (video mem addresses)
#define TXT_CHARS  0x0000  // CHAR_PIXEL_BASE 0 (4k)
#define TXT_MATRIX 0x1000  // MATRIX_BASE 2 (2k blocks)
#define TXT_COLOR  0x1800  // COLOR_BASE 3 (2k blocks)

// Color cell attribute bits for hires text mode
#define ATTR_BLINK 16
#define ATTR_UNDER 32
#define ATTR_RVRS  64

// A bare PEEK() whose value is unused gets no code generated for it by
// cc65. Reads done only for their side effect must store the result.
extern unsigned char reg_sink;
#define CLR_M2D() (reg_sink = PEEK(M2D_REG))

// tests.c - helpers
void fill(unsigned int addr, unsigned int size, unsigned int value);
void vpoke(unsigned int addr, unsigned char value);
void wait_frame(void);
void test_begin(void);
void test_end(void);
void spr_pos(unsigned char n, unsigned int x, unsigned char y);
void spr_on(unsigned char mask);
unsigned char coll(void);
unsigned char coll_at(unsigned int x, unsigned char y);
unsigned char sweep(unsigned int x, unsigned char y);

// test_text.c - mode 000
int text_pos(void);
int text_neg(void);
int text_attr(void);

// test_bitmap.c - modes 001 and 011 (640 wide)
int cell_pos_neg(void);
int cell_halfpix(void);
int c4_halfpix(void);

// test_color.c - packed pixel modes, color != $d021 is foreground
int c16_320_key(void);
int c16_160_key(void);
int c4_key(void);
int border_neg(void);

// test_misc.c
int spr_bits(void);
int irq_once(void);
int split(void);
int legacy(void);

#endif
