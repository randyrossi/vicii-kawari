#include <stdio.h>
#include <stdlib.h>

// A utility program to find equivalent vertical and horizontal
// refresh rates across different resolutions for C64
// video modes.
#define CHIP_6567R8 0
#define CHIP_6567R56A 1
#define CHIP_6569 2

void search(int chip);

void main()
{
    search(CHIP_6567R8);
    search(CHIP_6567R56A);
    search(CHIP_6569);
}

void search(int chip) {

    double color;
    double M;
    int divisor;
    int y,w;

    if (chip == CHIP_6569) {
        color = 17.7344750;
        divisor = 18;
        w = 504;
        y = 312;
        printf ("CHIP: 6569\n");
    } else {
        color = 14.3181818;
        divisor = 14;
        if (chip == CHIP_6567R8) {
           w = 520;
           y = 263;
           printf ("CHIP: 6567R8\n");
        } else {
           w = 512;
           y = 262;
           printf ("CHIP: 6567R56A\n");
        }
    }

    M = color*1000000;

    double target =1/((w*2)*(y*2)/(color/divisor*32000000));
    double h = ((M/divisor*8)/w);

    printf ("Target %f\n",target);
    printf ("H=%f\n",h);

    for (double c=1; c<= 32;c++) {
       for (int x=1; x<= w*2;x++) {
          double d =1/(x*(y*2)/(color/divisor*c*1000000));
          double l = d-target;
          double mhz = (color/divisor*c)/4;
          double h = (mhz*1000000*2)/x;
          if (l>=0 && l<=0.0001)  {
           printf ("%d x %d @ %f MULTIPLIER (dist=%f) %f MHZ (dot=%f h=%f)\n",
              x,y,c, l, (color/divisor*c), mhz, h);
          }
       }
    }
    printf ("\n\n");
}
