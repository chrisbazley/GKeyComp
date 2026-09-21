/*
 *  Gordon Key file compression utilities
 *  Platform-specific code (RISC OS implementation)
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

/* ISO library header files */
#include <assert.h>
#include <stdbool.h>

#ifdef ACORN_C
/* CBOSLib header files */
#include "OSFile.h"
#endif

/* Local headers */
#include "filetype.h"
#include "misc.h"

enum {
  FTYPE_FEDNET = 0x154, /* RISC OS file type illicitly used for SF3000
                          or SR2000 compressed code or data */
  FTYPE_DATA = 0xFFD    /* General-purpose RISC OS file type for data */
};

/* Platform-specific function */
bool set_file_type(const char *file_path, bool compressed)
{
#ifdef ACORN_C
  assert(file_path != NULL);

  /* Apply the RISC OS file type for Fednet game data to the
     specified file. */
  return os_file_set_type(file_path,
                          compressed ? FTYPE_FEDNET : FTYPE_DATA) == NULL;
#else
  NOT_USED(file_path);
  NOT_USED(compressed);
  return true;
#endif
}
