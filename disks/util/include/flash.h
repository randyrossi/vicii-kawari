#ifndef FLASH_H
#define FLASH_H

#include <6502.h>
#include <peekpoke.h>
#include <string.h>

#include "util.h"
#include "kawari.h"

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

#define SET(val) asm("lda #"STRINGIFY(val)); asm ("sta $d034");

#define DEVICE_ID_INSTR       0x90
#define READ_INSTR            0x03
#define WREN_INSTR            0x06
#define READ_STATUS1_INSTR    0x05
#define BLOCK_ERASE_4K_INSTR  0x20
#define WRITE_INSTR           0x02

extern unsigned char data_out[256];
extern unsigned char data_in[256];

// Helper to read 8 bits from SPI device
void read8(void);

// Generic routine to talk to SPI device
// 8-bit instruction
// optional 24 bit address
// write_count num bytes to write (from data[] array)
// read_count num bytes to read (into data[] array)
void talk(unsigned char instr,
          unsigned char with_addr, unsigned long addr,
	  unsigned int read_count, unsigned int write_count,
	  unsigned char close);

// Wait for flash device to be ready
void wait_busy(void);

// Read the flash device id bytes
void read_device(void);

void read_page(unsigned long addr);

void write_page(unsigned long addr);

// Write enable
void wren(void);

// Erase a 4k segment starting at addr
void erase_4k(unsigned long addr);

// Return > 0 on verify error.
unsigned wait_verify(void);

#endif
