#include <stdio.h>

// Helper to generate code for the 'old' chip luma levels
// for our init util.

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


// Using a real 6567R8 and 6569R3, we matched the voltage levels on an
// oscilloscope and came up with these DAC levels:

// NTSC
// 590	24
// 860	44
// 950	47
// 1030	50
// 1160	53
// 1210	54
// 1380	57
// 1560	60
// 1825	63

// PAL
// 700 08
// 1020 37
// 1090 42
// 1180 45
// 1300 50
// 1340 51
// 1480 55
// 1620 59
// 1850 63

// Using polynomial curve matching, on values except black to come
// up with curve for ntsc and pal.
// https://www.dcode.fr/function-equation-finder

// This is used to estimate the luma level values for NTSC R56A and PAL R1.
// I did not measure the voltage levels off those revisions.  Instead,
// I measured the R8 and R3 chips and used a curve match to the info
// above to 'guesstimate' what the DAC values ought to be.
int get_luma(double voltage)
{
   // NTSC curve (black excluded)
   double level = -0.0000171249d * voltage*voltage +
                          0.0637809d*voltage + 1.9825d;
   // PAL curve (black excluded)
   //double level = -0.0000222954d * voltage*voltage +
   //                       0.0942326d*voltage - 35.1443d;

   // Don't go below 1 for any color
   if (level < 1) level = 1;
   else if (level > 63) level = 63;
   return level;
}

void main(int argc, char* argv[]) {
   // Show DAC levels.  Use this to see how close the curves are
   // to what we measured for 'new' chips and use that as an indication
   // of how close we are (probably) for the old chips.
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
          printf ("%02x", get_luma(voltages[chip][col]));
          if (col < 15) printf (",");
      }
      printf ("},\n");
   }
}
