#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <errno.h>
#include <sys/stat.h>

#include "asm64.h"

#define EMPTY  "---"

Label::Label(char *iname, int iaddr)
{
  name = strcreate(iname);
  addr = iaddr;
}

Label::~Label()
{
  delete[] name;
}


LabelList::LabelList(char *iname)
{
  label = (Label**)malloc(sizeof(Label*));
  label[0] = NULL;

  nlabels = 0;
  if(iname) {
    strncpy(title, iname, 64);
    title[64] = 0;
  }
  else
    *title = 0;

  used = 0;
  delib = 0;
}

LabelList::~LabelList()
{
  register int i;

  for(i=0; label[i]; i++)
    delete label[i];

  free(label);
}

void LabelList::setLabelType(char *iname)
{
  strncpy(title, iname, 64);
  title[64] = 0;
}

int LabelList::isLabelType(char *iname)
{
  if(! strcmp(title, iname))
    return True;

  return False;
}

void LabelList::addLabel(char *name, int addr, int run)
{
  register int i;
  Label* l;

  if( (l = findLabel(name)) == NULL) {
    label = (Label**)realloc(label, sizeof(Label*) * (nlabels+2));
    label[nlabels] = new Label(name, addr);
    label[nlabels+1] = NULL;
    ++nlabels;
  }
  else {
    l->setAddress(addr);
    if(run == 1)
      error_state = ASM_DUPLABEL;
  }
}

Label* LabelList::findLabel(char *name)
{
  register int i;

  for(i=0; label[i]; i++)
    if(! strcmp(name, label[i]->Name()))
      return label[i];

  return NULL;
}

int LabelList::findLabelValue(char *name)
{
  Label* l;

  if( (l = findLabel(name)) == NULL) {
    error_state = ASM_NOLABEL;
    return 0x8000;
  }
  else
    return l->Address();
}

void LabelList::saveTable(char *fname, BOOL jmp, int off)
{
  register int i;
  FILE* fo;
  char temp[1024], cmd[1024];
  char *name;
  char *tmp;
  struct stat sb;

  tmp = tempnam(".", "asm");
  strcpy(temp, tmp);
  free(tmp);

  if( (fo = fopen(temp, "w")) == NULL)
    return;

  if(strlen(title))
    fprintf(fo, "%s\n", title);
  else
    fprintf(fo, "%s\n", EMPTY);

  for(i=0; label[i]; i++) {
    name = label[i]->Name();

    if(jmp) {
      if(*name == '_')
	fprintf(fo, "%s %x\n", &name[1], label[i]->Address() - off);
      continue;
    }

    fprintf(fo, "%s %x\n", name, label[i]->Address());
  }

  fclose(fo);

  if(stat(fname, &sb) == 0) {
    sprintf(cmd, "diff -q %s %s", temp, fname);
    if(system(cmd) == 0) {
      unlink(temp);
      return;
    }
    unlink(fname);
  }

  if(rename(temp, fname) < 0)
    fprintf(stderr, "Error: %s\n", strerror(errno));
}

void LabelList::loadTable(char *fname)
{
  register int i;
  FILE* fi;
  char name[WORDLEN+1];
  int addr;

  if( (fi = fopen(fname, "r")) == NULL) {
    error_state = ASM_NOFILE;
    return;
  }

  fscanf(fi, "%s", name);
  if(! strcmp(name, EMPTY))
    *name = 0;

  if(nlabels == 0) {
    strncpy(title, name, 64);
    title[64] = 0;
  }
  else {
    if(strcmp(title, name)) {
      error_state = ASM_WRONGLIB;
      fclose(fi);
      return;
    }
  }

  while(! feof(fi)) {
    fscanf(fi, "%s %x", name, &addr);
    addLabel(name, addr, 0);
    while(getc(fi) != LF && ! feof(fi));
  }

  fclose(fi);
}

void LabelList::delibTable(void)
{
  register int i;

  delib = 1;

  for(i=0; label[i]; i++)
    label[i]->setAddress( label[i]->Address() & (RELOC_ADDR-1) );
}

void LabelList::outputTable(char *fname)
{
  register int i;
  FILE* fo;
  int v;

  if( (fo = fopen(fname, "w")) == NULL)
    return;

  for(i=0; label[i]; i++) {
    v = label[i]->Address();

    fprintf(fo, "%-20s  $%04x  %5u\n", label[i]->Name(), v, v & 0xffff);
  }

  fclose(fo);
}
