/*
 *  Gordon Key file compression utilities
 *  Platform-specific code
 *  Copyright (C) 2011 Christopher Bazley
 */

#ifndef FILETYPE_H
#define FILETYPE_H

#include <stdbool.h>

bool set_file_type(const char *file_path, bool compressed);

#endif /* FILETYPE_H */
