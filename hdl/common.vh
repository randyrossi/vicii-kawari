`ifndef common_vh_
`define common_vh_

// DATA_DAV
//
// When to read from the data bus for both char/pixel and sprite dma
// in terms of phi_phase_start index.  This can't be changed without
// some serious rework of xpos, read delays in the pixel sequencer
// and many other timing values elsewhere. Zero value tells the bus
// access module to read data on the edge of phi as indicated
// by the datasheet. But we use a much earlier value for VICE
// simuation comparison.

// XSCROLL_LATCH
//
// This is the phi_phase_start_value used to 'pick up' xscroll changes
// but only during visible cycles.  Unless this is set right, xscroll
// won't be a pixel perfect match to VICE.  I don't think it's
// critical for behavior but it's good to be able to match VICE.
// (Use xscroll2.prg to verify).

// XPOS_BORDER_DELAY_9BIT
//
// This is an adjusted xpos we pass to the border module.
// The border logic xpos comparison values are taken from VICE
// and this adjustment is needed to trigger the logic
// correctly.

// XPOS_GFX_DELAY_9BIT
//
// This value -1 is how much we adjust xpos by before we give it
// to the pixel sequencer.  It is used to control the point
// at which xpos_mod_8 == 0.  A value of 1 here means no adjustment
// but if DATA_DAV changes, this must also change.

// XPOS_SPRITE_DELAY
//
// This value -1 is how much we adjust xpos by before we give it
// to the sprite module.  This delays the time at which sprite
// shifter starts due to a xpos match.  It is adjusted to make
// sprite pixels align with graphics.

`ifndef IS_SIMULATOR
// Real hardware values
`define DATA_DAV 0
`define XSCROLL_LATCH 0
`define XSCROLL_LATCH_PHASE clk_phi
`define BORDER_DELAY 11
`define SPRITE_CRUNCH_CYCLE_CHECK 15
`define M2CLR_CHECK 1
`define M2CLR_PHASE !clk_phi

`else

// Simlation values
`define DATA_DAV 12
`define XSCROLL_LATCH 0
`define XSCROLL_LATCH_PHASE clk_phi
`define BORDER_DELAY 11
`define SPRITE_CRUNCH_CYCLE_CHECK 14
`define M2CLR_CHECK 15
`define M2CLR_PHASE clk_phi

`endif

// Will never change but used in loops
`define NUM_SPRITES 8

// Chip types
`define CHIP6567R8   0
`define CHIP6569     1
`define CHIP6567R56A 2
`define CHIPUNUSED   3

// Cycle types
`define VIC_LP     0  // low phase, sprite pointer
`define VIC_LPI2   1  // low phase, sprite idle
`define VIC_LS2    2  // low phase, sprite dma byte 2
`define VIC_LR     3  // low phase, dram refresh
`define VIC_LG     4  // low phase, g-access
`define VIC_HS1    5  // high phase, sprite dma byte 1
`define VIC_HPI1   6  // high phase, sprite idle
`define VIC_HPI3   7  // high phase, sprite idle
`define VIC_HS3    8  // high phase, sprite dma byte 3
`define VIC_HRI    9  // high phase, refresh idle
`define VIC_HRC    10  // high phase, c-access after r
`define VIC_HGC    11  // high phase, c-access after g
`define VIC_HGI    12  // high phase, cached-c-access after g
`define VIC_HI     13  // high phase, idle
`define VIC_LI     14  // low phase, idle
`define VIC_HRX    15  // high phase, cached-c-access after r

`define TRUE	1'b1
`define FALSE	1'b0

// Colors
`define BLACK        4'd0
`define WHITE        4'd1
`define RED          4'd2
`define CYAN         4'd3
`define PURPLE       4'd4
`define GREEN        4'd5
`define BLUE         4'd6
`define YELLOW       4'd7
`define ORANGE       4'd8
`define BROWN        4'd9
`define PINK         4'd10
`define DARK_GREY    4'd11
`define GREY         4'd12
`define LIGHT_GREEN  4'd13
`define LIGHT_BLUE   4'd14
`define LIGHT_GREY   4'd15

// Registers
`define REG_SPRITE_X_0                6'h00
`define REG_SPRITE_Y_0                6'h01
`define REG_SPRITE_X_1                6'h02
`define REG_SPRITE_Y_1                6'h03
`define REG_SPRITE_X_2                6'h04
`define REG_SPRITE_Y_2                6'h05
`define REG_SPRITE_X_3                6'h06
`define REG_SPRITE_Y_3                6'h07
`define REG_SPRITE_X_4                6'h08
`define REG_SPRITE_Y_4                6'h09
`define REG_SPRITE_X_5                6'h0A
`define REG_SPRITE_Y_5                6'h0B
`define REG_SPRITE_X_6                6'h0C
`define REG_SPRITE_Y_6                6'h0D
`define REG_SPRITE_X_7                6'h0E
`define REG_SPRITE_Y_7                6'h0F
`define REG_SPRITE_X_BIT_8            6'h10
`define REG_SCREEN_CONTROL_1          6'h11
`define REG_RASTER_LINE               6'h12
`define REG_LIGHT_PEN_X               6'h13
`define REG_LIGHT_PEN_Y               6'h14
`define REG_SPRITE_ENABLE             6'h15
`define REG_SCREEN_CONTROL_2          6'h16
`define REG_SPRITE_EXPAND_Y           6'h17
`define REG_MEMORY_SETUP              6'h18
`define REG_INTERRUPT_STATUS          6'h19
`define REG_INTERRUPT_CONTROL         6'h1a
`define REG_SPRITE_PRIORITY           6'h1b
`define REG_SPRITE_MULTICOLOR_MODE    6'h1c
`define REG_SPRITE_EXPAND_X           6'h1d
`define REG_SPRITE_2_SPRITE_COLLISION 6'h1e
`define REG_SPRITE_2_DATA_COLLISION   6'h1f
`define REG_BORDER_COLOR              6'h20
`define REG_BACKGROUND_COLOR_0        6'h21
`define REG_BACKGROUND_COLOR_1        6'h22
`define REG_BACKGROUND_COLOR_2        6'h23
`define REG_BACKGROUND_COLOR_3        6'h24
`define REG_SPRITE_MULTI_COLOR_0      6'h25
`define REG_SPRITE_MULTI_COLOR_1      6'h26
`define REG_SPRITE_COLOR_0            6'h27
`define REG_SPRITE_COLOR_1            6'h28
`define REG_SPRITE_COLOR_2            6'h29
`define REG_SPRITE_COLOR_3            6'h2A
`define REG_SPRITE_COLOR_4            6'h2B
`define REG_SPRITE_COLOR_5            6'h2C
`define REG_SPRITE_COLOR_6            6'h2D
`define REG_SPRITE_COLOR_7            6'h2E

// Official video modes, source https://www.c64-wiki.com/wiki/Graphics_Modes
`define MODE_STANDARD_CHAR       3'b000
`define MODE_MULTICOLOR_CHAR     3'b001
`define MODE_STANDARD_BITMAP     3'b010
`define MODE_MULTICOLOR_BITMAP   3'b011
`define MODE_EXTENDED_BG_COLOR   3'b100
// "Illegal" invalid modes.
`define MODE_INV_EXTENDED_BG_COLOR_MULTICOLOR_CHAR     3'b101
`define MODE_INV_EXTENDED_BG_COLOR_STANDARD_BITMAP     3'b110
`define MODE_INV_EXTENDED_BG_COLOR_MULTICOLOR_BITMAP   3'b111

`endif // common_vh_
