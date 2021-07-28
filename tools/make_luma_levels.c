#include <stdio.h>

// Generate code for luma levels for our config util

// From "Commodore 6567/6569 video chip luminance levels" by
// Marko Makela, we have luminance levels for the four chips.
// These are in millivolts. 
int voltages[4][16] = {
   // 6567R8 - 9 levels
   { 590, 1825, 950, 1380, 1030, 1210, 860, 1560, 1030, 860, 1210, 950, 1160, 1560, 1160, 1380 },
   // 6569R3 - 9 levels
   { 700, 1850, 1090, 1480, 1180, 1340, 1020, 1620, 1180, 1020, 1340, 1090, 1300, 1620, 1300, 1480 },
   // 6567R56A - 5 levels
   { 560, 1825, 840, 1500, 1180, 1180, 840, 1500, 1180, 840, 1180, 840, 1180, 1500, 1180, 1500 },
   // 6569R1 - 5 levels
   { 630, 1850, 900, 1560, 1260, 1260, 900, 1560, 1260, 900, 1260, 900, 1260, 1560, 1260, 1560 },
};

// https://www.dcode.fr/function-equation-finder
// Using a real 6567R8, we matched the voltage levels on an
// oscilloscope and came up with these DAC levels:
// Measured: 12 14 19 22 28 30 36 43 58
// Adjusted: 12 20 25 28 34 36 42 49 64
// 
int get_luma(double voltage)
{
   // Curve matching
   //double level = .0000154881d * voltage*voltage +
   //                     .00103625d*voltage+4.62243;
   double level = .0000067367333d * voltage*voltage +
                          .0254356d*voltage - 5.54123d;
   // Don't go below 12 for any color
   if (level < 12) level = 12;
   return level;
}

void main(int argc, char* argv[]) {
   for (int chip=0;chip<4;chip++) {
      printf ("\n");
      if (chip==0)
         printf ("    // 6567R8   - 9 levels\n    {");
      else if (chip==1)
         printf ("    // 6569R3   - 9 levels\n    {");
      else if (chip==2)
         printf ("    // 6567R56A - 5 levels\n    {");
      else if (chip==3)
         printf ("    // 6569R1   - 5 levels\n    {");
      for (int col=0;col<16;col++) {
          printf ("%d", get_luma(voltages[chip][col]));
          if (col < 15) printf (",");
      }
      printf ("},\n");
   }
}
