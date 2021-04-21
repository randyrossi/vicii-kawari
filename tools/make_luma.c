
#include <stdio.h>

#define BINARY 0
#define DECIMAL 1
#define CHARS 2

static int output_type = BINARY;
static int do_ntsc = 0;
static int do_pal = 0;
static int do_ansii = 0;
static int do_community = 1;

unsigned int luma[16] ={
	0b010011, // 0
        0b111011, // 8
        0b011111, // 2
        0b101100, // 6
        0b100010, // 3
        0b100111, // 5
        0b011100, // 1
        0b110010, // 7
        0b100010, // 3
        0b011100, // 1
        0b100111, // 5
        0b011111, // 2
        0b100110, // 4
        0b110010, // 7
        0b100110, // 4
        0b101100  // 6
};

unsigned int amplitude[16] = {
        0b111, // no modulation
        0b111, // no modulation
        0b010,
        0b010,
        0b001,
        0b001,
        0b010,
        0b000,
        0b000,
        0b010,
        0b010,
        0b111, // no modulation
        0b111, // no modulation
        0b010,
        0b010,
        0b111  // no modulation
};

unsigned int phase[16] = {
        0,  // unmodulated
        0,  // unmodulated
        80, // 112.5 deg
        208, // 292.5 deg
        32, // 45 deg
        160, // 225 deg
        0, // 0 deg
        128, // 180 deg
        96, // 135 deg
        112, // 157.5 deg
        80, // 112.5 deg
        0,  // unmodulated
        0,  // unmodulated
        160, // 225 deg
        0,  // 0 deg
        0   // unmodulated
};

char dst[3][16];
char* bin(int n, int v, int nbit, int sbit) {
   for(int b=0;b<nbit;b++) {
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

  for (int i=0;i<16;i++) {
    printf ("%s%s%s\n",bin(0,luma[i],6,32), bin(1,phase[i],8,128), bin(2,amplitude[i],3,4));
  } 
}
