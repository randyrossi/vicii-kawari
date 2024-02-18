#include <stdio.h>
#include <strings.h>

const int NUM_CC = 28;
const int NUM_DC = 16;

#define POS_EDGE(n) (n+1)
#define NEG_EDGE(n) (n)

void show_wave(int num, int *wave) {
   for (int i=0;i<num*2;i++) {
      if (wave[i%num]) printf ("‾");
      else printf ("_");
   }
   printf ("\n\n\n\n\n");
}

int main(int argc, char *argv[]) {
   int num_cc_points = NUM_CC * 2;
   int num_dc_points = NUM_DC * 2;

   int num_wave_points = num_cc_points * num_dc_points;
 

   int ras_wave[num_wave_points];
   int cas_wave[num_wave_points];

   int ras_wave_dc_p[num_wave_points];
   int cas_wave_dc_p[num_wave_points];

   int ras_wave_dc_n[num_wave_points];
   int cas_wave_dc_n[num_wave_points];

   int ras_wave_cc_p[num_wave_points];
   int cas_wave_cc_p[num_wave_points];
   int ras_wave_cc_n[num_wave_points];
   int cas_wave_cc_n[num_wave_points];

   int clk_phi[num_wave_points];
   int clk_cc[num_wave_points];
   int clk_dc[num_wave_points];

   int n = sizeof(cas_wave);
   bzero (cas_wave, n);
   bzero (ras_wave, n);

   bzero (ras_wave_dc_p, n);
   bzero (cas_wave_dc_p, n);
   bzero (ras_wave_dc_n, n);
   bzero (cas_wave_dc_n, n);

   bzero (ras_wave_cc_p, n);
   bzero (cas_wave_cc_p, n);
   bzero (ras_wave_cc_n, n);
   bzero (cas_wave_cc_n, n);

   bzero (clk_phi, n);
   bzero (clk_cc, n);
   bzero (clk_dc, n);

   // For tests, +1 due to signal becoming valid at next tick

   int ras_rise_dc_p = 1+1;
   int ras_fall_dc_p = 4+1;

   int cas_rise_dc_p = 0+1;
   int cas_fall_dc_p = 6+1;

   int ras_rise_dc_n = 0; // does not exist in cur impl
   int ras_fall_dc_n = 0; // does not exist in cur impl

   int cas_rise_dc_n = 1;
   int cas_fall_dc_n = 7;

   int ras_rise_cc_p = 1+1;
   int ras_fall_cc_p = 4+1;

   int ras_rise_cc_n = 0; // does not exist in this impl
   int ras_fall_cc_n = 0; // does not exist in this impl

   int cas_rise_cc_p = 0+1; // does not exist in cur impl
   int cas_fall_cc_p = 0+1; // does not exist in cur impl

   int cas_rise_cc_n = 0; // does not exist in cur impl
   int cas_fall_cc_n = 0; // does not exist in cur impl


   // Current values of each signal
   int cur_ras_dc_p = 0;
   int cur_cas_dc_p = 0;

   int cur_ras_dc_n = 0;
   int cur_cas_dc_n = 0;

   int cur_ras_cc_p = 0;
   int cur_ras_cc_n = 0;
   int cur_cas_cc_p = 0;
   int cur_cas_cc_n = 0;

   int cur_phi = 0;
   int cur_cc = 0;
   int cur_dc = 0;

   for (int i=0;i<num_wave_points;i++) {

      int cc_tick = i / (num_dc_points * 2);
      int dc_tick = i / (num_cc_points * 2);

      int pos_cc = 0;
      int neg_cc = 0;

      if (i % num_dc_points == 0) {
         // CC tick
         if ((i / num_dc_points % 2) == 0) {
            // POS EDGE
            pos_cc = 1;
         } else {
            // NEG EDGE
            neg_cc = 1;
         }
      }

      int pos_dc = 0;
      int neg_dc = 0;

      if (i % num_cc_points == 0) {
         // CC tick
         if ((i / num_cc_points % 2) == 0) {
            // POS EDGE
            pos_dc = 1;
         } else {
            // NEG EDGE
            neg_dc = 1;
         }
      }

      if (pos_cc) cur_cc = 1;
      if (neg_cc) cur_cc = 0;

      if (pos_dc) cur_dc = 1;
      if (neg_dc) cur_dc = 0;

      if (pos_dc && dc_tick==0) cur_phi = 1;
      if (pos_dc && dc_tick==8) cur_phi = 0;

      if (pos_dc && dc_tick==ras_rise_dc_p) cur_ras_dc_p = 1;
      if (pos_dc && dc_tick==ras_fall_dc_p) cur_ras_dc_p = 0;
      if (pos_dc && dc_tick==cas_rise_dc_p) cur_cas_dc_p = 1;
      if (pos_dc && dc_tick==cas_fall_dc_p) cur_cas_dc_p = 0;

      //if (neg_dc && dc_tick==ras_rise_dc_n) cur_ras_dc_n = 1;
      //if (neg_dc && dc_tick==ras_fall_dc_n) cur_ras_dc_n = 0;
      if (neg_dc && dc_tick==cas_rise_dc_n) cur_cas_dc_n = 1;
      if (neg_dc && dc_tick==cas_fall_dc_n) cur_cas_dc_n = 0;

      if (pos_cc && cc_tick==ras_rise_cc_p) cur_ras_cc_p = 1;
      if (pos_cc && cc_tick==ras_fall_cc_p) cur_ras_cc_p = 0;
      //if (pos_cc && cc_tick==cas_rise_cc_p) cur_cas_cc_p = 1;
      //if (pos_cc && cc_tick==cas_fall_cc_p) cur_cas_cc_p = 0;
 
      //if (neg_cc && cc_tick==ras_rise_cc_n) cur_ras_cc_n = 1;
      //if (neg_cc && cc_tick==ras_fall_cc_n) cur_ras_cc_n = 0;
      //if (neg_cc && cc_tick==cas_rise_cc_n) cur_cas_cc_n = 1;
      //if (neg_cc && cc_tick==cas_fall_cc_n) cur_cas_cc_n = 0;

      clk_cc[i] = cur_cc;
      clk_dc[i] = cur_dc;
      clk_phi[i] = cur_phi;

      ras_wave_dc_p[i] = cur_ras_dc_p;      
      cas_wave_dc_p[i] = cur_cas_dc_p;      

      ras_wave_dc_n[i] = cur_ras_dc_n;      
      cas_wave_dc_n[i] = cur_cas_dc_n;      

      ras_wave_cc_p[i] = cur_ras_cc_p;      
      ras_wave_cc_n[i] = cur_ras_cc_n;      

      cas_wave_cc_p[i] = cur_cas_cc_p;      
      cas_wave_cc_n[i] = cur_cas_cc_n;      

      // assign cas = chip[0] ? (pal_cas_d4x_p | pal_cas_d4x_n | pal_cas_c16x_p) : (ntsc_cas_d4x_p | ntsc_cas_d4x_n | ntsc_cas_c16x_p);
      // assign ras = chip[0] ? (pal_ras_d4x | pal_ras_c16x_n) : (ntsc_ras_d4x | ntsc_ras_c16x_n);

      cas_wave[i] = cas_wave_dc_p[i] | cas_wave_dc_n[i];
      ras_wave[i] = ras_wave_dc_p[i] | ras_wave_cc_p[i];
   }

   printf ("$version Generated by VerilatedVcd $end\n");
   printf ("$date Wed Feb 14 22:15:28 2024\n");
   printf (" $end\n");
   printf ("$timescale   1ns $end\n");
   printf ("\n");
   printf (" $scope module TOP $end\n");
   printf ("  $var wire  1 a clk_cc $end\n");
   printf ("  $var wire  1 b clk_dc $end\n");
   printf ("  $var wire  1 c clk_phi $end\n");
   printf ("  $var wire  1 A ras_cc_p $end\n");
   printf ("  $var wire  1 B ras_cc_n $end\n");
   printf ("  $var wire  1 C cas_cc_p $end\n");
   printf ("  $var wire  1 D cas_cc_n $end\n");
   printf ("  $var wire  1 G ras_dc_p $end\n");
   printf ("  $var wire  1 H cas_dc_p $end\n");
   printf ("  $var wire  1 I ras_dc_n $end\n");
   printf ("  $var wire  1 J cas_dc_n $end\n");
   printf ("  $var wire  1 E cas $end\n");
   printf ("  $var wire  1 F ras $end\n");
   printf (" $upscope $end\n");
   printf ("$enddefinitions $end\n");
   printf ("\n");
   printf ("\n");

   int tick=0;
   for (int j=0;j<10;j++) {
   for (int i=0;i<num_wave_points;i++) {
      printf ("#%d\n",tick);
      printf ("%dc\n",clk_phi[i]);
      printf ("%da\n",clk_cc[i]);
      printf ("%db\n",clk_dc[i]);
      printf ("%dA\n",ras_wave_cc_p[i]);
      printf ("%dB\n",ras_wave_cc_n[i]);
      printf ("%dC\n",cas_wave_cc_p[i]);
      printf ("%dD\n",cas_wave_cc_n[i]);
      printf ("%dE\n",cas_wave[i]);
      printf ("%dF\n",ras_wave[i]);
      printf ("%dG\n",ras_wave_dc_p[i]);
      printf ("%dH\n",cas_wave_dc_p[i]);
      printf ("%dI\n",ras_wave_dc_n[i]);
      printf ("%dJ\n",cas_wave_dc_n[i]);
      tick++;
   }
   }

}
