#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "asm64.h"

/*
  Format of module (combined code) file:

  Two zero bytes              (2)
 Block:
  Name of block length        (1)
  Name of block               (N)
  Number of dependencies      (1)
  Length of dependency module (1)
  Name of dependency module   (N)
  Address of first block      (2)   (zero if relocatable)
  Length of code              (2)
  Last available address      (2)
  Length of table             (2)
  Attribute                   (1)
  Data                        (N)
 Relocation tables:
  Length of table name        (1)
  Table name                  (N)
  Number of hi page lists     (1)
   Page number                (1)
   Length of hi-byte list     (1)
   List of lo-parts+hi-bytes  (N*2)
   ..
  Number of lo page lists     (1)
   Page number                (1)
   Length of lo-byte list     (1)
   List of lo-bytes           (N)
   ..
*/

void outs(char *str, FILE* fo)
{
  register int i;

  fputc(strlen(str), fo);
  for(i=0; i<strlen(str); i++)
    fputc(ASCtoPET(str[i]), fo);
}

Block::Block(int iaddr)
{
  addr = iaddr;
  lastaddr = -1;
  size = 0;
  alloc = 1024;
  bytes = (byte*)malloc(alloc);
  attr = 0;
  *module = 0;
}

Block::~Block()
{
  free(bytes);
}

void Block::setModuleName(char *irname)
{
  strncpy(module, irname, 254);
  module[255] = 0;
}

void Block::addBytes(byte *b, int num)
{
  register int i;

  while(size + num > alloc) {
    alloc += 1024;
    bytes = (byte*)realloc(bytes, alloc);
  }

  for(i=0; i<num; i++)
    bytes[size++] = b[i];
}

void Block::addReloc(int address, reloc *iraddr, int num)
{
  rtbl.addReloc(address-addr, iraddr, num);
}

void Block::output(BOOL modpart, FILE* fo)
{
  register int i, j, k, n, o, fp, fps, fpn;
  int *itbl, *tbl, *lopart;
  int max, vhi, ntbl;
  int pg[256];
  LabelList* lb;

  if(! fo)
    return;

  if(! modpart) {
    putWord(addr, fo);
    fwrite(bytes, 1, size, fo);
    fflush(fo);
    return;
  }

  // Module name

  fputc(strlen(module), fo);
  for(j=0; j<strlen(module); j++)
    fputc(ASCtoPET(module[j]), fo);

  // Module dependencies

  itbl = new int[rtbl.total()];
  ntbl = 0;
  j = 0;
  for(n=0; n<rtbl.total(); n++) {
    vhi = rtbl.tableHi(n);

    for(k=0; k<nmap; k++)
      if(vhi == map[k].hi_addr)
	break;

    if(k < nmap) {
      itbl[j++] = k;
      ++ntbl;
    }
    else
      itbl[j++] = -1;
  }

  j = 0;
  for(n=0; n<rtbl.total(); n++)
    if( (k = itbl[n]) >= 0)
      if(strcmp(module, map[k].module))
	++j;

  fputc(j, fo);
  for(n=0; n<rtbl.total(); n++) {
    if( (k = itbl[n]) >= 0)
      if(strcmp(module, map[k].module))
	outs(map[k].module, fo);
  }

  // Address information and code

  putWord(addr, fo);
  putWord(size, fo);
  putWord(lastAddress(), fo);
  fp = ftell(fo);
  putWord(0, fo);
  fputc(attr, fo);
  fwrite(bytes, 1, size, fo);
  fps = ftell(fo);

  // Relocation tables

  if(ntbl && verbose) {
    fprintf(stderr, "Total tables: %d\n", ntbl);

    for(n=0; n<rtbl.total(); n++) {
      if( (k = itbl[n]) < 0)
	continue;

      tbl = rtbl.entries(n, True, max);
      lopart = rtbl.loparts(n);

      fprintf(stderr, "%s HI (%d):", map[k].module, max);

      for(i=0; i<max; i++)
	fprintf(stderr, " %x(%x)", tbl[i], lopart[i]);
      fprintf(stderr, "\n");

      tbl = rtbl.entries(n, False, max);
      fprintf(stderr, "%s LO (%d):", map[k].module, max);

      for(i=0; i<max; i++)
	fprintf(stderr, " %x", tbl[i]);
      fprintf(stderr, "\n");
    }
  }

  fputc(ntbl, fo);

  for(n=0; n<rtbl.total(); n++) {
    if( (k = itbl[n]) < 0)
      continue;

    outs(map[k].module, fo);

    // High bytes first

    for(j=0; j<256; j++)
      pg[j] = 0;

    tbl = rtbl.entries(n, True, max);
    lopart = rtbl.loparts(n);

    k = 0;
    o = -1;
    for(j=0; j<max; j++) {
      if(o != (byte)(tbl[j] >> 8)) {
	o = (byte)(tbl[j] >> 8);
	++k;
      }
      pg[o]++;
    }

    // Number of page lists
    fputc(k, fo);

    // Page lists
    j = 0;
    for(o=0; o<256 && j<max; o++)
      if(o == (byte)(tbl[j] >> 8)) {
	fputc(o, fo);
	fputc(pg[o], fo);
	while(o == (byte)(tbl[j] >> 8) && j<max) {
	  fputc((byte)lopart[j], fo);
	  fputc((byte)tbl[j], fo);
	  ++j;
	}
      }

    // Low bytes

    for(j=0; j<256; j++)
      pg[j] = 0;

    tbl = rtbl.entries(n, False, max);

    k = 0;
    o = -1;
    for(j=0; j<max; j++) {
      if(o != (byte)(tbl[j] >> 8)) {
	o = (byte)(tbl[j] >> 8);
	++k;
      }
      pg[o]++;
    }

    // Number of page lists
    fputc(k, fo);

    // Page lists
    j = 0;
    for(o=0; o<256 && j<max; o++)
      if(o == (byte)(tbl[j] >> 8)) {
	fputc(o, fo);
	fputc(pg[o], fo);
	while(o == (byte)(tbl[j] >> 8) && j<max) {
	  fputc((byte)tbl[j], fo);
	  ++j;
	}
      }
  }

  fpn = ftell(fo);
  fseek(fo, fp, SEEK_SET);
  putWord(fpn-fps, fo);
  fseek(fo, fpn, SEEK_SET);

  if(verbose)
    fprintf(stderr, "Table size: %d ($%04x) bytes\n", fpn-fps, fpn-fps);
}


File::File(char *ifname)
{
  strcpy(name, ifname);

  b = (Block**)malloc(sizeof(Block*));
  b[0] = NULL;
}

File::~File()
{
  register int i;

  for(i=0; b[i]; i++)
    delete b[i];
  free(b);
}

Block* File::addBlock(int addr)
{
  register int i;

  for(i=0; b[i]; i++);

  b = (Block**)realloc(b, sizeof(Block*)*(i+2));
  b[i] = new Block(addr);
  b[i+1] = NULL;

  return b[i];
}

int File::output(void)
{
  register int i, j, re=0;
  FILE* fo;
  BOOL modpart=False;

  if(b[0] == NULL)
    return 0;

  if(verbose)
    fprintf(stderr, "asm64: Writing file %s:\n", name);

  if( (fo = fopen(name, "w")) == NULL) {
    fprintf(stderr, "asm64: Error opening file\n");
    return -1;
  }

  for(i=0; b[i]; i++)
    if(b[i]->Address() >= RELOC_ADDR)
      re = 1;

  if(i > 1 || re > 0) {
    putWord(0, fo);
    modpart = True;
  }

  for(i=0; b[i]; i++) {
    fprintf(stderr, "asm64:  Block %d: $%04x - $%04x (last: $%04x)\n", i+1, b[i]->Address(), b[i]->endAddress(), b[i]->lastAddress());

    b[i]->output(modpart, fo);
  }

  fclose(fo);
}


Reloc::Reloc(BOOL low)
{
  rsize = 0;
  ralloc = 0;
  raddr = (int*)malloc(sizeof(int));

  if(low)
    rlopart = (int*)malloc(sizeof(int));
  else
    rlopart = NULL;
}

Reloc::~Reloc()
{
  free(raddr);
}

void Reloc::addReloc(int off_addr, int iraddr, int lo_part)
{
  register int i;

  if(rsize+1 > ralloc) {
    ralloc += 128;
    raddr = (int*)realloc(raddr, sizeof(int) * ralloc);
    if(rlopart)
      rlopart = (int*)realloc(rlopart, sizeof(int) * ralloc);
  }

  raddr[rsize] = (off_addr + iraddr) & 0xffff;
  if(rlopart)
    rlopart[rsize] = lo_part;

  rsize++;
}

RelocTable::RelocTable(void)
{
  ntbl = 0;
  r_lo = (Reloc**)malloc(sizeof(Reloc*));
  r_hi = (Reloc**)malloc(sizeof(Reloc*));
  vhi = (int*)malloc(sizeof(int));
}

RelocTable::~RelocTable()
{
  register int i;

  for(i=0; i<ntbl; i++) {
    delete r_lo[i];
    delete r_hi[i];
  }

  free(r_lo);
  free(r_hi);
  free(vhi);
}

int RelocTable::addTable(int ivhi)
{
  ++ntbl;
  r_lo = (Reloc**)realloc(r_lo, sizeof(Reloc*) * ntbl);
  r_hi = (Reloc**)realloc(r_hi, sizeof(Reloc*) * ntbl);
  vhi = (int*)realloc(vhi, sizeof(int) * ntbl);

  r_lo[ntbl-1] = new Reloc(False);
  r_hi[ntbl-1] = new Reloc(True);
  vhi[ntbl-1] = ivhi;

  return ntbl-1;
}

void RelocTable::addReloc(int off_addr, reloc *iraddr, int num)
{
  register int i, j, k;

  for(i=0; i<num; i++) {
    k = iraddr[i].hi;
    for(j=0; j<ntbl; j++)
      if(k == vhi[j])
	break;

    if(j == ntbl)
      j = addTable(k);

    if(iraddr[i].hi_byte)
      r_hi[j]->addReloc(off_addr, iraddr[i].off, iraddr[i].lo);
    else
      r_lo[j]->addReloc(off_addr, iraddr[i].off);
  }
}

int* RelocTable::entries(int tbl, BOOL hi, int& max)
{
  if(tbl >= ntbl)
    return NULL;

  if(hi)
    return r_hi[tbl]->entries(max);
  else
    return r_lo[tbl]->entries(max);
}

int* RelocTable::loparts(int tbl)
{
  if(tbl >= ntbl)
    return NULL;

  return r_hi[tbl]->loparts();
}
