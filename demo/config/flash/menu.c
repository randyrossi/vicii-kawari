#include <stdio.h>
#include <6502.h>
#include <peekpoke.h>
#include <conio.h>
#include <string.h>
#include <stdlib.h>

#include "util.h"
#include "kawari.h"
#include "menu.h"

// Program starts at 0x801.
// 0x5000-0x8fff is used for 16k flash load space
// 0x9000 is used first as scratch space for into then fast loader
// Program should not exceed ~14k to leave at least 4k heap space,
// otherwise heap may get corrupted by flash tmp writes since it
// wants to grow upwards starting from the end of the code.

#define FLASH_VERSION_MAJOR 1
#define FLASH_VERSION_MINOR 0

// Use a combination of direct SPI access and bulk
// SPI write operations provided by hardware to flash
// an updated bitstream to the device.  Flash (2Mb) is
// partitioned into header + golden master at 0x000000
// while 'current' bistream is located at 0x07d000.

// The max version of the image file format we can understand.
#define MAX_VERSION 1L
#define MAX_VERSION_STR "1"

// We won't write below this address in flash mem.
#define MIN_WRITE_ADDR 512000L

static struct regs r;

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
// * 24-bit write address set from 0x35,0x36,0x3a
//
// (Read)
// Bit 1 - SPI Data In
// Bit 2 - Write busy : 1=BUSY, 0=DONE
// Bit 3 - Verify error : 1=ERROR, 0=OK
// Bit 4 - SPI lock status
// Bit 5 - Extensions lock status
// Bit 6 - Persistence lock status
// Bit 7 - unused
// Bit 8 - unused

// SPI_REG
// All combinations of D/C/S bits for Flash
// programming. Make sure EEPROM select (Bit 4)
// is always held high.
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
#define BLOCK_ERASE_64K_INSTR 0xd8
#define WRITE_INSTR           0x02

#define TO_EXIT 0
#define TO_CONTINUE 1
#define TO_TRY_AGAIN 2
#define TO_NOTHING 3

unsigned char smp_tmp[40];
#define SMPRINTF_1(format, arg)\
        snprintf (smp_tmp, 39, format, arg); \
	mprintf(smp_tmp);
#define SMPRINTF_2(format, arg1, arg2)\
        snprintf (smp_tmp, 39, format, arg1, arg2);\
	mprintf(smp_tmp);
#define SMPRINTF_3(format, arg1, arg2, arg3)\
        snprintf (smp_tmp, 39, format, arg1, arg2, arg3);\
	mprintf(smp_tmp);

unsigned char data_out[256];
unsigned char data_in[256];

#define SCRATCH_SIZE 32
unsigned char filename[16];
unsigned char scratch[SCRATCH_SIZE];

unsigned char use_fast_loader;

#ifdef EXPERT
unsigned char is_expert = 0;
#endif

void load_loader(void);
void copy_5000_0000(void);
void compare(void);

// Output a single character using kernel BSOUT routine.
void bsout(unsigned char c) {
    r.pc = (unsigned) 0xFFD2;
    r.a = c;
    _sys(&r);
}

// For some odd reason, the fast loader will not install
// if we use printf. So we have to build our own print
// routine based on bsout.
void mprintf(unsigned char* text) {
   int n;
   for (n=0;n<strlen(text);n++) {
       unsigned char c = text[n];
       bsout(c);
   }
}

void press_any_key(int code) {
   mprintf ("Press any key");
   if (code == TO_CONTINUE) mprintf (" to continue.\n");
   if (code == TO_EXIT) mprintf (" to exit.\n");
   if (code == TO_TRY_AGAIN) mprintf (" try again.\n");
   if (code == TO_NOTHING) mprintf (".\n");
   WAITKEY;
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

// Read a petscii string from addr. Advance addr
// to after the 0x0a terminator.  Max SCRATCH_SIZE char
// string will get placed in 'scratch' global var.
void read_string(unsigned long* addr) {
    unsigned n = 0;
    unsigned char c;

    scratch[0] = '\0';
    do {
       c = PEEK(*addr);
       if (c != 0x0a && n < SCRATCH_SIZE-1) {
           scratch[n++] = c;
       }
       *addr = *addr + 1;
    } while (c != 0x0a);

    if (n < SCRATCH_SIZE)
       scratch[n] = '\0';
    else
       scratch[SCRATCH_SIZE-1] = '\0';
}

// Load the fast loader into $9000
unsigned char slow_load(void) {
    r.pc = (unsigned) &load_loader;
    r.x = (unsigned char)(&filename[0]);
    r.y = (unsigned)(&filename[0]) >> 8;
    r.a = (unsigned char)strlen(filename);
    _sys(&r);
    return r.x;
}

// Call the fast loader's initialization routine
void init_fast_loader(void) {
    r.pc = 36864L;
    _sys(&r);
}

// Fast load next 16k segment into $5000-$8FFF
// Return non-zero on failure to load file.
unsigned char fast_load() {
    r.pc = 36867L;
    r.x = (unsigned char)(&filename[0]);
    r.y = (unsigned)(&filename[0]) >> 8;
    _sys(&r);
    return r.a;
}

unsigned char load() {
   if (use_fast_loader)
      return fast_load();
   else
      return slow_load();
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

#ifdef EXPERT
void write_page(unsigned long addr) {
    if (addr < MIN_WRITE_ADDR) {
       mprintf("Can't write to protected address\n");
       SMPRINTF_1("(%ld). Address too low.\n",addr);
       return;
    }

    // INSTR + 24 bit addr + 256 write bytes + CLOSE
    talk(WRITE_INSTR,
	1 /* withaddr */, addr,
	0 /* read 0 */,
	256 /* write 256 */,
	1 /* close */);

    wait_busy();
}
#endif

// Write enable
void wren(void) {
    // INSTR + CLOSE
    talk(WREN_INSTR,
	0, 0L /* no addr */,
	0 /* read 0 */,
	0 /* write 0 */,
	1 /* close */);
}

// Erase a 64k segment starting at addr
void erase_64k(unsigned long addr) {
    if (addr < MIN_WRITE_ADDR) {
       mprintf("Can't write to protected address\n");
       SMPRINTF_1("(%ld). Address too low.\n",addr);
       return;
    }

    // INSTR + 24 bit 0 + 2 READ BYTES + CLOSE
    talk(BLOCK_ERASE_64K_INSTR,
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

unsigned long input_int(void) {
   unsigned n = 0;
   for (;;) {
      WAITKEY;
      SMPRINTF_1("%c",r.a);
      if (r.a == 0x0d) break;
      scratch[n++] = r.a;
   }
   scratch[n] = '\0';
   return atol(scratch);
}

#ifdef EXPERT
void expert(void) {
   unsigned long start_addr;
   unsigned int n;
   mprintf ("\nExpert mode\n");
   is_expert = 1;
   do {
      mprintf ("\n> ");
      WAITKEY;
      if (r.a == 'r') { // read flash (slow)
         mprintf ("\nEnter FLASH READ address:");
         start_addr = input_int();
         SMPRINTF_1 ("READ 256 bytes from FLASH (slow) %ld:", start_addr);
         read_page(start_addr);
         for (n=0;n<256;n++) {
            SMPRINTF_1 ("%02x:", data_in[n]);
         }
      } else if (r.a == 'e') { // erase flash
         mprintf ("\nEnter FLASH ERASE address:");
         start_addr = input_int();
         SMPRINTF_1 ("ERASE FLASH 64k @ %ld:", start_addr);
         wren();
         erase_64k(start_addr);
      } else if (r.a == 'w') { // write from vmem
         mprintf ("\nEnter FLASH WRITE (slow) address:");
         start_addr = input_int();
         SMPRINTF_1 ("WRITE 256 bytes to %ld:", start_addr);
         for (n=0;n<256;n++) {
            data_out[n] = n;
         }
         wren();
         write_page(start_addr);
      } else if (r.a == 'm') { // read vmem
         mprintf ("\nEnter VMEM read address:");
         start_addr = input_int();
         SMPRINTF_1 ("READ 256 vmem bytes from %ld:", start_addr);
         POKE(VIDEO_MEM_FLAGS, 1);
         POKE(VIDEO_MEM_1_IDX,0);
         POKE(VIDEO_MEM_2_IDX,0);
         POKE(VIDEO_MEM_1_LO,start_addr & 0xff);
         POKE(VIDEO_MEM_1_HI,start_addr >> 8);
         for (n=0;n<256;n++) {
            SMPRINTF_1("%02x ",PEEK(VIDEO_MEM_1_VAL));
         }
         POKE(VIDEO_MEM_FLAGS, 0);
      } else if (r.a == 'f') { // read vmem
         mprintf ("\nEnter FLASH read address:");
         start_addr = input_int();
         SMPRINTF_1 ("READ 16k from FLASH (bulk) %ld:", start_addr);
         POKE(VIDEO_MEM_FLAGS, 0);
         // From flash start_addr
         POKE(VIDEO_MEM_1_IDX,(start_addr >> 16) & 0xff);
         POKE(VIDEO_MEM_1_HI,(start_addr >> 8) & 0xff);
         POKE(VIDEO_MEM_1_LO,(start_addr & 0xff));
         // To video mem 0x0000
         POKE(VIDEO_MEM_2_HI, 0);
         POKE(VIDEO_MEM_2_LO, 0);
         POKE(SPI_REG, FLASH_BULK_OP | FLASH_BULK_READ);
      } else if (r.a == 'c') {
         copy_5000_0000();
      }
   } while (r.a != 'q');
}
#endif

void fast_start(void) {
    if (use_fast_loader) {
       mprintf ("LOAD LOADER...");
       strcpy (filename,"loader");
       while (slow_load()) {
          printf ("Can't read fast loader prg\n");
          press_any_key(TO_TRY_AGAIN);
       }
       mprintf ("DONE\n\n");

       mprintf ("INIT LOADER...");
       init_fast_loader();
       mprintf ("DONE\n\n");
    }
}

// Flash files are spread across 4 disks
// This routine erases the flash
void begin_flash(long num_to_write, unsigned long start_addr) {
    unsigned long src_addr;
    unsigned char disknum;
    unsigned char filenum;
    unsigned char abs_filenum;
    unsigned int n;

    fast_start();
    mprintf ("ERASE FLASH");
    for (src_addr=start_addr;
           src_addr<(start_addr+512000L) && src_addr < 2097152L;
              src_addr+=65536) {
        mprintf (".");
        wren();
        erase_64k(src_addr);
    }
    mprintf ("DONE\n\n");

    filenum = 0;
    abs_filenum = 0;
    disknum = 0;

    while (num_to_write > 0) {
       // Set next filename
       sprintf (filename,"i%02d", abs_filenum);
       SMPRINTF_2("%ld:READ %s,", num_to_write, filename);

       while (load()) {
            mprintf("\nFile not found.\n");
            press_any_key(TO_TRY_AGAIN);
            SMPRINTF_2("%ld:READ %s,", num_to_write, filename);
       }

       mprintf ("COPY,");

       // Pad remaining bytes
       if (num_to_write < 16384) {
           for (n=num_to_write; n < 16384; n++) {
              POKE(0x5000L+n, 0xff);
           }
       }

       // Transfer $5000 - $8fff into video memory @ $0000
       copy_5000_0000();

       // Tell kawari to flash it from vmem 0x0000 to the flash address
       POKE(VIDEO_MEM_FLAGS, 0);
       POKE(VIDEO_MEM_1_IDX,(start_addr >> 16) & 0xff);
       POKE(VIDEO_MEM_1_HI,(start_addr >> 8) & 0xff);
       POKE(VIDEO_MEM_1_LO,(start_addr & 0xff));
       POKE(VIDEO_MEM_2_HI, 0);
       POKE(VIDEO_MEM_2_LO, 0);
       mprintf ("FLASH,");
       POKE(SPI_REG, FLASH_BULK_OP | FLASH_BULK_WRITE);

#ifdef EXPERT
       if (is_expert) {
          expert();
       }
#endif

       // Wait for flash to be done and verified
       mprintf ("VERIFY,");
       if (wait_verify()) {
          mprintf("\nVERIFY ERROR\n");
          press_any_key(TO_TRY_AGAIN);
       } else {
          mprintf ("OK\n");
          start_addr += 16384;
          num_to_write -= 16384;

          abs_filenum++;
          filenum++;
          if (disknum < 3 && filenum == 8) {
	      filenum = 0;
	      disknum++;
	      SMPRINTF_1("Insert disk %d and press any key\n", disknum+1);
	      WAITKEY;
          }
       }
    }
    mprintf ("FINISHED\n");
    press_any_key(TO_NOTHING);
}

void begin_verify(long num_to_read, unsigned long start_addr) {
    unsigned char disknum;
    unsigned char filenum;
    unsigned char abs_filenum;
    unsigned int n;

    filenum = 0;
    abs_filenum = 0;
    disknum = 0;

    fast_start();

    while (num_to_read > 0) {
       // Set next filename
       sprintf (filename,"i%02d", abs_filenum);
       SMPRINTF_2("%ld:READ %s,", num_to_read, filename);

       while (load()) {
            mprintf("\nFile not found.\n");
            press_any_key(TO_TRY_AGAIN);
            SMPRINTF_2("%ld:READ %s,", num_to_read, filename);
       }

       // Tell kawari to read from flash to 0x0000
       POKE(VIDEO_MEM_FLAGS, 0);
       POKE(VIDEO_MEM_1_IDX,(start_addr >> 16) & 0xff);
       POKE(VIDEO_MEM_1_HI,(start_addr >> 8) & 0xff);
       POKE(VIDEO_MEM_1_LO,(start_addr & 0xff));
       POKE(VIDEO_MEM_2_HI, 0);
       POKE(VIDEO_MEM_2_LO, 0);
       mprintf ("READ FLASH,");
       POKE(SPI_REG, FLASH_BULK_OP | FLASH_BULK_READ);

       // Just wait for busy to be done, don't check verify bit.
       wait_verify();

#ifdef EXPERT
       if (is_expert) {
          expert();
       }
#endif

       // Wait for flash to be done and verified
       mprintf ("VERIFY,");


       // Set the number of bytes to compare
       // vmem 0x0000 with mem 0x5000
       n = num_to_read >= 16384 ? 16384 : num_to_read;

// For testing in sim
//copy_5000_0000();

       POKE(0xfe,(n >> 8) & 0xff);
       POKE(0xfd,(n & 0xff));

       compare();

       if (PEEK(0xfd) == 0) {
          mprintf ("OK\n");
          start_addr += 16384;
          num_to_read -= 16384;
          abs_filenum++;
          filenum++;
          if (disknum < 3 && filenum == 8) {
	     filenum = 0;
	     disknum++;
	     SMPRINTF_1("Insert disk %d and press any key\n", disknum+1);
	     WAITKEY;
          }
       } else {
	  SMPRINTF_1("FAIL @%d\n",
             PEEK(VIDEO_MEM_1_LO) + PEEK(VIDEO_MEM_1_HI) * 256);
          break;
       }
    }
    if (PEEK(0xfd) == 0)
       mprintf ("FINISHED\n");
    else
       mprintf ("VERIFY FAILED\n");

    press_any_key(TO_NOTHING);
}

void main_menu(void)
{
    unsigned char firmware_version_major;
    unsigned char firmware_version_minor;
    unsigned long disk_format_version;
    long num_to_write;
    unsigned long start_addr;
    unsigned long tmp_addr;

    clrscr();

    mprintf ("VIC-II Kawari Update Util\n\n");

    SMPRINTF_2 ("Update Util Version: %d.%d\n",
        FLASH_VERSION_MAJOR, FLASH_VERSION_MINOR);

    // Turn on regs overlay to get version
    POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_REGS_BIT);
    firmware_version_major = get_version_major();
    firmware_version_minor = get_version_minor();
    POKE(VIDEO_MEM_FLAGS, 0);

    SMPRINTF_2 ("Current Firmware Version: %d.%d\n",
        firmware_version_major, firmware_version_minor);
    mprintf ("\n");

    //        ----------------------------------------
    mprintf ("This utility will flash an update to\n");
    mprintf ("your VICII-Kawari. Do not turn off the\n");
    mprintf ("machine until the update is complete.\n");
    mprintf ("When using the fast loader, the garbage\n");
    mprintf ("at the top of the screen is normal. If\n");
    mprintf ("you have your own fast loader cartridge\n");
    mprintf ("select N when prompted. If you are\n");
    mprintf ("using a Pi1541, remember to add ALL\n");
    mprintf ("disks to your queue.\n\n");

    press_any_key(TO_CONTINUE);

    // Activate SPI reg.
    POKE(SPI_REG, 83);
    POKE(SPI_REG, 80);
    POKE(SPI_REG, 73);

    // Identify flash device
    for (;;) {
      mprintf ("\nIdentifying flash...");
      read_device();
      SMPRINTF_2 ("MID=%02x DID=%02x\n", data_in[0], data_in[1]);

      if (FLASH_LOCKED) {
         mprintf ("\nERROR: FLASH lock bit is enabled!\n");
         mprintf ("SPI functions are not available.\n");
         mprintf ("Please remove FLASH lock jumper\n");
         mprintf ("to continue.\n\n");
      }

      if (data_in[0] != 0xef || data_in[1] != 0x14) {
         mprintf ("Can't identify flash device.\n");
         press_any_key(TO_TRY_AGAIN);
      } else {
         break;
      }
    }

    mprintf ("\nInsert update disk #1 and press any key.\n");
    WAITKEY;
#ifdef EXPERT
    if (r.a == 'x') {
       expert();
    }
#endif

    mprintf ("\nREAD IMAGE INFO\n");
    strcpy (filename,"info");
    while (slow_load()) {
       printf ("Can't read info file.\n");
       press_any_key(TO_TRY_AGAIN);
       WAITKEY;
    }

    // Info is now at $9000
    tmp_addr=0x9000;
    disk_format_version = read_decimal(&tmp_addr);
    SMPRINTF_1 ("File Format  :v%ld\n", disk_format_version);

    if (disk_format_version > MAX_VERSION) {
       mprintf ("\nThis util can only read version " MAX_VERSION_STR "\n");
       press_any_key(TO_EXIT);
       WAITKEY;
       return;
    }

    read_string(&tmp_addr);
    SMPRINTF_1 ("Image name   :%s\n", scratch);
    read_string(&tmp_addr);
    SMPRINTF_1 ("Image version:%s\n", scratch);
    num_to_write = read_decimal(&tmp_addr);
    SMPRINTF_1 ("Size         :%ld bytes\n", num_to_write);
    start_addr = read_decimal(&tmp_addr);
    SMPRINTF_1 ("Start Address:%lx \n", start_addr);

    mprintf ("\nUse fast loader (Y/n) ?");

    use_fast_loader = 1;
    for (;;) {
       WAITKEY;
       if (r.a == 'y' || r.a == 0x0a) break;
       if (r.a == 'n') { use_fast_loader = 0; break; }
    }

    if (use_fast_loader)
       mprintf ("Y\n\n");
    else
       mprintf ("N\n\n");

    for (;;) {
       mprintf ("F - Perform flash\n");
       mprintf ("V - Perform verify\n");
       mprintf ("Q - Quit\n");
       WAITKEY;
       if (r.a == 'f') {
          mprintf ("\nMake sure disk #1 is in the drive.\n");
          press_any_key(TO_CONTINUE);
          begin_flash(num_to_write, start_addr);
       } else if (r.a == 'v') {
          mprintf ("\nMake sure disk #1 is in the drive.\n");
          press_any_key(TO_CONTINUE);
          begin_verify(num_to_write, start_addr);
       } else if (r.a == 'q') {
          break;
       }
    }
}
