#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/stat.h>

#include "asm64.h"

#define WORD_NORMAL  0
#define WORD_ASSIGN  1

#define strendcmp(a, b)  (strlen(a) >= strlen(b) ? strcmp(&a[strlen(a)-strlen(b)], b) : 1 )

static char space[] = { ' ', TAB, CR, LF, '=', 0 };

static char *directive[]=
{
 END_DIRECTIVE, ".addr", ".addiv", ".asc", ".text", ".byt", ".byte",
 ".word", ".nword", ".sst", ".lst", ".tst", ".scr",
 ".inv", ".rpt", ".z", ".zero", ".long", ".dword", ".ndword",
 ".binc", ".llib", ".slib", ".enum", ".enden",
 IF_DIRECTIVE, IFDEF_DIRECTIVE, IFNDEF_DIRECTIVE, ELSE_DIRECTIVE, ENDIF_DIRECTIVE,
 LIB_DIRECTIVE, LADDR_DIRECTIVE, FILE_DIRECTIVE, RELOC_DIRECTIVE,
 MACRO_DIRECTIVE, MODULE_DIRECTIVE, ATTR_DIRECTIVE, NULL
};

enum { DIR_END=0, DIR_ADDR, DIR_ADDIV, DIR_ASC, DIR_TEXT,
       DIR_BYT, DIR_BYTE, DIR_WORD, DIR_NWORD,
       DIR_SST, DIR_LST, DIR_TST, DIR_SCR, DIR_INV, DIR_RPT, DIR_Z, DIR_ZERO,
       DIR_LONG, DIR_DWORD, DIR_NDWORD, DIR_BINC, DIR_LLIB, DIR_SLIB,
       DIR_ENUM, DIR_ENDEN,
       DIR_IF, DIR_IFDEF, DIR_IFNDEF, DIR_ELSE, DIR_ENDIF,
       DIR_LIB, DIR_LADDR, DIR_FILE, DIR_RELOC, DIR_MACRO, DIR_MOD, DIR_ATTR };


Line::Line(void)
{
  label = NULL;
  cmd = NULL;
  arg = NULL;
  file = NULL;
}

Line::~Line()
{
  Clear();
}

void Line::Clear(void)
{
  if(label)
    delete[] label;
  if(cmd)
    delete[] cmd;
  if(arg)
    delete[] arg;

  label = NULL;
  cmd = NULL;
  arg = NULL;
  file = NULL;
}

int Line::Parse(int ifline, char* ifile, char* line)
{
  int ptr;
  int err;
  char word[WORDLEN+1];
  register int i, k, ok, o;
  BOOL q;

  Clear();
  fline = ifline;
  if(ifile)
    file = ifile;

  // Remove comment

  q = False;
  for(i=0; i<strlen(line); i++)
    if(line[i] == '\"')
      q = 1-q;
    else if(line[i] == ';' && ! q) {
      line[i] = 0;
      break;
    }

  err = ASM_OK;

  ptr = 0;
  while( (k = nextWord(word, line, ptr)) >= 0 && err == 0) {

    if(! strlen(word) && k == WORD_ASSIGN) {
      ok = k;
      continue;
    }

    if(*word == '.')
      o = 0;
    else
      o = whichOpcode(word);

    if(o < 0)
      o = findMacro(word);

    if(label == NULL && cmd == NULL)
      switch(k) {
      case WORD_NORMAL:
	if(o < 0)
	  label = strcreate(word);
	else
	  cmd = strcreate(word);
	break;

      case WORD_ASSIGN:
	if(o >= 0)
	  err = ASM_ISOP;
	else
	  label = strcreate(word);
	break;
      }

    else if(cmd == NULL && arg == NULL) {
      if(o < 0) {
	if(ok == WORD_ASSIGN)
	  cmd = strcreate("=");
	arg = strcreate(word);
      }
      else
	cmd = strcreate(word);
    }

    else if(arg == NULL)
      arg = strcreate(word);

    else
      err = ASM_EXTRA;

    ok = k;
  }

  if(line[ptr] == ':')
    strcpy(line, &line[ptr+1]);
  else
    *line = 0;

  if(label == NULL && cmd == NULL && arg == NULL)
    return ASM_EMPTY;

  return err;
}

int Line::nextWord(char word[WORDLEN+1], char *line, int& ptr)
{
  register int i;
  BOOL p, q, qe;

  *word = 0;

  while( strchr(space, line[ptr]) &&
	(line[ptr] != 0 && line[ptr] != ':' && line[ptr] != '='))
    ptr++;

  if(line[ptr] == 0 || line[ptr] == ':')
    return -1;

  if(line[ptr] == '=') {
    ptr++;
    return WORD_ASSIGN;
  }

  i = 0;
  p = False;
  q = False;
  qe = False;

  while(line[ptr] != 0 && i < WORDLEN) {
    word[i++] = line[ptr];

    if(line[ptr] == '\"' && ! qe)
      q = 1-q;

    if(line[ptr] == '\\')
      qe = True;
    else
      qe = False;

    if(line[ptr] == '(' && q == False)
      p = True;

    if(line[ptr] == ')' && q == False)
      p = False;

    ++ptr;

    if((! p && ! q) && (strchr(space, line[ptr]) || line[ptr] == ':'))
      break;
  }

  word[i] = 0;

  if(line[ptr] == '=')
    return WORD_ASSIGN;

  return WORD_NORMAL;
}

void Line::copy(int ifline, Line* line)
{
  Clear();

  fline = ifline;

  if(line->label)
    label = strcreate(line->label);
  if(line->cmd)
    cmd = strcreate(line->cmd);
  if(line->arg)
    arg = strcreate(line->arg);
  if(line->file)
    file = strcreate(line->file);
}

void Line::output(FILE* fo)
{
  fprintf(fo, "%-15s %-5s %-s\n",
	 (label == NULL) ? "" : label,
	 (cmd == NULL) ? "" : cmd,
	 (arg == NULL) ? "" : arg);
}

int Line::Process(int run, byte *bytes, reloc *raddr, int& rsize)
{
  register int i, j, b=0;
  int op, ophex, val, amode, naddr;
  BOOL is_addr;

  addr = address;
  rsize = 0;

  // Check for label assignment

  if(isCommand("=")) {
    if(enum_val >= 0) {
      val = evaluate(arg);
      lblist.addLabel(label, enum_val, run);
      enum_val += val;
      return 0;
    }
    else if(isLabel("*")) {
      if(arg) {
	address = evaluate(arg);
	if(verbose)
	  fprintf(stderr, "new address: %4x\n", address);
	return 0;
      }
    }
    else {
      if(arg)
	val = evaluate(arg);
      else
	val = 0;

      lblist.addLabel(label, val, run);
      return 0;
    }
  }    

  // Check for label

  if(label)
    if(*label != '-' && *label != '+')
      if(run == 1)
	lblist.addLabel(label, address, run);

  if(! cmd && ! arg)
    return 0;

  // Check for directive

  for(i=0; directive[i]; i++)
    if(isCommand(directive[i]))
      break;

  if(directive[i]) {
    if(i == DIR_BYT)
      i = DIR_BYTE;
    if(i == DIR_ASC)
      i = DIR_TEXT;
    if(i == DIR_Z)
      i = DIR_ZERO;

    switch(i) {
    case DIR_END:
      return 0;

    case DIR_ADDR:
      if(! arg) {
	if(verbose)
	  fprintf(stderr, "Current address: %4x\n", address);
	return 0;
      }
      else {
	naddr = evaluate(arg);
	fprintf(stderr, "jump to addr: %4x\n", naddr);

	for(i=0; i<naddr-address; i++)
	  bytes[i] = 0;

	return naddr-address;
      }

    case DIR_ADDIV:
      j = evaluate(arg);

      for(i=0; i<j; i++)
	bytes[i] = 0;

      return j - (address % j);

    case DIR_TEXT:
      {
	int ptr, used;
	int a, val, bs;

	bs = b;
	i = 0;
	while(arg[i] != '\"' && arg[i] != 0)
	  ++i;
	if(arg[i] == '\"') {
	  ptr = 1;
	  while(arg[ptr] != '\"' && arg[ptr] != 0) {
	    val = PETSCII(&arg[ptr], used);
	    bytes[b++] = (byte)val;
	    if(arg[ptr] == '\'') {
	      bytes[b++] = (byte)(val >> 8);
	      if(eval_addr) {
		raddr[rsize].hi_byte = False;
		raddr[rsize].off = b-2;
		raddr[rsize++].hi = eval_addr;

		raddr[rsize].hi_byte = True;
		raddr[rsize].off = b-1;
		raddr[rsize].hi = eval_addr;
		raddr[rsize++].lo = eval_lo;
	      }
	    }

	    ptr += used;
	  }

	  while(arg[ptr] != ',' && arg[ptr] != 0)
	    ptr++;
	  if(arg[ptr] == ',') {
	    val = evaluate(&arg[ptr+1]);
	    a = b - bs;
	    for(i=a; i<val; i++)
	      bytes[b++] = 0;
	  }
	}

	return b;
      }

    case DIR_SCR:
      {
	int ptr, used;
	int a, val;

	i = 0;
	while(arg[i] != '\"' && arg[i] != 0)
	  ++i;
	if(arg[i] == '\"') {
	  ptr = 1;
	  while(arg[ptr] != '\"') {
	    val = PETSCII(&arg[ptr], used);
	    bytes[b++] = PETtoSCRN((byte)val);
	    ptr += used;
	  }
	}

	return b;
      }

    case DIR_INV:
      {
	int ptr, used;
	int a, val;

	i = 0;
	while(arg[i] != '\"' && arg[i] != 0)
	  ++i;
	if(arg[i] == '\"') {
	  ptr = 1;
	  while(arg[ptr] != '\"') {
	    val = PETSCII(&arg[ptr], used);
	    bytes[b++] = PETtoSCRN((byte)val ^ 0x80);
	    ptr += used;
	  }
	}

	return b;
      }

    case DIR_BYTE:
      {
	char **args;
	int max;

	args = splitstring(arg, ",", max);
	delete[] args[0];
	for(i=1; args[i]; i++) {
	  bytes[b++] = (byte)evaluate(args[i]);
	  if(eval_addr) {
	    raddr[rsize].hi_byte = (eval_addr > 0) ? True : False;
	    raddr[rsize].off = b-1;
	    raddr[rsize].hi = abs(eval_addr);
	    raddr[rsize++].lo = eval_lo;
	  }

	  delete[] args[i];
	}
	delete[] args;

	return b;
      }

    case DIR_WORD:
      {
	char **args;
	int max;
	int val;

	args = splitstring(arg, ",", max);
	delete[] args[0];
	for(i=1; args[i]; i++) {
	  val = evaluate(args[i]);
	  bytes[b++] = (byte)val;
	  bytes[b++] = (byte)(val >> 8);
	  if(eval_addr) {
	    raddr[rsize].hi_byte = False;
	    raddr[rsize].off = b-2;
	    raddr[rsize++].hi = eval_addr;

	    raddr[rsize].hi_byte = True;
	    raddr[rsize].off = b-1;
	    raddr[rsize].hi = eval_addr;
	    raddr[rsize++].lo = eval_lo;
	  }

	  delete[] args[i];
	}
	delete[] args;

	return b;
      }

    case DIR_NWORD:
      {
	char **args;
	int max;
	int val;

	args = splitstring(arg, ",", max);
	delete[] args[0];
	for(i=1; args[i]; i++) {
	  val = evaluate(args[i]);
	  bytes[b++] = (byte)(val >> 8);
	  bytes[b++] = (byte)val;
	  if(eval_addr) {
	    raddr[rsize].hi_byte = False;
	    raddr[rsize].off = b-1;
	    raddr[rsize++].hi = eval_addr;

	    raddr[rsize].hi_byte = True;
	    raddr[rsize].off = b-2;
	    raddr[rsize].hi = eval_addr;
	    raddr[rsize++].lo = eval_lo;
	  }

	  delete[] args[i];
	}
	delete[] args;

	return b;
      }

    case DIR_LONG:
      {
	char **args;
	int max;
	int val;

	args = splitstring(arg, ",", max);
	delete[] args[0];
	for(i=1; args[i]; i++) {
	  val = evaluate(args[i]);
	  bytes[b++] = (byte)val;
	  bytes[b++] = (byte)(val >> 8);
	  bytes[b++] = (byte)(val >> 16);
	  delete[] args[i];
	}
	delete[] args;

	return b;
      }

    case DIR_DWORD:
      {
	char **args;
	int max;
	int val;

	args = splitstring(arg, ",", max);
	delete[] args[0];
	for(i=1; args[i]; i++) {
	  val = evaluate(args[i]);
	  bytes[b++] = (byte)val;
	  bytes[b++] = (byte)(val >> 8);
	  bytes[b++] = (byte)(val >> 16);
	  bytes[b++] = (byte)(val >> 24);
	  delete[] args[i];
	}
	delete[] args;

	return b;
      }

    case DIR_NDWORD:
      {
	char **args;
	int max;
	int val;

	args = splitstring(arg, ",", max);
	delete[] args[0];
	for(i=1; args[i]; i++) {
	  val = evaluate(args[i]);
	  bytes[b++] = (byte)(val >> 24);
	  bytes[b++] = (byte)(val >> 16);
	  bytes[b++] = (byte)(val >> 8);
	  bytes[b++] = (byte)val;
	  delete[] args[i];
	}
	delete[] args;

	return b;
      }

    case DIR_RPT:
      {
	char **args;
	int max;
	int rpt, val;

	args = splitstring(arg, ",", max);

	for(i=1; i<=max && args[i+1]; i+=2) {
	  rpt = evaluate(args[i]);
	  val = evaluate(args[i+1]);
	  for(j=0; j<rpt; j++)
	    bytes[b++] = (byte)val;
	}

	for(i=0; args[i]; i++)
	  delete[] args[i];
	delete[] args;

	return b;
      }

    case DIR_ZERO:
      {
	char **args;
	int max;
	int rpt;

	args = splitstring(arg, ",", max);
	delete[] args[0];
	for(i=1; args[i]; i++) {
	  rpt = evaluate(args[i]);
	  for(j=0; j<rpt; j++)
	    bytes[b++] = 0;
	  delete[] args[i];
	}
	delete[] args;

	return b;
      }

    case DIR_BINC:
      {
	char fname[256];
	FILE* fi;

	getString(arg, fname);
	if( (fi = fopen(fname, "r")) == NULL)
	  return 0;

	getc(fi);  getc(fi);
	b = fread(bytes, 1, 65536, fi);
	fclose(fi);

	return b;
      }

    case DIR_SST:
      {
	char fname[256];

	if(run == 1)
	  return 0;

	getString(arg, fname);
	lblist.saveTable(fname);

	return 0;
      }

    case DIR_LST:
      {
	char fname[256];

	if(run == 2)
	  return 0;

	getString(arg, fname);
	lblist.loadTable(fname);

	return 0;
      }

    case DIR_TST:
      {
	char fname[256];

	if(run == 1)
	  return 0;

	getString(arg, fname);
	lblist.outputTable(fname);

	return 0;
      }

    case DIR_LIB:
      {
	char fname[256];
	struct stat sb;
	register int i;

	if(run == 2)
	  return 0;

	getString(arg, fname);
	strcat(fname, ".lib");

	if(stat(fname, &sb)) {
	  error_state = ASM_NOFILE;
	  return 0;
	}

	for(i=0; lib[i]; i++);
	lib = (LabelList**)realloc(lib, sizeof(LabelList*) * (i+2));
	lib[i+1] = NULL;
	lib[i] = new LabelList();
	lib[i]->loadTable(fname);
	add_addrmap(i+LIB_HI, lib[i]->labelType());

	return 0;
      }

    case DIR_LLIB:
      {
	char fname[256];
	struct stat sb;
	register int i;

	if(run == 2)
	  return 0;

	getString(arg, fname);
	strcat(fname, ".lib");

	if(stat(fname, &sb)) {
	  error_state = ASM_NOFILE;
	  return 0;
	}

	for(i=0; lib[i]; i++);
	lib = (LabelList**)realloc(lib, sizeof(LabelList*) * (i+2));
	lib[i+1] = NULL;
	lib[i] = new LabelList();
	lib[i]->loadTable(fname);
	lib[i]->delibTable();

	return 0;
      }

    case DIR_SLIB:
      {
	char **args;
	int max, off=0;
	char ltype[256];
	char fname[256];

	if(run == 1)
	  return 0;

	args = splitstring(arg, ",", max);

	if(args[1]) {
	  getString(args[1], ltype);
	  lblist.setLabelType(ltype);

	  if(args[2])
	    off = evaluate(args[2]);
	}

	for(i=0; args[i]; i++)
	  delete[] args[i];
	delete[] args;

	sprintf(fname, "%s.lib", ltype);
	lblist.saveTable(fname, True, off);

	return 0;
      }

    case DIR_ENUM:
      {
	if(enum_val >= 0) {
	  error_state = ASM_SYNTAX;
	  return 0;
	}

	enum_val = 0;
	return 0;
      }

    case DIR_ENDEN:
      {
	if(enum_val < 0) {
	  error_state = ASM_SYNTAX;
	  return 0;
	}

	enum_val = -1;
	return 0;
      }

    default:
      return 0;
    }
  }

  // Check for opcode

  if(! cmd)
    return 0;

  op = whichOpcode(cmd);

  if(op >= 0) {
    amode = getAddressMode(op, val, ophex);

    bytes[b++] = ophex;

    if(amode == M_RELL) {
      eval_addr = False;
      val -= address+2;
      if(val < -32768 || val > 32767) {
	error_state = ASM_OUTRANGE;
	val &= 0xffff;
      }

      if(val < 0)
	val += 65536;
    }
    else if(amode == M_REL) {
      eval_addr = False;
      val -= address+2;
      if(val < -128 || val > 127) {
	error_state = ASM_OUTRANGE;
	val &= 0xff;
      }

      if(val < 0)
	val += 256;
    }

    if((amode & B_ZP) || (amode & B_REL) || amode == M_IMM) {
      bytes[b++] = (byte)val;
      if(eval_addr) {
	raddr[rsize].hi_byte = (eval_addr < 0) ? False : True;
	raddr[rsize].off = b-1;
	raddr[rsize].hi = abs(eval_addr);
	raddr[rsize++].lo = eval_lo;
      }
    }
    else if((amode & B_ADDR16) || (amode & B_RELL) || amode == M_IMML) {
      bytes[b++] = (byte)val;
      bytes[b++] = (byte)(val >> 8);
      if(eval_addr) {
	raddr[rsize].hi_byte = False;
	raddr[rsize].off = b-2;
	raddr[rsize++].hi = eval_addr;

	raddr[rsize].hi_byte = True;
	raddr[rsize].off = b-1;
	raddr[rsize].hi = eval_addr;
	raddr[rsize++].lo = eval_lo;
      }
    }
    else if(amode & B_LONG) {
      bytes[b++] = (byte)val;
      bytes[b++] = (byte)(val >> 8);
      bytes[b++] = (byte)(val >> 16);
    }

    return b;
  }

  error_state = ASM_SYNTAX;
  return 0;
}

int Line::getAddressMode(int opcode, int& val, int& ophex)
{
  register int a, i, n, x1, x2;
  char *r, *tr;
  char targ[256];
  int mode=0;

  val = 0;

  if(! arg)
    mode = M_IMP;
  else if(*arg == '#') {
    a = 1;
    if(arg[a] == '#') {
      ++a;
      mode |= B_LONG;
    }
    val = evaluate(&arg[a]);
    mode |= B_IMMED;
  }
  else {
    x1 = 0;
    x2 = 0;

    if(! strendcmp(arg, ",x")) {
      mode |= B_IX;
      x2 = 2;
    }

    else if(*arg == '(' && ! strendcmp(arg, ",s),y")) {
      mode |= B_IND | B_IS | B_IY;
      x1 = 1;
      x2 = 5;
    }

    else if(*arg == '(' && ! strendcmp(arg, "),y")) {
      strcpy(targ, arg);
      targ[strlen(arg)-2] = 0;

      if(inparens(targ)) {
	mode |= B_IND | B_IY;
	x1 = 1;
	x2 = 3;
      }
      else {
	mode |= B_IY;
	x2 = 2;
      }
    }

    else if(*arg == '[' && ! strendcmp(arg, "],y")) {
      mode |= B_INDL | B_IY;
      x1 = 1;
      x2 = 3;
    }

    else if(! strendcmp(arg, ",y")) {
      mode |= B_IY;
      x2 = 2;
    }

    else if(! strendcmp(arg, ",s")) {
      mode |= B_IS;
      x2 = 2;
    }

    else if(! strendcmp(arg, ",x)")) {
      mode |= B_IND | B_IX;
      x1 = 1;
      x2 = 3;
    }

    else if(*arg == '[' && ! strendcmp(arg, "]")) {
      mode |= B_INDL;
      x1 = 1;
      x2 = 1;
    }

    else if(*arg == '(' && ! strendcmp(arg, ")")) {
      if(inparens(arg)) {
	mode |= B_IND;
	x1 = 1;
	x2 = 1;
      }
    }

    n = strlen(arg)-x2-x1;
    strncpy(targ, &arg[x1], n);
    targ[n] = 0;

    val = evaluate(targ);

    if(val < (1 << 8))
      mode |= B_ZP;
    else if(val >= (1 << 16) && val < RELOC_ADDR)
      mode |= B_LONG;
    else
      mode |= B_ADDR16;
  }

  if( (ophex = findAddressMode(opcode, mode)) < 0)
    error_state = ASM_SYNTAX;

  return mode;
}

int Line::findAddressMode(int op, int& mode)
{
  register int i;
  int m = mode;

  for(i=0; sym[op].code[i].mode >= 0; i++)
    if(m == sym[op].code[i].mode && (procmode & sym[op].code[i].proc)) {
      mode = m;
      return sym[op].code[i].val;
    }

  if(m & B_ZP) {
    m = (m & ~B_ZP) | B_ADDR16;
    for(i=0; sym[op].code[i].mode >= 0; i++)
      if(m == sym[op].code[i].mode && (procmode & sym[op].code[i].proc)) {
	mode = m;
	return sym[op].code[i].val;
      }
  }

  for(i=0; sym[op].code[i].mode >= 0; i++) {
    if(sym[op].code[i].mode == M_RELL && (procmode & sym[op].code[i].proc)) {
      mode = M_RELL;
      return sym[op].code[i].val;
    }
    if(sym[op].code[i].mode == M_REL && (procmode & sym[op].code[i].proc)) {
      mode = M_REL;
      return sym[op].code[i].val;
    }
  }

  return -1;
}

BOOL Line::isLabel(char *str)
{
  if(label)
    if(! strcmp(label, str))
      return True;

  return False;
}

BOOL Line::isCommand(char *str)
{
  if(cmd)
    if(! strcmp(cmd, str))
      return True;

  return False;
}

BOOL Line::isArgument(char *str)
{
  if(arg)
    if(! strcmp(arg, str))
      return True;

  return False;
}

BOOL Line::replaceArgument(int anum, char *aname)
{
  char work[10240];
  char temp[10240];
  char astr[5];
  char *r;
  int i;

  if(! arg)
    return False;

  sprintf(astr, "@%d", anum);
  strcpy(work, arg);

  do {
    r = strstr(work, astr);
    if(! r)
      continue;

    i = (int)(r - work);

    strcpy(temp, work);
    strcpy(&temp[i], aname);
    strcat(temp, &work[i+strlen(astr)]);
    strcpy(work, temp);
  }
  while(r != NULL);

  delete[] arg;
  arg = strcreate(work);

  return True;
}

void Line::replaceLabel(char *l)
{
  if(label)
    delete[] label;

  if(l)
    label = strcreate(l);
  else
    label = NULL;
}
