`ifndef common_vh_
`define common_vh_

// Register write phi_phase_start data available
`define REG_DAV 7
// Char/pixel read phi_phase_start data available
`define DATA_DAV 13
// Sprite read phi_phase_start data available
`define SPRITE_DAV 13
// How many dot ticks gfx data is delayed before it gets into the shifter
`define XPOS_GFX_DELAY 8
// How many dot ticks sprite data is delayed before entering sprite shifter
// Sprite pixels out of the shifter are delayed by 3 more pixels to align with gfx.
`define XPOS_SPRITE_DELAY 5

// Will never change but used in loops
`define NUM_SPRITES 8

typedef enum bit[1:0] {
            CHIP6567R8,
            CHIP6569,
            CHIP6567R56A,
            CHIPUNUSED
        } chip_type;

// Cycle types
typedef enum bit[3:0] {
            VIC_LP   = 0, // low phase, sprite pointer
            VIC_LPI2 = 1, // low phase, sprite idle
            VIC_LS2  = 2, // low phase, sprite dma byte 2
            VIC_LR   = 3, // low phase, dram refresh
            VIC_LG   = 4, // low phase, g-access
            VIC_HS1  = 5, // high phase, sprite dma byte 1
            VIC_HPI1 = 6, // high phase, sprite idle
            VIC_HPI3 = 7, // high phase, sprite idle
            VIC_HS3  = 8, // high phase, sprite dma byte 3
            VIC_HRI  = 9, // high phase, refresh idle
            VIC_HRC  = 10, // high phase, c-access after r
            VIC_HGC  = 11, // high phase, c-access after g
            VIC_HGI  = 12, // high phase, cached-c-access after g
            VIC_HI   = 13, // high phase, idle
            VIC_LI   = 14, // low phase, idle
            VIC_HRX  = 15  // high phase, cached-c-access after r
        } vic_cycle;

`define TRUE	1'b1
`define FALSE	1'b0

typedef enum bit[3:0] {
            BLACK, WHITE, RED, CYAN, PURPLE, GREEN, BLUE, YELLOW, ORANGE,
            BROWN, PINK, DARK_GREY, GREY, LIGHT_GREEN, LIGHT_BLUE, LIGHT_GREY
        } vic_color;

// Registers
typedef enum bit[5:0]  {
            REG_SPRITE_X_0 = 6'h00,
            REG_SPRITE_Y_0 = 6'h01,
            REG_SPRITE_X_1 = 6'h02,
            REG_SPRITE_Y_1 = 6'h03,
            REG_SPRITE_X_2 = 6'h04,
            REG_SPRITE_Y_2 = 6'h05,
            REG_SPRITE_X_3 = 6'h06,
            REG_SPRITE_Y_3 = 6'h07,
            REG_SPRITE_X_4 = 6'h08,
            REG_SPRITE_Y_4 = 6'h09,
            REG_SPRITE_X_5 = 6'h0A,
            REG_SPRITE_Y_5 = 6'h0B,
            REG_SPRITE_X_6 = 6'h0C,
            REG_SPRITE_Y_6 = 6'h0D,
            REG_SPRITE_X_7 = 6'h0E,
            REG_SPRITE_Y_7 = 6'h0F,
            REG_SPRITE_X_BIT_8 = 6'h10,
            REG_SCREEN_CONTROL_1 = 6'h11,
            REG_RASTER_LINE = 6'h12,
            REG_LIGHT_PEN_X = 6'h13,
            REG_LIGHT_PEN_Y = 6'h14,
            REG_SPRITE_ENABLE = 6'h15,
            REG_SCREEN_CONTROL_2 = 6'h16,
            REG_SPRITE_EXPAND_Y = 6'h17,
            REG_MEMORY_SETUP = 6'h18,
            REG_INTERRUPT_STATUS = 6'h19,
            REG_INTERRUPT_CONTROL = 6'h1a,
            REG_SPRITE_PRIORITY = 6'h1b,
            REG_SPRITE_MULTICOLOR_MODE = 6'h1c,
            REG_SPRITE_EXPAND_X = 6'h1d,
            REG_SPRITE_2_SPRITE_COLLISION = 6'h1e,
            REG_SPRITE_2_DATA_COLLISION = 6'h1f,
            REG_BORDER_COLOR = 6'h20,
            REG_BACKGROUND_COLOR_0 = 6'h21,
            REG_BACKGROUND_COLOR_1 = 6'h22,
            REG_BACKGROUND_COLOR_2 = 6'h23,
            REG_BACKGROUND_COLOR_3 = 6'h24,
            REG_SPRITE_MULTI_COLOR_0 = 6'h25,
            REG_SPRITE_MULTI_COLOR_1 = 6'h26,
            REG_SPRITE_COLOR_0 = 6'h27,
            REG_SPRITE_COLOR_1 = 6'h28,
            REG_SPRITE_COLOR_2 = 6'h29,
            REG_SPRITE_COLOR_3 = 6'h2A,
            REG_SPRITE_COLOR_4 = 6'h2B,
            REG_SPRITE_COLOR_5 = 6'h2C,
            REG_SPRITE_COLOR_6 = 6'h2D,
            REG_SPRITE_COLOR_7 = 6'h2E
        } vicii_register;

// Official video modes, source https://www.c64-wiki.com/wiki/Graphics_Modes
typedef enum bit[2:0] {
            MODE_STANDARD_CHAR = 3'b000,
            MODE_MULTICOLOR_CHAR = 3'b001,
            MODE_STANDARD_BITMAP = 3'b010,
            MODE_MULTICOLOR_BITMAP = 3'b011,
            MODE_EXTENDED_BG_COLOR = 3'b100,

            // "Illegal" invalid modes.
            MODE_INV_EXTENDED_BG_COLOR_MULTICOLOR_CHAR = 3'b101,
            MODE_INV_EXTENDED_BG_COLOR_STANDARD_BITMAP = 3'b110,
            MODE_INV_EXTENDED_BG_COLOR_MULTICOLOR_BITMAP = 3'b111
        } vicii_video_mode;

`endif // common_vh_
