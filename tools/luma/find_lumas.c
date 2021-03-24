#include <stdio.h>

static  double rvalues[24*7];

// How many bits in our ladder. Max 6.
#define NUM_BITS 6
#define MAX_BITS 6
#define SUPPLY_VOLTAGE 4.6d

// Find another resistor value that is approximately double that of the
// given value.  Fuzz parameter of not 0 will return neighbors either up
// or down instead of the closest double we found (which would be fuzz == 0).
int findBestDoubleOf(double v, int fuzz){
   v=v*2;
   int found = 0;
   long mindist = 2147483648;
   for (int i=0;i<24*7; i++) {
      double dist = rvalues[i] - v;
      if (dist < 0) dist = -dist;
      if (dist < mindist) { mindist = dist; found = i; }
   }
   return found + fuzz;
}

// Do search for resistor values that will yield voltages as close as we
// can get to the target voltage values for luminances.
int main(int argc, char argv[])
{
   // Standard base values for resistors.
   double rbasevalues[24] = { 1.0, 1.1, 1.2, 1.3, 1.5, 1.6, 1.8, 2.0,
                              2.2, 2.4, 2.7, 3.0, 3.3, 3.6, 3.9, 4.3,
                              4.7, 5.1, 5.6, 6.2, 6.8, 7.5, 8.2, 9.1 };

   // Compute a table 24 * 7 with each colum getting an order of magnitude
   // larger from the base.
   int mag = 1; int destindex=0;
   for (int magexp = 0; magexp < 7; magexp++) {
      for (int srcindex = 0; srcindex < 24; srcindex++) {
         rvalues[destindex] = rbasevalues[srcindex] * mag;
         destindex++;
      }
      mag=mag*10;
   }

   // Compute the scale factor from luminance values measured from
   // the output jack as opposed to those measured off the chip.
/*
   double l[9];
   l[0] = 1380.0d / 590.0d; // 0 - black
   l[1] = 2100.0d / 860.0d; // 6,9
   l[2] = 2280.0d / 950.0d; // 2,11
   l[3] = 2460.0d / 1030.0d; // 4,8
   l[4] = 2760.0d / 1160.0d; // 12,14
   l[5] = 2860.0d / 1210.0d; // 5,10
   l[6] = 3240.0d / 1380.0d; // 3,15
   l[7] = 3660.0d / 1560.0d; // 7,13
   l[8] = 4280.0d / 1825.0d; // 1 - white

   double t = 0.0d;
   for (int i = 0; i < 9; i++) {
      printf ("%f\n", l[i]);
      t=t+l[i];
   }
   printf ("Avg %f\n", t/9.0d);
*/

   // These are the target voltages for our luminance values
   // These were measured off a 6567R9 chip.
   double v[9];
   v[0] = 1.380d;
   v[1] = 2.100d;
   v[2] = 2.280d;
   v[3] = 2.460d;
   v[4] = 2.760d;
   v[5] = 2.860d;
   v[6] = 3.240d;
   v[7] = 3.660d;
   v[8] = 4.280d;

   double besttotaldist = 1000000;
   int best4luma_final[9];
   double best4lumadist_final[9];
   double bestladdervalues_final[9];
   double finalrvalues[MAX_BITS];
   int finalrlvalue;

   // Try a range of RL from 2000 - 6000 in 100 ohm steps.
   for (int rl = 2000; rl <= 6000; rl+=100) {

   for (int rstartval = 24; rstartval < 128; rstartval++) {

   double r[MAX_BITS];
   r[5] = rvalues[rstartval];

   // Way too high for first resistor. Just bail.
   if (r[5] > 2000) continue;

   for (int fuzz4=-2;fuzz4<2;fuzz4++) {
   r[4] = rvalues[findBestDoubleOf(r[5], fuzz4)];
   for (int fuzz3=-2;fuzz3<2;fuzz3++) {
   r[3] = rvalues[findBestDoubleOf(r[4], fuzz3)];
   for (int fuzz2=-2;fuzz2<2;fuzz2++) {
   r[2] = rvalues[findBestDoubleOf(r[3], fuzz2)];
   for (int fuzz1=-2;fuzz1<2;fuzz1++) {
   r[1] = rvalues[findBestDoubleOf(r[2], fuzz1)];
   for (int fuzz0=-2;fuzz0<2;fuzz0++) {
   r[0] = rvalues[findBestDoubleOf(r[1], fuzz0)];

   // Show resistor values
   //printf ("RL=%d ",rl);
   //for (int ri=0;ri<NUM_BITS;ri++) {
   //  printf ("%f ",r[ri]);
   //}
   //printf ("\n");

   double laddervalues[64];
   for (int p=0;p<64;p++) {
      double sum = 0;
      int b = 1;
      for (int s=0;s<NUM_BITS;s++) { 
         if (p & b) sum=sum+1.0d/r[s];
         b=b*2;
      }
      double totalr = 1.0d/sum;
      double v = SUPPLY_VOLTAGE * (rl)/(totalr+rl);
      laddervalues[p] = v;
      //printf ("%f\n",v);
   }

   double totaldist = 0;
   int best4luma[9];
   double best4lumadist[9];
   for (int p=0;p<9;p++) {
       double mindist = 10000000;
       for (int q =0;q<64;q++) {
          double dist = v[p] - laddervalues[q];
          if (dist < 0 ) dist = -dist;
          if (dist < mindist) {
              mindist = dist; best4lumadist[p] = dist; best4luma[p] = q;
          }
       }
       totaldist=totaldist+mindist;
   }

   // Print out the best decimal values we found for each luma voltage
   //for (int p=0;p<9;p++) {
   //   printf ("BESTVALUE4LUMA %d = %d (dist=%f, desired=%f, actual=%f)\n",
   //       p, best4luma[p], best4lumadist[p], v[p], laddervalues[best4luma[p]]);
   //}

   if (totaldist < besttotaldist) {
       besttotaldist = totaldist;
       // Overwrite latest best results
       for (int p=0;p<9;p++) {
          best4luma_final[p] = best4luma[p];
          best4lumadist_final[p] = best4lumadist[p];
          bestladdervalues_final[p] = laddervalues[best4luma[p]];
       }
       for (int ri=0;ri<NUM_BITS;ri++) {
          finalrvalues[ri] = r[ri];
       }
       finalrlvalue = rl;
   }

   //printf ("TOTALDIST = %f \n",totaldist);

   } // fuzz0
   } // fuzz1
   } // fuzz2
   } // fuzz3
   } // fuzz4

   } // start
   } // rl

   printf ("BEST WAS = %f \n",besttotaldist);

   // Show resistor values
   printf ("RL=%d ",finalrlvalue);
   for (int ri=0;ri<NUM_BITS;ri++) {
     printf ("%f ",finalrvalues[ri]);
   }
   printf ("\n");

   for (int p=0;p<9;p++) {
      printf ("BESTVALUE4LUMA %d = %d (dist=%f, desired=%f, actual=%f)\n",
          p, best4luma_final[p], best4lumadist_final[p], v[p], 
             bestladdervalues_final[p]);
   }

   return 0;
}
