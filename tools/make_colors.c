
#include <stdio.h>

#define BINARY 0
#define DECIMAL 1
#define CHARS 2

static int output_type = BINARY;
static int do_ntsc = 0;
static int do_pal = 0;
static int do_ansii = 0;
static int do_community = 1;

static unsigned int community[] = {
  0x00,0x00,0x00, 0xff,0xff,0xff, 0xaf,0x2a,0x29, 0x62,0xd8,0xcc,
  0xb0,0x3f,0xb6, 0x4a,0xc6,0x4a, 0x37,0x39,0xc4, 0xe4,0xed,0x4e,
  0xb6,0x59,0x1c, 0x68,0x38,0x08, 0xea,0x74,0x6c, 0x4d,0x4d,0x4d,
  0x84,0x84,0x84, 0xa6,0xfa,0x9e, 0x70,0x7c,0xe6, 0xb6,0xb6,0xb5,
};

static unsigned int ntsc[] = {
  0x00,0x00,0x00, 0xFF,0xFF,0xFF, 0x67,0x37,0x2B, 0x70,0xA3,0xB1,
  0x6F,0x3D,0x86, 0x58,0x8C,0x42, 0x34,0x28,0x79, 0xB7,0xC6,0x6E,
  0x6F,0x4E,0x25, 0x42,0x38,0x00, 0x99,0x66,0x59, 0x43,0x43,0x43,
  0x6B,0x6B,0x6B, 0x9A,0xD1,0x83, 0x6B,0x5E,0xB5, 0x95,0x95,0x95,
};

static unsigned int pal[] = {
  0x00,0x00,0x00, 0xFF,0xFF,0xFF, 0x68,0x37,0x2b, 0x70,0xa4,0xb2,
  0x6f,0x3d,0x86, 0x58,0x8d,0x43, 0x35,0x28,0x79, 0xb8,0xc7,0x6f,
  0x6f,0x4f,0x25, 0x43,0x39,0x00, 0x9a,0x67,0x59, 0x44,0x44,0x44,
  0x6c,0x6c,0x6c, 0x9a,0xd2,0x84, 0x6c,0x5e,0xb5, 0x95,0x95,0x95,
};

static unsigned int ansii[] = {
/*black*/          0, 0, 0,
/*red*/            204, 0, 0,
/*green*/          78, 154, 6,
/*yellow*/         196, 160, 0,
/*blue*/           114, 159, 207,
/*magenta*/        117, 80, 123,
/*cyan*/           6, 152, 154,
/*white*/          211, 215, 207,
/*bright black*/   85, 87, 83,
/*bright red*/     239, 41, 41,
/*bright green*/   138, 226, 52,
/*bright yellow*/  252, 233, 79,
/*bright blue*/    50, 175, 255,
/*bright magenta*/ 173, 127, 168,
/*bright cyan*/    52, 226, 226,
/*bright white*/   255, 255, 255
};

char dst[3][16];
char* bin(int n, int v) {
   int bit=128;
   for(int b=0;b<6;b++) {
      if (v & bit) 
          dst[n][b] = '1';
      else  
          dst[n][b] = '0';
      bit=bit/2;
   }
   return dst[n];
}

// Take top 6 bits from VICE palette. Change later if we use more wires
// for colors.
int main(int argc, char *argv[]) {
  int loc;
  if (do_ntsc) {
    for (int i=0;i<16;i++) {
       if (output_type == BINARY)
          printf ("%s%s%s000000\n",bin(0,ntsc[i*3]), bin(1,ntsc[i*3+1]), bin(2,ntsc[i*3+2]));
       else if (output_type == DECIMAL)
          printf ("%d,%d,%d,0\n",ntsc[i*3]>>2, ntsc[i*3+1]>>2, ntsc[i*3+2]>>2);
       else if (output_type == CHARS)
          printf ("%c%c%c%c",ntsc[i*3]>>2, ntsc[i*3+1]>>2, ntsc[i*3+2]>>2, 0);
    } 
  }
  if (do_pal) {
    for (int i=0;i<16;i++) {
       if (output_type == BINARY)
          printf ("%s%s%s000000\n",bin(0,pal[i*3]), bin(1,pal[i*3+1]), bin(2,pal[i*3+2]));
       else if (output_type == DECIMAL)
          printf ("%d,%d,%d,0\n",pal[i*3]>>2, pal[i*3+1]>>2, pal[i*3+2]>>2);
       else if (output_type == CHARS)
          printf ("%c%c%c%c",pal[i*3]>>2, pal[i*3+1]>>2, pal[i*3+2]>>2, 0);
    } 
  }
  if (do_ansii) {
    for (int i=0;i<16;i++) {
       if (output_type == BINARY)
          printf ("%s%s%s000000\n",bin(0,ansii[i*3]), bin(1,ansii[i*3+1]), bin(2,ansii[i*3+2]));
       else if (output_type == DECIMAL)
          printf ("%d,%d,%d,0\n",ansii[i*3]>>2, ansii[i*3+1]>>2, ansii[i*3+2]>>2);
       else if (output_type == CHARS)
          printf ("%c%c%c%c",ansii[i*3]>>2, ansii[i*3+1]>>2, ansii[i*3+2]>>2, 0);
    } 
  }
  if (do_community) {
    for (int i=0;i<16;i++) {
       if (output_type == BINARY)
          printf ("%s%s%s000000\n",bin(0,community[i*3]), bin(1,community[i*3+1]), bin(2,community[i*3+2]));
       else if (output_type == DECIMAL)
          printf ("%d,%d,%d,0\n",community[i*3]>>2, community[i*3+1]>>2, community[i*3+2]>>2);
       else if (output_type == CHARS)
          printf ("%c%c%c%c",community[i*3]>>2, community[i*3+1]>>2, community[i*3+2]>>2, 0);
    } 
  }
}
