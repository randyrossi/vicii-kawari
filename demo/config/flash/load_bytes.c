#include <stdio.h>

#define LOAD_LO 0x00
#define LOAD_HI 0x90

int main(int argc, char *argv[]) {
   printf ("%c%c",LOAD_LO,LOAD_HI);
}
