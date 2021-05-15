/*=======================================================================================

 Parameters Definition for M95xxx process Behavioral Model

=========================================================================================

 This program is provided "as is" without warranty of any kind, either
 expressed or implied, including but not limited to, the implied warranty
 of merchantability and fitness for a particular purpose. The entire risk
 as to the quality and performance of the program is with you. Should the
 program prove defective, you assume the cost of all necessary servicing,
 repair or correction.
 
 Copyright 2001, STMicroelectronics Corporation, All Right Reserved.

=======================================================================================*/

`timescale 1ns/1ns

//////////////////////////////////////////////
`define DATA_BITS           8

`ifdef "M1Kb"
   `define VALID_PRT           1               //Valid Part
   `define MEM_SIZE            128             //1K bits = 128 bytes
   `define MEM_ADDR_BITS       7               //memory address bits
   `define PAGE_ADDR_BITS      3               //page address bits
   `define PAGES               8               //32 pages
   `define PAGE_SIZE           16              //16 bytes in each page
   `define PAGE_OFFSET_BITS    4               
`elsif "M2Kb"
   `define VALID_PRT           1               //Valid Part
   `define MEM_SIZE            256             //2K bits = 128 bytes
   `define MEM_ADDR_BITS       8               //memory address bits
   `define PAGE_ADDR_BITS      4               //page address bits
   `define PAGES               16              //16 pages
   `define PAGE_SIZE           16              //16 bytes in each page
   `define PAGE_OFFSET_BITS    4               
`elsif "M4Kb"
   `define VALID_PRT           1               //Valid Part
   `define MEM_SIZE            512             //4K bits = 512 bytes
   `define MEM_ADDR_BITS       9               //memory address bits
   `define PAGE_ADDR_BITS      5               //page address bits
   `define PAGES               32              //32 pages
   `define PAGE_SIZE           16              //16 bytes in each page
   `define PAGE_OFFSET_BITS    4               
`elsif "M8Kb"
   `define VALID_PRT           1               //Valid Part
   `define MEM_SIZE            1024            //8K bits = 1024 bytes
   `define MEM_ADDR_BITS       10              //memory address bits
   `define PAGE_ADDR_BITS      5               //page address bits
   `define PAGES               32              //32 pages
   `define PAGE_SIZE           32              //32 bytes in each page
   `define PAGE_OFFSET_BITS    5               
`elsif "M16Kb"
   `define VALID_PRT           1               //Valid Part
   `define MEM_SIZE            2048            //16K bits = 2048 bytes
   `define MEM_ADDR_BITS       11              //memory address bits
   `define PAGE_ADDR_BITS      6               //page address bits
   `define PAGES               64              //64 pages
   `define PAGE_SIZE           32              //32 bytes in each page
   `define PAGE_OFFSET_BITS    5               
`elsif "M32Kb"
    `define VALID_PRT           1               //Valid Part
    `define MEM_SIZE            4096            //32K bits = 4096 bytes
    `define MEM_ADDR_BITS       12              //memory address bits
    `define PAGE_ADDR_BITS      7               //page address bits
    `define PAGES               128             //128 pages
    `define PAGE_SIZE           32              //32 bytes in each page
    `define PAGE_OFFSET_BITS    5               
`elsif "M64Kb"
    `define VALID_PRT           1               //Valid Part
    `define MEM_SIZE            8192            //64K bits = 8192 bytes
    `define MEM_ADDR_BITS       13              //memory address bits
    `define PAGE_ADDR_BITS      8               //page address bits
    `define PAGES               256             //256 pages
    `define PAGE_SIZE           32              //32 bytes in each page
    `define PAGE_OFFSET_BITS    5     
`elsif "M128Kb"
   `define VALID_PRT           1               //Valid Part
   `define MEM_SIZE            16384           //128K bits = 16384 bytes
   `define MEM_ADDR_BITS       14              //memory address bits
   `define PAGE_ADDR_BITS      8               //page address bits
   `define PAGES               256             //256 pages
   `define PAGE_SIZE           64              //64 bytes in each page
   `define PAGE_OFFSET_BITS    6               
`elsif "M256Kb"
   `define VALID_PRT           1               //Valid Part
   `define MEM_SIZE            32768           //256K bits = 16384 bytes
   `define MEM_ADDR_BITS       15              //memory address bits
   `define PAGE_ADDR_BITS      9               //page address bits
   `define PAGES               512             //512 pages
   `define PAGE_SIZE           64              //64 bytes in each page
   `define PAGE_OFFSET_BITS    6                        
`elsif "M512Kb"
   `define VALID_PRT           1               //Valid Part
   `define MEM_SIZE            65536           //512K bits = 65536 bytes
   `define MEM_ADDR_BITS       16              //memory address bits
   `define PAGE_ADDR_BITS      9               //page address bits
   `define PAGES               512             //512 pages
   `define PAGE_SIZE           128             //128 bytes in each page
   `define PAGE_OFFSET_BITS    7               
`elsif "M1Mb"
   `define VALID_PRT           1               //Valid Part
   `define MEM_SIZE            131072          //1024K bits = 131072 bytes
   `define MEM_ADDR_BITS       17              //memory address bits
   `define PAGE_ADDR_BITS      9               //page address bits
   `define PAGES               512             //512 pages
   `define PAGE_SIZE           256             //256 bytes in each page
   `define PAGE_OFFSET_BITS    8               
`elsif "M2Mb"
   `define VALID_PRT           1               //Valid Part
   `define MEM_SIZE            262144          //2048K bits = 262144 bytes
   `define MEM_ADDR_BITS       18              //memory address bits
   `define PAGE_ADDR_BITS      10              //page address bits
   `define PAGES               1024            //1024 pages
   `define PAGE_SIZE           256             //256 bytes in each page
   `define PAGE_OFFSET_BITS    8               
`else
   `define VALID_PRT           0               //Valid Part
   `define MEM_SIZE            65536           //512K bits = 65536 bytes
   `define MEM_ADDR_BITS       16              //memory address bits
   `define PAGE_ADDR_BITS      9               //page address bits
   `define PAGES               512             //512 pages
   `define PAGE_SIZE           128             //128 bytes in each page
   `define PAGE_OFFSET_BITS    7               
`endif  


`ifdef "M1Kb"
   `define M1Kb_var               1             
   `define M2Kb_var               0
   `define M4Kb_var               0
   `define M8Kb_var               0
   `define M16Kb_var              0
   `define M32Kb_var              0
   `define M64Kb_var              0
   `define M128Kb_var             0
   `define M256Kb_var             0
   `define M512Kb_var             0
   `define M1Mb_var               0
   `define M2Mb_var               0
`elsif "M2Kb"
   `define M1Kb_var               0             
   `define M2Kb_var               1
   `define M4Kb_var               0
   `define M8Kb_var               0
   `define M16Kb_var              0
   `define M32Kb_var              0
   `define M64Kb_var              0
   `define M128Kb_var             0
   `define M256Kb_var             0
   `define M512Kb_var             0
   `define M1Mb_var               0
   `define M2Mb_var               0
`elsif "M4Kb"
   `define M1Kb_var               0             
   `define M2Kb_var               0
   `define M4Kb_var               1
   `define M8Kb_var               0
   `define M16Kb_var              0
   `define M32Kb_var              0
   `define M64Kb_var              0
   `define M128Kb_var             0
   `define M256Kb_var             0
   `define M512Kb_var             0
   `define M1Mb_var               0
   `define M2Mb_var               0
`elsif "M8Kb"
   `define M1Kb_var               0             
   `define M2Kb_var               0
   `define M4Kb_var               0
   `define M8Kb_var               1
   `define M16Kb_var              0
   `define M32Kb_var              0
   `define M64Kb_var              0
   `define M128Kb_var             0
   `define M256Kb_var             0
   `define M512Kb_var             0
   `define M1Mb_var               0
   `define M2Mb_var               0
`elsif "M16Kb"
   `define M1Kb_var               0             
   `define M2Kb_var               0
   `define M4Kb_var               0
   `define M8Kb_var               0
   `define M16Kb_var              1
   `define M32Kb_var              0
   `define M64Kb_var              0
   `define M128Kb_var             0
   `define M256Kb_var             0
   `define M512Kb_var             0
   `define M1Mb_var               0
   `define M2Mb_var               0
`elsif "M32Kb"
   `define M1Kb_var               0             
   `define M2Kb_var               0
   `define M4Kb_var               0
   `define M8Kb_var               0
   `define M16Kb_var              0
   `define M32Kb_var              1
   `define M64Kb_var              0
   `define M128Kb_var             0
   `define M256Kb_var             0
   `define M512Kb_var             0
   `define M1Mb_var               0
   `define M2Mb_var               0
`elsif "M64Kb"
   `define M1Kb_var               0             
   `define M2Kb_var               0
   `define M4Kb_var               0
   `define M8Kb_var               0
   `define M16Kb_var              0
   `define M32Kb_var              0
   `define M64Kb_var              1
   `define M128Kb_var             0
   `define M256Kb_var             0
   `define M512Kb_var             0
   `define M1Mb_var               0
   `define M2Mb_var               0
`elsif "M128Kb"
   `define M1Kb_var               0             
   `define M2Kb_var               0
   `define M4Kb_var               0
   `define M8Kb_var               0
   `define M16Kb_var              0
   `define M32Kb_var              0
   `define M64Kb_var              0
   `define M128Kb_var             1
   `define M256Kb_var             0
   `define M512Kb_var             0
   `define M1Mb_var               0
   `define M2Mb_var               0
`elsif "M256Kb"
   `define M1Kb_var               0             
   `define M2Kb_var               0
   `define M4Kb_var               0
   `define M8Kb_var               0
   `define M16Kb_var              0
   `define M32Kb_var              0
   `define M64Kb_var              0
   `define M128Kb_var             0
   `define M256Kb_var             1
   `define M512Kb_var             0
   `define M1Mb_var               0
   `define M2Mb_var               0
`elsif "M512Kb"
   `define M1Kb_var               0             
   `define M2Kb_var               0
   `define M4Kb_var               0
   `define M8Kb_var               0
   `define M16Kb_var              0
   `define M32Kb_var              0
   `define M64Kb_var              0
   `define M128Kb_var             0
   `define M256Kb_var             0
   `define M512Kb_var             1
   `define M1Mb_var               0
   `define M2Mb_var               0
`elsif "M1Mb"
   `define M1Kb_var               0            
   `define M2Kb_var               0
   `define M4Kb_var               0
   `define M8Kb_var               0
   `define M16Kb_var              0
   `define M32Kb_var              0
   `define M64Kb_var              0
   `define M128Kb_var             0
   `define M256Kb_var             0
   `define M512Kb_var             0
   `define M1Mb_var               1
   `define M2Mb_var               0
`elsif "M2Mb"
   `define M1Kb_var               0             
   `define M2Kb_var               0
   `define M4Kb_var               0
   `define M8Kb_var               0
   `define M16Kb_var              0
   `define M32Kb_var              0
   `define M64Kb_var              0
   `define M128Kb_var             0
   `define M256Kb_var             0
   `define M512Kb_var             0
   `define M1Mb_var               0
   `define M2Mb_var               1
`else
   `define M1Kb_var               0             
   `define M2Kb_var               0
   `define M4Kb_var               0
   `define M8Kb_var               0
   `define M16Kb_var              0
   `define M32Kb_var              0
   `define M64Kb_var              0
   `define M128Kb_var             0
   `define M256Kb_var             0
   `define M512Kb_var             0
   `define M1Mb_var               0
   `define M2Mb_var               0
`endif  

`ifdef "W"
   `define W_var                  1
   `define R_var                  0
   `define F_var                  0
`elsif "R"
   `define W_var                  0
   `define R_var                  1
   `define F_var                  0
`elsif "F"
   `define W_var                  0
   `define R_var                  0
   `define F_var                  1
`else
   `define W_var                  0
   `define R_var                  0
   `define F_var                  0
`endif

`ifdef "A125"
   `define A125_var               1
   `define A145_var               0
`elsif "A145"
   `define A125_var               0
   `define A145_var               1
`else
   `define A125_var               0
   `define A145_var               0
`endif

`ifdef "S125"
   `define S125_var                1
`else
   `define S125_var                0
`endif

`ifdef "ID"
   `define IDPAGE           1
`elsif "A125"
   `define IDPAGE           1
`elsif "A145"
   `define IDPAGE           1
`else
   `define IDPAGE           0
`endif

