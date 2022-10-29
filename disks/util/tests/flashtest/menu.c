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

// 16k At this location is used to test flash
// Must be beyond multiboot image for both spartan and efinix devices
#define FLASH_SCRATCH_START 1392640L

#define SCRATCH_SIZE 32
unsigned char scratch[SCRATCH_SIZE];

void copy_5000_0000(void);
void fill_5000(void);
void zero_5000(void);
void test_0000(unsigned char*);

void erase_16k(void) {
   unsigned long addr;
   for (addr=FLASH_SCRATCH_START;
         addr<(FLASH_SCRATCH_START+16384L) && addr < 2097152L;
            addr+=4096) {
      wren();
      erase_4k(addr);
    }
}

void test_erase(void) {
   unsigned long addr = FLASH_SCRATCH_START;
   int i;
   printf ("TEST ERASE:");
   wren();
   erase_4k(addr);
   read_page(addr);
   for (i=0;i<256;i++) {
      if (data_in[i] != 0xff) {
         printf ("FAILED\n");
         return;
      }
   }
   printf ("OK\n");
}

void test_fast_write(void) {
   unsigned long addr = FLASH_SCRATCH_START;
   unsigned long to_addr = 0;
   unsigned int page_size;
   unsigned int num_to_write = 16384;

   printf ("TEST FAST WRITE:");
   erase_16k();
   fill_5000();
   copy_5000_0000();

   page_size = get_flash_page_size();
  
   while (num_to_write > 0) {
      // To flash addr
      POKE(VIDEO_MEM_1_IDX,(addr >> 16) & 0xff);
      POKE(VIDEO_MEM_1_HI,(addr >> 8) & 0xff);
      POKE(VIDEO_MEM_1_LO,(addr & 0xff));
      // From video mem 0x0000
      POKE(VIDEO_MEM_2_HI, (to_addr >> 8 ) & 0xff);
      POKE(VIDEO_MEM_2_LO, to_addr & 0xff);
      POKE(SPI_REG, FLASH_BULK_OP | FLASH_BULK_WRITE);

      if (wait_verify()) {
         printf ("VERIFY ERROR\n");
         break;
      } else {
         printf ("OK\n");
      }
      addr += page_size;
      to_addr += page_size;
      num_to_write -= page_size;
   }
}

void test_fast_read(void) {
   unsigned long addr = FLASH_SCRATCH_START;
   unsigned long from_addr = 0;
   unsigned char fail;
   unsigned int page_size;
   unsigned int num_to_read = 16384;

   printf ("TEST FAST READ:");
   zero_5000();
   copy_5000_0000();

   page_size = get_flash_page_size();

   while (num_to_read > 0) {
      // From flash start_addr
      POKE(VIDEO_MEM_1_IDX,(addr >> 16) & 0xff);
      POKE(VIDEO_MEM_1_HI,(addr >> 8) & 0xff);
      POKE(VIDEO_MEM_1_LO,(addr & 0xff));
      // To video mem 0x0000
      POKE(VIDEO_MEM_2_HI, (from_addr >> 8) & 0xff);
      POKE(VIDEO_MEM_2_LO, from_addr & 0xff);
      POKE(SPI_REG, FLASH_BULK_OP | FLASH_BULK_READ);

      wait_verify();

      addr += page_size;
      from_addr += page_size;
      num_to_read -= page_size;
   }

   // Check we got back what we wrote (16k)
   POKE(VIDEO_MEM_1_IDX,0);
   POKE(VIDEO_MEM_1_HI,0);
   POKE(VIDEO_MEM_1_LO,0);
   POKE(VIDEO_MEM_FLAGS, 1); // autoinc

   test_0000(&fail);

   if (fail) {
      printf ("FAILED\n");
      return;
   }

   printf ("OK\n");
}

void test_slow_write(void) {
   unsigned long addr = FLASH_SCRATCH_START;
   int n;
   printf ("TEST SLOW WRITE:");
   erase_4k(addr);
   for (n=0;n<256;n++) {
      data_out[n] = n;
   }
   wren();
   write_page(addr);
   printf ("OK\n");
}

void test_slow_read(void) {
   unsigned long addr = FLASH_SCRATCH_START;
   int n;
   printf ("TEST SLOW READ:");
   read_page(addr);
   for (n=0;n<256;n++) {
      if (data_in[n] != n) {
         printf ("FAILED\n");
         return;
      }
   }
   printf ("OK\n");
}

void main_menu(void)
{
    unsigned char c = 0x54;
    clrscr();

    printf ("VIC-II Kawari Flash Test\n\n");

    POKE(VIDEO_MEM_FLAGS, 0);

    // Activate SPI reg.
    POKE(SPI_REG, 83);
    POKE(SPI_REG, 80);
    POKE(SPI_REG, 73);

    // Identify flash device

    printf ("\nIdentifying flash...");
    read_device();
    printf ("MID=%02x DID=%02x\n", data_in[0], data_in[1]);

    if (FLASH_LOCKED) {
       printf ("\nERROR: FLASH lock bit is enabled!\n");
       printf ("SPI functions are not available.\n");
       printf ("Please add FLASH lock jumper\n");
       printf ("to continue.\n\n");
    }

    if (data_in[0] == 0xef) {
       printf ("WinBond ");
       if (data_in[1] == 0x14)
          printf ("W25Q16\n");
       else if (data_in[1] == 0x15)
          printf ("W25Q32\n");
    } else {
       printf ("UNKNOWN FLASH DEVICE.\n");
       return;
    }

   test_erase();
   test_slow_write();
   test_slow_read();
   test_fast_write();
   test_fast_read();
}
