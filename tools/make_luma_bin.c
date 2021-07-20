// Make luma.bin for block ram registers

#include <stdio.h>

#define BINARY 0
#define DECIMAL 1
#define HEX 2
#define CHARS 3

static int output_type = BINARY;

// Pick the 6569R8 values for the defaults. If the board
// has EEPROM, they will get overwritten at startup if
// it has been initialized.  Otherwise, we use these sane
// defaults.

// THESE ALSO NEED TO GO INTO registers.v in case no EEPROM is
// compiled in.
unsigned int luma[16] ={
        0x0c,
        0x3a,
        0x13,
        0x24,
        0x16,
        0x1e,
        0x0e,
        0x2b,
        0x16,
        0x0e,
        0x1e,
        0x13,
        0x1c,
        0x2b,
        0x1c,
        0x24,
};

unsigned int amplitude[16] = {
        0b0000, // no modulation
        0b0000, // no modulation
        0b1010,
        0b1010,
        0b1100,
        0b1100,
        0b1010,
        0b1110,
        0b1110,
        0b1010,
        0b1010,
        0b0000, // no modulation
        0b0000, // no modulation
        0b1010,
        0b1010,
        0b0000  // no modulation
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
  } 
}
