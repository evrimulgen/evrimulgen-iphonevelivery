/*
 Copyright (C) 2011 - F. Guillemé
 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
*/
#ifndef DEBUG_H_INCLUDED
#define DEBUG_H_INCLUDED
#if defined(DEBUG) || defined(YESDEBUG)
#undef DEBUG
#define DEBUG
#include <stdio.h>
#include <stdarg.h>
void TRACE(const char *p, size_t n, const char *label, ...);
void DUMP(const uint8_t *p, size_t n, const char *label, ...);
#define LOG(str...) do { fprintf(stderr, str); fprintf(stderr, "\n"); } while(0)
#else
#define TRACE(str...) do { } while (0)
#define DUMP(str...) do { } while (0)
#define LOG(str...) do { } while (0)
#endif
#endif

// vim: set ts=4 expandtab
