#include "tests.h"
#include "macros.h"

#include <6502.h>
#include <peekpoke.h>
#include <kawari.h>
#include <util.h>
#include <stdio.h>

void save_screen(unsigned int dest)
{
  POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_DMA);

  // Vmem dest 
  POKE(VIDEO_MEM_1_LO, dest & 0xff);
  POKE(VIDEO_MEM_1_HI, (dest >> 8) & 0xff);

  // Screen mem src from DRAM
  POKE(VIDEO_MEM_2_LO, 0x00);
  POKE(VIDEO_MEM_2_HI, 0x04);

  // 1024 k
  POKE(VIDEO_MEM_1_IDX, 0x00);
  POKE(VIDEO_MEM_2_IDX, 0x04);

  POKE(VIDEO_MEM_1_VAL, DMA_DRAM_TO_VMEM);

  while (PEEK(VIDEO_MEM_2_IDX) != 0);
}

void restore_screen(unsigned int src)
{
  POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_DMA);

  // Dram dest @ 0x0400
  POKE(VIDEO_MEM_1_LO, 0x00);
  POKE(VIDEO_MEM_1_HI, 0x04);

  // Vmem src 
  POKE(VIDEO_MEM_2_LO, src & 0xff);
  POKE(VIDEO_MEM_2_HI, (src >> 8) & 0xff);

  // 1024 k
  POKE(VIDEO_MEM_1_IDX, 0x00);
  POKE(VIDEO_MEM_2_IDX, 0x04);

  POKE(VIDEO_MEM_1_VAL, DMA_VMEM_TO_DRAM);

  while (PEEK(VIDEO_MEM_2_IDX) != 0);
}

void clear_vmem(unsigned int loc) {
  unsigned int n;
  POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_AUTO_INC_1);
  POKE(VIDEO_MEM_1_IDX, 0);
  POKE(VIDEO_MEM_2_IDX, 0);

  POKE(VIDEO_MEM_1_LO, loc & 0xff);
  POKE(VIDEO_MEM_1_HI, (loc >> 8) & 0xff);
  for (n=0;n<1024;n++) {
    POKE(VIDEO_MEM_1_VAL, 0);
  }
}

void fill_vem(unsigned int loc) {
  unsigned int n;
  POKE(VIDEO_MEM_FLAGS, VMEM_FLAG_AUTO_INC_1);
  POKE(VIDEO_MEM_1_IDX, 0);
  POKE(VIDEO_MEM_2_IDX, 0);

  POKE(VIDEO_MEM_1_LO, loc & 0xff);
  POKE(VIDEO_MEM_1_HI, (loc >> 8) & 0xff);
  for (n=0;n<1024;n++) {
    POKE(VIDEO_MEM_1_VAL, n % 256);
  }
}

int check_vmem(unsigned int loc) {
  unsigned int n;
  POKE(VIDEO_MEM_FLAGS, 0);
  POKE(VIDEO_MEM_1_IDX, 0);
  POKE(VIDEO_MEM_2_IDX, 0);

  for (n=0;n<1024;n++) {
    POKE(VIDEO_MEM_1_LO, loc & 0xff);
    POKE(VIDEO_MEM_1_HI, (loc >> 8) & 0xff);
    if (PEEK(VIDEO_MEM_1_VAL) != n % 256) {
       printf ("CHECK VMEM FAILED @ %d\n", n);
       return 1;
    }
    loc++;
  }
  return 0;
}

void clear_screen(void) {
  // Screen @ 0x0400
  unsigned int screen = 0x400; 
  unsigned int n;
  for (n=0;n<25*40;n++) {
    POKE(screen + n, 0);
  }
}

void fill_screen(void) {
  // Screen @ 0x0400
  unsigned int screen = 0x400; 
  unsigned int n;
  // Fill past visible area.
  for (n=0;n<1024;n++) {
    POKE(screen + n, n % 256);
  }
}

int check_screen(void) {
  // Screen @ 0x0400
  unsigned int loc = 0x0400;
  unsigned int n;
  // Check past visible area
  for (n=0;n<1024;n++) {
    if (PEEK(loc + n) != n % 256) {
        printf ("CHECK SCREEN FAILED @ %d\n", n);
        return 1;
    }
  }
  return 0;
}

// Tests DMA between DRAM and VMEM (both dirs)
int dma(void)
{
  save_screen(0x0000);

  fill_screen();
  clear_vmem(0x1000);
  save_screen(0x1000);
  if (check_vmem(0x1000)) {
     return 1;
  }

  clear_screen();
  restore_screen(0x1000);
  if (check_screen()) {
     return 1;
  }

  restore_screen(0x0000);

  return 0;
}
