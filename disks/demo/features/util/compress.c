#include <stdio.h>
#include <stdlib.h>

// Compress a kawari raw hires .bin file
// Simple compression algo that counts repeats or
// non-repeated sections.  Only good for images with
// lots of blank space.
void main(int argc, char *argv[]) {
   FILE *fp = fopen(argv[1],"r");

   int buf[256];

   if (fp == NULL) return;

   int c;
   int prevc = -1;
   int count = 0;
   int same_val;
   int same_count = 0;
   int flush = 0;
   int streak = 0;

   while (1) {
      c = fgetc(fp);
      //printf ("read %d\n",c);
      if (c < 0) break;

      if (c == prevc) {
          if (count > 0) {
               printf ("%c",count|128);
               for (int q=0;q<count;q++)
                   printf ("%c",buf[q]);
               count = 0;
          }
          same_count++;
          same_val = c;
          if (same_count == 127) {
               printf ("%c",same_count);
               printf ("%c",same_val);
               same_count = 0;
          }
      } else {
          if (same_count > 0) {
               printf ("%c",same_count);
               printf ("%c",same_val);
               same_count = 0;
          }
          buf[count] = c;
          count++;
          if (count == 127) {
               printf ("%c",count|128);
               for (int q=0;q<count;q++)
                   printf ("%c",buf[q]);
               count = 0;
          }
      }

      prevc = c;
   }
   printf ("%c",0);
}
