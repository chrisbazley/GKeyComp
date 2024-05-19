# Project:   GKeyComp

# Tools
CC = cc
Link = link

# Toolflags:
CCCommonFlags = -c -depend !Depend -IC: -throwback -fahi -apcs 3/32/fpe2/swst/fp/nofpr -memaccess -L22-S22-L41
CCflags = $(CCCommonFlags) -DNDEBUG -Otime
CCDebugFlags = $(CCCommonFlags) -g -DUSE_CBDEBUG -DFORTIFY -DDEBUG_OUTPUT
Linkflags = -aif
LinkDebugFlags = $(Linkflags) -d

include MakeCommon

DebugObjectsComp = $(addprefix debug.,$(ObjectListComp))
ReleaseObjectsComp = $(addprefix o.,$(ObjectListComp))

DebugObjectsDecomp = $(addprefix debug.,$(ObjectListDecomp))
ReleaseObjectsDecomp = $(addprefix o.,$(ObjectListDecomp))

DebugLibs = C:o.Stubs C:o.Fortify C:o.CBDebugLib C:debug.CBUtilLib C:debug.GKeyLib
ReleaseLibs = C:o.StubsG C:o.CBUtilLib C:o.GKeyLib

# Final targets:
all: gkdecomp gkcomp gkdecompD gkcompD

gkcomp: $(ReleaseObjectsComp)
	$(Link) $(LinkFlags) $(ReleaseObjectsComp) $(ReleaseLibs)

gkcompD: $(DebugObjectsComp)
	$(Link) $(LinkDebugFlags) $(DebugObjectsComp) $(DebugLibs)

gkdecomp: $(ReleaseObjectsDecomp)
	$(Link) $(LinkFlags) $(ReleaseObjectsDecomp) $(ReleaseLibs)

gkdecompD: $(DebugObjectsDecomp)
	$(Link) $(LinkDebugFlags) $(DebugObjectsDecomp) $(DebugLibs)

# User-editable dependencies:
.SUFFIXES: .o .c .debug
.c.o:; $(CC) $(CCflags) -o $@ $<
.c.debug:; $(CC) $(CCDebugFlags) -o $@ $<

# Static dependencies:

# Dynamic dependencies:
