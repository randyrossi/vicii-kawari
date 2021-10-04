#include <6502.h>
#include <peekpoke.h>

#include "util.h"
#include "kawari.h"

int enable_kawari(void) {
    POKE(VIDEO_MEM_FLAGS, 86);
    POKE(VIDEO_MEM_FLAGS, 73);
    POKE(VIDEO_MEM_FLAGS, 67);
    POKE(VIDEO_MEM_FLAGS, 50);
    POKE(VIDEO_MEM_FLAGS, 0);
    // Zero out IDX regs
    POKE(VIDEO_MEM_1_IDX, 0);
    POKE(VIDEO_MEM_2_IDX, 0);
    return PEEK(VIDEO_MEM_FLAGS) == 0;
}

int have_magic(void) {
    int m1,m2,m3,m4;
    int chip;

    POKE(VIDEO_MEM_FLAGS, PEEK(VIDEO_MEM_FLAGS) | VMEM_FLAG_REGS_BIT);

    POKE(VIDEO_MEM_1_LO, MAGIC_0);
    m1 = PEEK(VIDEO_MEM_1_VAL);
    POKE(VIDEO_MEM_1_LO, MAGIC_1);
    m2 = PEEK(VIDEO_MEM_1_VAL);
    POKE(VIDEO_MEM_1_LO, MAGIC_2);
    m3 = PEEK(VIDEO_MEM_1_VAL);
    POKE(VIDEO_MEM_1_LO, MAGIC_3);
    m4 = PEEK(VIDEO_MEM_1_VAL);

    // Make sure eeprom bank matches current chip
    POKE(VIDEO_MEM_1_LO, CHIP_MODEL);
    chip = PEEK(VIDEO_MEM_1_VAL);
    POKE(VIDEO_MEM_1_LO, EEPROM_BANK);
    POKE(VIDEO_MEM_1_VAL, chip);

    return m1 == 86 && m2 == 73 && m3 == 67 && m4 == 50;
}

// Poll persist busy bit and don't perform poke
// until it is 0
void safe_poke(long addr, char value)
{
    while (PEEK(VIDEO_MEM_FLAGS) & 16) { }
    POKE(addr,value);
}

// Wait for either a key press or a change in
// the external switch state.  Returns '*' if
// swith state changed.
unsigned char wait_key_or_change(unsigned char current_switch_val,
                                 unsigned char current_lock_bits,
                                 unsigned char *new_switch_val,
                                 unsigned char *new_lock_bits)
{
    unsigned char inv; 
    unsigned char lb; 
    struct regs r;
    POKE(VIDEO_MEM_1_LO, DISPLAY_FLAGS);
    for(;;) {
        r.pc=0xF13E; _sys(&r);
	if (r.a != 0) return r.a;
        inv = PEEK(VIDEO_MEM_1_VAL) & DISPLAY_CHIP_INVERT_SWITCH;
        lb = get_lock_bits();
        if (current_switch_val != inv) {
            *new_switch_val = inv;
            return '*';
        }
        if (current_lock_bits != lb) {
            *new_lock_bits = lb;
            return '%';
        }
    }
}

unsigned char get_version_major(void)
{
   POKE(VIDEO_MEM_1_IDX, 0);
   POKE(VIDEO_MEM_2_IDX, 0);
   POKE(VIDEO_MEM_1_LO, VERSION_MAJOR);
   return PEEK(VIDEO_MEM_1_VAL);
}

unsigned char get_version_minor(void)
{
   POKE(VIDEO_MEM_1_IDX, 0);
   POKE(VIDEO_MEM_2_IDX, 0);
   POKE(VIDEO_MEM_1_LO, VERSION_MINOR);
   return PEEK(VIDEO_MEM_1_VAL);
}

unsigned char get_lock_bits(void)
{
   return PEEK(SPI_REG) & 56;
}

unsigned char get_chip_model(void)
{
   POKE(VIDEO_MEM_1_LO,CHIP_MODEL);
   return PEEK(VIDEO_MEM_1_VAL) & 3;
}
