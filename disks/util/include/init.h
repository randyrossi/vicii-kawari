#ifndef INIT_H
#define INIT_H

#include "data.h"

// Returns 1 on successful initialization
int first_init(void);

// Apply defaults
void set_lumas(unsigned int variant_num, int chip_model);
void set_phases(int chip_model);
void set_amplitudes(int chip_model);

#endif
