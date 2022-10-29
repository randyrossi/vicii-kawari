#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "asm64.h"

Macro::Macro(FILE* fi)
{
  Line li;
  char str[1024];
  register int i;

  name = NULL;
  lines = (Line**)malloc(sizeof(Line*));
  lines[0] = NULL;

  do {
    getstr(str, 1024, fi);
    li.Parse(0, NULL, str);
  }
  while(! li.Label() && ! feof(fi));

  if(feof(fi))
    return;

  name = strcreate(li.Label());

  do
    getstr(str, 1024, fi);
  while(strcmp(str, "{") && ! feof(fi));

  if(feof(fi))
    return;

  while(strcmp(str, "}") && ! feof(fi)) {
    getstr(str, 1024, fi);
    if(! strcmp(str, "}"))
      continue;

    if(li.Parse(0, NULL, str) >= 0) {
      for(i=0; lines[i]; i++);
      lines = (Line**)realloc(lines, sizeof(Line*) * (i+2));
      lines[i] = new Line;
      lines[i]->copy(0, &li);
      lines[i+1] = NULL;
    }
  }
}

Macro::~Macro()
{
  register int i;

  if(name)
    delete[] name;

  for(i=0; lines[i]; i++)
    delete lines[i];
  delete[] lines;
}

BOOL Macro::isValidMacro(void)
{
  if(name == NULL || lines[0] == NULL)
    return False;

  return True;
}

void Macro::output(void)
{
  register int i;

  fprintf(stderr, "Macro: %s\n", name);
  for(i=0; lines[i]; i++)
    lines[i]->output();
}

int Macro::lineCount(void)
{
  register int i;

  for(i=0; lines[i]; i++);
  return i;
}

int Macro::putLines(int ifline, Line** ls, char *arg, char *label)
{
  register int i, j;
  char **alist;

  alist = parseArgument(arg);

  for(i=0; lines[i]; i++) {
    ls[i] = new Line;
    ls[i]->copy(ifline, lines[i]);

    if(i == 0 && label)
      ls[i]->replaceLabel(label);

    for(j=0; alist[j]; j++)
      ls[i]->replaceArgument(j+1, alist[j]);
  }

  for(i=0; alist[i]; i++)
    delete[] alist[i];
  delete[] alist;

  return 0;
}

char** Macro::parseArgument(char *arg)
{
  char delim[] = { '(', ',', ' ', TAB, ')', 0 };
  register int i, j;
  char** alist;
  char *r, *orx;
  int anum;
  char work[1024];

  alist = (char**)malloc(sizeof(char*));
  alist[0] = NULL;
  anum = 0;

  r = arg;
  do {
    orx = r;
    if(*orx == 0)
      continue;

    r = strpbrk(orx, delim);
    if(r == orx) {
      ++r;
      continue;
    }

    j = (int)(r - orx);
    strncpy(work, orx, j);
    work[j] = 0;

    alist = (char**)realloc(alist, sizeof(char*) * (anum+2));
    alist[anum] = strcreate(work);
    alist[anum+1] = NULL;
    ++anum;
  }
  while(*orx);

  return alist;
}
