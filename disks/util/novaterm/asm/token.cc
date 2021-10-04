#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "token.h"

static char pass[]  = ":;()$0123456789";

struct _cokeys
{
  char ltr;
  int val;
} cokeys[]={
  { 'A', 176 },
  { 'B', 191 },
  { 'C', 188 },
  { 'D', 172 },
  { 'E', 177 },
  { 'F', 187 },
  { 'G', 165 },
  { 'H', 180 },
  { 'I', 162 },
  { 'J', 181 },
  { 'K', 161 },
  { 'L', 182 },
  { 'M', 167 },
  { 'N', 170 },
  { 'O', 185 },
  { 'P', 175 },
  { 'Q', 171 },
  { 'R', 178 },
  { 'S', 174 },
  { 'T', 163 },
  { 'U', 184 },
  { 'V', 190 },
  { 'W', 179 },
  { 'X', 189 },
  { 'Y', 183 },
  { 'Z', 173 },
  { '@', 164 },
  { '+', 166 },
  { '-', 220 },
  { '\\', 168 },
  { 0,   0 }
};

// Basic commands

#define REM    143
#define PRINT  153
#define LF     10

char *cmd[]={
  "end", "for", "next", "data", "input#", "input", "dim", "read", "let",
  "goto", "run", "if", "restore", "gosub", "return", "rem", "stop", "on",
  "wait", "load", "save", "verify", "def", "poke", "print#", "print",
  "cont", "list", "clr", "cmd", "sys", "open", "close", "get", "new",

  "tab(", "to", "fn", "spc(", "then", "not", "step",

  "+", "-", "*", "/", "^", "and", "or", ">", "=", "<",

  "sgn", "int", "abs", "usr", "fre", "pos", "sqr", "rnd", "log", "exp",
  "cos", "sin", "tan", "atn", "peek", "len", "str$", "val", "asc",
  "chr$", "left$", "right$", "mid$",

  NULL
};


Line::Line(char *iline)
{
  register int i=0;

  if(! isdigit(iline[0]))
    num = 1;
  else {
    num = atoi(iline);
    while(isdigit(iline[i]))
      ++i;
    while(isspace(iline[i]))
      ++i;
  }

  strcpy(line, &iline[i]);
  tokenize();
}

void Line::tokenize(void)
{
  register int i;
  int c, r=0, p=0, q=0;
  char number[128];
  char special[] = { '\\', '~', '_', 0 };

  while(line[r] != 0 && p < 250) {
    if(line[r] == '\"') {
      q = 1-q;
      line[p++] = line[r++];
      continue;
    }

    if(q) {
      if(! strchr(special, line[r])) {
	line[p++] = cvt(line[r++]);
	continue;
      }

      switch(line[r]) {
      case '_':
	c = 160;
	++r;
	break;

      case '\\':
	c = line[++r];
	if(c >= 'a' && c <= 'z') {
	  c = c - 'a' + 1;
	  r++;
	}
	else if(c >= 'A' && c <= 'Z') {
	  c = c - 'A' + 129;
	  r++;
	}
	else if(isdigit(c)) {
	  i = 0;
	  while(isdigit(line[r]))
	    number[i++] = line[r++];
	  number[i] = 0;
	  c = atoi(number);
	}
	else
	  r++;

	break;

      case '~':
	c = line[++r];

	for(i=0; cokeys[i].ltr; i++)
	  if(c == cokeys[i].ltr) {
	    c = cokeys[i].val;
	    break;
	  }

	r++;
	break;
      }

      line[p++] = c;
      continue;
    }

    if(isspace(line[r])) {
      r++;
      continue;
    }

    if(strchr(pass, line[r])) {
      line[p++] = line[r++];
      continue;
    }

    if(line[r] == '?') {
      line[p++] = PRINT;
      r++;
      continue;
    }

    for(i=0; cmd[i]; i++)
      if(! strncmp(&line[r], cmd[i], strlen(cmd[i])))
	 break;

    if(cmd[i]) {
      line[p++] = i+128;
      r += strlen(cmd[i]);

      if(i+128 == REM)
	q = 2;

      continue;
    }

    line[p++] = cvt(line[r++]);
  }

  if(line[p-1] == '\"' && ! q)
    p--;

  if(line[r] != 0)
    fprintf(stderr, "token64: Warning: line %d truncated\n", num);

  line[p] = 0;
}


int main(int argc, char **argv)
{
  register int i, j, l;
  Line** line;
  char oname[512], name[256], ext[128];
  char buf[1024];
  FILE *fi, *fo;
  int addr;
  char* lbuf;

  if(argc < 1) {
    fprintf(stderr, "Usage: token [file]\n");
    exit(1);
  }

  fnsplit(argv[1], name, ext);
  strcpy(ext, "bas");
  fnmerge(oname, name, ext);

  if( (fi = fopen(argv[1], "r")) == NULL) {
    fprintf(stderr, "Couldn't open %s\n", argv[1]);
    exit(1);
  }

  line = (Line**)malloc(sizeof(Line*));
  line[0] = NULL;
  l = 0;

  while(! feof(fi)) {
    *buf = 0;
    getstr(buf, 1024, fi);

    if(strlen(buf)) {
      while(buf[strlen(buf)-1] == '\\')
	getstr(&buf[strlen(buf)-1], 1024-strlen(buf), fi);

      if(! strcmp(buf, "/*")) {
	while(strcmp(buf, "*/") && ! feof(fi)) {
	  *buf = 0;
	  getstr(buf, 1024, fi);
	}

	continue;
      }

      line = (Line**)realloc(line, sizeof(Line*) * (l+2));
      line[l++] = new Line(buf);
      line[l] = NULL;
    }
  }

  fclose(fi);

  if( (fo = fopen(oname, "w")) == NULL) {
    fprintf(stderr, "Couldn't open %s\n", oname);
    exit(1);
  }

  addr = 2049;
  putWord(addr, fo);

  for(i=0; line[i]; i++) {
    addr += line[i]->length()+1 + 4;
    putWord(addr, fo);
    putWord(line[i]->number(), fo);
    lbuf = line[i]->data();
    for(j=0; j<=line[i]->length(); j++)
      fputc(lbuf[j], fo);
  }

  putWord(0, fo);
  fclose(fo);

  exit(0);
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

char* getstr(char *str, int max, FILE* fi)
{
  do {
    *str = 0;
    fgets(str, 1024, fi);
    if(str[strlen(str)-1] == LF)
      str[strlen(str)-1] = 0;
  }
  while(*str == '#' || *str == ';');

  return str;
}

void putWord(int val, FILE* fo)
{
  fprintf(fo, "%c%c", (unsigned char)val, (unsigned char)(val >> 8));
}

char cvt(char c)
{
  if(c >= 'a' && c <= 'z')
    return c - 'a' + 65;

  if(c >= 'A' && c <= 'Z')
    return c - 'A' + 193;

  return c;
}
