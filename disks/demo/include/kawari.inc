; Bytes to enable VICII-Kawari extensions
CHAR_V = 86
CHAR_I = 73
CHAR_C = 67
CHAR_2 = 50

; Some VICII-Kawari registers
KAWARI_VMODE1 = $d037
KAWARI_VMODE2 = $d038

; Deprecated. Use KAWARI_MEM_FLAGS to match docs
KAWARI_PORT = $d03f

KAWARI_MEM_FLAGS = $d03f

KAWARI_VICSCN = $1000 ; screen ram in KAWARI space

; Kawari video memory port A regs
VMEM_A_IDX = $d035
VMEM_A_HI = $d03a
VMEM_A_LO = $d039
VMEM_A_VAL = $d03b

; Kawari video memory port B regs
VMEM_B_IDX = $d036
VMEM_B_HI = $d03d
VMEM_B_LO = $d03c
VMEM_B_VAL = $d03e

VMEM_FLAG_AUTO_INC_1=1
VMEM_FLAG_AUTO_DEC_1=2
VMEM_FLAG_AUTO_INC_2=4
VMEM_FLAG_AUTO_DEC_2=8
VMEM_FLAG_DMA=15
VMEM_FLAG_REGS_BIT=32
VMEM_FLAG_PERSIST_BIT=64
