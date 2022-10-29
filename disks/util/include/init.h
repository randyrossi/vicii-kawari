#ifndef INIT_H
#define INIT_H

#include "data.h"

// Display a message that the board needs to
// be initialized and wait for a key press.
// Returns 1 on successful initialization
int first_init(void);
void init(int isPal);

// Routines to apply default values with persistence
// to eeprom.
void set_rgb(void);
void set_lumas(unsigned int variant_num, int chip_model);
void set_phases(int chip_model);
void set_amplitudes(int chip_model);

#endif
