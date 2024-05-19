/*
 *  Gordon Key file compression utilities
 *  Compression program entry point
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
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <stdbool.h>
#include <errno.h>

/* CBUtilLib headers */
#include "FileRWInt.h"

/* GKeyLib headers */
#include "GKeyComp.h"

/* Local headers */
#include "misc.h"
#include "gkcommon.h"
#include "version.h"

/* Constant numeric values */
enum
{
  FEDNET_HEADER_SIZE = 4,  /* No. of bytes in a 32 bit integer */
  BUFFER_SIZE       = 256, /* I/O buffer size, in bytes */
  PROGRESS_FREQ     = 64,  /* No. of bytes to read between progress reports */
};

static void show_progress(long int in, long int out)
{
  if (in > 0)
    printf("Compression ratio %.2f%% (%ld bytes in, %ld bytes out)\n",
           ((double)out * 100) / in, in, out);
}

static bool update_progress(void *arg, size_t in, size_t out)
{
  NOT_USED(arg);

  if (in % PROGRESS_FREQ == 0) {
    out += FEDNET_HEADER_SIZE; /* include uncompressed size at start of file */
    show_progress((long int)in, (long int)out);
  }

  return true; /* continue compressing */
}

static long int flen(FILE *f)
{
  /* Get the length of a seekable stream by seeking its end and then querying
     its file position indicator */
  long int len;

  if (fseek(f, 0, SEEK_END)) {
    fprintf(stderr, "Failed to seek end of input\n");
    len = -1L;
  } else {
    len = ftell(f);
    if (len == -1L) {
      fprintf(stderr, "Failed to tell input file position\n");
    } else if (fseek(f, 0, SEEK_SET)) {
      fprintf(stderr, "Failed to seek start of input\n");
      len = -1L;
    }
  }
  return len;
}

static bool comp(FILE *in, FILE *out, unsigned int history_log_2, bool verbose)
{
  char in_buffer[BUFFER_SIZE], out_buffer[BUFFER_SIZE];
  bool success = false;
  long int in_total, out_total, in_told;
  GKeyComp *comp = NULL;
  GKeyStatus status;
  GKeyParameters params;

  assert(in != NULL);
  assert(out != NULL);

  out_total = in_total = 0;

  /* Try to leave room for the uncompressed size. This will fail if
     the output stream isn't seekable (e.g. stdout to a terminal). */
  if (verbose)
    printf("Leaving %lu bytes for uncompressed size\n",
           (unsigned long)FEDNET_HEADER_SIZE);

  if (!fseek(out, FEDNET_HEADER_SIZE, SEEK_CUR)) {
    in_told = -1L;
  } else {
    /* fseek returns non-zero upon failure */
    if (verbose)
      puts("Failed to seek beyond start of output");

    /* Try to find out the uncompressed size. This will fail if the
       input stream isn't seekable (e.g. stdin from a terminal). */
    in_told = flen(in);
    if (in_told == -1L)
      goto cleanup;

    /* Write expected size of uncompressed data */
    if (verbose)
        puts("Writing uncompressed size");

    if (!fwrite_int32le(in_told, out)) {
      fprintf(stderr,
              "Failed to write uncompressed size: %s\n",
              strerror(errno));
      goto cleanup;
    }
  }

  /* We either wrote the uncompressed size or left room to do so */
  out_total += FEDNET_HEADER_SIZE;

  comp = gkeycomp_make(history_log_2);
  if (comp == NULL) {
    fprintf(stderr, "Failed to allocate memory: %s\n", strerror(errno));
    goto cleanup;
  }

  params.out_buffer = out_buffer;
  params.out_size = sizeof(out_buffer);
  params.in_size = 0;
  params.prog_cb = verbose ? update_progress : NULL;
  params.cb_arg = NULL;

  do {
    /* Is the input buffer empty? We don't guard against refilling it if we
       got EOF last time: the worst outcome would only be an unnecessarily
       split sequence. */
    if (params.in_size == 0) {
      /* Fill the input buffer by reading from file */
      params.in_buffer = in_buffer;
      params.in_size = fread(in_buffer, 1, sizeof(in_buffer), in);
      if (params.in_size != sizeof(in_buffer) && ferror(in)) {
        /* Read error not end of file */
        fprintf(stderr,
                "Failed to read uncompressed data from input: %s\n",
                strerror(errno));
        goto cleanup;
      }

      /* Update a running total of the uncompressed input size */
      in_total += params.in_size;
    }

    /* Compress the data from the input buffer to the output buffer.
       If the input buffer is empty then this flushes any pending output.
       Returns GKeyStatus_Finished when the flush is complete. */
    status = gkeycomp_compress(comp, &params);

    /* Is the output buffer full or have we finished? */
    if (status == GKeyStatus_Finished ||
        status == GKeyStatus_BufferOverflow ||
        params.out_size == 0)
    {
      /* Empty the output buffer by writing to file */
      const size_t nout = sizeof(out_buffer) - params.out_size;
      out_total += nout;

      if (fwrite(out_buffer, 1, nout, out) != nout) {
        fprintf(stderr,
                "Failed to write %lu bytes to output: %s\n",
                (unsigned long)nout,
                strerror(errno));
        goto cleanup;
      }

      params.out_buffer = out_buffer;
      params.out_size = sizeof(out_buffer);

      if (status == GKeyStatus_BufferOverflow)
        status = GKeyStatus_OK; /* Buffer overflow has been fixed up */
    }
  } while (status != GKeyStatus_Finished &&
           (status == GKeyStatus_OK || status == GKeyStatus_TruncatedInput));

  if (verbose)
    show_progress(in_total, out_total);

  if (in_told != -1L) {
    /* Verify that the input was the expected size */
    if (verbose)
        puts("Validating input size against expected");

    if (in_told != in_total) {
      fprintf(stderr,
              "%ld bytes read from input mismatches expected size %ld\n",
              in_total, in_told);
      goto cleanup;
    }
  } else {
    /* We deferred writing the uncompressed size */
    if (verbose)
        printf("Writing uncompressed size %ld\n", in_total);

    /* Restore the initial output position */
    if (fseek(out, 0, SEEK_SET)) {
      fprintf(stderr, "Failed to seek start of output\n");
      goto cleanup;
    }

    /* Write size of uncompressed data */
    if (!fwrite_int32le(in_total, out)) {
      fprintf(stderr,
              "Failed to write uncompressed size: %s\n",
              strerror(errno));
      goto cleanup;
    }
  }

  success = true;

cleanup:
  gkeycomp_destroy(comp);
  return success;
}

int main(int argc, const char *argv[])
{
  static const char description[] =
    "Gordon Key file compression utility, "VERSION_STRING"\n"
    "Copyright (C) 2011, Christopher Bazley\n";

  return main_common(argc, argv, comp, description, true);
}
