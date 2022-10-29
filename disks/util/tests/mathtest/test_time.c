#include "tests.h"
#include "macros.h"

#include <6502.h>
#include <peekpoke.h>
#include <kawari.h>
#include <util.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

int time_cpu_udiv(void) {
   unsigned short i;

   time_t t;
   time_t t2;
   time(&t);

   for (i=0;i<10000;i++) {
   asm(
        "   lda #3\n"
        "   sta $58\n"
        "   lda #0\n"
        "   sta $59\n"
        "   lda #255\n"
        "   sta $fd\n"
        "   lda #255\n"
        "   sta $fe\n"
   );

   asm(
"divide:  lda #0\n"
"	sta $fd\n"
"	sta $fe\n"
"	ldx #16\n"
"divloop:   asl $fb\n"
"	rol $fc	\n"
"	rol $fd\n"
"	rol $fe\n"
"	lda $fd\n"
"	sec\n"
"	sbc $58\n"
"	tay\n"
"	lda $fe\n"
"	sbc $59\n"
"	bcc skip\n"
"	sta $fe\n"
"	sty $fd\n"
"	inc $fb\n"
"skip:	dex\n"
"	bne divloop\n");

   }
   time(&t2);
   printf ("%ld\n",t2-t);
   return 0;
}

int time_vic_udiv(void) {
   unsigned short i;
   
   time_t t;
   time_t t2;
   time(&t);
   for (i=0u;i<10000u;i++) {
   asm(
        "   lda #3\n"
        "   sta $58\n"
        "   lda #0\n"
        "   sta $59\n"
        "   lda #255\n"
        "   sta $fd\n"
        "   lda #255\n"
        "   sta $fe\n"
   );
   asm ("divide:  lda $58; divisor\n"
        "    sta $d031\n"
        "    lda $59\n"
        "    sta $d032\n"
        "    lda $fd ; divided\n"
        "    sta $d02f\n"
        "    lda $fe\n"
        "    sta $d030\n"
        "    lda #1\n"
        "    sta $d033\n"
        "    lda $d02f ; remainder\n"
        "    sta $fd\n"
        "    lda $d030\n"
        "    sta $fe\n"
        "    lda $d031 ; result\n"
        "    sta $fb\n"
        "    lda $d032\n"
        "    sta $fc\n"
   );
   }
   time(&t2);
   printf ("%ld\n",t2-t);
   return 0;
}
