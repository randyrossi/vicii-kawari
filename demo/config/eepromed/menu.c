#include <stdio.h>
#include <6502.h>
#include <peekpoke.h>
#include <conio.h>
#include <string.h>
#include <stdlib.h>

#include "util.h"
#include "kawari.h"
#include "menu.h"

// SPI_REG - Used for both direct (slow) access to SPI devices
//           and bulk SPI operation for Kawari to execute.
//
// (Write)
// Bit 1 : FLASH Select
// Bit 2 : SPI Clock
// Bit 3 : SPI Data Out
// Bit 4 : EEPROM Select
// Bit 5 : unused
// Bit 6 : unused
// Bit 7 : unused
// Bit 8 : Write/Verify 16k block from 0x00000 video ram (*)
//
// (Read)
// Bit 1 - SPI Data In
// Bit 2 - N/A for eeprom
// Bit 3 - N/A for eeprom
// Bit 4 - SPI lock status
// Bit 5 - Extensions lock status
// Bit 6 - Persistence lock status
// Bit 7 - unused
// Bit 8 - unused

// SPI_REG
// All combinations of D/C/S bits for EEPROM.
// Make sure FLASH select (Bit 1) is always held high.
#define D1_C1_S1 15 // 1111
#define D1_C1_S0  7 // 0111
#define D1_C0_S1 13 // 1101
#define D1_C0_S0  5 // 0101
#define D0_C1_S1 11 // 1011
#define D0_C1_S0  3 // 0011
#define D0_C0_S1  9 // 1001
#define D0_C0_S0  1 // 0001

#define STRINGIFY(x) #x
#define TOSTRING(x) STRINGIFY(x)

#define SET(val) asm("lda #"STRINGIFY(val)); asm ("sta $d034");

#define DEVICE_ID_INSTR       0x83
#define READ_INSTR            0x03
#define WREN_INSTR            0x06
#define READ_STATUS1_INSTR    0x05
#define WRITE_INSTR           0x02

#define TO_EXIT 0
#define TO_CONTINUE 1
#define TO_TRY_AGAIN 2
#define TO_NOTHING 3

unsigned char data_out[32];
unsigned char data_in[32];

#define SCRATCH_SIZE 32
unsigned char scratch[SCRATCH_SIZE];

static struct regs r;

void press_any_key(int code) {
   printf ("Press any key");
   if (code == TO_CONTINUE) printf (" to continue.\n");
   if (code == TO_EXIT) printf (" to exit.\n");
   if (code == TO_TRY_AGAIN) printf (" try again.\n");
   if (code == TO_NOTHING) printf (".\n");
   WAITKEY;
}

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
// optional 16 bit address
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

    // Should we shift a 16 bit address now?
    if (with_addr) {
       // 16 bit address
       for (b=32768L;b>=1L;b=b/2L) {
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

    // TODO - Retrieve result byte
}

// Read the flash device id bytes
void read_device(void) {
    // INSTR + 16 bit 0 + 3 READ BYTES + CLOSE
    talk(DEVICE_ID_INSTR,
         1 /* withaddr */, 0,
	 3 /* read 3 */,
	 0 /* write 0 */,
	 1 /* close */);
}

void read_page(unsigned long addr) {
    // INSTR + 16 bit addr + 32 read bytes + CLOSE
    talk(READ_INSTR,
	1 /* withaddr */, addr,
	32 /* read 32 */,
	0 /* write 0 */,
	1 /* close */);
}

void write_page(unsigned long addr) {
    // INSTR + 16 bit addr + 32 write bytes + CLOSE
    talk(WRITE_INSTR,
	1 /* withaddr */, addr,
	0 /* read 0 */,
	32 /* write 32 */,
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

void erase_all(void)
{
    unsigned long addr;
    int c;
    for (c = 0; c < 32; c=c+1) { data_out[c] = 0xff; }

    printf ("Erase all EEPROM memory?\n");
    printf ("Q to quit. Any other key to continue\n");
    WAITKEY;
    if (r.a == 'q') return;

    for (addr = 0; addr < 1024; addr=addr+32) {
        printf ("Write @ %04x\n",(int)addr);
        wren();
        write_page(addr);
    }
}  

void read_all(void)
{
    unsigned long addr;
    int c;

    for (addr = 0; addr < 1024; addr=addr+32) {
       read_page(addr);

       for (c=0;c<32;c++) {
           if (c % 8 == 0) {
               printf ("%04x: ", (int)(addr+c));
           }
           printf ("%02x ", data_in[c]);
           if (c ==7 || c==15 || c==23 || c==31) printf ("\n");
       }
       press_any_key(TO_CONTINUE);
    }
}

void main_menu(void)
{

    clrscr();

    printf ("VIC-II Kawari EEPROM Test Util\n\n");

    read_device();

    printf ("MF=%02x SPI_FAM=%02x DENSITY=%02x\n\n", data_in[0], data_in[1], data_in[2]);

    for (;;) {
       printf ("Command:");
       WAITKEY;
       printf ("%c\n",r.a);
       if (r.a == 'q') break;
       if (r.a == 'r') read_all();
       if (r.a == 'e') erase_all();
       if (r.a == '?') {
           printf ("q quit\n");
           printf ("r read all pages\n");
           printf ("e erase all pages\n");
       }
    }
}
