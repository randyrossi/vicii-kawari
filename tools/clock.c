int main() {
   double c = 50.000000;
   double t = 31.527955;
   double min = 1000;
   double minm;
   double mind;
   double minc;

   //double step = .125;  // for Spartan7
   double step = 1;  // for Spartan6

   t = 31.527955;
   min = 1000;
   for (double m = 1; m <= 64; m+= step) {
      for (double d = 1; d <= 52; d+= step) {
	      if (d == m) continue;
	      double r = c * m / d;
	      //printf ("%f\n", r);
	      double dist = t - r;
	      if (dist < 0) dist = -dist;
	      if (dist < min) {
		      min = dist; minm = m; mind = d; minc = r;
	      }
      }
   }

   printf ("WANT %f MIN %f MULT %f DIV %f GET %f\n", t, min, minm, mind, minc);

   t = 32.727272;
   min = 1000;
   for (double m = 1; m <= 64; m+= step) {
      for (double d = 1; d <=  52; d+= step) {
	      if (d == m) continue;
	      double r = c * m / d;
	      //printf ("%f\n", r);
	      double dist = t - r;
	      if (dist < 0) dist = -dist;
	      if (dist < min) {
		      min = dist; minm = m; mind = d; minc = r;
	      }
      }
   }

   printf ("WANT %f MIN %f MULT %f DIV %f GET %f\n", t, min, minm, mind, minc);
}

// 31.527955
// 32.727272
