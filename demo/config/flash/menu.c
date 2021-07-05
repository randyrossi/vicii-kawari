#include <stdio.h>
#include <6502.h>
#include <peekpoke.h>
#include <conio.h>
#include <string.h>

#include "util.h"
#include "kawari.h"
#include "menu.h"

// The max version of the image file we can understand
#define MAX_VERSION 1
#define MAX_VERSION_STR "1"
#define MIN_WRITE_ADDR 512000L

static struct regs r;

// SPI_REG - Used for both direct (slow) access to SPI devices
//           and bulk SPI operation for Kawari to execute.
//
// (Write)
// Bit 1 : FLASH S
// Bit 2 : SPI C
// Bit 3 : SPI D
// Bit 4 : unused
// Bit 5 : unused
// Bit 6 : unused
// Bit 7 : unused
// Bit 8 : Write/Verify 16k block from 0x00000 video ram (*)
//
// * 24-bit write address set from 0x3c,0x3d,0x3e
//
// (Read)
// Bit 1 - SPI Q
// Bit 2 - Write busy : 1=BUSY, 0=DONE
// Bit 3 - Verify error : 1=ERROR, 0=OK
// Bit 4 - unused
// Bit 5 - unused
// Bit 6 - unused
// Bit 7 - unused
// Bit 8 - unused

#define SPI_REG 0x34

#define D1_C1_S1 7
#define D1_C1_S0 6
#define D1_C0_S1 5
#define D1_C0_S0 4
#define D0_C1_S1 3
#define D0_C1_S0 2
#define D0_C0_S1 1
#define D0_C0_S0 0

#define STRINGIFY(x) #x
#define TOSTRING(x) STRINGIFY(x)

#define SET(val) asm("lda #"STRINGIFY(val)); asm ("sta $d034");

#define DEVICE_ID_INSTR       0x90
#define READ_INSTR            0x03
#define WREN_INSTR            0x06
#define READ_STATUS1_INSTR    0x05
#define BLOCK_ERASE_64K_INSTR 0xd8
#define WRITE_INSTR           0x02

#define SMPRINTF_1(format, arg) sprintf (scratch, format, arg); \
	mprintf(scratch);
#define SMPRINTF_2(format, arg1, arg2) sprintf (scratch, format, arg1, arg2);\
	mprintf(scratch);

unsigned char data_out[256];
unsigned char data_in[256];

unsigned char filename[16];
unsigned char scratch[16];

void load_loader(void);

// Output a single character using kernel BSOUT routine.
void bsout(unsigned char c) {
    r.pc = (unsigned) 0xFFD2;
    r.a = c;
    _sys(&r);
}

// For some odd reason, the fast loader will not install
// if we use printf.  So we have to build our own print
// routine based on bsout.
void mprintf(unsigned char* text) {
   int n;
   for (n=0;n<strlen(text);n++) {
       unsigned char c = text[n];
       bsout(c);
   }
}

// Read a decimal value terminated with 0x0a from memory
// starting at addr.  Advance addr to after the 0x0a and
// return the decimal value as an unsigned long.
unsigned long read_decimal(unsigned long* addr) {
    unsigned long val = 0;
    unsigned char buf[16];
    unsigned n = 0;
    unsigned t = 0;
    unsigned long base;
    unsigned digit_val;

    do {
       buf[n] = PEEK(*addr);
       if(buf[n] == 0x0a) break;
       n++;
       *addr = *addr + 1;
    } while (n < 16);
    *addr = *addr + 1;

    base = 1;
    for (t=n;t>=1;t--) {
	    digit_val = buf[t-1] - '0';
	    val = val + digit_val * base;
	    base = base * 10;
    }
    return val;
}

// Load the fast loader into $9000
void slow_load(void) {
    r.pc = (unsigned) &load_loader;
    r.x = (unsigned char)(&filename[0]);
    r.y = (unsigned)(&filename[0]) >> 8;
    r.a = (unsigned char)strlen(filename);
    _sys(&r);
}

// Call the fast loader's initialization routine
void init_fast_loader(void) {
    r.pc = 36864L;
    _sys(&r);
}

// Fast load next 16k segment into $4000-$8000
// Return non-zero on failure to load file.
unsigned char fast_load() {
    r.pc = 36867L;
    r.x = (unsigned char)(&filename[0]);
    r.y = (unsigned)(&filename[0]) >> 8;
    _sys(&r);
    return r.a;
}

// Helper to read 8 bits from SPI device
void read8() {
   int b;
   unsigned char value;
   for (b=128;b>=1;b=b/2) {
        SET(D0_C0_S0);
        SET(D0_C1_S0);
        value |= PEEK(SPI_REG) ? b : 0;
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
    int b;
    int n;
    int bit;

    asm("sei");
    SET(D1_C1_S1);
    SET(D0_C1_S0);

    // 8 bit instruction
    for (b=128;b>=1;b=b/2) {
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
       for (b=8388608;b>=1;b=b/2) {
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
       for (b=128;b>=1;b=b/2) {
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
       for (b=128;b>=1;b=b/2) {
	   SET(D0_C0_S0);
	   SET(D0_C1_S0);
	   value |= PEEK(SPI_REG) ? b : 0;
       }
       data_in[n] = value;
    }    

    if (close) {
       SET(D0_C0_S0); // final clock low tick
       SET(D1_C1_S1); // drive S high again
    }

    asm("cli");
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

//void read_page(unsigned long addr) {
//    // INSTR + 24 bit addr + 256 read bytes + CLOSE
//    talk(READ_INSTR,
//	1 /* withaddr */, addr,
//	256 /* read 256 */,
//	0 /* write 0 */,
//	1 /* close */);
//}

//void write_page(unsigned long addr) {
//    // INSTR + 24 bit addr + 256 write bytes + CLOSE
//    talk(READ_INSTR,
//	1 /* withaddr */, addr,
//	0 /* read 0 */,
//	256 /* write 256 */,
//	1 /* close */);
//}

// Write enable
void wren(void) {
    // INSTR + CLOSE
    talk(WREN_INSTR,
	0, 0L /* no addr */,
	0 /* read 0 */,
	0 /* write 0 */,
	1 /* close */);
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

// Erase a 64k segment starting at addr
void erase_64k(unsigned long addr) {
    // INSTR + 24 bit 0 + 2 READ BYTES + CLOSE
    talk(DEVICE_ID_INSTR,
         1 /* withaddr */, addr,
	 0 /* read 0 */,
	 0 /* write 0 */,
	 1 /* close */);
}

// Return > 0 on verify error
unsigned wait_verify(void) {
   unsigned char v;
   // Keep checking bit 2 for write busy flag
   do {
       v = PEEK(SPI_REG);
   } while (v&2);
   // Done? Check verify bit
   return v & 4;
}

// Flash files are spread across 4 disks
// This routine erases the flash 
void begin_flash(unsigned long num_to_write, unsigned long addr) {
    unsigned long src_addr;
    unsigned char disknum;
    unsigned char filenum;

    if (addr < MIN_WRITE_ADDR) {
       mprintf("Can't write to protected address\n");
       SMPRINTF_1("(%ld). Address too low.\n",addr);
       return;
    }

    mprintf ("LOAD LOADER...");
    strcpy (filename,"loader");
    slow_load();
    mprintf ("DONE\n\n");

    mprintf ("INIT LOADER...");
    init_fast_loader();
    mprintf ("DONE\n\n");

    mprintf ("ERASE FLASH");
    for (src_addr=addr;src_addr<addr+512000L;src_addr+=65536) {
        mprintf (".");
        wren();
        erase_64k(src_addr);
        //wait_busy();
    }
    mprintf ("DONE\n\n");

    // Set port 1 to auto inc, no overlay
    POKE(53311L, 1);

    filenum = 0;
    disknum = 0;
    addr = 0;
    while (num_to_write > 0) {
       // Set next filename
       sprintf (filename,"%c%d", 'a'+disknum, filenum);
       SMPRINTF_2("%ld:READ %s,", num_to_write, filename);

       while (fast_load()) {
            mprintf("\nFile not found.\nPress any key to try again\n");
	    WAITKEY;
            SMPRINTF_2("%ld:READ %s,", num_to_write, filename);
       }

       mprintf ("COPY,");

       // Transfer $4000 - $7fff into video memory @ $0000
       // TODO: Replace this with assembler routine to be faster
       POKE(53305L,0);
       POKE(53306L,0);
       for (src_addr=0x4000L;src_addr<0x8000L;src_addr++) {
           POKE(53307L,PEEK(src_addr));
       }

       // Tell kawari to flash it
       mprintf ("FLASH,");
       POKE(SPI_REG, 128);

       // Wait for flash to be done and verified
       mprintf ("VERIFY,");
       if (wait_verify()) {
          mprintf("\nVERIFY ERROR: Press any key to try again.\n");
	  WAITKEY;
       } else {
          mprintf ("OK\n");
          addr += 16384;
          num_to_write -= 16384;

          filenum++;
          if (disknum < 3 && filenum == 8) {
	      filenum = 0;
	      disknum++;
	      SMPRINTF_1("Insert disk %d and press any key\n", disknum+1);
	      WAITKEY;
          }
       }
    }
    mprintf ("FINISHED. Press any key.\n");
    WAITKEY;
}

void main_menu(void)
{
    int key;
    unsigned long version;
    unsigned long num_to_write;
    unsigned long start_addr;
    unsigned long tmp_addr;

    clrscr();

    mprintf ("VIC-II Kawari Update Util\n\n");

    // TODO - Grab versions
    SMPRINTF_2 ("Update Util Version: %d.%d\n", 0, 0);
    SMPRINTF_2 ("Current Firmware Version: %d.%d\n", 0, 0);
    mprintf ("\n");

    // TODO: Show instructions.
    // Warning. If your machine loses power during flash, there is a chance
    // the device will not boot.
    // Remove any fast loader cartridges
    // Garbage at top of screen is normal.

    // Identify flash device
    mprintf ("Identifying flash...");
    read_device();
    SMPRINTF_2 ("MID=%02x DID=%02x\n", data_in[0], data_in[1]);

    // TODO check for expected MID and DID and bail if not expected
 
    mprintf ("\nInsert update disk and press SPACE.\n");

    for (;;) {
       WAITKEY;
       if (r.a == ' ')  {break;}
       if (r.a == 'q')  {return;}
    }

    mprintf ("Read info\n");
    strcpy (filename,"info");
    slow_load();

    // Info is now at $9000
    tmp_addr=0x9000;
    version = read_decimal(&tmp_addr);
    num_to_write = read_decimal(&tmp_addr);
    start_addr = read_decimal(&tmp_addr);

    SMPRINTF_1 ("\nImage version is %ld\n", version);

    if (version > MAX_VERSION) {
       mprintf ("This util can only read version " MAX_VERSION_STR);
       mprintf ("\nPress any key to exit.\n");
       WAITKEY;
       return;
    }

    SMPRINTF_1 ("\nImage is %ld bytes\n", num_to_write);
    SMPRINTF_1 ("Dest addr is %ld \n", start_addr);

    if ((num_to_write % 16384) != 0) {
        mprintf ("Image is not properly padded.\n");
        mprintf ("Press any key to exit.\n");
        WAITKEY;
        return;
    }

    mprintf ("\nPress SPACE to begin programming\n");

    for (;;) {

       WAITKEY;
       key = r.a;

       if (key == ' ')  {
           begin_flash(num_to_write, start_addr);
           return;
       } else if (key == 'q')  {
           return;
       }
    }
}
