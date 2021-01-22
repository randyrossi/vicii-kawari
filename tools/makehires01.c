#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char *argv[]) {
   FILE* fp = fopen("chargen","r");

   unsigned char* d = (unsigned char*) malloc(4096);
   fread(d,1,4096,fp);
   fclose(fp);

   // First put character rom at 0x0000 (16k)
   int i=0;
   int ch=0;
   int sch=-80;
   for (int y=0;y<200;y++) {
     ch=sch;
     if (y % 8 == 0) {
         sch+=80; if (sch >= 512) sch=sch-512;
         ch=sch;
     }
     for (int x=0;x<80;x++) {
       printf ("%02x ",d[ch*8+y%8]);
       i++; ch++; if (ch >= 512) ch=0;
       if (i % 8 == 0) printf ("\n");
     }
   }

   // Fill in remaining 384 with 0's
   for (int fill=0;fill<384;fill++) {
       printf ("%02x ",1); i++;
       if (i % 8 == 0) printf ("\n");
   }


   // Now put 2k colors for the screen at 0x8000
   for (int row=0;row<25;row++) {
	   for (int col=0;col<80;col++) {
                  printf ("%02x ",(row*col)%16); i++;
                  if (i % 8 == 0) printf ("\n");
	   }
   }

   // Fill in remaining 48 with 0's
   for (int fill=0;fill<48;fill++) {
       printf ("%02x ",1); i++;
       if (i % 8 == 0) printf ("\n");
   }

   // Remaining 14k with 0
   for (int fill=0;fill<14*1024;fill++) {
       printf ("%02x ",0); i++;
       if (i % 8 == 0) printf ("\n");
   }

}
