/*
 *  Gordon Key file compression utilities
 *  Decompression program entry point
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
#include "GKeyDecomp.h"

/* Local headers */
#include "misc.h"
#include "gkcommon.h"
#include "version.h"

/* Constant numeric values */
enum
{
  FEDNET_HEADER_SIZE = 4,   /* No. of bytes in a 32 bit integer */
  BUFFER_SIZE        = 256, /* I/O buffer size, in bytes */
  PROGRESS_FREQ      = 64,  /* No. of bytes to read between progress reports */
  FEDNET_COMP_LOG_2  = 9    /* Base 2 logarithm of the history size used by
                               the compression algorithm, in bytes */
};

static void show_progress(long int in, long int out)
{
  if (out > 0) {
    printf("Compression ratio %.2f%% (%ld bytes in, %ld bytes out)\n",
           ((double)in * 100) / out, in, out);
  }
}

static bool update_progress(void *arg, size_t in, size_t out)
{
  NOT_USED(arg);

  in += FEDNET_HEADER_SIZE; /* include uncompressed size at start of file */
  if (in % PROGRESS_FREQ == 0)
    show_progress((long int)in, (long int)out);

  return true; /* continue decompressing */
}

static bool decomp(FILE *in, FILE *out, unsigned int history_log_2, bool verbose)
{
  char in_buffer[BUFFER_SIZE], out_buffer[BUFFER_SIZE];
  bool in_pending, success = false;
  long int expected, out_total, in_total;
  GKeyDecomp *decomp = NULL;
  GKeyStatus status;
  GKeyParameters params;

  assert(in != NULL);
  assert(out != NULL);

  out_total = in_total = 0;

  /* Read the expected size of the decompressed data to check that the
     file wasn't truncated or otherwise corrupted. */
  if (!fread_int32le(&expected, in)) {
    fprintf(stderr,
            "Failed to read uncompressed size: %s\n",
            strerror(errno));
    goto cleanup;
  }
  in_total += FEDNET_HEADER_SIZE;

  if (expected < 0) {
    /* Gordon Key's file decompression module 'FDComp', which is presumably
       normative, rejects top bit set values. */
    fprintf(stderr,
            "Negative or over-large uncompressed size %ld\n",
            expected);
    goto cleanup;
  }

  decomp = gkeydecomp_make(history_log_2);
  if (decomp == NULL) {
    fprintf(stderr,
            "Failed to allocate memory: %s\n",
            strerror(errno));
    goto cleanup;
  }

  params.out_buffer = out_buffer;
  params.out_size = sizeof(out_buffer);
  params.in_size = 0;
  params.prog_cb = verbose ? update_progress : NULL;
  params.cb_arg = NULL;

  do {
    /* Is the input buffer empty? */
    if (params.in_size == 0) {
      /* Fill the input buffer by reading from file */
      params.in_buffer = in_buffer;
      params.in_size = fread(in_buffer, 1, sizeof(in_buffer), in);
      if (params.in_size != sizeof(in_buffer) && ferror(in)) {
        /* Read error not end of file */
        fprintf(stderr,
                "Failed to read compressed data from file: %s\n",
                strerror(errno));
        goto cleanup;
      }
      in_total += params.in_size;
    }

    /* Decompress the data from the input buffer to the output buffer */
    status = gkeydecomp_decompress(decomp, &params);

    /* If the input buffer is empty and it cannot be (re-)filled then
       there is no more input pending. */
    in_pending = params.in_size > 0 || !feof(in);

    if (in_pending && status == GKeyStatus_TruncatedInput)
    {
      /* False alarm before end of input data */
      status = GKeyStatus_OK;
    }

    /* Is there insufficient room in the output buffer or no more input? */
    if (status == GKeyStatus_BufferOverflow || !in_pending) {
      const size_t nout = sizeof(out_buffer) - params.out_size;
      out_total += nout;

      /* Empty the output buffer by writing to file */
      if (fwrite(out_buffer, 1, nout, out) != nout) {
        fprintf(stderr,
                "Failed to write %lu bytes to file: %s\n",
                (unsigned long)nout,
                strerror(errno));
        goto cleanup;
      }

      params.out_buffer = out_buffer;
      params.out_size = sizeof(out_buffer);
    }

    /* Continue decompressing data until the output buffer wasn't filled
       and there is no more input available. */
  } while (status == GKeyStatus_BufferOverflow || in_pending);

  if (verbose)
    show_progress(in_total, out_total);

  switch (status) {
    case GKeyStatus_BadInput:
      fprintf(stderr, "Compressed bitstream contains bad data\n");
      break;

    case GKeyStatus_TruncatedInput:
      fprintf(stderr, "Compressed bitstream appears truncated\n");
      break;

    default:
      if (out_total != expected) {
        fprintf(stderr,
                "Decompressed %ld bytes but expected %ld\n",
                out_total, expected);
      } else {
        success = true;
      }
      break;
  }

cleanup:
  gkeydecomp_destroy(decomp);
  return success;
}

int main(int argc, const char *argv[])
{
  static const char description[] =
    "Gordon Key file decompression utility, "VERSION_STRING"\n"
    "Copyright (C) 2011, Christopher Bazley\n";

  return main_common(argc, argv, decomp, description, false);
}
