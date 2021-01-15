
#include <stdio.h>

static unsigned int pal[] = {
    0x00, 0x00, 0x00, 0xFF, 0xFF, 0xFF, 0x68, 0x37, 0x2b, 0x70, 0xa4, 0xb2,
    0x6f, 0x3d, 0x86, 0x58, 0x8d, 0x43, 0x35, 0x28, 0x79, 0xb8, 0xc7, 0x6f,
    0x6f, 0x4f, 0x25, 0x43, 0x39, 0x00, 0x9a, 0x67, 0x59, 0x44, 0x44, 0x44,
    0x6c, 0x6c, 0x6c, 0x9a, 0xd2, 0x84, 0x6c, 0x5e, 0xb5, 0x95, 0x95, 0x95,
};


static char* names[16] = {
	"`BLACK","`WHITE","`RED","`CYAN","`PURPLE","`GREEN","`BLUE","`YELLOW",
	"`ORANGE","`BROWN","`PINK","`DARK_GREY","`GREY", "`LIGHT_GREEN","`LIGHT_BLUE","`LIGHT_GREY" 
};

// Take top 4 bits from VICE palette. Change later if we use more wires
// for colors.
int main(int argc, char *argv[]) {
    for (int i=0;i<16;i++) {
	    unsigned int r = (pal[i*3] >> 4) ;
	    unsigned int g = (pal[i*3+1] >> 4);
	    unsigned int b = (pal[i*3+2] >> 4);
	    printf ("redi[%d] <= {4'h%02x, 4'h%02x};\n", i, r,r);
	    printf ("greeni[%d] <= {4'h%02x, 4'h%02x};\n", i, g,g);
	    printf ("bluei[%d] <= {4'h%02x, 4'h%02x};\n", i, b,b);
    } 
}
