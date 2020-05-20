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
