/*
 *  Gordon Key file compression utilities
 *  Miscellaneous macro definitions
 *  Copyright (C) 2018 Christopher Bazley
 */

#ifndef MISC_H
#define MISC_H

/* Modify these definitions for Unix or Windows file paths. */
#ifndef PATH_SEPARATOR
#define PATH_SEPARATOR '.'
#endif

#ifdef FORTIFY
#include "Fortify.h"
#endif

/* Suppress compiler warnings about an unused function argument. */
#ifndef NOT_USED
#define NOT_USED(x) x = x;
#endif

#ifdef USE_CBDEBUG

#include "Debug.h"
#include "PseudoIO.h"
#include "PseudoKern.h"

#else /* USE_CBDEBUG */

#include <stdio.h>
#include <assert.h>

#define DEBUG_SET_OUTPUT(output_mode, log_name)

#ifdef DEBUG_OUTPUT
#define DEBUGF if (1) printf
#else
#define DEBUGF if (0) printf
#endif /* DEBUG_OUTPUT */

#endif /* USE_CBDEBUG */

#ifdef USE_OPTIONAL
#include <stdio.h>

#undef NULL
#define NULL ((_Optional void *)0)

static inline _Optional FILE *optional_fopen(const char *name, const char *mode)
{
    return fopen(name, mode);
}
#undef fopen
#define fopen(p, n) optional_fopen(p, n)

#else
#define _Optional
#endif

#endif /* MISC_H */
