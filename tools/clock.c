int main() {
   double c = 25.000000;
   //double t = 17.734475;
   double t = 14.318181;
   double min = 1000;
   double minm;
   double mind;
   double minc;

   for (double m = 10; m < 100; m+= .125) {
      for (double d = 10; d < 100; d+= .125) {
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
