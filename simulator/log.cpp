// This file is part of the vicii-kawari distribution
// (https://github.com/randyrossi/vicii-kawari)
// Copyright (c) 2022 Randy Rossi.
// 
// This program is free software: you can redistribute it and/or modify  
// it under the terms of the GNU General Public License as published by  
// the Free Software Foundation, version 3.
//
// This program is distributed in the hope that it will be useful, but 
// WITHOUT ANY WARRANTY; without even the implied warranty of 
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU 
// General Public License for more details.
//
// You should have received a copy of the GNU General Public License 
// along with this program. If not, see <http://www.gnu.org/licenses/>.

#include "log.h"

const char* logLevelStr[5] = { "none","error","warn","info", "verb" };
int logLevel = LOG_ERROR;

static int binBufNum=0;
static char binBuf[8][65];
char* toBin(int len, unsigned long reg) {
   unsigned long b =1;
   for (int c = 0 ; c < len; c++) {
      binBuf[binBufNum][len-1-c] = reg & b ? '1' : '0';
      b=b*2;
   }
   binBuf[binBufNum][len] = '\0';
   char *buf = binBuf[binBufNum];
   binBufNum = (binBufNum + 1) % 8;
   return buf;
}
