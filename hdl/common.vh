`ifndef common_vh_
`define common_vh_

`define VERSION_MAJOR 4'd0
`define VERSION_MINOR 4'd1

// DATA_DAV
//
// When to read from the data bus for both char/pixel and sprite dma
// in terms of phi_phase_start index.  This can't be changed without
// some serious rework of xpos, read delays in the pixel sequencer
// and many other timing values elsewhere. Zero value tells the bus
// access module to read data on the edge of phi as indicated
// by the datasheet. But we use a much earlier value for VICE
// simuation comparison.

// PIXEL_LATCH
//
// When to transfer char/pixel data into the final delayed register
// from the delay pipeline.  This is chosen so that the data
// in the final delay register is first available when load_pixels
// rises (xpos_mod_8 == 0)

`define DATA_DAV 0
`define DATA_DAV_PLUS_1 1
`define DATA_DAV_PLUS_2 2
`define M2CLR_CHECK 1
`define M2CLR_PHASE !clk_phi
`define SPRITE_CRUNCH_CYCLE_CHECK 15
`define PIXEL_LATCH 0

// Will never change but used in loops
`define NUM_SPRITES 8

// cycle_bit values for sprite pixels
`define SPRITE_PIXEL_0 2
`define SPRITE_PIXEL_1 3
`define SPRITE_PIXEL_2 4
`define SPRITE_PIXEL_3 5
`define SPRITE_PIXEL_4 6
`define SPRITE_PIXEL_5 7
`define SPRITE_PIXEL_6 0
`define SPRITE_PIXEL_7 1

// dot_rising values for pixel ticks
`define PIXEL_TICK_0 1
`define PIXEL_TICK_1 2
`define PIXEL_TICK_2 3
`define PIXEL_TICK_3 0

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

`define REG_UNUSED1                   6'h2F
`define REG_UNUSED2                   6'h30
`define REG_UNUSED3                   6'h31
`define REG_UNUSED4                   6'h32
`define REG_UNUSED5                   6'h33
`define REG_UNUSED6                   6'h34
`define REG_UNUSED7                   6'h35
`define REG_UNUSED8                   6'h36

// --- BEGIN EXTENSIONS ---
`define VIDEO_MEM_1_IDX               6'h35
`define VIDEO_MEM_2_IDX               6'h36
`define VIDEO_MODE1                   6'h37
`define VIDEO_MODE2                   6'h38
`define VIDEO_MEM_1_LO                6'h39
`define VIDEO_MEM_1_HI                6'h3A
`define VIDEO_MEM_1_VAL               6'h3B
`define VIDEO_MEM_2_LO                6'h3C
`define VIDEO_MEM_2_HI                6'h3D
`define VIDEO_MEM_2_VAL               6'h3E
`define VIDEO_MEM_FLAGS               6'h3F  // Extra Reg Activation Port

// For VIDEO_MODE_1
`define PALETTE_SELECT_BIT            3
`define HIRES_ENABLE                  4
`define HIRES_TEXT_BITMAP             5
`define HIRES_COLOR_2K_16K            6

`define EXT_REG_VIDEO_FREQ           8'h81
`define EXT_REG_CHIP_MODEL           8'h82
`define EXT_REG_VERSION              8'h83
`define EXT_REG_DISPLAY_FLAGS        8'h84

// Bits in display flags
`define SHOW_RASTER_LINES            0

`define EXT_REG_VARIANT_NAME1        8'h90
`define EXT_REG_VARIANT_NAME2        8'h91
`define EXT_REG_VARIANT_NAME3        8'h92
`define EXT_REG_VARIANT_NAME4        8'h93
`define EXT_REG_VARIANT_NAME5        8'h94
`define EXT_REG_VARIANT_NAME6        8'h95
`define EXT_REG_VARIANT_NAME7        8'h96
`define EXT_REG_VARIANT_NAME8        8'h97
`define EXT_REG_VARIANT_NAME9        8'h98
`define EXT_REG_VARIANT_NAME10       8'h99
`define EXT_REG_VARIANT_NAME11       8'h9a
`define EXT_REG_VARIANT_NAME12       8'h9b
`define EXT_REG_VARIANT_NAME13       8'h9c
`define EXT_REG_VARIANT_NAME14       8'h9d
`define EXT_REG_VARIANT_NAME15       8'h9e
`define EXT_REG_VARIANT_NAME16       8'h9f

`define VARIANT_NAME1   8'h4F  // O
`define VARIANT_NAME2   8'h46  // F
`define VARIANT_NAME3   8'h46  // F
`define VARIANT_NAME4   8'h49  // I
`define VARIANT_NAME5   8'h43  // C
`define VARIANT_NAME6   8'h49  // I
`define VARIANT_NAME7   8'h41  // A
`define VARIANT_NAME8   8'h4C  // L

// --- END EXTENSIONS ---

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
