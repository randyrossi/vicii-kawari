#include <6502.h>
#include <peekpoke.h>
#include <string.h>
#include <stdio.h>

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

int is_version_min(int major, int minor)
{
   int need;
   int have;
   unsigned char flag;

   flag = PEEK(53311L);
   POKE(53311L,32);
   have = get_version_major()*256+get_version_minor();
   need = major * 256 + minor;
   POKE (53311L,flag);
   return have >= need;
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

void get_variant(unsigned char *dest)
{
   int t=0;
   char v;
   while (t < 16) {
      POKE(VIDEO_MEM_1_LO,VARIANT+t);
      v = PEEK(VIDEO_MEM_1_VAL);
      if (v == 0) break;
      dest[t++] = v;
   }
   dest[t] = 0;
}

unsigned int ascii_variant_to_board_int(unsigned char *variant)
{
   if (strcmp(variant,"sim") == 0)
      return BOARD_SIM;

   if (strlen(variant) >= 4) {
      if (variant[4] == 0)
         return BOARD_REV_3T;
      if (variant[4] == 'l') {
         if (variant[5] == 'd')
            return BOARD_REV_4LD;
         if (variant[5] == 'h')
            return BOARD_REV_4LH;
         if (variant[5] == 'g')
             return BOARD_REV_4LG;
      }
   }
   return BOARD_UNKNOWN;
}

unsigned int get_flash_page_size(void) {
   char variant_str[32];
   unsigned int board_int;

   get_variant(variant_str);
   board_int = ascii_variant_to_board_int(variant_str);

   // The two spartan models have 16k flash page size
   if (board_int == BOARD_REV_4LD || board_int == BOARD_REV_3T)
      return 16384;
   else
      return 4096;
}

unsigned short get_capability_bits(void)
{
   unsigned char lo,hi;
   POKE(VIDEO_MEM_1_IDX, 0);
   POKE(VIDEO_MEM_1_LO, CAP_LO);
   lo = PEEK(VIDEO_MEM_1_VAL);
   POKE(VIDEO_MEM_1_LO, CAP_HI);
   hi = PEEK(VIDEO_MEM_1_VAL);
   return lo | (hi << 8);
}

// Added in v.0xfe to safely/smartly initialize newly added
// EEPROM locations from the flash program. If the current
// value > the flash program's value, then we initialize
// all fields added in every version until we reach the
// current value. (We count up because our version scheme
// works downward starting from 0xff as the first version.)
unsigned char get_cfg_version(void)
{
   POKE(VIDEO_MEM_1_IDX, 0);
   POKE(VIDEO_MEM_1_LO, CFG_VERSION);
   return PEEK(VIDEO_MEM_1_VAL);
}

// TODO: Turn this into a generic dialog some day
// For now, specific to selecting color presets and only for COMPED
#define MAX_CHOICES 3
int dialog(int board, int chip)
{
   struct regs r;
   char choice[42];
   int selection = 0;
   int ln = 10;
   int i;
   int key;
   int num_choices = 0;

   char *choices[MAX_CHOICES];
   switch (chip) {
      case CHIP6567R8:
         choices[num_choices] = "Longboard-Adrian's Digital Basement";
         break;
      case CHIP6569R3:
      case CHIP6567R56A:
      case CHIP6569R1:
         choices[num_choices] = "Longboard-Mark (TheRetroChannel)   ";
         break;
      default:
         choices[num_choices] = "Not available";
   }
   num_choices++;

   // For now, only Mini has lumacode
   if (board == BOARD_REV_4LH || board == BOARD_SIM) {
      choices[num_choices] = "Lumacode                           ";
      num_choices++;
   }

   choices[num_choices] = "Cancel                             ";
   num_choices++;
   

   TOXY(2,ln++);
   printf ("%c                                   %c  ",18,146);
   for (i=0;i<num_choices;i++) {
      TOXY(2,ln++);
      sprintf (choice,"%c%s%c", 18, choices[i],146);
      printf ("%s",choice);
   }
   TOXY(2,ln++);
   printf ("%c                                   %c  ",18,146);

   while (1) {
      // Show selected line
      POKE(646,6);
      TOXY(2,11+selection);
      sprintf (choice,"%c%s%c", 18, choices[selection],146);
      printf ("%s",choice);
      POKE(646,1);

      WAITKEY;
      key = r.a;

      // Unhilight current line
      POKE(646,1);
      TOXY(2,11+selection);
      sprintf (choice,"%c%s%c", 18, choices[selection],146);
      printf ("%s",choice);

      if (key == CRSR_DOWN) {
         selection++; if (selection >= num_choices) selection = num_choices-1;
      }
      else if (key == CRSR_UP) {
         selection--; if (selection < 0) selection = 0;
      }
      else if (key == 13) {
         break;
      }
   }

   // Last choice is always cancel
   if (selection == num_choices-1) selection = -1; // indicate cancel
   return selection;
}
