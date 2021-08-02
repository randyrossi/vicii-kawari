
#include <stdio.h>
#include <math.h>

#define BINARY 0
#define DECIMAL 1
#define CHARS 2
#define CODE 3
#define HEX 4

#define max(a,b) \
   ({ __typeof__ (a) _a = (a); \
       __typeof__ (b) _b = (b); \
     _a > _b ? _a : _b; })

#define min(a,b) \
   ({ __typeof__ (a) _a = (a); \
       __typeof__ (b) _b = (b); \
     _a < _b ? _a : _b; })

static int output_type = DECIMAL;
static int do_ntsc = 0;
static int do_pal = 0;
static int do_ansii = 1;
static int do_community = 0;

static int is_rgb = 0;

static unsigned int community[] = {
  0x00,0x00,0x00, 0xff,0xff,0xff, 0xaf,0x2a,0x29, 0x62,0xd8,0xcc,
  0xb0,0x3f,0xb6, 0x4a,0xc6,0x4a, 0x37,0x39,0xc4, 0xe4,0xed,0x4e,
  0xb6,0x59,0x1c, 0x68,0x38,0x08, 0xea,0x74,0x6c, 0x4d,0x4d,0x4d,
  0x84,0x84,0x84, 0xa6,0xfa,0x9e, 0x70,0x7c,0xe6, 0xb6,0xb6,0xb5,
};

static unsigned int ntsc[] = {
  0x00,0x00,0x00, 0xFF,0xFF,0xFF, 0x67,0x37,0x2B, 0x70,0xA3,0xB1,
  0x6F,0x3D,0x86, 0x58,0x8C,0x42, 0x34,0x28,0x79, 0xB7,0xC6,0x6E,
  0x6F,0x4E,0x25, 0x42,0x38,0x00, 0x99,0x66,0x59, 0x43,0x43,0x43,
  0x6B,0x6B,0x6B, 0x9A,0xD1,0x83, 0x6B,0x5E,0xB5, 0x95,0x95,0x95,
};

static unsigned int pal[] = {
  0x00,0x00,0x00, 0xFF,0xFF,0xFF, 0x68,0x37,0x2b, 0x70,0xa4,0xb2,
  0x6f,0x3d,0x86, 0x58,0x8d,0x43, 0x35,0x28,0x79, 0xb8,0xc7,0x6f,
  0x6f,0x4f,0x25, 0x43,0x39,0x00, 0x9a,0x67,0x59, 0x44,0x44,0x44,
  0x6c,0x6c,0x6c, 0x9a,0xd2,0x84, 0x6c,0x5e,0xb5, 0x95,0x95,0x95,
};

static unsigned int ansii[] = {
/*black*/          0, 0, 0,
/*red*/            204, 0, 0,
/*green*/          78, 154, 6,
/*yellow*/         196, 160, 0,
/*blue*/           114, 159, 207,
/*magenta*/        117, 80, 123,
/*cyan*/           6, 152, 154,
/*white*/          211, 215, 207,
/*bright black*/   85, 87, 83,
/*bright red*/     239, 41, 41,
/*bright green*/   138, 226, 52,
/*bright yellow*/  252, 233, 79,
/*bright blue*/    50, 175, 255,
/*bright magenta*/ 173, 127, 168,
/*bright cyan*/    52, 226, 226,
/*bright white*/   255, 255, 255
};

static char *name[] = {
	"BLACK",
        "WHITE",
        "RED",
        "CYAN",
        "PURPLE",
        "GREEN",
        "BLUE",
        "YELLOW",
        "ORANGE",
        "BROWN",
        "PINK",
        "DARK_GREY",
        "GREY",
        "LIGHT_GREEN",
        "LIGHT_BLUE",
        "LIGHT_GREY"
};

void rgb_to_hsv(double r, double g, double b, int *phase, int *amp, int *luma) {
        // R, G, B values are divided by 255
        // to change the range from 0..255 to 0..1
        r = r / 255.0;
        g = g / 255.0;
        b = b / 255.0;
 
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
        else if (cmax == b)
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
        if (*luma < 12) *luma = 12;
        //printf("%f  %f %f %f\n", h,  h*(255.0d/359.0d), s*(15.0d/100.0d), v*(63.0d/100.0d));
 
}

char dst[3][16];
char* bin(int n, int sb, int nb, int v) {
   int bit=sb;
   for(int b=0;b<nb;b++) {
      if (v & bit) 
          dst[n][b] = '1';
      else  
          dst[n][b] = '0';
      bit=bit/2;
   }
   return dst[n];
}

// Take top 6 bits from VICE palette. Change later if we use more wires
// for colors.
int main(int argc, char *argv[]) {
  int loc;
  int R,G,B;

  if (output_type == CODE)
     printf ("    case (pixel_color4)\n");

  for (int i=0;i<16;i++) {
     if (do_ntsc) {
       R=ntsc[i*3];
       G=ntsc[i*3+1];
       B=ntsc[i*3+2];
     }
     if (do_pal) {
       R=pal[i*3];
       G=pal[i*3+1];
       B=pal[i*3+2];
     }
     if (do_ansii) {
       R=ansii[i*3];
       G=ansii[i*3+1];
       B=ansii[i*3+2];
     }
     if (do_community) {
       R=community[i*3];
       G=community[i*3+1];
       B=community[i*3+2];
     }

     if (is_rgb) {
        if (output_type == BINARY)
           printf ("%s%s%s000000\n",bin(0,128,6,R), bin(1,128,6,G), bin(2,128,6,B));
        else if (output_type == DECIMAL)
           printf ("%d,%d,%d,0\n",R>>2, G>>2, B>>2);
        else if (output_type == HEX)
           printf ("%02x,%02x,%02x,0\n",R>>2, G>>2, B>>2);
        else if (output_type == CHARS)
           printf ("%c%c%c%c",R>>2, G>>2, B>>2, 0);
        else if (output_type == CODE)
           printf ("        `%s:{red, green, blue} <= {6'h%02x, 6'h%02x, 6'h%02x};\n", name[i], R>>2, G>>2, B>>2);
     } else {
        int phase, amp, luma;
        rgb_to_hsv(R,G,B, &phase, &amp, &luma);
        if (output_type == BINARY)
           printf ("%s%s%s\n",bin(0,32,6,luma), bin(1,128,8,phase), bin(2,8,4,amp));
        else if (output_type == DECIMAL)
           printf ("%d,%d,%d\n",luma, phase, amp);
        else if (output_type == HEX)
           printf ("%02x,%02x,%02x\n",luma, phase, amp);
        else if (output_type == CHARS)
           printf ("%c%c%c",luma, phase, amp);
        else if (output_type == CODE)
           printf ("        `%s:{luma, phase, amp} <= {6'h%02x, 6'h%02x, 6'h%02x};\n", name[i], luma, phase, amp);
     }
  }
  if (output_type == CODE)
     printf ("    endcase\n");
}
