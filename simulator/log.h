#ifndef VICII_LOG_H
#define VICII_LOG_H

#define LOG_NONE     0
#define LOG_ERROR    1
#define LOG_WARN     2
#define LOG_INFO     3
#define LOG_VERBOSE  4

extern const char* logLevelStr[5];

extern int logLevel;

#define LOG(minLevel, FORMAT, ...)  if (logLevel >= minLevel) { printf ("%s: " FORMAT "\n", logLevelStr[logLevel], ##__VA_ARGS__); }

char* toBin(int len, unsigned long reg);

#endif
