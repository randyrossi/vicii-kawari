#include <stdio.h>

#include "../disks/util/include/data.h"

#define BYTE_TO_BINARY6_PATTERN "%c%c%c%c%c%c"
#define BYTE_TO_BINARY6(byte)  \
  (byte & 0x20 ? '1' : '0'), \
  (byte & 0x10 ? '1' : '0'), \
  (byte & 0x08 ? '1' : '0'), \
  (byte & 0x04 ? '1' : '0'), \
  (byte & 0x02 ? '1' : '0'), \
  (byte & 0x01 ? '1' : '0') 

#define BYTE_TO_BINARY8_PATTERN "%c%c%c%c%c%c%c%c"
#define BYTE_TO_BINARY8(byte)  \
  (byte & 0x80 ? '1' : '0'), \
  (byte & 0x40 ? '1' : '0'), \
  (byte & 0x20 ? '1' : '0'), \
  (byte & 0x10 ? '1' : '0'), \
  (byte & 0x08 ? '1' : '0'), \
  (byte & 0x04 ? '1' : '0'), \
  (byte & 0x02 ? '1' : '0'), \
  (byte & 0x01 ? '1' : '0') 

#define BYTE_TO_BINARY4_PATTERN "%c%c%c%c"
#define BYTE_TO_BINARY4(byte)  \
  (byte & 0x08 ? '1' : '0'), \
  (byte & 0x04 ? '1' : '0'), \
  (byte & 0x02 ? '1' : '0'), \
  (byte & 0x01 ? '1' : '0') 

char *names[] = {"BLACK","WHITE","RED","CYAN","PURPLE","GREEN","BLUE","YELLOW","ORANGE","BROWN","PINK","DARK_GREY","GREY","LIGHT_GREEN","LIGHT_BLUE","LIGHT_GREY"};

// Utility to make colors.bin and luma_rev4.bin
int main() {
   printf ("registers.v\n");
   for (int i=0;i<16;i++) {
      printf ("`%s:{red, green, blue} <= {6'h%02x, 6'h%02x, 6'h%02x};\n",
          names[i],colors[i*4], colors[i*4+1], colors[i*4+2]);
   }

   printf ("\n");
   printf ("colors.bin\n");
   for (int i=0;i<16;i++) {
       printf (BYTE_TO_BINARY6_PATTERN BYTE_TO_BINARY6_PATTERN BYTE_TO_BINARY6_PATTERN "000000\n",
          BYTE_TO_BINARY6(colors[i*4]),
          BYTE_TO_BINARY6(colors[i*4+1]),
          BYTE_TO_BINARY6(colors[i*4+2]));
   }

   printf ("\n");
   printf ("luma_rev4.bin\n");
   for (int i=0;i<16;i++) {
       printf (BYTE_TO_BINARY6_PATTERN BYTE_TO_BINARY8_PATTERN BYTE_TO_BINARY4_PATTERN "\n",
          BYTE_TO_BINARY6(luma_rev4[1][i]),
          BYTE_TO_BINARY8(phase[1][i]),
          BYTE_TO_BINARY4(amplitude[1][i]));
   }
}
