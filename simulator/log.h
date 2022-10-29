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
