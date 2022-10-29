#include <peekpoke.h>

#include "kawari.h"
#include "color.h"

void save_colors(unsigned char *save_space) {
  int reg;
  int d = 0;
  for (reg=64;reg<128;reg++) {
     if (reg % 4 == 3) continue;
     POKE(VIDEO_MEM_1_LO, reg);
     save_space[d++] = PEEK(VIDEO_MEM_1_VAL);
  }
  for (reg=0;reg<16;reg++) {
     POKE(VIDEO_MEM_1_LO, reg+ 0xa0); // luma
     save_space[d++] = PEEK(VIDEO_MEM_1_VAL);
  }
  for (reg=0;reg<16;reg++) {
     POKE(VIDEO_MEM_1_LO, reg+ 0xb0); // phase
     save_space[d++] = PEEK(VIDEO_MEM_1_VAL);
  }
  for (reg=0;reg<16;reg++) {
     POKE(VIDEO_MEM_1_LO, reg+ 0xc0); // amp
     save_space[d++] = PEEK(VIDEO_MEM_1_VAL);
  }
}

void restore_colors(unsigned char *save_space) {
  int reg;
  int d = 0;
  for (reg=64;reg<128;reg++) {
     if (reg % 4 == 3) continue;
     POKE(VIDEO_MEM_1_LO, reg);
     POKE(VIDEO_MEM_1_VAL, save_space[d++]);
  }
  for (reg=0;reg<16;reg++) {
     POKE(VIDEO_MEM_1_LO, reg+ 0xa0); // luma
     POKE(VIDEO_MEM_1_VAL, save_space[d++]);
  }
  for (reg=0;reg<16;reg++) {
     POKE(VIDEO_MEM_1_LO, reg+ 0xb0); // phase
     POKE(VIDEO_MEM_1_VAL, save_space[d++]);
  }
  for (reg=0;reg<16;reg++) {
     POKE(VIDEO_MEM_1_LO, reg+ 0xc0); // amp
     POKE(VIDEO_MEM_1_VAL, save_space[d++]);
  }
}

/*
RgbColor hsv_to_rgb(HsvColor hsv)
{
    RgbColor rgb;
    unsigned char region, remainder, p, q, t;

    if (hsv.s == 0)
    {
        rgb.r = hsv.v;
        rgb.g = hsv.v;
        rgb.b = hsv.v;
        return rgb;
    }

    region = hsv.h / 43;
    remainder = (hsv.h - (region * 43)) * 6; 

    p = (hsv.v * (255 - hsv.s)) >> 8;
    q = (hsv.v * (255 - ((hsv.s * remainder) >> 8))) >> 8;
    t = (hsv.v * (255 - ((hsv.s * (255 - remainder)) >> 8))) >> 8;

    switch (region)
    {
        case 0:
            rgb.r = hsv.v; rgb.g = t; rgb.b = p;
            break;
        case 1:
            rgb.r = q; rgb.g = hsv.v; rgb.b = p;
            break;
        case 2:
            rgb.r = p; rgb.g = hsv.v; rgb.b = t;
            break;
        case 3:
            rgb.r = p; rgb.g = q; rgb.b = hsv.v;
            break;
        case 4:
            rgb.r = t; rgb.g = p; rgb.b = hsv.v;
            break;
        default:
            rgb.r = hsv.v; rgb.g = p; rgb.b = q;
            break;
    }

    return rgb;
}
*/

// This is a RGB to HSV routine that does not
// use floating point math (but is less accurate
// as a consequence).
//
// Input RGB values should be between 0 and 63
// Returned H (hue) is 0-255 representing 0-360 degrees
// Returned V (value) is 0-63
// Returned S (saturation) is 0-15
// It is up to the caller to make sure V does not
// fall below the back level.
void rgb_to_hsv(unsigned char r, unsigned char g, unsigned char b,
                    unsigned char* h, unsigned char *s, unsigned char *v)
{
    unsigned char rgbMin, rgbMax;

    // clamp RGB to max 63 (6 bits)
    if (r > 63) r = 63;
    if (g > 63) g = 63;
    if (b > 63) b = 63;

    rgbMin = r < g ? (r < b ? r : b) : (g < b ? g : b);
    rgbMax = r > g ? (r > b ? r : b) : (g > b ? g : b);

    *v = rgbMax;
    if (*v == 0)
    {
        *h = 0;
        *s = 0;
        return;
    }

    // Saturation (amplitude) is 4 bits
    *s = 15 * (long)(rgbMax - rgbMin) / *v;
    if (*s == 0)
    {
        *h = 0;
        return;
    }

    // We have 8 bits (0-255) for hue angle
    // 43 = 60 degrees
    if (rgbMax == r)
        *h = 85 + 43 * (g - b) / (rgbMax - rgbMin);  // 120 degrees
    else if (rgbMax == g)
        *h = 170 + 43 * (b - r) / (rgbMax - rgbMin); // 240 degrees
    else
        *h = 43 * (r - g) / (rgbMax - rgbMin); // 0 degrees
}

void get_col(int index, unsigned char *r, unsigned char *g, unsigned char *b)
{
    POKE(VIDEO_MEM_1_LO, 64+index*4);
    *r = PEEK(VIDEO_MEM_1_VAL);
    POKE(VIDEO_MEM_1_LO, 65+index*4);
    *g = PEEK(VIDEO_MEM_1_VAL);
    POKE(VIDEO_MEM_1_LO, 66+index*4);
    *b = PEEK(VIDEO_MEM_1_VAL);
}

void prep_col(int index,
              unsigned char *r_reg,
              unsigned char *g_reg,
              unsigned char *b_reg,
              unsigned char r, unsigned char g, unsigned char b,
              unsigned char *h_reg,
              unsigned char *s_reg,
              unsigned char *v_reg,
              unsigned char *h, unsigned char *s, unsigned char *v,
              unsigned char min_v)
{
    rgb_to_hsv(r, g, b, h, s, v);
    if (*v < min_v) *v = min_v;

    *r_reg = 64+index*4;
    *g_reg = 65+index*4;
    *b_reg = 66+index*4;
    *v_reg = 0xa0+index;
    *h_reg = 0xb0+index;
    *s_reg = 0xc0+index;
}

void set_col(unsigned char r_reg,
             unsigned char g_reg,
             unsigned char b_reg,
             unsigned char r, unsigned char g, unsigned char b,
             unsigned char h_reg,
             unsigned char s_reg,
             unsigned char v_reg,
             unsigned char h, unsigned char s, unsigned char v) {

    POKE(VIDEO_MEM_1_LO, r_reg);
    POKE(VIDEO_MEM_1_VAL, r);
    POKE(VIDEO_MEM_1_LO, g_reg);
    POKE(VIDEO_MEM_1_VAL, g);
    POKE(VIDEO_MEM_1_LO, b_reg);
    POKE(VIDEO_MEM_1_VAL, b);

    POKE(VIDEO_MEM_1_LO, v_reg);
    POKE(VIDEO_MEM_1_VAL, v);
    POKE(VIDEO_MEM_1_LO, h_reg);
    POKE(VIDEO_MEM_1_VAL, h);
    POKE(VIDEO_MEM_1_LO, s_reg);
    POKE(VIDEO_MEM_1_VAL, s);
}

void fade_to(int index,
             unsigned char r, unsigned char g, unsigned char b,
             unsigned char min_v)
{
   int step;
   int r2, g2, b2;
   int cur2_r, cur2_g, cur2_b;
   int diff_r, diff_g, diff_b;
   int step_r, step_g, step_b;
   int r3,g3,b3;
   unsigned char cur_r, cur_g, cur_b;
   unsigned char r_reg,g_reg,b_reg;
   unsigned char h_reg,s_reg,v_reg;
   unsigned char h,s,v;
   get_col(index, &cur_r, &cur_g, &cur_b);

   r2 = r*100;
   g2 = g*100;
   b2 = b*100;
   cur2_r = cur_r * 100;
   cur2_g = cur_g * 100;
   cur2_b = cur_b * 100;
   diff_r = r2 - cur2_r;
   step_r = diff_r / 30;
   diff_g = g2 - cur2_g;
   step_g = diff_g / 30;
   diff_b = b2 - cur2_b;
   step_b = diff_b / 30;

   for (step = 0; step < 30; step++) {
      cur2_r += step_r;
      if (step_r < 0 && cur2_r < 0) cur2_r = 0;
      if (step_r > 0 && cur2_r > r2) cur2_r = r2;
      cur2_g += step_g;
      if (step_g < 0 && cur2_g < 0) cur2_g = 0;
      if (step_g > 0 && cur2_g > g2) cur2_g = g2;
      cur2_b += step_b;
      if (step_b < 0 && cur2_b < 0) cur2_b = 0;
      if (step_b > 0 && cur2_b > r2) cur2_b = b2;

      r3=cur2_r/100;
      g3=cur2_g/100;
      b3=cur2_b/100;

      prep_col(index,
               &r_reg, &g_reg, &b_reg,
               r3, g3, b3,
               &h_reg, &s_reg, &v_reg,
               &h, &s, &v,
               min_v);
      while(PEEK(0xd012L) != 240) { }
      while(PEEK(0xd012L) == 240) { }
      set_col(r_reg, g_reg, b_reg,
              r3,g3,b3,
              h_reg, s_reg, v_reg,
              h, s, v);
   }
   prep_col(index,
            &r_reg, &g_reg, &b_reg,
            r, g, b,
            &h_reg, &s_reg, &v_reg,
            &h, &s, &v,
            min_v);
   while(PEEK(0xd012L) != 240) { }
   while(PEEK(0xd012L) == 240) { }
   set_col(r_reg, g_reg, b_reg,
           r3,g3,b3,
           h_reg, s_reg, v_reg,
           h, s, v);
}

void save_colors_vmem(unsigned long addr) {
  int reg;
  int d = 0;
  unsigned char v;
  POKE(VIDEO_MEM_2_IDX, 0);
  POKE(VIDEO_MEM_2_LO, addr & 0xFF);
  POKE(VIDEO_MEM_2_HI, (addr >> 8) & 0xFF);

  for (reg=64;reg<128;reg++) {
     if (reg % 4 == 3) continue;
     POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_REGS_BIT);
     POKE(VIDEO_MEM_1_LO, reg);
     v = PEEK(VIDEO_MEM_1_VAL); // from regs
     POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_AUTO_INC_2);
     POKE(VIDEO_MEM_2_VAL, v); // to vram
  }
  for (reg=0;reg<16;reg++) {
     POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_REGS_BIT);
     POKE(VIDEO_MEM_1_LO, reg+ 0xa0); // luma
     v = PEEK(VIDEO_MEM_1_VAL);
     POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_AUTO_INC_2);
     POKE(VIDEO_MEM_2_VAL, v); // to vram
  }
  for (reg=0;reg<16;reg++) {
     POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_REGS_BIT);
     POKE(VIDEO_MEM_1_LO, reg+ 0xb0); // phase
     v = PEEK(VIDEO_MEM_1_VAL);
     POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_AUTO_INC_2);
     POKE(VIDEO_MEM_2_VAL, v); // to vram
  }
  for (reg=0;reg<16;reg++) {
     POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_REGS_BIT);
     POKE(VIDEO_MEM_1_LO, reg+ 0xc0); // amp
     v = PEEK(VIDEO_MEM_1_VAL);
     POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_AUTO_INC_2);
     POKE(VIDEO_MEM_2_VAL, v); // to vram
  }
}

void restore_colors_vmem(unsigned long addr) {
  int reg;
  int d = 0;
  unsigned char v;

  POKE(VIDEO_MEM_2_IDX, 0);
  POKE(VIDEO_MEM_2_LO, addr & 0xFF);
  POKE(VIDEO_MEM_2_HI, (addr >> 8) & 0xFF);
  for (reg=64;reg<128;reg++) {
     if (reg % 4 == 3) continue;
     POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_AUTO_INC_2);
     v = PEEK(VIDEO_MEM_2_VAL);
     POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_REGS_BIT);
     POKE(VIDEO_MEM_1_LO, reg);
     POKE(VIDEO_MEM_1_VAL, v);
  }
  for (reg=0;reg<16;reg++) {
     POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_AUTO_INC_2);
     v = PEEK(VIDEO_MEM_2_VAL);
     POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_REGS_BIT);
     POKE(VIDEO_MEM_1_LO, reg + 0xa0); // luma
     POKE(VIDEO_MEM_1_VAL, v);
  }
  for (reg=0;reg<16;reg++) {
     POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_AUTO_INC_2);
     v = PEEK(VIDEO_MEM_2_VAL);
     POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_REGS_BIT);
     POKE(VIDEO_MEM_1_LO, reg + 0xb0); // phase
     POKE(VIDEO_MEM_1_VAL, v);
  }
  for (reg=0;reg<16;reg++) {
     POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_AUTO_INC_2);
     v = PEEK(VIDEO_MEM_2_VAL);
     POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_REGS_BIT);
     POKE(VIDEO_MEM_1_LO, reg + 0xc0); // amp
     POKE(VIDEO_MEM_1_VAL, v);
  }

}
