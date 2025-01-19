#include <stdio.h>
#include <6502.h>
#include <peekpoke.h>
#include <conio.h>
#include <string.h>
#include <stdlib.h>

#include "util.h"
#include "kawari.h"
#include "menu.h"
#include "flash.h"

#define SCRATCH_SIZE 32
unsigned char scratch[SCRATCH_SIZE];

void copy_6000_0000(void);

static struct regs r;

unsigned long input_int(void) {
   unsigned n = 0;
   unsigned long accum,mult;
   int i;
   scratch[0] = '\0';
   for (;;) {
      WAITKEY;
      if (r.a == 20) {
          if (n>0) {
             n--;
             printf ("%c",20);
             scratch[n] = '\0';
          }
          continue;
      }
      printf("%c",r.a);
      if (r.a == 0x0d) break;
      scratch[n++] = r.a;
   }
   scratch[n] = '\0';
   if (n >= 2 && scratch[0] == '0' && scratch[1] == 'x') {
      accum = 0; mult=1;
      for (i=n-1; i >= 2; i--) {
          if (scratch[i] >='0' && scratch[i] <='9') 
             accum += (scratch[i] - '0')*mult;
          else if (scratch[i] >='a' && scratch[i] <='f') 
             accum += (scratch[i] - 'a' + 10)*mult;
          mult=mult*16;
      }
      return accum;
   }
   else
      return atol(scratch);
}

char printable(char c) {
   if ((c >= 0x20 && c <=0x7f) || (c >= 0xa0 && c <=0xff))
      return c;
   else
      return '.';
}

void print_page(unsigned long addr) {
   int n=0;
   int c=0;
   char c1,c2,c3,c4,c5,c6,c7,c8;
   int idx;
   for (n=0;n<256/8;n++) {
       idx = n*8;
       c1=data_in[idx];
       c2=data_in[idx+1];
       c3=data_in[idx+2];
       c4=data_in[idx+3];
       c5=data_in[idx+4];
       c6=data_in[idx+5];
       c7=data_in[idx+6];
       c8=data_in[idx+7];
       printf ("%06lx:%02x %02x %02x %02x %02x %02x %02x %02x:",
             addr,c1,c2,c3,c4,c5,c6,c7,c8);
       c1 = printable(c1);
       c2 = printable(c2);
       c3 = printable(c3);
       c4 = printable(c4);
       c5 = printable(c5);
       c6 = printable(c6);
       c7 = printable(c7);
       c8 = printable(c8);
       printf ("%c%c%c%c%c%c%c%c\n",c1,c2,c3,c4,c5,c6,c7,c8);
       addr+=8;
       GETKEY;
       if (r.a != 0x00) break;
   }
}

void expert(void) {
   unsigned long start_addr;
   unsigned int n;
   unsigned char key;

   printf ("\nExpert CMD\n");
   do {
      printf ("\n> ");
      WAITKEY;
      key = r.a;
      printf ("\n");
      switch(key) {
        case '?':
          printf ("R slow read 256 from flash\n");
          printf ("e erase 4k flash\n");
          printf ("w slow write 256 to flash\n");
          printf ("m read 256 from vmem\n");
          printf ("f bulk flash read to vmem\n");
          printf ("g bulk flash write from vmem\n");
          printf ("c copy 0x6000 DRAM to 0x0000 VMEM\n");
          printf ("l fill 16k VMEM with pattern\n");
          printf ("s get spi status reg\n");
          break;
        case 'r': // SLOW READ 256 FROM FLASH
          printf ("\nEnter FLASH READ address:");
          start_addr = input_int();
          printf ("READ 256 bytes from FLASH (slow) %lx\n", start_addr);
          read_page(start_addr);
          print_page(start_addr);
          break;
        case 'e': // ERASE FLASH 4K
          printf ("\nEnter FLASH ERASE address:");
          start_addr = input_int();
          printf ("ERASE FLASH 4k @ %lx\n", start_addr);
          wren();
          erase_4k(start_addr);
          break;
        case 'w': // SLOW WRITE 256 TO FLASH
          printf ("\nEnter FLASH WRITE address:");
          start_addr = input_int();
          printf ("WRITE 256 bytes to %lx (slow)\n", start_addr);
          for (n=0;n<256;n++) {
             data_out[n] = n;
          }
          wren();
          write_page(start_addr);
          break;
        case 'm': // READ 256 FROM VMEM
          printf ("\nEnter VMEM read address:");
          start_addr = input_int();
          printf ("READ 256 vmem bytes from %lx (slow)\n", start_addr);
          POKE(VIDEO_MEM_FLAGS, 1);
          POKE(VIDEO_MEM_1_IDX,0);
          POKE(VIDEO_MEM_2_IDX,0);
          POKE(VIDEO_MEM_1_LO,start_addr & 0xff);
          POKE(VIDEO_MEM_1_HI,start_addr >> 8);
          for (n=0;n<256;n++) {
             data_in[n] = PEEK(VIDEO_MEM_1_VAL);
          }
          print_page(start_addr);
          POKE(VIDEO_MEM_FLAGS, 0);
          break;
        case 'f': // BULK FLASH READ TO VMEM
          printf ("\nEnter FLASH read address:");
          start_addr = input_int();
          printf ("READ 16k from FLASH (bulk)\n");
          printf ("%lx to vmem 0x0000\n", start_addr);
          POKE(VIDEO_MEM_FLAGS, 0);
          // From flash start_addr
          POKE(VIDEO_MEM_1_IDX,(start_addr >> 16) & 0xff);
          POKE(VIDEO_MEM_1_HI,(start_addr >> 8) & 0xff);
          POKE(VIDEO_MEM_1_LO,(start_addr & 0xff));
          // To video mem 0x0000
          POKE(VIDEO_MEM_2_HI, 0);
          POKE(VIDEO_MEM_2_LO, 0);
          POKE(SPI_REG, FLASH_BULK_OP | FLASH_BULK_READ);
          break;
        case 'g': // BULK FLASH WRITE FROM VMEM
          printf ("\nEnter FLASH write address:");
          start_addr = input_int();
          printf ("WRITE 16k to FLASH (bulk) %lx\nfrom vmem 0x0000\n", start_addr);
          POKE(VIDEO_MEM_FLAGS, 0);
          // To flash start_addr
          POKE(VIDEO_MEM_1_IDX,(start_addr >> 16) & 0xff);
          POKE(VIDEO_MEM_1_HI,(start_addr >> 8) & 0xff);
          POKE(VIDEO_MEM_1_LO,(start_addr & 0xff));
          // From video mem 0x0000
          POKE(VIDEO_MEM_2_HI, 0);
          POKE(VIDEO_MEM_2_LO, 0);
          POKE(SPI_REG, FLASH_BULK_OP | FLASH_BULK_WRITE);
          printf("VERIFY %d\n", wait_verify());
          break;
        case 'c': // COPY 0x6000 to vmem 0x000
          printf ("\nCopy 0x6000 DRAM to 0x000 VMEM\n");
          copy_6000_0000();
          break;
        case 'l': // FILL 16k vmem with pattern
          POKE(VIDEO_MEM_FLAGS, 1);
          POKE(VIDEO_MEM_1_IDX,0);
          POKE(VIDEO_MEM_2_IDX,0);
          POKE(VIDEO_MEM_1_LO,0);
          POKE(VIDEO_MEM_1_HI,0);
          for (n=0;n<16384;n++) {
             POKE(VIDEO_MEM_1_VAL, n % 256);
          }
          POKE(VIDEO_MEM_FLAGS, 0);
          break;
        case 's': // GET SPI REG
          printf ("\nSPI_REG=%d\n", PEEK(SPI_REG));
          break;
      }
   } while (key != 'q');
}

void main_menu(void)
{
    clrscr();

    printf ("VIC-II Kawari FLASH expert util\n\n");

    // Activate SPI reg.
    POKE(SPI_REG, 83);
    POKE(SPI_REG, 80);
    POKE(SPI_REG, 73);

    printf ("\nIdentifying flash...");
    use_device(DEVICE_TYPE_FLASH);
    read_device();
    printf ("MID=%02x DID=%02x\n", data_in[0], data_in[1]);

    expert();
}
