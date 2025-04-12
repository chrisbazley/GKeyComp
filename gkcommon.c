/*
 *  Gordon Key file compression utilities
 *  Command-line parser and common code
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
#include <ctype.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <stdbool.h>
#include <errno.h>
#include <time.h>

/* CBUtilLib headers */
#include "StrExtra.h"
#include "ArgUtils.h"

/* Local headers */
#include "misc.h"
#include "filetype.h"
#include "gkcommon.h"

enum
{
  FEDNET_COMP_LOG_2 = 9, /* Base 2 logarithm of the history size used by The
                            Fourth Dimension and Fednet games, in bytes */
  MAX_HISTORY_LOG_2 = 31,
  BUFFER_SIZE       = 256 /* Buffer used when reading temporary file back in */
};

static bool fcopy(FILE *in, FILE *out)
{
  char buffer[BUFFER_SIZE];
  bool success = true;

  assert(in != NULL);
  assert(out != NULL);

  do {
    /* Read as much data as possible into the input buffer */
    size_t n = fread(buffer, 1, sizeof(buffer), in);
    if (n != sizeof(buffer)) {
      /* The input buffer wasn't filled (end of file or read error) */
      if (ferror(in)) {
        fprintf(stderr,
                "Failed to read from temporary file: %s\n",
                strerror(errno));
        success = false;
        break;
      }
    }

    /* Write out the data read into the input buffer */
    if (n != fwrite(buffer, 1, n, out)) {
      /* Not all the data was written */
      fprintf(stderr,
              "Failed to write %lu bytes to output file: %s\n",
              (unsigned long)n,
              strerror(errno));
      success = false;
      break;
    }
  } while (!feof(in));

  return success;
}

static bool process_file(_Optional const char *input_file,
                         _Optional const char *output_file,
                         GKProcessFn *processor, unsigned int history_log_2,
                         bool verbose, bool time, bool compress)
{
  _Optional FILE *out = NULL, *in = NULL, *tmp = NULL;
  bool success = true;

  if (input_file != NULL) {
    /* An explicit input file name was specified, so open it */
    if (verbose)
      printf("Opening input file '%s'\n", input_file);

    in = fopen(&*input_file, "rb");
    if (in == NULL) {
      fprintf(stderr, "Failed to open input file: %s\n", strerror(errno));
      success = false;
    }
  } else {
    /* Default input is from standard input stream */
    fprintf(stderr, "Reading from stdin...\n");
    in = stdin;
  }

  if (success) {
    if (output_file != NULL) {
      if (input_file != NULL && strcmp(&*output_file, &*input_file) == 0) {
        /* Can't overwrite the input file whilst reading from it, so direct
           output to a temporary file instead */
        if (verbose)
          puts("Opening temporary output file");

        tmp = tmpfile();
        if (tmp == NULL) {
          fprintf(stderr, "Failed to create temporary output file: %s\n",
                  strerror(errno));
          success = false;
        }
      } else {
        /* A different output file name was specified, so open it */
        if (verbose)
          printf("Opening output file '%s'\n", output_file);

        out = fopen(&*output_file, "wb");
        if (out == NULL) {
          fprintf(stderr, "Failed to open output file: %s\n", strerror(errno));
          success = false;
        }
      }
    } else {
      /* Default output is to standard output stream */
      out = stdout;
    }
  }

  if (success && in && out) {
    const clock_t start_time = time ? clock() : 0;

    success = processor(&*in, tmp != NULL ? &*tmp : &*out, history_log_2, verbose);

    if (success && time)
    {
      printf("Time taken: %.2f seconds\n",
             (double)(clock_t)(clock() - start_time) / CLOCKS_PER_SEC);
    }
  }

  if (in != NULL && in != stdout) {
    if (verbose)
      puts("Closing input file");
    fclose(&*in);
  }

  /* If we wrote to a temporary file then copy it to the real output */
  if (tmp != NULL) {
    if (success) {
      if (output_file != NULL) {
        /* Open the real output file */
        if (verbose)
          printf("Opening output file '%s'\n", output_file);

        out = fopen(&*input_file, "wb");
        if (out == NULL) {
          fprintf(stderr,
                  "Failed to open output file: %s\n",
                  strerror(errno));
          success = false;
        }
      } else {
        /* Default output is to standard output stream */
        out = stdout;
      }
    }

    if (success) {
      if (verbose)
        puts("Copying from temporary to final output");

      if (fseek(&*tmp, 0L, SEEK_SET)) {
        fprintf(stderr, "Failed to seek start of temporary file\n");
        success = false;
      } else if (!fcopy(&*tmp, &*out)) {
        success = false;
      }
    }

    /* Close the temporary file (which also deletes it) */
    if (verbose)
      puts("Closing temporary file");
    fclose(&*tmp);
  }

  if (out != NULL && out != stdout) {
    if (verbose)
      puts("Closing output file");
    if (fclose(&*out)) {
      fprintf(stderr, "Failed to close output file: %s\n", strerror(errno));
      success = false;
    }
  }

  /* If we know the output file name then we should set its type
     and/or delete it on error */
  if (output_file != NULL) {
    if (success) {
      if (verbose)
        puts("Setting type of output file");

      if (!set_file_type(&*output_file, compress)) {
        fputs("Failed to set output file type\n", stderr);
        success = false;
      }
    }

    /* Delete malformed output unless debugging is enabled or
       it may actually be the input (still intact) */
    if (!success && !verbose && out != NULL && out != stdout)
      remove(&*output_file);
  }

  return success;
}

static int syntax_msg(FILE *f, const char *path)
{
  const char *leaf;

  assert(f != NULL);
  assert(path != NULL);

  leaf = strtail(path, PATH_SEPARATOR, 1);
  fprintf(f,
          "usage: %s [switches] inputfile [outputfile]\n"
          "or     %s -batch [switches] file1 [file2 file3 .. fileN]\n"
          "If no input file is specified, it reads from stdin.\n"
          "If no output file is specified, it writes to stdout.\n"
          "In batch processing mode, output overwrites the input.\n"
          "Switches (names may be abbreviated):\n"
          "  -help               Display this text\n"
          "  -batch              Process a batch of files (see above)\n"
          "  -outfile name       Specify name for output file\n"
          "  -history N          History buffer size as a base 2 logarithm\n"
          "  -time               Show the total time for each file processed\n"
          "  -verbose or -debug  Emit debug information (and keep bad output)\n",
          leaf, leaf);
  return EXIT_FAILURE;
}

#ifdef FORTIFY
static void check_for_leaks(void)
{
  /* Report any memory still allocated upon exit from the program */
  Fortify_LeaveScope();
}
#endif

int main_common(int argc, const char *argv[], GKProcessFn *processor, const char *description, bool compress)
{
  int n;
  bool verbose = false, time = false, batch = false;
  int rtn = EXIT_SUCCESS;
  _Optional const char *output_file = NULL, *input_file = NULL;
  unsigned int history_log_2 = FEDNET_COMP_LOG_2;

  assert(argc > 0);
  assert(argv != NULL);
  assert(processor);
  assert(description != NULL);

#ifdef FORTIFY
  Fortify_EnterScope();
  atexit(check_for_leaks);
#endif
  DEBUG_SET_OUTPUT(DebugOutput_StdErr, "");

  /* Parse any options specified on the command line */
  for (n = 1; n < argc && argv[n][0] == '-'; n++) {
    const char *opt = argv[n] + 1;

    if (is_switch(opt, "help", 1)) {
      /* Output version number and usage information */
      (void)syntax_msg(stdout, argv[0]);
      return EXIT_SUCCESS;
    } else if (is_switch(opt, "batch", 1)) {
      /* Enable batch processing mode */
      batch = true;
    } else if (is_switch(opt, "outfile", 1)) {
      /* Output file path was specified */
      if (++n >= argc || argv[n][0] == '-') {
        fputs("Missing output file name\n", stderr);
        return syntax_msg(stderr, argv[0]);
      }
      output_file = argv[n];
    } else if (is_switch(opt, "history", 1)) {
      long int num;
      if (!get_long_arg("history", &num, 0, MAX_HISTORY_LOG_2,
                        argc, argv, ++n)) {
        return syntax_msg(stderr, argv[0]);
      }
      history_log_2 = (int)num;
    } else if (is_switch(opt, "time", 1)) {
      /* Enable debugging output */
      time = true;
    } else if (is_switch(opt, "verbose", 1) || is_switch(opt, "debug", 1)) {
      /* Enable debugging output */
      verbose = true;
      puts(description);
    } else {
      fprintf(stderr, "Unrecognised switch '%s'\n", opt);
      return syntax_msg(stderr, argv[0]);
    }
  }

  if (batch) {
    if (output_file != NULL) {
      fputs("Cannot specify an output file in batch processing mode\n", stderr);
      return syntax_msg(stderr, argv[0]);
    }
    if (n >= argc) {
      fputs("Must specify file(s) in batch processing mode\n", stderr);
      return syntax_msg(stderr, argv[0]);
    }
  }

  if (batch) {
    /* In batch processing mode, there remaining arguments are treated as a
       list of file names (output to input files) */
    for (; n < argc && rtn == EXIT_SUCCESS; n++)
    {
      assert(argv[n] != NULL);
      if (!process_file(argv[n],
                        argv[n],
                        processor,
                        history_log_2,
                        verbose,
                        time,
                        compress))
        rtn = EXIT_FAILURE;
    }
  } else {
    /* If an input file was specified, it should follow the switches */
    if (n < argc)
      input_file = argv[n++];

    /* An output file name may follow the input file name, but only if not
       already specified */
    if (n < argc) {
      if (output_file != NULL) {
        fputs("Cannot specify more than one output file\n", stderr);
        return syntax_msg(stderr, argv[0]);
      }
      output_file = argv[n++];
    }

    if (output_file == NULL && (time || verbose)) {
      fputs("Must specify an output file in verbose/timer mode\n", stderr);
      return syntax_msg(stderr, argv[0]);
    }

    if (n < argc) {
      fputs("Too many arguments (did you intend -batch?)\n", stderr);
      return syntax_msg(stderr, argv[0]);
    }

    if (!process_file(input_file,
                      output_file,
                      processor,
                      history_log_2,
                      verbose,
                      time,
                      compress))
      rtn = EXIT_FAILURE;
  }

  return rtn;
}
