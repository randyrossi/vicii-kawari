#include <stdio.h>
#include <stdlib.h>

// Tool for converting Efinix multi.hex file into a
// .bit file
//
// Usage:
// multi_hex_to_bit multi.hex > bitstream.bit
// bitstream.bit is what flash making tool needs
int main(int argc, char* argv[]) {
   if (argc < 2) {
      printf ("Usage: multi_hex_to_bit multi.hex > bitstream.bit\n");
      exit(0);
   }

   FILE *fp = fopen(argv[1],"r");
   if (fp == NULL) {
      printf ("Can't open file\n");
      exit(-1);
   }
   int n1,n2;
   int c1,c2,c3;
   while (1) {
       c1 =fgetc(fp);
       if (c1 == -1) break;
       if (c1 >= 'A' && c1 <='F') n1=c1-'A'+10;
       if (c1 >= 'a' && c1 <='f') n1=c1-'a'+10;
       else if (c1 >= '0' && c1 <='9') n1=c1-'0';
       c2 =fgetc(fp);
       if (c2 == -1) break;
       if (c2 >= 'A' && c2 <='F') n2=c2-'A'+10;
       if (c2 >= 'a' && c2 <='f') n2=c2-'a'+10;
       else if (c2 >= '0' && c2 <='9') n2=c2-'0';
       c3 =fgetc(fp);
       if (c3 == -1) break;
       printf ("%c",n1*16+n2);
       if (c3 != '\n') { printf ("ERROR\n"); exit(0); }
   }
}
