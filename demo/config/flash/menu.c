#include <stdio.h>
#include <6502.h>
#include <peekpoke.h>
#include <conio.h>
#include <string.h>

#include "util.h"
#include "kawari.h"
#include "menu.h"

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
// Bit 2 - Write busy
// Bit 3 - Verify error
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

void bsout(unsigned char c) {
    r.pc = (unsigned) 0xFFD2;
    r.a = c;
    _sys(&r);
}

void mprintf(unsigned char* text) {
   int n;
   for (n=0;n<strlen(text);n++) {
       unsigned char c = text[n];
       bsout(c);
   }
}

// Load the fast loader into $9000
void do_load_loader() {
    strcpy (filename,"loader");
    r.pc = (unsigned) &load_loader;
    r.x = (unsigned char)(&filename[0]);
    r.y = (unsigned)(&filename[0]) >> 8;
    r.a = (unsigned char)strlen(filename);
    _sys(&r);
}

void init_loader() {
    r.pc = 36864L;
    _sys(&r);
}

// Load next 16k segment into $4000-$8000
// Return non-zero on failure to load file.
unsigned char load_file() {
    r.pc = 36867L;
    r.x = (unsigned char)(&filename[0]);
    r.y = (unsigned)(&filename[0]) >> 8;
    _sys(&r);
    return r.a;
}


void read8()
{
   int b;
   unsigned char value;
   for (b=128;b>=1;b=b/2) {
        SET(D0_C0_S0);
        SET(D0_C1_S0);
        value |= PEEK(SPI_REG) ? b : 0;
   }
   data_in[0] = value;
}

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

void wren(void) {
    // INSTR + CLOSE
    talk(WREN_INSTR,
	0, 0L /* no addr */,
	0 /* read 0 */,
	0 /* write 0 */,
	1 /* close */);
}

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

void erase_64k(unsigned long addr) {
    // INSTR + 24 bit 0 + 2 READ BYTES + CLOSE
    talk(DEVICE_ID_INSTR,
         1 /* withaddr */, addr,
	 0 /* read 0 */,
	 0 /* write 0 */,
	 1 /* close */);
}

// Flash files are spread across 4 disks
void begin_flash(unsigned long num_to_write) {
    unsigned long addr;
    unsigned long src_addr;
    unsigned char disknum;
    unsigned char filenum;

    mprintf ("LOAD LOADER...");
    do_load_loader();
    mprintf ("DONE\n\n");

    mprintf ("INIT LOADER...");
    init_loader();
    mprintf ("DONE\n\n");

    mprintf ("ERASE FLASH");
    for (addr=0;addr<512000;addr+=65536) {
        mprintf (".");
        wren();
        erase_64k(addr);
        //wait_busy();
    }
    mprintf ("DONE\n\n");

    filenum = 0;
    disknum = 0;
    addr = 0;
    while (num_to_write > 0) {
       // Set next filename
       sprintf (filename,"%c%d", 'a'+disknum, filenum);
       SMPRINTF_2("READ %s (%ld remaining)...", filename, num_to_write);

       while (load_file()) {
            mprintf("\nFile not found.\nPress any key to try again\n");
	    WAITKEY;
       }

       mprintf ("WRITE\n");

       // Transfer $4000 - $7fff into video memory @ $0000
       POKE(53305L,0);
       POKE(53306L,0);
       for (src_addr=0x4000L;src_addr<0x8000L;src_addr++) {
           POKE(53307L,PEEK(src_addr));
       }

       // Tell kawari to flash it
       POKE(SPI_REG, 0);

       // Wait for flash to be done
       //wait_busy();
	       
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
    mprintf ("FINISHED. Press any key.\n");
    WAITKEY;
}

void main_menu(void)
{
    int key;
    unsigned long num_to_write;

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

    // TODO Read size and confirm this is an image disk
    num_to_write = 458752;
    SMPRINTF_1 ("\nImage is %ld bytes\n", num_to_write);

    if ((num_to_write % 16384) != 0) {
        mprintf ("Image is not properly padded.\n");
        mprintf ("Press any key to exit.\n");
        WAITKEY;
        return;
    }

    mprintf ("Press SPACE to begin programming\n");

    for (;;) {

       WAITKEY;
       key = r.a;

       if (key == ' ')  {
           begin_flash(num_to_write);
           return;
       } else if (key == 'q')  {
           return;
       }
    }
}
