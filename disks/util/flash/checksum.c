#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>

// Utility to run on a i### file directly from Linux to
// compute it's checksum.  Use to verify checksum computed
// by flash utility matches.

int main(int argc, char* argv[]) {
   FILE *fpin = fopen(argv[1],"rb");
   if (fpin == NULL) {
      printf ("Can't open input file\n");
      exit(-1);
   }

   int i;
   char c;
   uint32_t *v;
   char sc[4];
   sc[0] = 0;
   sc[1] = 0;
   sc[2] = 0;
   sc[3] = 0;
   while (1) {
       i = fgetc(fpin);
       if (i < 0) break;
       sc[0] ^= (char)i;
 
       i = fgetc(fpin);
       if (i < 0) goto alignment;
       sc[1] ^= (char)i;

       i = fgetc(fpin);
       if (i < 0) goto alignment;
       sc[2] ^= (char)i;

       i = fgetc(fpin);
       if (i < 0) goto alignment;
       sc[3] ^= (char)i;
   }
   v = (uint32_t*)&sc[0];

   fclose(fpin);
   printf ("%c%c%c%c", sc[0], sc[1], sc[2], sc[3]);
   fflush(stdout);

   return 0;

alignment:
   fclose(fpin);
   printf ("ERROR: Size must be multiple of 4 bytes\n");
   return -1;
}
