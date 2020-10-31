`ifndef common_vh_
`define common_vh_

// Char/pixel read phi_phase_start data available
`define DATA_DAV 14
// Sprite read phi_phase_start data available
`define SPRITE_DAV 14
// How many dot ticks gfx data is delayed before it gets into the shifter
`define XPOS_GFX_DELAY_9BIT 9'd8
`define XPOS_GFX_DELAY_4BIT 4'd8
`define XPOS_GFX_DELAY_32BIT 32'd8
// How many dot ticks sprite data is delayed before entering sprite shifter
// Sprite pixels out of the shifter are delayed by 3 more pixels to align with gfx.
`define XPOS_SPRITE_DELAY 9'd5

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
