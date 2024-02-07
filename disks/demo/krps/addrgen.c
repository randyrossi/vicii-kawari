
// Small c program to generate the hi/lo address table
// for rgb or hsv color palette lookups.
main()
{
   int addr;

   int inc = 64;
   int startl = 51;
   int endl = 250;

   // Uncomment this for HSV version
   //inc = 48;

   printf ("table_lo:");
   for (int i=0;i<255;i++) {
      if (i >=startl && i <=endl) {
         addr = (i-startl)*inc + 0x8000;
      } else {
         addr = 0x8000;
      }
      printf ("    !BYTE $%02x\n",addr&0xff);
   }
   printf ("table_hi:");
   for (int i=0;i<255;i++) {
      if (i >=startl && i <=endl) {
         addr = (i-startl)*inc + 0x8000;
      } else {
         addr = 0x8000;
      }
      printf ("    !BYTE $%02x\n", addr>>8);
   }
}
