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

void copy_5000_0000(void);

static struct regs r;

unsigned long input_int(void) {
   unsigned n = 0;
   for (;;) {
      WAITKEY;
      printf("%c",r.a);
      if (r.a == 0x0d) break;
      scratch[n++] = r.a;
   }
   scratch[n] = '\0';
   return atol(scratch);
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
          printf ("c copy 0x5000 DRAM to 0x0000 VMEM\n");
          printf ("l fill 16k VMEM with pattern\n");
          printf ("s get spi status reg\n");
          break;
        case 'r': // SLOW READ 256 FROM FLASH
          printf ("\nEnter FLASH READ address:");
          start_addr = input_int();
          printf ("READ 256 bytes from FLASH (slow) %ld\n", start_addr);
          read_page(start_addr);
          for (n=0;n<256;n++) {
             printf ("%02x:", data_in[n]);
          }
          break;
        case 'e': // ERASE FLASH 4K
          printf ("\nEnter FLASH ERASE address:");
          start_addr = input_int();
          printf ("ERASE FLASH 4k @ %ld\n", start_addr);
          wren();
          erase_4k(start_addr);
          break;
        case 'w': // SLOW WRITE 256 TO FLASH
          printf ("\nEnter FLASH WRITE address:");
          start_addr = input_int();
          printf ("WRITE 256 bytes to %ld (slow)\n", start_addr);
          for (n=0;n<256;n++) {
             data_out[n] = n;
          }
          wren();
          write_page(start_addr);
          break;
        case 'm': // READ 256 FROM VMEM
          printf ("\nEnter VMEM read address:");
          start_addr = input_int();
          printf ("READ 256 vmem bytes from %ld (slow)\n", start_addr);
          POKE(VIDEO_MEM_FLAGS, 1);
          POKE(VIDEO_MEM_1_IDX,0);
          POKE(VIDEO_MEM_2_IDX,0);
          POKE(VIDEO_MEM_1_LO,start_addr & 0xff);
          POKE(VIDEO_MEM_1_HI,start_addr >> 8);
          for (n=0;n<256;n++) {
             printf("%02x ",PEEK(VIDEO_MEM_1_VAL));
          }
          POKE(VIDEO_MEM_FLAGS, 0);
          break;
        case 'f': // BULK FLASH READ TO VMEM
          printf ("\nEnter FLASH read address:");
          start_addr = input_int();
          printf ("READ 16k from FLASH (bulk)\n");
          printf ("%ld to vmem 0x0000\n", start_addr);
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
          printf ("WRITE 16k to FLASH (bulk) %ld\nfrom vmem 0x0000\n", start_addr);
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
        case 'c': // COPY 0x5000 to vmem 0x000
          printf ("\nCopy 0x5000 DRAM to 0x000 VMEM\n");
          copy_5000_0000();
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
