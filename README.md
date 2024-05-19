# GKeyComp
Gordon Key file compression utilities

(C) Chris Bazley, 2011

Version 0.05 (19 May 2024)

-----------------------------------------------------------------------------
 1   Introduction and Purpose
-----------------------------

  These command-line programs can be used to compress and decompress files
with an algorithm used in old Fourth Dimension and Fednet games for 32-bit
Acorn RISC OS computers such as 'Chocks Away', 'Stunt Racer 2000' and 'Star
Fighter 3000'. Compression is lossless.

  The original compression code was written by Gordon Key in ARM assembly
language. These programs use GKeyLib's portable implementation of the
same algorithm in ISO standard 'C'.

-----------------------------------------------------------------------------
2   Requirements
----------------

  The supplied executable file will only work on RISC OS machines. It has
not been tested on any version of RISC OS earlier than 3.7, although it
should also work on earlier versions provided that a 'SharedCLibrary' module
is active. It is known to be compatible with 32 bit versions of RISC OS.

-----------------------------------------------------------------------------
3   Quick Guide
---------------

  To compress a file, use the gkcomp program. In the following example,
uncompressed input is read from a file named 'orange' and compressed output
is written to a file named 'squeezed':
```
  *gkcomp orange squeezed
```
  To decompress a file, use the gkdecomp program. In the following example,
compressed input is read from a file named 'squeezed' and decompressed
output is written to a file named 'orange':
```
  *gkdecomp squeezed orange
```
  If the application directories of any old Fourth Dimension or Fednet games
have been 'seen' by the Filer then you might like to try decompressing some
of their files:
```
  *gkdecomp <Chocks$Dir>.Code <Wimp$ScrapDir>.Chocks
  *gkdecomp <SR2000$Dir>.Code.Code <Wimp$ScrapDir>.SR2000
  *gkdecomp <Star3000$Dir>.Code.Code <Wimp$ScrapDir>.Star3000
  *Filer_OpenDir <Wimp$ScrapDir>
```
  To display information about how to use either program, use the '-help'
switch (which may be abbreviated, e.g. 'gkcomp -h').

-----------------------------------------------------------------------------
4   Detailed guide
------------------

4.1 Command line syntax
-----------------------
```
usage: gk[de]comp [switches] inputfile [outputfile]
or     gk[de]comp -batch [switches] file1 [file2 file3 .. fileN]
```
Switches (names may be abbreviated):
```
  -help               Display this text
  -batch              Process a batch of files
  -outfile name       Specify name for output file
  -history N          History buffer size as a base 2 logarithm
  -time               Show the total time for each file processed
  -verbose or -debug  Emit debug information (and keep bad output)
```
  These programs have two principle modes of operation: single file mode
and batch processing. All switches are optional, but some are incompatible
with each other (e.g. '-batch' with '-outfile').

4.2 Single file mode
--------------------
  Single file mode is the default mode of operation. Unlike batch mode,
the input and output files can be specified separately, which allows the
input file to be kept rather than overwritten. An output file name can be
specified after the input file name, or before it using the '-outfile'
switch.

  If no input file is specified, input is read from 'stdin' (the standard
input stream; keyboard unless redirected). If no output file is specified,
output is written to 'stdout' (the standard output stream; screen unless
redirected).

  All of the following examples read input from a file named 'foo' and
write to a file named 'bar':
```
  gkcomp foo bar
  gkcomp -outfile bar foo
  gkcomp -outfile bar <foo
  gkcomp foo >bar
```
  The last command isn't quite equivalent to those preceding it because
under RISC OS the type of the output file isn't set correctly unless its
name is visible to gkcomp/gkdecomp (otherwise it receives type 'Text').

  Under UNIX-like operating systems, output from gkcomp or gkdecomp can be
piped directly into another program.

  Search for text in a compressed file named 'foo':
```
  gkdecomp foo | grep -i 'snails'
```
  A bizarre method of copying a file named 'foo' as 'bar':
```
  gkcomp foo | gkdecomp >bar
```
  Compressed files begin with a header giving the uncompressed size of their
contents. This can be tricky to prepend because it requires random access on
either the input or output stream, or all of the input data to be loaded into
memory before writing any output.

  By preference, gkcomp leaves room for the header and returns to write it
when all of the input has been read. If that is not possible (e.g. stdout to
a terminal) then it tries to find out the length of the input before reading
it. If that fails too (e.g. stdin from a terminal) then gkcomp gives up.

4.3 Batch processing mode
-------------------------
  Batch processing is enabled by the switch '-batch'. In this mode, multiple
files can be compressed or decompressed using a single command. However,
output always overwrites the input files and programs cannot be chained
using pipes as in the examples above. At least one file name must be
specified.

  Decompress a file named 'foo' in-situ:
```
  gkdecomp -batch foo
```
  Compress files named 'foo', 'bar' and 'baz' in-situ:
```
  gkcomp -batch foo bar baz
```
  If the input and output file names are the same, or a batch of files was
specified, output will be written to a temporary file before being copied
over the input file. This only works when gkcomp/gkdecomp have visibility of
both file names; not when reading from 'stdin' or writing to 'stdout' when
either has been redirected to a file.

  Workable examples:
```
  gkcomp -batch foo
  gkcomp foo foo
  gkcomp -outfile foo foo
```
  Unworkable examples:
```
  gkcomp foo >foo
  gkcomp -outfile foo <foo
```

4.4 History buffer size
-----------------------
  The history buffer is used when searching for byte sequences that can be
recycled in preference to outputting a literal byte value. Its size is
specified by the '-history' switch as a base 2 logarithm. The default value
of '9' (512 bytes) matches Gordon Key's file format and should be adequate
for most purposes.

  You can experiment with different values to investigate the effect on
speed and compression ratio. The amount of memory used for the history
buffer and time needed to search it increase logarithmically with its size.

  Up to a point, a larger history buffer typically improves the compression
ratio, but eventually the greater number of bits required to represent
offsets and sizes in the output outweighs any gains from the ability to
copy more distant data. Sometimes that occurs even before the history buffer
size exceeds the input size. This effect can be seen in the following timings
(compressing 17.56 KB G.P.L. v2 on a StrongARM Risc PC):

|  History (log 2)  | Time taken (sec) | Compression ratio (%)
|-------------------|------------------|----------------------
|  0 (1 byte)       | 0.08 (best)      | 112.53 (worst)
|  1                | 0.08             | 110.37
|  2                | 0.09             | 103.18
|  3                | 0.10             |  99.30
|  4                | 0.11             | 101.84
|  5                | 0.13             |  96.71
|  6                | 0.16             |  88.86
|  7                | 0.21             |  80.88
|  8                | 0.29             |  75.96
|  9                | 0.42             |  71.22
|  10 (1 KB)        | 0.63             |  65.87
|  11               | 1.01             |  64.22
|  12               | 1.59             |  62.22 (best)
|  13               | 2.52             |  62.42
|  14 (< input size)| 3.43             |  62.59
|  15 (> input size)| 3.45             |  64.75
|  16               | 3.45             |  67.33
|  17               | 3.44             |  69.92
|  18               | 3.47             |  72.51
|  19               | 3.47             |  74.47
|  20 (1 MB)        | 3.48 (worst)     |  76.41

  When invoking gkdecomp, you must specify the same history buffer size as
that used to compress the input. Failure to do so may result in garbage
output but more likely the error message 'Compressed bitstream contains bad
data'.

4.5 Getting diagnostic information
----------------------------------
  If either of the switches '-verbose' and '-debug' is used then gkcomp or
gkdecomp will emit information about their internal operation on the
standard output stream. For example, the number of bytes read/written and
current compression ratio are printed periodically. However, this makes them
slower and prevents output being piped to another program.

  If the switch '-time' is used then the total time for each file processed
(to centisecond precision) is printed. This can be used independently of
'-verbose' and '-debug'.

  When debugging output or the timer is enabled, you must specify an output
file name. Otherwise the output from the compressor or decompressor would
be sent to the standard output stream and become mixed up with the
diagnostic information.

-----------------------------------------------------------------------------
5   Compression format
----------------------

  The first 4 bytes of a compressed file give the expected size of the data
when decompressed, as a 32 bit signed little-endian integer. Gordon Key's
file decompression module 'FDComp', which is presumably normative, rejects
input files where the top bit of the fourth byte is set (i.e. negative
values).

  Thereafter, the compressed data consists of tightly packed groups of 1, 8
or 9 bits without any padding between them or alignment with byte boundaries.
A decompressor must deal with two main types of directive: The first (store a
byte) consists of 1+8=9 bits and the second (copy previously-decompressed
data) consists of 1+9+8=18 or 1+9+9=19 bits.

The type of each directive is determined by whether its first bit is set:

0.   The next 8 bits of the input file give a literal byte value (0-255) to
   be written at the current output position.

     When attempting to compress input that contains few repeating patterns,
   the output may actually be larger than the input because each byte value
   is encoded using 9 rather than 8 bits.

1.   The next 9 bits of the input file give an offset (0-511) within the data
   already decompressed, relative to a point 512 bytes behind the current
   output position.

     If the offset is greater than or equal to 256 (i.e. within the last 256
   bytes written) then the next 8 bits give the number of bytes (0-255) to be
   copied to the current output position. Otherwise, the number of bytes
   (0-511) to be copied is encoded using 9 bits.

If the read pointer is before the start of the output buffer then zeros
  should be written at the output position until it becomes valid again. This
  is a legitimate method of initialising areas of memory with zeros.

It isn't possible to replicate the whole of the preceding 512 bytes in
  one operation.

  The decompressors written by the Fourth Dimension and David O'Shea always
copy at least 1 byte from the source offset, even if the compressed bitstream
specified 0 as the number of bytes to be copied. A well-written compressor
should not insert directives to copy 0 bytes and no instances are known in
the wild. CBLibrary's new decompressor will treat directives to copy 0 bytes
as invalid input.

-----------------------------------------------------------------------------
6   File types
--------------

  There follows a list of the known filetypes that a Fednet compressed file
may have. Beware that files of type &400 are not necessarily compressed
because the 'Stunt Racer 2000' track editor saves non-compressed tracks with
this type!

| Type | Name         | Contents
|------|--------------|----------------------------------------------
| &154 | Fednet   (1) | SF3000 or SR2000 compressed code or data.
| &300 | SFObjGfx (4) | SF3000 compressed polygonal objects set.
| &400 | SFBasMap (4) | SF3000 compressed ground map, or
|      |              | SR2000 track (not necessarily compressed).
| &402 | SFBasObj (4) | SF3000 compressed objects map.
| &401 | SFOvrMap (4) | SF3000 compressed ground map overlay, or
|      |              | SR2000 rec file.
| &403 | SFOvrObj (4) | SF3000 compressed objects map overlay.
| &404 | SFSkyCol (2) | SF3000 compressed sky colours.
| &405 | SFMissn  (4) | SF3000 compressed mission data.
| &406 | SFSkyPic (3) | SF3000 compressed sky pictures set.
| &407 | SFMapGfx (5) | SF3000 compressed map tile graphics set.
| &408 | SFMapAni (4) | SF3000 compressed ground map animations.
| &FFD | Data         | 'Chocks Away' or SR2000 compressed code or data (not easily identifiable).

1) Only named if !FednetCmp or !SFcolours has been 'seen' by the Filer.
2) Only named if !SFskyedit has been 'seen' by the Filer.
3) Only named if !SFtoSpr has been 'seen' by the Filer.
4) Only named if !SFeditor has been 'seen' by the Filer.
5) Only named if !SFeditor or !SFtoSpr has been 'seen' by the Filer.

-----------------------------------------------------------------------------
8   Program history
-------------------

0.01 (28 Jan 2011)
- First public release.

0.02 (30 Jan 2011)
- Fixed a bug in gkdecomp. It produced truncated output if all of the input
  had been fed to the decompressor before all of the output had been generated
  (e.g. because of output buffer overflow).

0.03 (07 Nov 2018)
- Adapted to use CBUtilLib and GKeyLib instead of the monolithic CBLibrary
  previously required. The is_switch, fwrite_int32le and fread_int32le
  functions can be found in CBUtilLib therefore local versions of them were
  deleted.
- Created an alternative makefile for use with GNU Make and the GNU C
  Compiler.
- The supplied executable file was compiled with GCCSDK GCC 4.7.4 Release 2)
  instead of the Norcroft RISC OS ARM C compiler.

0.04 (02 May 2020)
- Failure to close the output stream is now detected and treated like any
  other error since data may have been lost.

0.05 (19 May 2024)
- Added a new makefile for use on Linux.
- Improved the README.md file for Linux users.
- Some code is now conditionally compiled only if the macro ACORN_C is defined.

-----------------------------------------------------------------------------
9   Compiling the program
-------------------------

  Source code is only supplied for the command-line programs. To compile
and link the code you will also require an ISO 9899:1999 standard 'C'
library and two of my own libraries: CBUtilLib and GKeyLib. These are
available separately from http://starfighter.acornarcade.com/mysite/

  Three makefiles are supplied:

1. 'Makefile' is intended for use with GNU Make and the GNU C Compiler on Linux.

2. 'NMakefile' is intended for use with Acorn Make Utility (AMU) and the
   Norcroft C compiler supplied with the Acorn C/C++ Development Suite.

3. 'GMakefile' is intended for use with GNU Make and the GNU C Compiler on RISC OS.

  The APCS variant specified for the Norcroft compiler is 32 bit for
compatibility with ARMv5 and fpe2 for compatibility with older versions of
the floating point emulator. Generation of unaligned data loads/stores is
disabled for compatibility with ARMv6. When building the code for release,
it is linked with RISCOS Ltd's generic C library stubs ('StubsG').

  Before compiling the library for RISC OS, move the C source and header files
with .c and .h suffixes into subdirectories named 'c' and 'h' and remove
those suffixes from their names. You probably also need to create 'o', 'd'
and 'debug' subdirectories for compiler output.

  The only platform-specific code is the PATH_SEPARATOR macro definition in
misc.h. This must be defined according to the file name convention on the
target platform (e.g. '\\' for DOS or Windows).

-----------------------------------------------------------------------------
10  Licence and Disclaimer
--------------------------

  These programs are free software; you can redistribute them and/or modify
them under the terms of the GNU General Public Licence as published by the
Free Software Foundation; either version 2 of the Licence, or (at your
option) any later version.

  These programs are distributed in the hope that they will be useful, but
WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public Licence for
more details.

  You should have received a copy of the GNU General Public Licence along
with this program; if not, write to the Free Software Foundation, Inc.,
675 Mass Ave, Cambridge, MA 02139, USA.

  These programs use CBLibrary, which is (C) 2003 Chris Bazley. This library
and its use are covered by the GNU Lesser General Public Licence.

-----------------------------------------------------------------------------
11  Credits
-----------

  gkcomp and gkdecomp were designed and programmed by Christopher Bazley.

  Credit to David O'Shea and Keith McKillop for working out the Fednet
compression algorithm. (David wrote a DeComp module for the Stunt Racer 2000
track designer, which was a useful point of comparison.)

  The game Star Fighter 3000 is (C) FEDNET Software 1994, 1995.

-----------------------------------------------------------------------------
12  Contact details
-------------------

  Feel free to contact me with any bug reports, suggestions or anything else.

  Email: mailto:cs99cjb@gmail.com

  WWW:   http://starfighter.acornarcade.com
