`ifndef common_vh_
`define common_vh_

typedef enum [1:0] { CHIP6567R8, CHIP6567R56A, CHIP6569, CHIPUNUSED} chip_type;

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
    VIC_HGI  = 12, // high phase, idle after g
    VIC_HI   = 13, // high phase, idle
    VIC_LI   = 14, // low phase, idle
    VIC_HRX  = 15  // high phase, cached-c-access after r
} vic_cycle;

`define TRUE	1'b1
`define FALSE	1'b0

`endif // common_vh_