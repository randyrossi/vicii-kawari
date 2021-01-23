#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int main(int argc, char *argv[]) {
   FILE* fp = fopen("chargen","r");

   unsigned char* d = (unsigned char*) malloc(4096);
   fread(d,1,4096,fp);
   fclose(fp);

   // First put character rom at 0x0000 (4k)
   int i=0;
   for (int j=0;j<4096;j++) {
       printf ("%02x ",d[j]); i++;
       if (i % 8 == 0) printf ("\n");
   }

   // Now put 2k colors for the screen at 0x1000
   for (int row=0;row<25;row++) {
	   for (int col=0;col<80;col++) {
                  printf ("%02x ",row%16); i++;
                  if (i % 8 == 0) printf ("\n");
	   }
   }

   // Fill in remaining 48 with 0's
   for (int fill=0;fill<48;fill++) {
       printf ("%02x ",0); i++;
       if (i % 8 == 0) printf ("\n");
   }

   // Let's put in some text in the next 2k 
   char msg[] = "abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzab";
   if (strlen(msg) != 80) { printf ("ERROR\n"); exit(0); }
   for (int row=0;row<25;row++) {
	   for (int col=0;col<80;col++) {
		   unsigned int v;
		   if (msg[col] >='a' && msg[col] <= 'z')
			   v = msg[col]-'a'+1;
		   else if (msg[col] == ' ')
			   v = 0x20;
                  printf ("%02x ",v); i++;
                  if (i % 8 == 0) printf ("\n");
	   }
   }
   for (int fill=0;fill<48;fill++) {
       printf ("%02x ",0); i++;
       if (i % 8 == 0) printf ("\n");
   }

   // Remaining 24k with 0
   for (int fill=0;fill<24*1024;fill++) {
       printf ("%02x ",0); i++;
       if (i % 8 == 0) printf ("\n");
   }

}
