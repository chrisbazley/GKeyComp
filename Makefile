# Project: GKeyComp

# Tools
CC = gcc
Link = gcc

# Toolflags:
CCCommonFlags = -c  -Wall -Wextra -pedantic -std=c99 -MMD -MP -o $@
CCFlags = $(CCCommonFlags) -DNDEBUG -O3 -MF $*.d
CCDebugFlags = $(CCCommonFlags) -g -DDEBUG_OUTPUT -MF $*D.d
LinkCommonFlags = -o $@
LinkFlags = $(LinkCommonFlags) $(addprefix -l,$(ReleaseLibs))
LinkDebugFlags = $(LinkCommonFlags) $(addprefix -l,$(DebugLibs))

include MakeCommon

DebugObjectsComp = $(addsuffix .debug,$(ObjectListComp))
ReleaseObjectsComp = $(addsuffix .o,$(ObjectListComp))

DebugObjectsDecomp = $(addsuffix .debug,$(ObjectListDecomp))
ReleaseObjectsDecomp = $(addsuffix .o,$(ObjectListDecomp))

DebugLibs = CBUtildbg GKeydbg
ReleaseLibs = CBUtil GKey 

# Final targets:
all: gkdecomp gkcomp gkdecompD gkcompD

gkcomp: $(ReleaseObjectsComp)
	$(Link) $(ReleaseObjectsComp) $(LinkFlags)

gkcompD: $(DebugObjectsComp)
	$(Link) $(DebugObjectsComp) $(LinkDebugFlags)

gkdecomp: $(ReleaseObjectsDecomp)
	$(Link) $(ReleaseObjectsDecomp) $(LinkFlags)

gkdecompD: $(DebugObjectsDecomp)
	$(Link) $(DebugObjectsDecomp) $(LinkDebugFlags)

# User-editable dependencies:
.SUFFIXES: .o .c .debug
.c.debug:
	$(CC) $(CCDebugFlags) $<

.c.o:
	$(CC) $(CCFlags) $<

# Static dependencies:

# Dynamic dependencies:
# These files are generated during compilation to track C header #includes.
# It's not an error if they don't exist.
-include $(addsuffix .d,$(ObjectListComp))
-include $(addsuffix D.d,$(ObjectListComp))
-include $(addsuffix .d,$(ObjectListDecomp))
-include $(addsuffix D.d,$(ObjectListDecomp))
