/*
  asm64.h - prototypes for 6502 assembler
*/

typedef unsigned char byte;
typedef unsigned short ushort;
typedef unsigned char BOOL;

#define P02     0x1
#define P02X    0x2
#define P816    0x4

#define ASM_OK        0
#define ASM_EXPECTOP  -1
#define ASM_ISOP      -2
#define ASM_EXTRA     -3
#define ASM_EMPTY     -4
#define ASM_FLEXP     -5
#define ASM_NOLABEL   -6
#define ASM_DUPLABEL  -7
#define ASM_ILLVALUE  -8
#define ASM_SYNTAX    -9
#define ASM_OUTRANGE  -10
#define ASM_NOFILE    -11
#define ASM_EXPECTAD  -12
#define ASM_WRONGLIB  -13

#define B_IMMED         0x1
#define B_ZP            0x2
#define B_ADDR16        0x4
#define B_REL           0x8
#define B_RELL          0x10
#define B_LONG          0x20
#define B_IND           0x40
#define B_INDL          0x80
#define B_IX            0x100
#define B_IY            0x200
#define B_IS            0x400

#define M_IMP        0
#define M_IMM        B_IMMED
#define M_IMML       (B_IMMED | B_LONG)
#define M_ZP         B_ZP
#define M_ZPX        (B_ZP | B_IX)
#define M_ZPY        (B_ZP | B_IY)
#define M_ZPI        (B_ZP | B_IND)
#define M_ZPIX       (B_ZP | B_IND | B_IX)
#define M_ZPIY       (B_ZP | B_IND | B_IY)
#define M_ZPIL       (B_ZP | B_INDL)
#define M_ZPILY      (B_ZP | B_INDL | B_IY)
#define M_ABS        B_ADDR16
#define M_ABSX       (B_ADDR16 | B_IX)
#define M_ABSY       (B_ADDR16 | B_IY)
#define M_ABSI       (B_ADDR16 | B_IND)
#define M_ABSIX      (B_ADDR16 | B_IND | B_IX)
#define M_ABSIL      (B_ADDR16 | B_INDL)
#define M_LONG       B_LONG
#define M_LONGX      (B_LONG | B_IX)
#define M_SR         B_IS
#define M_SRIY       (B_IS | B_IND | B_IY)
#define M_REL        B_REL
#define M_RELL       B_RELL

#define WORDLEN      1024

#define RELOC_BIT    24
#define RELOC_ADDR   (1 << RELOC_BIT)
#define LIB_HI       0x20

#define TAB  '\t'
#define CR   '\r'
#define LF   '\n'

#define True    1
#define False   0

#define END_DIRECTIVE     ".end"
#define FILE_DIRECTIVE    ".file"
#define RELOC_DIRECTIVE   ".reloc"
#define MACRO_DIRECTIVE   ".macro"
#define MODULE_DIRECTIVE  ".mod"
#define INCLUDE_DIRECTIVE ".include"
#define LADDR_DIRECTIVE   ".laddr"
#define LIB_DIRECTIVE     ".lib"
#define ATTR_DIRECTIVE    ".attr"
#define IF_DIRECTIVE      ".if"
#define IFDEF_DIRECTIVE   ".ifdef"
#define IFNDEF_DIRECTIVE  ".ifndef"
#define ELSE_DIRECTIVE    ".else"
#define ENDIF_DIRECTIVE   ".endif"

void readFile(char* fname);
int findMacro(char* name);
int whichOpcode(char* opcode);
char* strcreate(char* str);
void fnsplit(char* fname, char* name, char* ext);
void fnmerge(char* fname, char* name, char* ext);
int evaluate(char* arg);
int eval(char* arg);
int torpn(char* arg, int *stream);
int inparens(char* arg);
char ASCtoPET(char c);
int PETSCII(char* arg, int& used);
int PETtoSCRN(int val);
void getString(char* arg, char* str);
char** splitstring(char* str, char* delim, int& max);
char* getstr(char* str, int max, FILE* fi);
void putWord(int val, FILE* fo);
void readMacro(char* fname);
void add_addrmap(int hi, char* name);

#define ____       -1

struct _code
{
  short mode;
  short val;
  char proc;
};

struct symtable {
  char op[4];
  _code code[20];
};

struct reloc {
  BOOL hi_byte;
  int hi;
  int lo;
  int off;
};

struct addrmap {
  int hi_addr;
  char module[256];
};

class Reloc
{
  int rsize;
  int *raddr;
  int *rlopart;
  int ralloc;

public:
  Reloc(BOOL low=False);
  ~Reloc();

  void addReloc(int off_addr, int iraddr, int lo_part=0);
  int* entries(int& max) { max = rsize; return raddr; }
  int* loparts(void) { return rlopart; }
};

class RelocTable
{
  int ntbl;
  Reloc** r_lo;
  Reloc** r_hi;
  int* vhi;

public:
  RelocTable(void);
  ~RelocTable();

  int tableHi(int tbl) { return vhi[tbl]; }
  int addTable(int ivhi);
  void addReloc(int off_addr, reloc *iraddr, int num);
  int* entries(int tbl, BOOL hi, int& max);
  int* loparts(int tbl);
  int total(void) { return ntbl; }
};

class Block
{
  char module[256];

  int addr;
  int lastaddr;
  byte *bytes;

  int size;
  int alloc;

  RelocTable rtbl;
  int attr;

public:
  Block(int iaddr);
  ~Block();

  void setModuleName(char* irname);
  void setLastAddress(int iaddr) { lastaddr = iaddr; }
  int Address(void) { return addr; }
  int endAddress(void) { return addr+size; }
  int lastAddress(void) { if(lastaddr >= 0) return lastaddr; else return endAddress(); }
  void output(BOOL modpart, FILE* fo);

  void addBytes(byte* b, int num);
  void addReloc(int off_addr, reloc *iraddr, int num);
  void setAttribute(int mask) { attr |= mask; }
};


class File
{
  char name[256];
  Block **b;

public:
  File(char* ifname);
  ~File();

  Block* addBlock(int addr);
  int output(void);
};



class Label
{
  char* name;
  int addr;

public:
  Label(char* iname, int iaddr);
  ~Label();

  char* Name(void) { return name; }
  int Address(void) { return addr; }
  void setAddress(int iaddr) { addr = iaddr; }
};

class LabelList
{
  char title[65];
  int nlabels;
  Label** label;
  int used;
  int delib;

public:
  LabelList(char* iname=NULL);
  ~LabelList();

  void setLabelType(char* iname);
  int isLabelType(char* iname);
  char* labelType(void) { return title; }

  void addLabel(char* name, int addr, int run);
  Label* findLabel(char* name);
  int findLabelValue(char* name);
  void setUsed(void) { if(! delib) used=1; }
  int isUsed(void) { return used; }

  void saveTable(char*, BOOL jmp=False, int off=0);
  void loadTable(char*);
  void delibTable(void);
  void outputTable(char*);
};


class Line
{
  char* label;
  char* cmd;
  char* arg;
  int addr;

  char* file;
  int fline;

public:
  Line(void);
  ~Line();

  int Parse(int ifline, char* ifile, char* line);
  int nextWord(char word[WORDLEN+1], char* line, int& ptr);
  void output(FILE* = stderr);
  void copy(int ifline, Line*);

  BOOL isLabel(char*);
  BOOL isCommand(char*);
  BOOL isArgument(char*);

  int FileLine(void) { return fline; }
  char* FileName(void) { return file; }
  char* Label(void) { return label; }
  char* Command(void) { return cmd; }
  char* Argument(void) { return arg; }
  int Address(void) { return addr; }

  int Process(int run, byte *bytes, reloc *raddr, int& rsize);
  int getAddressMode(int opcode, int& val, int& ophex);
  int findAddressMode(int opcode, int& mode);
  BOOL replaceArgument(int anum, char* aname);
  void replaceLabel(char*);
  void Clear(void);
};


class Macro
{
  char* name;
  Line **lines;

public:
  Macro(FILE* fi);
  ~Macro();

  char* Name(void) { return name; }
  Line** Lines(void) { return lines; }

  BOOL isValidMacro(void);
  void output(void);

  int lineCount(void);
  int putLines(int ifline, Line** ls, char* arg, char* label);
  char** parseArgument(char* arg);
};



extern File** file;
extern LabelList lblist;
extern LabelList** lib;
extern Macro** macro;
extern Line** line;           // each line from the source file
extern addrmap* map;
extern int nmap;
extern int address;
extern int cur_line;
extern int enum_val;
extern symtable sym[];
extern int error_state;

extern Block* reloc_cb;
extern int eval_addr;
extern int eval_lo;
extern BOOL verbose;
extern int procmode;

File* AddFile(char* name);
void report_error(Line* li, int estate);
