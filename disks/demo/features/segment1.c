#include <stdio.h>
#include <6502.h>
#include <peekpoke.h>
#include <string.h>

#include "util.h"
#include "kawari.h"
#include "menu.h"
#include "color.h"

static struct regs r;

static int have_kawari;
static int powers[8];
static int npowers[8];
static char scratch[40];
static int black_level;
static unsigned char saved_colors[COLOR_SAVE_SPACE];

void delay(long v) { long t; for (t=0;t<v;t++) { } }

void clr_snd() {
   asm(
"ldx #24\n"
"clear_snd:\n"
"  lda #0\n"
"  sta 54272\n"
"  dex\n"
"  bne clear_snd\n"
"  lda #9\n"
"  sta 54272+5\n"
"  lda #0\n"
"  sta 54272+6\n"
"  lda #15\n"
"  sta 54272+24\n");
}

void wow_snd() {
   asm(
"ldx #24\n"
"clear_snd:\n"
"  lda #0\n"
"  sta 54272\n"
"  dex\n"
"  bne clear_snd\n"
"  lda #144+9\n" // attack/decay
"  sta 54272+5\n"
"  lda #15\n" // sustain/release
"  sta 54272+6\n"
"  lda #15\n" // vol
"  sta 54272+24\n"
"  lda #02\n" // freq hi
"  sta 54272+1\n"
"  lda #00\n" // freq lo
"  sta 54272\n"
"  lda #32+1\n" // control1
"  sta 54272+4\n"
);
}

void wow2_snd() {
   asm(
"  lda #255\n" // attack/decay
"  sta 54272+5\n"
"  lda #15\n" // sustain/release
"  sta 54272+6\n"
"  lda #15\n" // vol
"  sta 54272+24\n"
"  lda #02\n" // freq hi
"  sta 54272+1\n"
"  lda #00\n" // freq lo
"  sta 54272\n"
"  lda #32+1\n" // control1
"  sta 54272+4\n"
);
}

void bleep() {
   asm(
" lda #25\n"
" sta 54272+1\n"
" lda #177\n"
" sta 54272\n"
" lda #33\n"
" sta 54272+4\n"
);
}

void bloop() {
   asm(
" lda #28\n"
" sta 54272+1\n"
" lda #214\n"
" sta 54272\n"
" lda #33\n"
" sta 54272+4\n"
);
}

void snd_stop() {
   asm(
" lda #32\n"
" sta 54272+4\n"
);
}

void silence() {
   asm(
" lda #0\n"
" sta 54272+24\n"
);
}

void tick() {
   asm(
" lda #32\n"
" sta 54272+1\n"
" lda #214\n"
" sta 54272\n"
" lda #129\n"
" sta 54272+4\n"
);
}

void rumble() {
   asm(
" lda #4\n"
" sta 54272+1\n"
" lda #214\n"
" sta 54272\n"
" lda #129\n"
" sta 54272+4\n"
);
}

void stop() {
   asm(
" lda #128\n"
" sta 54272+4\n"
);
}

int is_color(char c) {
  return c == 28 || c ==30 || c == 31 || c ==0x90 || c == 81 ||
         (c >= 0x95  && c <= 0x9f);
}

void terminal(char *c) {
  int l;
  int i;
  l = strlen(c);
  for (i=0;i<l;i++) {
     if (c[i] != '@')
        printf ("%c",c[i]);
     else
        printf (" ");
     if (is_color(c[i])) {
       // skip
     } else if (c[i] == ' ') {
       delay(80);
     } else if (c[i] == '\n') {
       delay(500);
     } else if (c[i] == '@') {
       // nodelay
     } else {
       bloop(); delay(20); snd_stop();
       bleep(); delay(20); snd_stop();
       delay(80);
     }
  }
}

void fake_reset() {
    delay(1000L);
    CLRSCRN;
    clr_snd();
    POKE(53270L,192); // csel
    delay(2000L);
    POKE(53270L,200); // csel
    //printf("\n    **** commodore 64 basic v2 ****\n\n 64k ram system  38911 basic bytes free\n\nready.\n");
    //delay(1000);
    //CLRSCRN;
}

void intro(void) {
    long cram;
    for (cram=55296L;cram<55296L+40*25;cram++)
       POKE(cram,14);

    delay(800);
    terminal("hi there!\n\n");
    terminal("looks like i'm running on a good 'ol\n");
    terminal("commodore 64...");
    delay(2000);
    terminal("nice\n\n");
    delay(1000);

    terminal("let's check some things out\n\n\n");

    terminal("cpu... "); delay(500); terminal("check\n");
    terminal("sound... "); delay(500); terminal("check\n");
    terminal("video... "); delay(500); terminal("check\n");
}

void ena_sprite(int s, int e) {
   if (e) POKE (53269L,PEEK(53269L) | powers[s]);
   else POKE (53269L,PEEK(53269L) & npowers[s]);
}

void set_sprite(int s, int x, int y)
{
   POKE(53248L+s*2,x%256);
   POKE(53249L+s*2,y);
   if (x > 255)
      POKE(53264L, PEEK(53264L) | (powers[s]));
   else
      POKE(53264L, PEEK(53264L) & npowers[s]);
}

int font[16][5]= {
{15,9,9,9,15},
{6,2,2,2,7},
{15,1,15,8,15},
{15,1,15,1,15},
{9,9,15,1,1},
{15,8,15,1,15},
{15,8,15,9,15},
{15,1,2,4,8},
{15,9,15,9,15},
{15,9,15,1,1},
{6,9,15,9,9},
{14,9,14,9,14},
{15,8,8,8,15},
{14,9,9,9,14},
{15,8,14,8,15},
{15,8,14,8,8},
};

void clr_sprite(int s) {
   int l;
   long r = (248+s)*64;
   for (l=0;l<21;l++) {
       POKE(r, 0);
       POKE(r+1, 0);
       POKE(r+2, 0);
       r=r+3;
   }
}

void col_sprite(int s, int c) {
   POKE (53287L+s,c);
}

void hex_sprite(int s, long v) {
   int l;
   int n1,n2,n3,n4;
   long w;
   long r = (248+s)*64;

   n1 = (v & 0xf000L) >> 12;
   n2 = (v & 0x0f00L) >> 8;
   n3 = (v & 0x00f0L) >> 4;
   n4 = (v & 0x000fL);

   for (l=0;l<5;l++) {
       w = ((long)font[n1][l] << 15L) | ((long)font[n2][l] << 10L) |
            ((long)font[n3][l] << 5L) | ((long)font[n4][l]);
       POKE(r, (w & 0xff0000L) >> 16);
       POKE(r+1, (w & 0x00ff00L) >> 8);
       POKE(r+2, (w & 0x0000ffL));
       r=r+3;
   }
}

int sx[8];
int sy = 240;
int en[8];
long vx[8];

void do_swipe(int accel) {
    int acceldec,s;
    acceldec =0;
    while (accel >0) {
       for (s=0;s<8;s++) {
          sx[s]-= accel;
             if (sx[s] < 0) {
             sx[s] += 400; ena_sprite(s, 1);
             vx[s] += 8; hex_sprite(s,vx[s]);
             tick(); delay(2); stop();
             if (vx[s] == 0xd03f && have_kawari) col_sprite(s, 5);
          }
          set_sprite(s, sx[s], sy);
       }
       acceldec++;
       if (acceldec > 10) {
          acceldec=0; accel--;
          if (accel == 0) break;
       }
    }
    delay(500);
}

int memory_check(void)
{
    int s;
    int swipe;

    terminal("memory...");
    POKE(53269L,255); // all sprites on
    for (s=0;s<8;s++)
       POKE(2040L+s,248+s); // sprite mem

    en[0] = 0;
    en[1] = 0;
    en[2] = 0;
    en[3] = 0;
    en[4] = 0;
    en[5] = 0;
    en[6] = 1;
    en[7] = 1;

    for (s=0;s<8;s++) {
       clr_sprite(s);
       set_sprite(s,50+s*50,sy);
       col_sprite(s,1);
       sx[s] = 50+s*50;
       vx[s] = 0x4000 + s;
       ena_sprite(s,en[s]);
       hex_sprite(s,s);
    }

    for (swipe=0;swipe < 3; swipe++) {
       do_swipe(8);
    }

    terminal("check\n\nlet's look at some vic2 registers\n");
    
    sprintf(scratch, "@@@@@@@@@@@@@@@@@@@%c%c%c%c\n",227,227,227,227);
    terminal(scratch);

    for (s=0;s<8;s++) {
       vx[s] +=0x9007L;
    }

    do_swipe(16);
    
    return 0;
}

int rnd[16] = {7,0,7,0,5,0,5,0,3,0,3,0,1,0,1,0};

// VIC2 @ 19,13
void do_shake() {
    int h;
    int shake;
    int shake2;
    
    terminal("that's different\n");
    terminal("one second...\n");
    delay(1000);
    h= PEEK(53270L);
    for (shake2=0;shake2<3;shake2++) {
      rumble();
      for (shake=0;shake<16;shake++) {
         POKE (53270L,h | rnd[shake]);
         delay(100);
      }
      if (shake2 == 0) {
         POKE(1024L+19+13*40,32);
         POKE(1024L+19+14*40,'v'-64);
         POKE(1024L+20+14*40,'/');
      }
      else if (shake2 == 1) {
         POKE(1024L+20+13*40,32);
         POKE(1024L+21+14*40,'/');
         POKE(1024L+20+15*40,'/');
         POKE(1024L+20+14*40,'i'-64);
         POKE(1024L+19+14*40,32);
         POKE(1024L+19+15*40,'v'-64);
      }
      else if (shake2 == 2) {
         POKE(1024L+19+16*40,'v'-64);
         POKE(1024L+20+15*40,'i'-64);
         POKE(1024L+21+14*40,'c'-64);
         POKE(1024L+20+16*40,'/');
         POKE(1024L+21+15*40,'/');
         POKE(1024L+22+14*40,'/');
         POKE(1024L+20+14*40,32);
         POKE(1024L+19+15*40,32);
         POKE(1024L+21+13*40,32);
      }
      stop();
      delay(800);
    }
}

int fallx[11] = {19,19,19,19,19,19,19,19,20,21,22};
int fally[11] = {23,22,21,20,19,18,17,16,15,14,13};
void do_fall() {
  int t;
  int d;
  int m;
  int accel;
  int q;
  accel=5;

  d=200;
  q=60;
  for (m=0;m<20;m++) {
   for (t=0;t<q/10;t++) {
      POKE(1024L+fallx[t]+fally[t]*40,PEEK(1024L+fallx[t+1]+fally[t+1]*40));
   }
   POKE(1024L+fallx[t]+fally[t]*40,32);
   delay(d);
   d=d-accel; if (d<0) d=0;
   accel=accel+10;
   q=q+5; if (q>100) q=100;
  }
}

void do_pulse(void)
{
   int t,y;
   // Make extra regs visible
   POKE(VIDEO_MEM_FLAGS, PEEK(VIDEO_MEM_FLAGS) | VMEM_FLAG_REGS_BIT);

   // Grab blanking level
   POKE(VIDEO_MEM_1_LO, 0x80);
   black_level = PEEK(VIDEO_MEM_1_VAL);

   save_colors(saved_colors);

   wow_snd();
   fade_to(5, 63, 0, 0, black_level);
   snd_stop();
   wow_snd();
   fade_to(5, 0, 63, 0, black_level);
   snd_stop();
   wow_snd();
   fade_to(5, 0, 0, 63, black_level);
   snd_stop();
   wow_snd();
   fade_to(5, 63, 0, 0, black_level);
   snd_stop();
   wow_snd();
   fade_to(5, 0, 63, 0, black_level);
   snd_stop();
   wow_snd();
   fade_to(5, 0, 0, 63, black_level);
   snd_stop();
   silence();

   // Move sprites off screen
   y = PEEK(53249L);
   for (t=y;t<y+20;t++) {
      POKE(53249L,t);
      POKE(53251L,t);
      POKE(53253L,t);
      POKE(53255L,t);
      POKE(53257L,t);
      POKE(53259L,t);
      POKE(53261L,t);
      POKE(53263L,t);
      delay(50);
   }
   POKE(53269L,0);

   restore_colors(saved_colors);
}

void do_fade(void) {
   wow2_snd();
   save_colors(saved_colors);
   POKE(53281L,6);
   POKE(53280L,6);

   // Grab blanking level
   POKE(VIDEO_MEM_1_LO, 0x80);
   black_level = PEEK(VIDEO_MEM_1_VAL);

   fade_to(6, 63, 0, 0, black_level);
   fade_to(6, 0, 63, 0, black_level);
   fade_to(6, 63, 0, 63, black_level);
   fade_to(6, 63, 0, 0, black_level);
   fade_to(6, 0, 63, 0, black_level);
   fade_to(6, 63, 63, 0, black_level);
   fade_to(6, 0, 0, 0, black_level);

   // Fade text color to black also
   fade_to(14, 0, 0, 0, black_level);
   CLRSCRN;

   // Actual black screen
   POKE(53281L,0);
   POKE(53280L,0);

   restore_colors(saved_colors);

   POKE(646L, 1); // white
   TOXY(5,5);
   printf ("kawari extensions activated\n\n");
   printf ("         loading....");
}

int main(void)
{
    int s;
    clr_snd();

    for (s=0;s<8;s++) {
       powers[s] = 1 << s;
       npowers[s] = ~(1 << s);
    }

    POKE(53272L,21); // upper case
    POKE(53280L,14);
    POKE(53281L,6);
    CLRSCRN;

    have_kawari = enable_kawari();

    // So we can restore any time across segments
    save_colors_vmem(0x8000L);

    fake_reset();
    intro();
    memory_check();

    if (have_kawari) {
      do_shake();
      do_fall();
      do_pulse();
      asm("jsr $80d\n"); // start music
      do_fade();
    } else {
      printf("everything looks normal\n");
      printf("bye\n");
      for(;;) {}
    }

    return 0;
}
