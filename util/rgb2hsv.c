#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

#define DEBUG

#define max(a,b) \
   ({ __typeof__ (a) _a = (a); \
       __typeof__ (b) _b = (b); \
     _a > _b ? _a : _b; })

#define min(a,b) \
   ({ __typeof__ (a) _a = (a); \
       __typeof__ (b) _b = (b); \
     _a < _b ? _a : _b; })

#define BINARY 0
#define HEX 1
#define BIN 2


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

void rgb_to_hsv(double r, double g, double b, int *phase, int *amp, int *luma) {
        // R, G, B values are divided by 255
        // to change the range from 0..255 to 0..1
        r = r / 63.0;
        g = g / 63.0;
        b = b / 63.0;
 
        // h, s, v = hue, saturation, value
        double cmax = max(r, max(g, b)); // maximum of r, g, b
        double cmin = min(r, min(g, b)); // minimum of r, g, b
        double diff = cmax - cmin; // diff of cmax and cmin.
        double h = -1, s = -1;
         
        // if cmax and cmax are equal then h = 0
        if (cmax == cmin)
            h = 0;
 
        // if cmax equal r then compute h
        else if (cmax == r)
            h = (int)((60 * ((g - b) / diff) + 360)) % 360;
 
        // if cmax equal g then compute h
        else if (cmax == g)
            h = (int)((60 * ((b - r) / diff) + 120)) % 360;
 
        // if cmax equal b then compute h
        else
            h = (int)((60 * ((r - g) / diff) + 240)) % 360;
 
        // if cmax equal zero
        if (cmax == 0)
            s = 0;
        else
            s = (diff / cmax) * 100;
 
        // compute v
        double v = cmax * 100;

        h=(int)(h+112.5d) % 360;

        *phase = h * (256.0d/359.0d);
        *amp = s*(15.0d/100.0d);
        *luma = v*(63.0d/100.0d);
        if (*amp == 0) *phase = 0;
        //if (*luma < 12) *luma = 12;
        //if (*luma > 63) *luma = 63;
        //printf("%f  %f %f %f\n", h,  h*(255.0d/359.0d), s*(15.0d/100.0d), v*(63.0d/100.0d));
}

int main(int argc, char *argv[]) {
   int outputFormat = BIN;

   // Expect bin file with bytes RGBX
   if (argc < 4) {
      printf ("Usage: rgb2hsv <rgb.bin.file> <num_colors> <min_luma> <out.bin>\n");
      exit(0);
   }
   
   FILE *fp = fopen(argv[1],"r");
   if (fp == NULL) {
      printf ("Can't open file\n");
      exit(-1);
   }

   int num_colors = atoi(argv[2]);
   if (num_colors != 4 && num_colors != 16)
   {
      printf ("Bad num colors\n");
      exit(-1);
   }

   int min_luma = atoi(argv[3]);
   if (min_luma < 0) min_luma = 0;
   if (min_luma > 63) min_luma = 63;

   FILE *fp2 = fopen(argv[4],"w");
   if (fp2 == NULL) {
      printf ("Can't open output file\n");
      exit(-1);
   }

   int p[16];
   int a[16];
   int l[16];
   for (int col=0;col<num_colors;col++) {
      unsigned int r = fgetc(fp);
      //r = r * 255 / 63; // scale up to 0-255
      unsigned int g = fgetc(fp);
      //g = g * 255 / 63; // scale up to 0-255
      unsigned int b = fgetc(fp);
      //b = b * 255 / 63; // scale up to 0-255
      fgetc(fp); // ignore
      
      rgb_to_hsv(r, g, b, &p[col], &a[col], &l[col]);

      // clamp luma
      if (l[col] > 63) l[col] = 63;
   }

   // Adjust luma
   int minl = 64;
   int maxl = 0;
   for (int col=0;col<num_colors;col++) {
      if (l[col] < minl) minl = l[col];
      if (l[col] > maxl) maxl = l[col];
   }
#ifdef DEBUG
   printf ("min luma %d\n", minl);
   printf ("max luma %d\n", maxl);
#endif

   int min_dist = min_luma - minl;
#ifdef DEBUG
   printf ("min_dist %d\n",min_dist);
#endif

   double slope = (double)(-min_dist) / (double)(maxl-minl);
#ifdef DEBUG
   printf ("slope %f\n",slope);
#endif
   
   if (min_dist > 0) { 
     for (int col = 0; col < num_colors; col++) {
#ifdef DEBUG
      printf("%d %f-> ", l[col], slope*(l[col]-minl));
#endif
      l[col] = l[col] + ceil(min_dist + slope*(l[col]-minl));
      if(l[col] > 63) l[col]=63;
#ifdef DEBUG
      printf("%d\n", l[col]);
#endif
     }
   }
   

   if (outputFormat == HEX) {
     for (int col=0;col<16;col++) {
        fprintf (fp2,"0x%02x,", l[col]);
        fprintf (fp2,"0x%02x,", p[col]);
        fprintf (fp2,"0x%02x,\n", a[col]);
      }
   } else if (outputFormat == BINARY) {
     for (int col=0;col<16;col++) {
        fprintf (fp2,BYTE_TO_BINARY6_PATTERN, BYTE_TO_BINARY6(l[col]));
        fprintf (fp2,BYTE_TO_BINARY8_PATTERN, BYTE_TO_BINARY8(p[col]));
        fprintf (fp2,BYTE_TO_BINARY4_PATTERN, BYTE_TO_BINARY4(a[col]));
        fprintf (fp2,"\n");
      }
   } else if (outputFormat == BIN) {
     for (int col=0;col<16;col++) {
        fprintf (fp2,"%c", l[col]);
     }
     for (int col=0;col<16;col++) {
        fprintf (fp2,"%c", p[col]);
     }
     for (int col=0;col<16;col++) {
        fprintf (fp2,"%c", a[col]);
     }
   }
      
   fclose(fp);
   fclose(fp2);
}
