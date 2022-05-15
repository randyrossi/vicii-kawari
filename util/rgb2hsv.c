#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>

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
   if (argc < 1) {
      printf ("Usage: rgb2hsv <rgb.bin.file> > hsv.bin.file\n");
      exit(0);
   }
   if (argc > 2) {
      if (strcmp(argv[2],"-h") == 0) outputFormat=HEX;
      if (strcmp(argv[2],"-b") == 0) outputFormat=BINARY;
   }

   FILE *fp = fopen(argv[1],"r");
   if (fp == NULL) {
      printf ("Can't open file\n");
      exit(-1);
   }

   int p[16];
   int a[16];
   int l[16];
   for (int col=0;col<16;col++) {
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
   int min_luma = 64;
   int max_luma = 0;
   for (int col=0;col<16;col++) {
      if (l[col] < min_luma) min_luma = l[col];
      if (l[col] > max_luma) max_luma = l[col];
   }
   //printf ("min luma %d\n", min_luma);
   //printf ("max luma %d\n", max_luma);

   int min_dist = 12 - min_luma;
   int max_dist = 63 - max_luma;
   //printf ("min_dist %d\n",min_dist);
   //printf ("max_dist %d\n",max_dist);

   double slope = (double)(max_dist - min_dist) / (double)(63-12+1);
   //printf ("slope %f\n",slope);
   
   if (min_dist > 0) { 
     for (int col = 0; col < 16; col++) {
      //printf("%d -> ", l[col]);
      l[col] = l[col] + ceil(min_dist - slope*(l[col]-12));
      if(l[col] > 63) l[col]=63;
      //printf("%d\n", l[col]);
     }
   }
   

   if (outputFormat == HEX) {
     for (int col=0;col<16;col++) {
        printf ("0x%02x,", l[col]);
        printf ("0x%02x,", p[col]);
        printf ("0x%02x,\n", a[col]);
      }
   } else if (outputFormat == BINARY) {
     for (int col=0;col<16;col++) {
        printf (BYTE_TO_BINARY6_PATTERN, BYTE_TO_BINARY6(l[col]));
        printf (BYTE_TO_BINARY8_PATTERN, BYTE_TO_BINARY8(p[col]));
        printf (BYTE_TO_BINARY4_PATTERN, BYTE_TO_BINARY4(a[col]));
        printf ("\n");
      }
   } else if (outputFormat == BIN) {
     for (int col=0;col<16;col++) {
        printf ("%c", l[col]);
     }
     for (int col=0;col<16;col++) {
        printf ("%c", p[col]);
     }
     for (int col=0;col<16;col++) {
        printf ("%c", a[col]);
     }
   }
      
   fclose(fp);
}
