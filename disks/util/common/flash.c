#include <flash.h>

unsigned char type = DEVICE_TYPE_FLASH;

unsigned char data_out[256];
unsigned char data_in[256];

static unsigned char d1_c1_s1;
static unsigned char d1_c1_s0;
static unsigned char d1_c0_s1;
static unsigned char d1_c0_s0;
static unsigned char d0_c1_s1;
static unsigned char d0_c1_s0;
static unsigned char d0_c0_s1;
static unsigned char d0_c0_s0;
static unsigned char device_id_instr;

void use_device(unsigned char t) {
   type = t;
   if (type == DEVICE_TYPE_FLASH) {
      d1_c1_s1 = F_D1_C1_S1;
      d1_c1_s0 = F_D1_C1_S0;
      d1_c0_s1 = F_D1_C0_S1;
      d1_c0_s0 = F_D1_C0_S0;
      d0_c1_s1 = F_D0_C1_S1;
      d0_c1_s0 = F_D0_C1_S0;
      d0_c0_s1 = F_D0_C0_S1;
      d0_c0_s0 = F_D0_C0_S0;
      device_id_instr = F_DEVICE_ID_INSTR;
   } else {
      d1_c1_s1 = E_D1_C1_S1;
      d1_c1_s0 = E_D1_C1_S0;
      d1_c0_s1 = E_D1_C0_S1;
      d1_c0_s0 = E_D1_C0_S0;
      d0_c1_s1 = E_D0_C1_S1;
      d0_c1_s0 = E_D0_C1_S0;
      d0_c0_s1 = E_D0_C0_S1;
      d0_c0_s0 = E_D0_C0_S0;
      device_id_instr = E_DEVICE_ID_INSTR;
   }
}

// Helper to read 8 bits from SPI device
void read8() {
   unsigned char b;
   unsigned char value = 0;
   unsigned int bit;
   for (b=128;b>=1;b=b/2) {
        SET(d0_c0_s0);
        SET(d0_c1_s0);
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
    SET(d1_c1_s1);
    SET(d0_c1_s0);

    // 8 bit instruction
    for (b=128L;b>=1L;b=b/2L) {
       bit = instr & b;
       if (bit) {
	       SET(d1_c0_s0);
               SET(d1_c1_s0);
       } else {
	       SET(d0_c0_s0);
               SET(d0_c1_s0);
       }
    }

    // Should we shift a 24(flash)/16(eeprom) bit address now?
    if (with_addr) {
       // 24(flash)/16(eeprom) bit address
       for (b=type ? 8388608L : 32768L;b>=1L;b=b/2L) {
          bit = addr & b;
          if (bit) {
	       SET(d1_c0_s0);
               SET(d1_c1_s0);
          } else {
	       SET(d0_c0_s0);
               SET(d0_c1_s0);
          }
       }
    }

    for (n=0;n<write_count;n++) {
       for (b=128L;b>=1L;b=b/2L) {
          bit = data_out[n] & b;
          if (bit) {
	       SET(d1_c0_s0);
               SET(d1_c1_s0);
          } else {
	       SET(d0_c0_s0);
               SET(d0_c1_s0);
          }
       }
    }

    // count is num bytes to read
    for (n=0;n<read_count;n++) {
       // 8 bit data
       value = 0;
       for (b=128L;b>=1L;b=b/2L) {
	   SET(d0_c0_s0);
	   SET(d0_c1_s0);
           bit = PEEK(SPI_REG) & 1;
           if (bit)
	      value = value + b;
       }
       data_in[n] = value;
    }

    if (close) {
       SET(d0_c1_s0); // leave clock high before S high
       SET(d1_c1_s1); // drive S high again
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
    SET(d0_c0_s0);
    SET(d1_c1_s1);
}

// Read the flash device id bytes
void read_device(void) {
    // Some FPGAs leave the flash in a bad state.
    // Reset it first.
    if (type == DEVICE_TYPE_FLASH) {
      talk(0x66,
         0 /* withaddr */, 0,
	 0 /* read 2 */,
	 0 /* write 0 */,
	 1 /* close */);
      talk(0x99,
         0 /* withaddr */, 0,
	 0 /* read 2 */,
	 0 /* write 0 */,
	 1 /* close */);
    }
    // INSTR + 24 bit 0 + 2 READ BYTES + CLOSE
    talk(device_id_instr,
         1 /* withaddr */, 0,
	 type == DEVICE_TYPE_FLASH ? 2 : 3 /* read 2(flash) 3(eeprom) */,
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
    if (type != DEVICE_TYPE_FLASH)
       return;

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

   if (type != DEVICE_TYPE_FLASH)
      return 1;

   // Keep checking bit 2 for write busy flag.
   do { v = PEEK(SPI_REG); } while (v & 2);
   // Done? Return verify bit.
   return v & 4;
}

unsigned read_byte(unsigned long addr) {
    if (type != DEVICE_TYPE_EEPROM)
      return 1;

    // INSTR + 24 bit addr + 1 read byte + CLOSE
    talk(READ_INSTR,
	1 /* withaddr */, addr,
	1 /* read 1 */,
	0 /* write 0 */,
	1 /* close */);
    return data_in[0];
}

void write_byte(unsigned long addr, unsigned char value) {
   if (type != DEVICE_TYPE_EEPROM)
      return;

   wren();
   data_out[0] = value;
   talk(WRITE_INSTR,
        1 /* withaddr */, addr,
        0 /* read 0 */,
        1 /* write 1 */,
        1 /* close */);
   wait_busy();
}
