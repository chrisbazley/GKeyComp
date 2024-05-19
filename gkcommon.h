/*
 *  Gordon Key file compression utilities
 *  Common command-line processor
 *  Copyright (C) 2011 Christopher Bazley
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public Licence as published by
 *  the Free Software Foundation; either version 2 of the Licence, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public Licence for more details.
 *
 *  You should have received a copy of the GNU General Public Licence
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#ifndef GKCOMMON_H
#define GKCOMMON_H

/* ISO library header files */
#include <stdio.h>
#include <stdbool.h>

typedef bool GKProcessFn(FILE *in, FILE *out, unsigned int history_log_2, bool verbose);

int main_common(int argc, const char *argv[], GKProcessFn *processor, const char *description, bool compress);

#endif /* GKCOMMON_H */
