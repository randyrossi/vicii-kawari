#include <stdio.h>

// This is a tool to take known angles from YUV color space
// and output the equivalent angles in YIQ color space.  The
// angles are taken from the mirrored YUV space (before rotation)
// using the 'yuv_mirrored.png' image. Then those are rotated by
// 33 degrees and scaled to 0:255 for our phase table.
int main(int argc, char argv[])
{
   // YIQ is YUV mirrored along -U,-V -> U,V axis.
   // Then rotated by 33 degrees.
   int rot = -33;

   // Using mirrored YUV diagram, set the transposed YUV angles.
   // NOTE: Angle 0 starts at the SOUTH line and moves clockwise.
   // whereas on YUV, it starts at EAST line and moves counter-clockwise.
   double blue = 180;
   double light_blue = 180;
   double cyan = 90+22.5;
   double green = 45;
   double light_green = 45;
   double yellow = 0;
   double brown = 360-22.5;
   double orange = 360-45;
   double red = 270+22.5;
   double light_red = 270+22.5;
   double purple = 180+45;

   // Now rotate 33 degrees
   double rot_blue = blue + rot;
   double rot_light_blue = light_blue + rot;
   double rot_cyan = cyan + rot;
   double rot_green = green + rot;
   double rot_light_green = light_green + rot;
   double rot_yellow = yellow + rot;
   double rot_brown = brown + rot;
   double rot_orange = orange + rot;
   double rot_red = red + rot;
   double rot_light_red = light_red + rot;
   double rot_purple = purple + rot;

   if (rot_blue < 0) rot_blue += 360;
   if (rot_light_blue < 0) rot_light_blue += 360;
   if (rot_cyan < 0) rot_cyan += 360;
   if (rot_green < 0) rot_green += 360;
   if (rot_light_green < 0) rot_light_green += 360;
   if (rot_yellow < 0) rot_yellow += 360;
   if (rot_brown < 0) rot_brown += 360;
   if (rot_orange < 0) rot_orange += 360;
   if (rot_red < 0) rot_red += 360;
   if (rot_light_red < 0) rot_light_red += 360;
   if (rot_purple < 0) rot_purple += 360;

   // Now convert to 0 - 255
   printf ("    `BLACK:       phase = 8'd%d;  // unmodulated\n", 0);
   printf ("    `WHITE:       phase = 8'd%d;  // unmodulated\n", 0);
   printf ("    `RED:         phase = 8'd%d;\n", (int)((rot_red/360.0d)*256.0d));
   printf ("    `CYAN:        phase = 8'd%d;\n", (int)((rot_cyan/360.0d)*256.0d));
   printf ("    `PURPLE:      phase = 8'd%d;\n", (int)((rot_purple/360.0d)*256.0d));
   printf ("    `GREEN:       phase = 8'd%d;\n", (int)((rot_green/360.0d)*256.0d));
   printf ("    `BLUE:        phase = 8'd%d;\n", (int)((rot_blue/360.0d)*256.0d));
   printf ("    `YELLOW:      phase = 8'd%d;\n", (int)((rot_yellow/360.0d)*256.0d));
   printf ("    `ORANGE:      phase = 8'd%d;\n", (int)((rot_orange/360.0d)*256.0d));
   printf ("    `BROWN:       phase = 8'd%d;\n", (int)((rot_brown/360.0d)*256.0d));
   printf ("    `PINK:        phase = 8'd%d;\n", (int)((rot_light_red/360.0d)*256.0d));
   printf ("    `DARK_GREY:   phase = 8'd%d;  // unmodulated\n", 0);
   printf ("    `GREY:        phase = 8'd%d;  // unmodulated\n", 0);
   printf ("    `LIGHT_GREEN: phase = 8'd%d;\n", (int)((rot_light_green/360.0d)*256.0d));
   printf ("    `LIGHT_BLUE:  phase = 8'd%d;\n", (int)((rot_light_blue/360.0d)*256.0d));
   printf ("    `LIGHT_GREY:  phase = 8'd%d;  // unmodulated\n", 0);
}
