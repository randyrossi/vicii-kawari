#ifndef COLOR_H
#define COLOR_H

#include "data.h"

#define COLOR_SAVE_SPACE 96

// Save all color registers (both rgb and hsv)
// Requires temp space of size COLOR_SAVE_SPACE bytes
void save_colors(unsigned char *save_space);
void save_colors_vmem(unsigned long addr);

// Restore all color registers (both rgb and hsv)
// Requires temp space of size COLOR_SAVE_SPACE bytes
void restore_colors(unsigned char *save_space);
void restore_colors_vmem(unsigned long addr);

// Convert RGB to HSV
void rgb_to_hsv(unsigned char r, unsigned char g, unsigned char b,
                unsigned char *h, unsigned char *s, unsigned char *v);

// Grab current RGB color. Expects registers to be activated.
void get_col(int index, unsigned char *r, unsigned char *g, unsigned char *b);

void prep_col(int index,
              unsigned char *r_reg,
              unsigned char *g_reg,
              unsigned char *b_reg,
              unsigned char r, unsigned char g, unsigned char b,
              unsigned char *h_reg,
              unsigned char *s_reg,
              unsigned char *v_reg,
              unsigned char *h, unsigned char *s, unsigned char *v,
              unsigned char min_v);

// Set both RGB color AND HSV colors. Expects registers to be activated.
void set_col(unsigned char r_reg,
             unsigned char g_reg,
             unsigned char b_reg,
             unsigned char r, unsigned char g, unsigned char b,
             unsigned char h_reg,
             unsigned char s_reg,
             unsigned char v_reg,
             unsigned char h, unsigned char s, unsigned char v);

// Cheap fade effect from current color to a differnnt one.
void fade_to(int index, unsigned char r, unsigned char g, unsigned char b, unsigned char min_v);

#endif
