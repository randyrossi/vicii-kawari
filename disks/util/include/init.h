#define DEFAULT_BLANKING_LEVEL 12
#define DEFAULT_BURST_AMPLITUDE 12
#define DEFAULT_DISPLAY_FLAGS 0

// Returns 1 on successful initialization
int first_init(void);

// Apply defaults
void set_lumas(int chip_model);
void set_phases(int chip_model);
void set_amplitudes(int chip_model);

