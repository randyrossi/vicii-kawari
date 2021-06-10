// Header for register_eeprom.v

// Every 64 ticks of state_ctr cycles through all 256
// EEPROM addresses and performs the operation as indicated
// by eeprom_state (READ, WRITE)
reg [14:0] state_ctr = 15'b0;

// clk_div divides dot4x by 4 to give us approx 8Mhz clock
// for EEPROM access.
reg [3:0] clk_div = 4'b0001;

// Register for an internal 8Mhz clock that is sometimes
// 'exported' to C
reg clk8 = 1'b1;

// Bits 13-6 represent the address in EEPROM we are reading
// (0-256) but we offset by -4 to start at 0xfc and end at
// 0xfb rather than 0x00-0xff.  This is so the first thing
// we read are the magic bytes.  If we don't find them within
// the first 4 reads, none of the data gets assigned to any
// registers. This prevents blank EEPROM from setting registers
// to garbage.
wire [5:0] state_val = state_ctr[5:0];

// We start at 0xfc so we read the magic bytes first
wire [7:0] addr_lo = state_ctr[13:6] - 8'd4;

reg [7:0] instr; // Instruction shift register
reg [15:0] addr; // Address shift register
reg [7:0] data; // Data shift reigster
reg [7:0] status; // Status shift reigster

reg [2:0] magic = 3'd0;

// Start off reading existing eeprom data
reg [1:0] eeprom_state = `EEPROM_READ;

// When in EEPROM_WRITE mode, what addr are we writing
// to? Use 0x100 for ALL.
reg [7:0] eeprom_w_addr = 8'd0;
reg [7:0] eeprom_w_value;
reg eeprom_busy = 1'b0;

`ifdef CMOD_BOARD
assign led[0] = magic == 4;  // indicates we successfully read magic bytes
assign led[1] = eeprom_state == `EEPROM_WRITE; // indicates our r/w mode
reg [7:0] wreg = 8'hfc;
`endif

`ifdef SIMULATOR_BOAD
reg test_init;
`endif
