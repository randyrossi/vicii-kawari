# New Graphics Modes

Resolution | Type    | Format  | Colors | Palette | Memory  | Color Registers
-----------|---------|---------|--------|---------|---------|----------------
320x200    | Bitmap  | RGB323  | 256    | 256     | 64k     | None
320x200    | Bitmap  | Indexed | 256    | 4096    | 64k     | 256x3=768 4-bit
||||||
640x200    | Text    | 80x25   | 2      | 4096    | 2k      | 2x3=6 4-bit
640x200    | Text    | 80x25   | 16     | 4096    | 2k + 1k | 16x3=48 4-bit
640x200    | Bitmap  | Indexed | 16     | 4096    | 64k     | 16x3=48 4-bit
||||||
640x400    | Text    | 80x50   | 2      | 4096    | 4k      | 2x3=6 4-bit
640x400    | Text    | 80x50   | 16     | 4096    | 4k + 2K | 16x3=48 4-bit
640x400    | Bitmap  | Indexed | 4      | 4096    | 64k     | 4x3=12 4-bit
