#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <getopt.h>
#include <ctype.h>
#include <errno.h>

#include "asm64.h"

#define OPTS       "x:D:p:vh?"

#define END        "zzz"

#define DEF(a)     { a, {
#define EDEF       { -1, -1 } } },

#define OPER_FLAG  0x10000000
#define OPER(a)    (a | OPER_FLAG)

symtable sym[]=
{
  DEF("aax")
    { M_ZP,    0x87, P02X },
    { M_ZPY,   0x97, P02X },
    { M_ABS,   0x8f, P02X },
    { M_ZPIX,  0x83, P02X },
    { M_ZPIY,  0x93, P02X },
  EDEF

  DEF("adc")
    { M_IMM,   0x69, P02 },
    { M_IMML,  0x69, P816 },
    { M_ZP,    0x65, P02 },
    { M_ZPX,   0x75, P02 },
    { M_ABS,   0x6d, P02 },
    { M_ABSX,  0x7d, P02 },
    { M_ABSY,  0x79, P02 },
    { M_LONG,  0x6f, P816 },
    { M_LONGX, 0x7f, P816 },
    { M_ZPI,   0x72, P816 },
    { M_ZPIX,  0x61, P02 },
    { M_ZPIY,  0x71, P02 },
    { M_ZPIL,  0x67, P816 },
    { M_ZPILY, 0x77, P816 },
    { M_SR,    0x63, P816 },
    { M_SRIY,  0x73, P816 },
  EDEF

  DEF("ama")
    { M_IMM,   0xab, P02X },
  EDEF

  DEF("ana")
    { M_IMM,   0x0b, P02X },
  EDEF

  DEF("and")
    { M_IMM,   0x29, P02 },
    { M_IMML,  0x29, P816 },
    { M_ZP,    0x25, P02 },
    { M_ZPX,   0x35, P02 },
    { M_ABS,   0x2d, P02 },
    { M_ABSX,  0x3d, P02 },
    { M_ABSY,  0x39, P02 },
    { M_LONG,  0x2f, P816 },
    { M_LONGX, 0x3f, P816 },
    { M_ZPI,   0x32, P816 },
    { M_ZPIX,  0x21, P02 },
    { M_ZPIY,  0x31, P02 },
    { M_ZPIL,  0x27, P816 },
    { M_ZPILY, 0x37, P816 },
    { M_SR,    0x23, P816 },
    { M_SRIY,  0x33, P816 },
  EDEF

  DEF("asl")
    { M_ZP,    0x06, P02 },
    { M_ZPX,   0x16, P02 },
    { M_ABS,   0x0e, P02 },
    { M_ABSX,  0x1e, P02 },
    { M_IMP,   0x0a, P02 },
  EDEF

  DEF("axm")
    { M_IMM,   0xcb, P02X },
  EDEF

  DEF("axs")
    { M_ABSY,  0x9b, P02X },
  EDEF

  DEF("bcc")
    { M_REL,   0x90, P02 },
  EDEF

  DEF("bcs")
    { M_REL,   0xb0, P02 },
  EDEF

  DEF("beq")
    { M_REL,   0xf0, P02 },
  EDEF

  DEF("bit")
    { M_IMM,   0x89, P816 },
    { M_IMML,  0x89, P816 },
    { M_ZP,    0x24, P02 },
    { M_ZPX,   0x34, P816 },
    { M_ABS,   0x2c, P02 },
    { M_ABSX,  0x3c, P816 },
  EDEF

  DEF("bmi")
    { M_REL,   0x30, P02 },
  EDEF

  DEF("bne")
    { M_REL,   0xd0, P02 },
  EDEF

  DEF("bpl")
    { M_REL,   0x10, P02 },
  EDEF

  DEF("bra")
    { M_REL,   0x80, P816 },
  EDEF

  DEF("brk")
    { M_IMP,   0x00, P02 },
  EDEF

  DEF("brl")
    { M_RELL,  0x82, P816 },
  EDEF

  DEF("bvc")
    { M_REL,   0x50, P02 },
  EDEF

  DEF("bvs")
    { M_REL,   0x70, P02 },
  EDEF

  DEF("clc")
    { M_IMP,   0x18, P02 },
  EDEF

  DEF("cld")
    { M_IMP,   0xd8, P02 },
  EDEF

  DEF("cli")
    { M_IMP,   0x58, P02 },
  EDEF

  DEF("clp")
    { M_IMM,   0xc2, P816 },
  EDEF

  DEF("clr")
    { M_ZP,    0x64, P816 },
    { M_ZPX,   0x74, P816 },
    { M_ABS,   0x9c, P816 },
    { M_ABSX,  0x9e, P816 },
  EDEF

  DEF("clv")
    { M_IMP,   0xb8, P02 },
  EDEF

  DEF("cmp")
    { M_IMM,   0xc9, P02 },
    { M_IMML,  0xc9, P816 },
    { M_ZP,    0xc5, P02 },
    { M_ZPX,   0xd5, P02 },
    { M_ABS,   0xcd, P02 },
    { M_ABSX,  0xdd, P02 },
    { M_ABSY,  0xd9, P02 },
    { M_LONG,  0xcf, P816 },
    { M_LONGX, 0xdf, P816 },
    { M_ZPI,   0xd2, P816 },
    { M_ZPIX,  0xc1, P02 },
    { M_ZPIY,  0xd1, P02 },
    { M_ZPIL,  0xc7, P816 },
    { M_ZPILY, 0xd7, P816 },
    { M_SR,    0xc3, P816 },
    { M_SRIY,  0xd3, P816 },
  EDEF

  DEF("cop")
    { M_IMM,   0x02, P816 },
  EDEF

  DEF("cpx")
    { M_IMM,   0xe0, P02 },
    { M_IMML,  0xe0, P816 },
    { M_ZP,    0xe4, P02 },
    { M_ABS,   0xec, P02 },
  EDEF

  DEF("cpy")
    { M_IMM,   0xc0, P02 },
    { M_IMML,  0xc0, P816 },
    { M_ZP,    0xc4, P02 },
    { M_ABS,   0xcc, P02 },
  EDEF

  DEF("csp")
    { M_IMM,   0x02, P816 },
  EDEF

  DEF("dcp")
    { M_ZP,    0xc7, P02X },
    { M_ZPX,   0xd7, P02X },
    { M_ZPIX,  0xc3, P02X },
    { M_ZPIY,  0xd3, P02X },
    { M_ABS,   0xcf, P02X },
    { M_ABSX,  0xdf, P02X },
    { M_ABSY,  0xdb, P02X },
  EDEF

  DEF("dec")
    { M_IMP,   0x3a, P816 },
    { M_ZP,    0xc6, P02 },
    { M_ZPX,   0xd6, P02 },
    { M_ABS,   0xce, P02 },
    { M_ABSX,  0xde, P02 },
  EDEF

  DEF("dex")
    { M_IMP,   0xca, P02 },
  EDEF

  DEF("dey")
    { M_IMP,   0x88, P02 },
  EDEF

  DEF("eor")
    { M_IMM,   0x49, P02 },
    { M_IMML,  0x49, P816 },
    { M_ZP,    0x45, P02 },
    { M_ZPX,   0x55, P02 },
    { M_ABS,   0x4d, P02 },
    { M_ABSX,  0x5d, P02 },
    { M_ABSY,  0x59, P02 },
    { M_LONG,  0x4f, P816 },
    { M_LONGX, 0x5f, P816 },
    { M_ZPI,   0x52, P816 },
    { M_ZPIX,  0x41, P02 },
    { M_ZPIY,  0x51, P02 },
    { M_ZPIL,  0x47, P816 },
    { M_ZPILY, 0x57, P816 },
    { M_SR,    0x43, P816 },
    { M_SRIY,  0x53, P816 },
  EDEF

  DEF("hlt")
    { M_IMP,   0xdb, P816 },
  EDEF

  DEF("inc")
    { M_IMP,   0x1a, P816 },
    { M_ZP,    0xe6, P02 },
    { M_ZPX,   0xf6, P02 },
    { M_ABS,   0xee, P02 },
    { M_ABSX,  0xfe, P02 },
  EDEF

  DEF("inx")
    { M_IMP,   0xe8, P02 },
  EDEF

  DEF("iny")
    { M_IMP,   0xc8, P02 },
  EDEF

  DEF("isb")
    { M_ZP,    0xe7, P02X },
    { M_ZPX,   0xf7, P02X },
    { M_ZPIX,  0xe3, P02X },
    { M_ZPIY,  0xf3, P02X },
    { M_ABS,   0xef, P02X },
    { M_ABSX,  0xff, P02X },
    { M_ABSY,  0xfb, P02X },
  EDEF

  DEF("jmp")
    { M_ABS,   0x4c, P02 },
    { M_ABSI,  0x6c, P02 },
    { M_ABSIX, 0x7c, P816 },
    { M_ABSIL, 0xdc, P816 },
    { M_LONG,  0x5c, P816 },
  EDEF

  DEF("jsr")
    { M_ABS,   0x20, P02 },
    { M_ABSIX, 0xfc, P816 },
    { M_LONG,  0x22, P816 },
  EDEF

  DEF("lan")
    { M_ZP,    0x27, P02X },
    { M_ZPX,   0x37, P02X },
    { M_ZPIX,  0x23, P02X },
    { M_ZPIY,  0x33, P02X },
    { M_ABS,   0x2f, P02X },
    { M_ABSX,  0x3f, P02X },
    { M_ABSY,  0x3b, P02X },
  EDEF

  DEF("las")
    { M_ABSY,  0xbb, P02X },
  EDEF

  DEF("lax")
    { M_ZP,    0xa7, P02X },
    { M_ZPX,   0xb7, P02X },
    { M_ZPIX,  0xa3, P02X },
    { M_ZPIY,  0xb3, P02X },
    { M_ABS,   0xaf, P02X },
    { M_ABSY,  0xbb, P02X },
  EDEF

  DEF("lda")
    { M_IMM,   0xa9, P02 },
    { M_IMML,  0xa9, P816 },
    { M_ZP,    0xa5, P02 },
    { M_ZPX,   0xb5, P02 },
    { M_ABS,   0xad, P02 },
    { M_ABSX,  0xbd, P02 },
    { M_ABSY,  0xb9, P02 },
    { M_LONG,  0xaf, P816 },
    { M_LONGX, 0xbf, P816 },
    { M_ZPI,   0xb2, P816 },
    { M_ZPIX,  0xa1, P02 },
    { M_ZPIY,  0xb1, P02 },
    { M_ZPIL,  0xa7, P816 },
    { M_ZPILY, 0xb7, P816 },
    { M_SR,    0xa3, P816 },
    { M_SRIY,  0xb3, P816 },
  EDEF

  DEF("ldx")
    { M_IMM,   0xa2, P02 },
    { M_IMML,  0xa2, P816 },
    { M_ZP,    0xa6, P02 },
    { M_ZPY,   0xb6, P02 },
    { M_ABS,   0xae, P02 },
    { M_ABSY,  0xbe, P02 },
  EDEF

  DEF("ldy")
    { M_IMM,   0xa0, P02 },
    { M_IMML,  0xa0, P816 },
    { M_ZP,    0xa4, P02 },
    { M_ZPX,   0xb4, P02 },
    { M_ABS,   0xac, P02 },
    { M_ABSX,  0xbc, P02 },
  EDEF

  DEF("lor")
    { M_ZP,    0x07, P02X },
    { M_ZPX,   0x17, P02X },
    { M_ZPIX,  0x03, P02X },
    { M_ZPIY,  0x13, P02X },
    { M_ABS,   0x0f, P02X },
    { M_ABSX,  0x1f, P02X },
    { M_ABSY,  0x1b, P02X },
  EDEF

  DEF("lsr")
    { M_ZP,    0x46, P02 },
    { M_ZPX,   0x56, P02 },
    { M_ABS,   0x4e, P02 },
    { M_ABSX,  0x5e, P02 },
    { M_IMP,   0x4a, P02 },
  EDEF

  DEF("mvn")
    { M_IMP,   0x54, P816 },
  EDEF

  DEF("mvp")
    { M_IMP,   0x44, P816 },
  EDEF

  DEF("nop")
    { M_IMP,   0xea, P02 },
  EDEF

  DEF("ora")
    { M_IMM,   0x09, P02 },
    { M_IMML,  0x09, P816 },
    { M_ZP,    0x05, P02 },
    { M_ZPX,   0x15, P02 },
    { M_ABS,   0x0d, P02 },
    { M_ABSX,  0x1d, P02 },
    { M_ABSY,  0x19, P02 },
    { M_LONG,  0x0f, P816 },
    { M_LONGX, 0x1f, P816 },
    { M_ZPI,   0x12, P816 },
    { M_ZPIX,  0x01, P02 },
    { M_ZPIY,  0x11, P02 },
    { M_ZPIL,  0x07, P816 },
    { M_ZPILY, 0x17, P816 },
    { M_SR,    0x03, P816 },
    { M_SRIY,  0x13, P816 },
  EDEF

  DEF("pea")
    { M_IMP,   0xf4, P816 },
  EDEF

  DEF("pei")
    { M_IMP,   0xd4, P816 },
  EDEF

  DEF("per")
    { M_IMP,   0x62, P816 },
  EDEF

  DEF("pha")
    { M_IMP,   0x48, P02 },
  EDEF

  DEF("phb")
    { M_IMP,   0x8b, P816 },
  EDEF

  DEF("phd")
    { M_IMP,   0x0b, P816 },
  EDEF

  DEF("phk")
    { M_IMP,   0x4b, P816 },
  EDEF

  DEF("php")
    { M_IMP,   0x08, P02 },
  EDEF

  DEF("phx")
    { M_IMP,   0xda, P816 },
  EDEF

  DEF("phy")
    { M_IMP,   0x5a, P816 },
  EDEF

  DEF("pla")
    { M_IMP,   0x68, P02 },
  EDEF

  DEF("plb")
    { M_IMP,   0xab, P816 },
  EDEF

  DEF("pld")
    { M_IMP,   0x2b, P816 },
  EDEF

  DEF("plp")
    { M_IMP,   0x28, P02 },
  EDEF

  DEF("plx")
    { M_IMP,   0xfa, P816 },
  EDEF

  DEF("ply")
    { M_IMP,   0x7a, P816 },
  EDEF

  DEF("rad")
    { M_ZP,    0x67, P02X },
    { M_ZPX,   0x77, P02X },
    { M_ZPIX,  0x63, P02X },
    { M_ZPIY,  0x73, P02X },
    { M_ABS,   0x6f, P02X },
    { M_ABSX,  0x7f, P02X },
    { M_ABSY,  0x7b, P02X },
  EDEF

  DEF("ram")
    { M_IMM,   0x6b, P02X },
  EDEF

  DEF("rbm")
    { M_IMM,   0x4b, P02X },
  EDEF

  DEF("reo")
    { M_ZP,    0x47, P02X },
    { M_ZPX,   0x57, P02X },
    { M_ZPIX,  0x43, P02X },
    { M_ZPIY,  0x53, P02X },
    { M_ABS,   0x4f, P02X },
    { M_ABSX,  0x5f, P02X },
    { M_ABSY,  0x5b, P02X },
  EDEF

  DEF("rep")
    { M_IMM,   0xc2, P816 },
  EDEF

  DEF("rol")
    { M_ZP,    0x26, P02 },
    { M_ZPX,   0x36, P02 },
    { M_ABS,   0x2e, P02 },
    { M_ABSX,  0x3e, P02 },
    { M_IMP,   0x2a, P02 },
  EDEF

  DEF("ror")
    { M_ZP,    0x66, P02 },
    { M_ZPX,   0x76, P02 },
    { M_ABS,   0x6e, P02 },
    { M_ABSX,  0x7e, P02 },
    { M_IMP,   0x6a, P02 },
  EDEF

  DEF("rti")
    { M_IMP,   0x40, P02 },
  EDEF

  DEF("rtl")
    { M_IMP,   0x6b, P816 },
  EDEF

  DEF("rts")
    { M_IMP,   0x60, P02 },
  EDEF

  DEF("sbc")
    { M_IMM,   0xe9, P02 },
    { M_IMML,  0xe9, P816 },
    { M_ZP,    0xe5, P02 },
    { M_ZPX,   0xf5, P02 },
    { M_ABS,   0xed, P02 },
    { M_ABSX,  0xfd, P02 },
    { M_ABSY,  0xf9, P02 },
    { M_LONG,  0xef, P816 },
    { M_LONGX, 0xff, P816 },
    { M_ZPI,   0xf2, P816 },
    { M_ZPIX,  0xe1, P02 },
    { M_ZPIY,  0xf1, P02 },
    { M_ZPIL,  0xe7, P816 },
    { M_ZPILY, 0xf7, P816 },
    { M_SR,    0xe3, P816 },
    { M_SRIY,  0xf3, P816 },
  EDEF

  DEF("sec")
    { M_IMP,   0x38, P02 },
  EDEF

  DEF("sed")
    { M_IMP,   0xf8, P02 },
  EDEF

  DEF("sei")
    { M_IMP,   0x78, P02 },
  EDEF

  DEF("sep")
    { M_IMM,   0xe2, P816 },
  EDEF

  DEF("skp")
    { M_IMM,   0x04, P02X },
  EDEF

  DEF("sta")
    { M_ZP,    0x85, P02 },
    { M_ZPX,   0x95, P02 },
    { M_ABS,   0x8d, P02 },
    { M_ABSX,  0x9d, P02 },
    { M_ABSY,  0x99, P02 },
    { M_LONG,  0x8f, P816 },
    { M_LONGX, 0x9f, P816 },
    { M_ZPI,   0x92, P816 },
    { M_ZPIX,  0x81, P02 },
    { M_ZPIY,  0x91, P02 },
    { M_ZPIL,  0x87, P816 },
    { M_ZPILY, 0x97, P816 },
    { M_SR,    0x83, P816 },
    { M_SRIY,  0x93, P816 },
  EDEF

  DEF("stp")
    { M_IMP,   0xdb, P816 },
  EDEF

  DEF("stx")
    { M_ZP,    0x86, P02 },
    { M_ZPY,   0x96, P02 },
    { M_ABS,   0x8e, P02 },
  EDEF

  DEF("sty")
    { M_ZP,    0x84, P02 },
    { M_ZPX,   0x94, P02 },
    { M_ABS,   0x8c, P02 },
  EDEF

  DEF("stz")
    { M_ZP,    0x64, P816 },
    { M_ZPX,   0x74, P816 },
    { M_ABS,   0x9c, P816 },
    { M_ABSX,  0x9e, P816 },
  EDEF

  DEF("tad")
    { M_IMP,   0x5b, P816 },
  EDEF

  DEF("tas")
    { M_IMP,   0x1b, P816 },
  EDEF

  DEF("tax")
    { M_IMP,   0xaa, P02 },
  EDEF

  DEF("tay")
    { M_IMP,   0xa8, P02 },
  EDEF

  DEF("tcd")
    { M_IMP,   0x5b, P816 },
  EDEF

  DEF("tcs")
    { M_IMP,   0x1b, P816 },
  EDEF

  DEF("tda")
    { M_IMP,   0x7b, P816 },
  EDEF

  DEF("tdc")
    { M_IMP,   0x7b, P816 },
  EDEF

  DEF("tea")
    { M_ABSY,  0x9f, P02X },
  EDEF

  DEF("tex")
    { M_ABSY,  0x9e, P02X },
  EDEF

  DEF("tey")
    { M_ABSX,  0x9c, P02X },
  EDEF

  DEF("trb")
    { M_ZP,    0x14, P816 },
    { M_ABS,   0x1c, P816 },
  EDEF

  DEF("tsb")
    { M_ZP,    0x04, P816 },
    { M_ABS,   0x0c, P816 },
  EDEF

  DEF("tsc")
    { M_IMP,   0x3b, P816 },
  EDEF

  DEF("tsx")
    { M_IMP,   0xba, P02 },
  EDEF

  DEF("txa")
    { M_IMP,   0x8a, P02 },
  EDEF

  DEF("txs")
    { M_IMP,   0x9a, P02 },
  EDEF

  DEF("txy")
    { M_IMP,   0x9b, P816 },
  EDEF

  DEF("tya")
    { M_IMP,   0x98, P02 },
  EDEF

  DEF("tyx")
    { M_IMP,   0xbb, P816 },
  EDEF

  DEF("wai")
    { M_IMP,   0xcb, P816 },
  EDEF

  DEF("xba")
    { M_IMP,   0xeb, P816 },
  EDEF

  DEF("xce")
    { M_IMP,   0xfb, P816 },
  EDEF

  DEF("xma")
    { M_IMM,   0x8b, P02X },
  EDEF

  { END, { } }
};

static char *errormsg[]=
{
  "Ok",
  "Opcode expected",
  "Label is an opcode",
  "Extra stuff on line",
  "Empty line",
  "Floating point exception",
  "Label not found",
  "Duplicate label",
  "Illegal value",
  "Syntax",
  "Branch out of range",
  "File not found",
  "Address definition expected",
  "Wrong library type",
  NULL
};

int error_state;

File** file;
LabelList lblist;
LabelList** lib;
Macro** macro;
Line** line;           // each line from the source file
addrmap* map;
int nmap;
int address;
int cur_line;
int max_line;
int enum_val;

int eval_addr = 0;
int eval_lo = 0;
int reloc_hi = 0;
BOOL verbose = False;
int procmode = P02;

char fname[256]="";                 // input file name
char fext[32]="";                   // input file name extension
char tfext[32]="";
char oname[256]="";                 // output file name
char logstr[10240];
char logbld[10240];

FILE *fi;                           // input file pointer
FILE *fo;                           // output file pointer


void help(void)
{
  fprintf(stderr, "Usage: asm64 [-p] [-x extension] filename\n");
  exit(1);
}

int main(int argc, char **argv)
{
  char name[256];        // file name
  char *r;
  char c;
  byte bytes[65536];
  reloc raddr[65536];
  int rsize;
  register int i, j, k;
  int pmodes[] = { P02, P02 | P02X, P02 | P816 };

  while( (c = getopt(argc, argv, OPTS)) >= 0) {
    switch(c) {
    case 'x':
      strcpy(fext, optarg);
      break;

    case 'D':
      setenv(optarg, "", 1);
      break;

    case 'p':
      if( (i = abs(atoi(optarg))) > 2)
	i = 2;

      procmode = pmodes[i];
      break;

    case 'v':
      verbose = True;
      break;

    case 'h':
      help();

    case '?':
      help();
    }
  }

  if(verbose)
    fprintf(stderr, "asm64: 6510 source code assembler\n");

  strcpy(fname, argv[optind]);

  fnsplit(fname, name, tfext);
  if(! strlen(fext))
    strcpy(fext, "ml");
  fnmerge(oname, name, fext);

  macro = (Macro**)malloc(sizeof(Macro*));
  macro[0] = NULL;

  lib = (LabelList**)malloc(sizeof(LabelList*));
  lib[0] = NULL;

  map = (addrmap*)malloc(sizeof(addrmap));
  nmap = 0;

  if(verbose)
    fprintf(stderr, "asm64: Reading source file...\n");

  max_line = 0;

  readFile(fname);

  if(verbose) {
    fprintf(stderr, "asm64: Number of lines: %d\n", max_line);
    fprintf(stderr, "asm64: Determining label addresses...\n");
  }

  // First run

  {
    int oa;

    address = -1;
    enum_val = -1;
    error_state = 0;
    reloc_hi = 0;

    for(i=0; i<max_line; i++) {
      cur_line = i;
      oa = address;

      if(line[i]->isCommand(RELOC_DIRECTIVE)) {
	address = ++reloc_hi << RELOC_BIT;
	continue;
      }
#if 0
      if(line[i]->isCommand(ELSE_DIRECTIVE))
	while(! line[i]->isCommand(ENDIF_DIRECTIVE) && i < max_line)
	  ++i;
#endif

      if(line[i]->isCommand(ELSE_DIRECTIVE)) {
	while(! line[i]->isCommand(ENDIF_DIRECTIVE) && i < max_line)
	  line[i++]->Clear();
	line[i]->Clear();
	continue;
      }

      if(line[i]->isCommand(IF_DIRECTIVE))
	if(evaluate(line[i]->Argument()) == 0) {
	  while(! line[i]->isCommand(ENDIF_DIRECTIVE) && ! line[i]->isCommand(ELSE_DIRECTIVE) && i < max_line)
	    line[i++]->Clear();
	  line[i]->Clear();
	  continue;
	}

      if(line[i]->isCommand(IFDEF_DIRECTIVE)) {
	r = getenv(line[i]->Argument());
	line[i++]->Clear();
	if(r == NULL) {
	  while(! line[i]->isCommand(ENDIF_DIRECTIVE) && ! line[i]->isCommand(ELSE_DIRECTIVE) && i < max_line)
	    line[i++]->Clear();
	  line[i]->Clear();
	  continue;
	}
      }

      if(line[i]->isCommand(IFNDEF_DIRECTIVE)) {
	r = getenv(line[i]->Argument());
	line[i++]->Clear();
	if(r != NULL) {
	  while(! line[i]->isCommand(ENDIF_DIRECTIVE) && ! line[i]->isCommand(ELSE_DIRECTIVE) && i < max_line)
	    line[i++]->Clear();
	  line[i]->Clear();
	  continue;
	}
      }

      if(line[i]->isCommand(ENDIF_DIRECTIVE)) {
	line[i]->Clear();
	continue;
      }

      k = line[i]->Process(1, bytes, raddr, rsize);
      address += k;

      if(error_state < 0 && error_state != ASM_EMPTY && error_state != ASM_NOLABEL
	 && error_state != ASM_OUTRANGE)
	report_error(line[i], error_state);
      error_state = ASM_OK;

#if 0
      fprintf(stderr, "%5d: %04x ", line[i]->FileLine(), address);
      for(j=0; j<k && j<3; j++)
	fprintf(stderr, " %3u", (byte)bytes[j]);
      if(j < k)
	fprintf(stderr, " ...");
#endif
    }
  }

  if(verbose)
    fprintf(stderr, "final address: %04x\n", address);

  // Second run

  if(verbose)
    fprintf(stderr, "asm64: Building output file...\n");

  {
    File* cf;
    Block* cb=NULL;
    int oa;

    address = -1;
    enum_val = -1;
    error_state = 0;
    reloc_hi = 0;

    file = (File**)malloc(sizeof(File*));
    file[0] = NULL;

    cf = AddFile(oname);

    for(i=0; i<max_line; i++) {
      cur_line = i;

      if(line[i]->isCommand(FILE_DIRECTIVE)) {
	getString(line[i]->Argument(), oname);
	cf = AddFile(oname);
	continue;
      }

      if(line[i]->isCommand(MODULE_DIRECTIVE))
	if(cb != NULL) {
	  getString(line[i]->Argument(), oname);
	  cb->setModuleName(oname);
	  add_addrmap(address >> RELOC_BIT, oname);
	  if(verbose)
	    fprintf(stderr, "asm64: Module name: %s\n", oname);
	  continue;
	}
	else {
	  error_state = ASM_EXPECTAD;
	  continue;
	}

      if(line[i]->isCommand(RELOC_DIRECTIVE)) {
	address = ++reloc_hi << RELOC_BIT;
	cb = cf->addBlock(address);
	continue;
      }

      if(line[i]->isCommand(LADDR_DIRECTIVE)) {
	if(! line[i]->Argument())
	  k = address;
	else
	  k = evaluate(line[i]->Argument());

	cb->setLastAddress(k);
	continue;
      }

      if(line[i]->isCommand(ATTR_DIRECTIVE)) {
	if(line[i]->Argument())
	  cb->setAttribute(evaluate(line[i]->Argument()));
	continue;
      }

      if(line[i]->isCommand(ELSE_DIRECTIVE))
	while(! line[i]->isCommand(ENDIF_DIRECTIVE) && i < max_line)
	  ++i;

      if(line[i]->isCommand(IF_DIRECTIVE))
	if(evaluate(line[i]->Argument()) == 0)
	  while(! line[i]->isCommand(ENDIF_DIRECTIVE) && ! line[i]->isCommand(ELSE_DIRECTIVE) && i < max_line)
	    ++i;

      if(line[i]->isCommand(IFDEF_DIRECTIVE))
	if(getenv(line[i]->Argument()) == NULL)
	  while(! line[i]->isCommand(ENDIF_DIRECTIVE) && ! line[i]->isCommand(ELSE_DIRECTIVE) && i < max_line)
	    ++i;

      if(line[i]->isCommand(IFNDEF_DIRECTIVE))
	if(getenv(line[i]->Argument()) != NULL)
	  while(! line[i]->isCommand(ENDIF_DIRECTIVE) && ! line[i]->isCommand(ELSE_DIRECTIVE) && i < max_line)
	    ++i;

      oa = address;
      k = line[i]->Process(2, bytes, raddr, rsize);

      if(address != oa)
	cb = cf->addBlock(address);

      if(verbose)
	sprintf(logstr, "%5d: %04x ", line[i]->FileLine(), address);

      if(k) {
	if(address < 0)
	  error_state = ASM_EXPECTAD;
	else {
	  cb->addBytes(bytes, k);
	  if(rsize)
	    cb->addReloc(address, raddr, rsize);
	  address += k;
	}
      }

      if(verbose) {
	for(j=0; j<k && j<3; j++) {
	  sprintf(logbld, " %02x", (byte)bytes[j]);
	  strcat(logstr, logbld);
	}

	if(j < k) {
	  for(; j<k; j++) {
	    sprintf(logbld, " %02x", (byte)bytes[j]);
	    strcat(logstr, logbld);
	  }
	}

	if(strlen(logstr) > 25)
	  fprintf(stderr, "%s\n%25s", logstr, "");
	else
	  fprintf(stderr, "%-25s", logstr);

	line[i]->output();
      }

      if(error_state < 0 && error_state != ASM_EMPTY)
	report_error(line[i], error_state);
      error_state = ASM_OK;
    }
  }

  for(i=0; file[i]; i++)
    file[i]->output();

  exit(0);
}

void readFile(char* fname)
{
  Line li;
  int fline=0;
  int i, j, k;
  char buf[1024]="";
  char* pfname;
  FILE* fi;

  if(! fname)
    return;

  if( (fi = fopen(fname, "r")) == NULL) {
    fprintf(stderr, "asm64: Couldn't open input file\n%s\n", strerror(errno));
    exit(1);
  }

  pfname = strcreate(fname);

  while(! feof(fi)) {
    if(strlen(buf) == 0) {
      ++fline;
      *buf = 0;
      getstr(buf, 1024, fi);
      if(strlen(buf) == 0)
	continue;
    }

    if(li.Parse(fline, pfname, buf) >= 0) {
      if(li.isCommand(MACRO_DIRECTIVE)) {
	readMacro(li.Argument());
	continue;
      }
      else if(li.isCommand(INCLUDE_DIRECTIVE)) {
	readFile(li.Argument());
	continue;
      }
      else if( (j = findMacro(li.Command())) >= 0) {
	k = macro[j]->lineCount();
	if(max_line == 0)
	  line = (Line**)malloc(sizeof(Line*) * k);
	else
	  line = (Line**)realloc(line, sizeof(Line*) * (max_line+k));

	macro[j]->putLines(fline, &line[max_line], li.Argument(), li.Label());

	max_line += k;
      }
      else {
	++max_line;
	if(max_line == 1)
	  line = (Line**)malloc(sizeof(Line*));
	else
	  line = (Line**)realloc(line, sizeof(Line*)*max_line);

	line[max_line-1] = new Line;
	line[max_line-1]->copy(fline, &li);

	if(line[max_line-1]->Command())
	  if(! strcmp(line[max_line-1]->Command(), END_DIRECTIVE))
	    break;
      }
    }
  }

  fclose(fi);
}

File* AddFile(char *name)
{
  register int i;

  for(i=0; file[i]; i++);
  file = (File**)realloc(file, sizeof(File*) * (i+2));
  file[i] = new File(name);
  file[i+1] = NULL;

  return file[i];
}

int findMacro(char *name)
{
  register int i;

  if(name == NULL)
    return -1;

  for(i=0; macro[i]; i++)
    if(! strcmp(name, macro[i]->Name()))
       return i;

  return -1;
}

int PETSCII(char *arg, int& used)
{
  register int i;
  char lb[WORDLEN+1];
  char *r;
  int sign=1;

  used = 1;
  eval_addr = 0;
  eval_lo = 0;

  if(*arg == '\'') {
    strcpy(lb, &arg[1]);
    r = strchr(lb, '\'');
    if(r)
      *r = 0;

    r = strchr(&arg[1], '\'');
    if(r)
      used += (int)(r - arg);
    else
      used += strlen(arg);

    return evaluate(lb);
  }

  if(*arg == '@') {
    ++used;
    if(arg[1] == 0)
      return *arg;

    if(arg[1] >= 'A' && arg[1] <= 'Z')
      return arg[1] - 'A' + 97;
    else
      return arg[1];
  }

  if(*arg == '\\') {
    ++used;
    if(arg[1] == 0)
      return *arg;

    if(arg[1] == '-' && isdigit(arg[2])) {
      ++used;
      for(i=3; isdigit(arg[i]); i++)
	++used;
      return -atoi(&arg[2]);
    }

    if(isdigit(arg[1])) {
      for(i=2; isdigit(arg[i]); i++)
	++used;
      return atoi(&arg[1]);
    }
    else if(arg[1] >= 'a' && arg[1] <= 'z')
      return arg[1] - 'a' + 1;
    else if(arg[1] >= 'A' && arg[1] <= 'Z')
      return arg[1] - 'A' + 129;
    else if(arg[1] == ' ')
      return arg[1] | 0x80;
    else
      return arg[1];
  }
  else {
    if(*arg >= 'a' && *arg <= 'z')
      return *arg - 'a' + 65;
    else if(*arg >= 'A' && *arg <= 'Z')
      return *arg - 'A' + 193;
    else
      return (int)*arg;
  }
}

char ASCtoPET(char c)
{
  if(c >= 'a' && c <= 'z')
    c = c - 'a' + 65;
  else if(c >= 'A' && c <= 'Z')
    c = c - 'A' + 193;

  return c;
}

int PETtoSCRN(int val)
{
  if(val >= 64 && val <= 95)
    return val & ~64;

  if(val >= 96 && val <= 122)
    return val & ~96;

  if(val > 122 && val <= 126)
    return val & ~32;

  if(val >= 192 && val <= 223)
    return val & ~128;

  return val;
}

void getString(char *arg, char *str)
{
  char *r;
  int n;

  if(arg == NULL) {
    *str = 0;
    return;
  }

  if(*arg == '\"' || *arg == '\'')
    ++arg;

  r = strpbrk(arg, "\'\"");
  if(r)
    n = (int)(r - arg);
  else
    n = strlen(arg);

  strncpy(str, arg, n);
  str[n] = 0;
}


int evaluate(char *arg)
{
  register int i, j;
  int v;
  int smax, stream[512];
  int ec, ev[512];
  char *r;

  eval_addr = 0;
  eval_lo = -1;

  while((*arg == ' ' || *arg == TAB) && *arg != 0)
    ++arg;

  if(! strcmp(arg, "*")) {
    v = address;
    eval_addr = v >> RELOC_BIT;    // =False if <$1000000, otherwise table number
    return v;
  }

  if(*arg == '-' || *arg == '+' || *arg == '%')
    if(! isdigit(arg[1]))
      switch(*arg) {
      case '-':
	for(j=cur_line-1; j>=0; j--)
	  if(line[j]->isLabel(arg)) {
	    v = line[j]->Address();
	    eval_lo = (byte)v;
	    eval_addr = v >> RELOC_BIT;
	    return v;
	  }
	break;

      case '+':
	for(j=cur_line+1; j<max_line; j++)
	  if(line[j]->isLabel(arg)) {
	    v = line[j]->Address();
	    eval_lo = (byte)v;
	    eval_addr = v >> RELOC_BIT;
	    return v;
	  }
	break;

      case '%':
	if( (r = getenv(&arg[1])) )
	  return atoi(r);
	else
	  return 0;
	break;
      }

  smax = torpn(arg, stream);

  ec = 0;
  for(i=0; i<smax; i++)
    if((stream[i] & OPER_FLAG) != OPER_FLAG)
      ev[ec++] = stream[i];
    else if(ec > 1) {
      --ec;
      switch(stream[i] & ~OPER_FLAG) {
      case '+':
	ev[ec-1] += ev[ec];
	break;
      case '-':
	ev[ec-1] -= ev[ec];
	break;
      case '*':
	ev[ec-1] *= ev[ec];
	break;
      case '/':
	ev[ec-1] /= ev[ec];
	break;
      case '&':
	ev[ec-1] &= ev[ec];
	break;
      case '|':
	ev[ec-1] |= ev[ec];
	break;
      case '=':
	ev[ec-1] = (ev[ec] == ev[ec-1]);
	break;
      }
    }
    else if(ec > 0) {
      switch(stream[i] & ~OPER_FLAG) {
      case '>':
	eval_lo = (byte)ev[ec-1];
	ev[ec-1] = (byte)(ev[ec-1] >> 8);
	break;
      case '<':
	eval_addr = -eval_addr;
	ev[ec-1] = (byte)ev[ec-1];
	break;
      case '^':
	ev[ec-1] = (byte)(ev[ec-1] >> 16);
	break;
      case '!':
	if((ev[ec-1] % 256) == 0)
	  ev[ec-1] = (byte)(ev[ec-1] >> 8);
	else
	  ev[ec-1] = (byte)(ev[ec-1] >> 8) + 1;
	break;
      case '~':
	ev[ec-1] = ~ev[ec-1];
	break;
      }
    }

  v = ev[ec-1];

  if(eval_addr && eval_lo < 0)
    eval_lo = (byte)v;

  return v;
}

int eval(char *arg)
{
  register int i, j, o;
  char pdef[] = { '>', '<', '^', '!', '~', '$', '%', '*', '\"', '0', 0 };
  int v=0, *val;
  int used;
  char *r;
  char str[1024];

  switch(*arg) {
#if 0
  case '>':
    v = evaluate(&arg[1]);
    eval_lo = (byte)v;
    return (byte)(v >> 8);

  case '<':
    v = (byte)evaluate(&arg[1]);
    eval_addr = -eval_addr;
    return v;

  case '^':
    v = evaluate(&arg[1]);
    return (byte)(v >> 16);

  case '!':
    v = evaluate(&arg[1]);
    if((v % 256) == 0)
      return (v >> 8);
    else
      return (v >> 8) + 1;

  case '~':
    v = ~evaluate(&arg[1]);
    return v;
#endif
  case '$':
    return strtol(&arg[1], NULL, 16);

  case '%':
    return strtol(&arg[1], NULL, 2);

  case '0':
    return strtol(&arg[1], NULL, 8);

  case '\"':
    return PETSCII(&arg[1], used);

  default:
    if(isdigit(*arg))
      return strtol(arg, NULL, 10);
    else {
      strcpy(str, arg);
      if( (r = strchr(str, '.')) ) {
	*r = 0;
	r++;

	// find named library
	for(i=0; lib[i]; i++)
	  if(lib[i]->isLabelType(str))
	    break;
	if(! lib[i]) {
	  error_state = ASM_NOLABEL;
	  return 0;
	}

	v = (lib[i]->findLabelValue(r) & (RELOC_ADDR-1)) | ((i+LIB_HI) << RELOC_BIT);
	eval_addr = v >> RELOC_BIT;
	return v;
      }
      else {
	v = lblist.findLabelValue(arg);
	eval_addr = v >> RELOC_BIT;
	return v;
      }
    }
  }

  return 0;
}

int torpn(char *arg, int *stream)
{
  register int i, k;
  int sp, st, nq;
  char oper[] = { '>', '<', '^', '!', '~', '&', '|', '*', '/', '+', '-', '=', 0 };
  char *boper = oper+5;
  char stack[512];
  char targ[128];

  sp = 0;
  st = 0;

  for(i=0; i<strlen(arg); i++) {
    if(arg[i] == '(') {
      stack[sp++] = arg[i];
      continue;
    }

    if(arg[i] == ')') {
      while(sp > 0 && stack[--sp] != '(')
	stream[st++] = OPER(stack[sp]);
      continue;
    }

    if(strchr(oper, arg[i])) {
      if(strchr(boper, arg[i]))
	if(i == 0 || (i > 0 && strchr(boper, arg[i-1])))
	  continue;

      while(sp > 0 && stack[sp-1] != '(') {
	if(strchr(oper, arg[i]) < strchr(oper, stack[sp-1]))
	  break;

	stream[st++] = OPER(stack[--sp]);
      }

      stack[sp++] = arg[i];
      continue;
    }

    k = 0;
    nq = 0;
    do {
      targ[k++] = arg[i++];
      if(targ[k-1] == '\"')
	nq = 1 - nq;
    }
    while(i < (int)strlen(arg) && (! strchr(oper, arg[i]) && arg[i] != '(' && arg[i] != ')') || nq > 0);
    targ[k] = 0;
    --i;

    stream[st++] = eval(targ);
  }

  while(sp > 0)
    if(stack[--sp] != '(')
      stream[st++] = OPER(stack[sp]);

  return st;
}

int inparens(char *arg)
{
  register int i, n;

  n = 0;
  for(i=0; i<strlen(arg); i++) {
    if(arg[i] == '(')
      ++n;
    if(arg[i] == ')')
      --n;
    if(i < strlen(arg)-1 && n == 0)
      return 0;
  }

  return 1;
}

void fnsplit(char *fname, char *name, char *ext)
{
  char *split;

  strcpy(name, fname);

  if((split = strrchr(name, '.'))) {
    strcpy(ext, &split[1]);
    split[0] = 0;
  }
  else
    ext[0] = 0;
}

void fnmerge(char *fname, char *name, char *ext)
{
  sprintf(fname, "%s.%s", name, ext);
}

char* strcreate(char *str2)
{
  char *str;

  if(str2 == NULL) {
    str = new char[1];
    str[0] = 0;
  }
  else {
    str = new char[strlen(str2)+1];
    strcpy(str, str2);
  }

  return str;
}

char** splitstring(char *str, char* delim, int& max)
{
  int i;
  char **ar;
  char *sstr;
  char *optr, *cptr, *q1ptr, *q2ptr;
  char t;

  max = 0;

  if(! strlen(str)) {
    ar = new char*[1];
    ar[0] = NULL;
  }
  else {
    cptr = str;
    do {
      optr = cptr;
      cptr = strpbrk(optr, delim);
      if(cptr != NULL)
        cptr = &cptr[1];

      ++max;
    }
    while(cptr != NULL);

    ar = new char*[max+2];
    ar[0] = new char[max+1];

    cptr = str;
    i = 1;
    do {

/* Break up string into operators and operands.  If an operator is in
   quotes, do not break up; instead, skip over it.
*/

      do {
	optr = cptr;
	cptr = strpbrk(optr, delim);

	q1ptr = strchr(optr, '\"');
	if(q1ptr == NULL) {
	  q1ptr = &optr[strlen(optr)];
	  q2ptr = q1ptr;
	}
	else {
	  q2ptr = strchr(&q1ptr[1], '\"');
	  if(q2ptr == NULL)
	    q2ptr = &optr[strlen(optr)];
	}

	if(cptr > q1ptr && cptr < q2ptr)
	  cptr = &q2ptr[1];
      }
      while((cptr > q1ptr && cptr < q2ptr) && cptr != NULL);

      if(cptr != NULL) {
        ar[0][i-1] = cptr[0];
	t = cptr[0];
        cptr[0] = 0;
      }
      ar[i++] = strcreate(optr);
      if(cptr != NULL) {
        cptr[0] = t;
        cptr = &cptr[1];
      }
    }
    while(cptr != NULL && i < max+1);

    ar[i] = NULL;
    ar[0][i-1] = 0;

    max = i-1;
  }

  return ar;
}

int whichOpcode(char *opcode)
{
  register int i;

  if(opcode == NULL)
    return -1;

  for(i=0; strcmp(sym[i].op, END) && strcmp(sym[i].op, opcode); i++);

  if(strcmp(sym[i].op, END))
    return i;

  return -1;
}

char* getstr(char *str, int max, FILE* fi)
{
  fgets(str, 1024, fi);
  if(str[strlen(str)-1] == LF)
    str[strlen(str)-1] = 0;

  return str;
}

void report_error(Line* li, int estate)
{
  fprintf(stderr, "ERROR: %s at %s(%d)\n", errormsg[-estate],
	  li->FileName(), li->FileLine());
  li->output(stderr);
}

void putWord(int val, FILE* fo)
{
  fprintf(fo, "%c%c", (byte)val, (byte)(val >> 8));
}

void readMacro(char *fname)
{
  register int i;
  FILE* fi;

  if(! fname)
    return;

  if( (fi = fopen(fname, "r")) ) {
    while(! feof(fi)) {
      for(i=0; macro[i]; i++);
      macro = (Macro**)realloc(macro, sizeof(Macro*) * (i+2));
      macro[i+1] = NULL;
      macro[i] = new Macro(fi);
      if(! macro[i]->isValidMacro()) {
	delete macro[i];
	macro[i] = NULL;
	break;
      }
    }

    fclose(fi);
  }
}

void add_addrmap(int hi, char *name)
{
  ++nmap;
  map = (addrmap*)realloc(map, nmap*sizeof(addrmap));

  map[nmap-1].hi_addr = hi;
  strcpy(map[nmap-1].module, name);
}
