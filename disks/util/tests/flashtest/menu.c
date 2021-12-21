#include <stdio.h>
#include <6502.h>
#include <peekpoke.h>
#include <conio.h>
#include <string.h>
#include <stdlib.h>

#include "util.h"
#include "kawari.h"
#include "menu.h"

// 16k At this location is used to test flash
#define FLASH_SCRATCH_START 1048576L

#define D1_C1_S1 15 // 1111
#define D1_C1_S0 14 // 1110
#define D1_C0_S1 13 // 1101
#define D1_C0_S0 12 // 1100
#define D0_C1_S1 11 // 1011
#define D0_C1_S0 10 // 1010
#define D0_C0_S1 9  // 1001
#define D0_C0_S0 8  // 1000

#define STRINGIFY(x) #x
#define TOSTRING(x) STRINGIFY(x)

#define SET(val) asm("lda #"STRINGIFY(val)); asm ("sta $d034");

#define DEVICE_ID_INSTR       0x90
#define READ_INSTR            0x03
#define WREN_INSTR            0x06
#define READ_STATUS1_INSTR    0x05
#define BLOCK_ERASE_4K_INSTR  0x20
#define WRITE_INSTR           0x02

unsigned char data_out[256];
unsigned char data_in[256];

#define SCRATCH_SIZE 32
unsigned char scratch[SCRATCH_SIZE];

void copy_5000_0000(void);
void fill_5000(void);
void zero_5000(void);
void test_0000(unsigned char*);

// Helper to read 8 bits from SPI device
void read8() {
   unsigned char b;
   unsigned char value = 0;
   unsigned int bit;
   for (b=128;b>=1;b=b/2) {
        SET(D0_C0_S0);
        SET(D0_C1_S0);
        bit = PEEK(SPI_REG) & 1;
        if (bit)
	   value = value + b;
   }
   data_in[0] = value;
}

// Generic routine to talk to SPI device
// 8-bit instruction
// optional 24 bit address
// write_count num bytes to write (from data[] array)
// read_count num bytes to read (into data[] array)
void talk(unsigned char instr,
          unsigned char with_addr, unsigned long addr,
	  unsigned int read_count, unsigned int write_count,
	  unsigned char close)
{
    unsigned char value;
    unsigned long b;
    int n;
    unsigned long bit;

    asm("sei");
    SET(D1_C1_S1);
    SET(D0_C1_S0);

    // 8 bit instruction
    for (b=128L;b>=1L;b=b/2L) {
       bit = instr & b;
       if (bit) {
	       SET(D1_C0_S0);
               SET(D1_C1_S0);
       } else {
	       SET(D0_C0_S0);
               SET(D0_C1_S0);
       }
    }

    // Should we shift a 24 bit address now?
    if (with_addr) {
       // 24 bit address
       for (b=8388608L;b>=1L;b=b/2L) {
          bit = addr & b;
          if (bit) {
	       SET(D1_C0_S0);
               SET(D1_C1_S0);
          } else {
	       SET(D0_C0_S0);
               SET(D0_C1_S0);
          }
       }
    }

    for (n=0;n<write_count;n++) {
       for (b=128L;b>=1L;b=b/2L) {
          bit = data_out[n] & b;
          if (bit) {
	       SET(D1_C0_S0);
               SET(D1_C1_S0);
          } else {
	       SET(D0_C0_S0);
               SET(D0_C1_S0);
          }
       }
    }

    // count is num bytes to read
    for (n=0;n<read_count;n++) {
       // 8 bit data
       value = 0;
       for (b=128L;b>=1L;b=b/2L) {
	   SET(D0_C0_S0);
	   SET(D0_C1_S0);
           bit = PEEK(SPI_REG) & 1;
           if (bit)
	      value = value + b;
       }
       data_in[n] = value;
    }

    if (close) {
       SET(D0_C1_S0); // leave clock high before S high
       SET(D1_C1_S1); // drive S high again
    }

    asm("cli");
}

// Wait for flash device to be ready
void wait_busy(void) {
    // INSTR + 1 BYTE READ + NO CLOSE
    talk(READ_STATUS1_INSTR,
	0, 0L /* no addr */,
	1 /* read 1 */,
	0 /* write 0 */,
	0 /* no close */);

    while (data_in[0] & 1) {
       read8();
    }

    // close
    SET(D0_C0_S0);
    SET(D1_C1_S1);
}

// Read the flash device id bytes
void read_device(void) {
    // INSTR + 24 bit 0 + 2 READ BYTES + CLOSE
    talk(DEVICE_ID_INSTR,
         1 /* withaddr */, 0,
	 2 /* read 2 */,
	 0 /* write 0 */,
	 1 /* close */);
}

void read_page(unsigned long addr) {
    // INSTR + 24 bit addr + 256 read bytes + CLOSE
    talk(READ_INSTR,
	1 /* withaddr */, addr,
	256 /* read 256 */,
	0 /* write 0 */,
	1 /* close */);
}

void write_page(unsigned long addr) {
    // INSTR + 24 bit addr + 256 write bytes + CLOSE
    talk(WRITE_INSTR,
	1 /* withaddr */, addr,
	0 /* read 0 */,
	256 /* write 256 */,
	1 /* close */);

    wait_busy();
}

// Write enable
void wren(void) {
    // INSTR + CLOSE
    talk(WREN_INSTR,
	0, 0L /* no addr */,
	0 /* read 0 */,
	0 /* write 0 */,
	1 /* close */);
}

// Erase a 4k segment starting at addr
void erase_4k(unsigned long addr) {
    // INSTR + 24 bit 0 + 2 READ BYTES + CLOSE
    talk(BLOCK_ERASE_4K_INSTR,
         1 /* withaddr */, addr,
	 0 /* read 0 */,
	 0 /* write 0 */,
	 1 /* close */);
    wait_busy();
}

// Return > 0 on verify error.
unsigned wait_verify(void) {
   unsigned char v;
   // Keep checking bit 2 for write busy flag.
   do { v = PEEK(SPI_REG); } while (v & 2);
   // Done? Return verify bit.
   return v & 4;
}

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

   printf ("TEST FAST WRITE:");
   erase_16k();
   fill_5000();
   copy_5000_0000();

   // To flash addr
   POKE(VIDEO_MEM_1_IDX,(addr >> 16) & 0xff);
   POKE(VIDEO_MEM_1_HI,(addr >> 8) & 0xff);
   POKE(VIDEO_MEM_1_LO,(addr & 0xff));
   // From video mem 0x0000
   POKE(VIDEO_MEM_2_HI, 0);
   POKE(VIDEO_MEM_2_LO, 0);
   POKE(SPI_REG, FLASH_BULK_OP | FLASH_BULK_WRITE);

   if (wait_verify()) {
      printf ("VERIFY ERROR\n");
   } else {
      printf ("OK\n");
   }
}

void test_fast_read(void) {
   unsigned long addr = FLASH_SCRATCH_START;
   unsigned char fail;

   printf ("TEST FAST READ:");
   zero_5000();
   copy_5000_0000();

   // From flash start_addr
   POKE(VIDEO_MEM_1_IDX,(addr >> 16) & 0xff);
   POKE(VIDEO_MEM_1_HI,(addr >> 8) & 0xff);
   POKE(VIDEO_MEM_1_LO,(addr & 0xff));
   // To video mem 0x0000
   POKE(VIDEO_MEM_2_HI, 0);
   POKE(VIDEO_MEM_2_LO, 0);
   POKE(SPI_REG, FLASH_BULK_OP | FLASH_BULK_READ);

   wait_verify();

   // Check we got back what we wrote
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

    if (data_in[0] != 0xef || data_in[1] != 0x14) {
       printf ("Can't identify flash device.\n");
       return;
    }

   test_erase();
   test_fast_write();
   test_fast_read();
   test_slow_write();
   test_slow_read();
}
