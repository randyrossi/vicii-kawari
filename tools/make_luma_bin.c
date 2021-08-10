// Make luma.bin for block ram registers

#include <stdio.h>

#define BINARY 0
#define DECIMAL 1
#define HEX 2
#define CHARS 3
#define CODE 4

#define LUMA 1
#define PHASE 2
#define AMP 3

static int output_type = CODE;
static int output_attr = AMP;

// Pick the 6567R8 values for the defaults. If the board
// has EEPROM, they will get overwritten at startup if
// it has been initialized.  Otherwise, we use these sane
// defaults.

// These are the same values in init.c for 6567R8

// Use this prog to generate luma.bin and they also have
// to go into registers.v in case no EEPROM is compiled in.
unsigned int luma[16] =
    {12,63,24,42,27,35,21,50,27,21,35,24,33,50,33,42};

unsigned int amplitude[16] =
   {0, 0, 0xd, 0xa, 0xc, 0xb, 0xb, 0xf, 0xf, 0xb, 0xc, 0, 0, 0xd, 0xd, 0};

unsigned int phase[16] =
   {0, 0, 80, 208, 32, 160, 241, 128, 96, 112, 80, 0, 0, 160, 241, 0};

static char *name[] = {
        "BLACK      ",
        "WHITE      ",
        "RED        ",
        "CYAN       ",
        "PURPLE     ",
        "GREEN      ",
        "BLUE       ",
        "YELLOW     ",
        "ORANGE     ",
        "BROWN      ",
        "PINK       ",
        "DARK_GREY  ",
        "GREY       ",
        "LIGHT_GREEN",
        "LIGHT_BLUE ",
        "LIGHT_GREY "
};

char dst[3][16];
char* bin(int n, int v, int nbit, int sbit) {
   int b;
   for(b=0;b<nbit;b++) {
      if (v & sbit) 
          dst[n][b] = '1';
      else  
          dst[n][b] = '0';
      sbit=sbit/2;
   }
   return dst[n];
}

int main(int argc, char *argv[]) {
  int loc;
  int i;

  for (i=0;i<16;i++) {
    if (output_type == BINARY)
       printf ("%s%s%s\n",
          bin(0,luma[i],6,32), bin(1,phase[i],8,128), bin(2,amplitude[i],4,8));
    else if (output_type == DECIMAL)
       printf ("%d,%d,%d,\n",luma[i], phase[i], amplitude[i]);
    else if (output_type == HEX)
       printf ("%02x,%02x,%02x,\n",luma[i], phase[i], amplitude[i]);
    else if (output_type == CODE)
       if (output_attr == LUMA)
          printf ("        `%s: lumareg_o <= 6'h%02x;\n", name[i], luma[i]);
       else if (output_attr == PHASE) {
          int degrees = phase[i] * 360 / 256;
          float degrees_dec = (double)phase[i] * 360.0d / 256.0d;
          int dec = (degrees_dec - degrees) * 10;
          if (i == 0 || i == 1 || i == 15 || i == 12 || i == 11)
             printf ("        `%s: phasereg_o <= 8'h%02x; // unmodulated\n", name[i], phase[i]);
          else
             printf ("        `%s: phasereg_o <= 8'h%02x; // %d.%d degrees\n", name[i], phase[i], degrees, dec);
       }
       else if (output_attr == AMP)
          if (i == 0 || i == 1 || i == 15 || i == 12 || i == 11)
             printf ("        `%s: amplitudereg_o <= 4'h%02x; // unmodulated\n", name[i], amplitude[i]);
          else
             printf ("        `%s: amplitudereg_o <= 4'h%02x;\n", name[i], amplitude[i]);
  } 
}
