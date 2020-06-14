include platforms.mk

CLIENT_APPS=squirt_exec squirt_suck squirt_dir squirt_backup squirt squirt_cli squirt_cwd squirt_restore
MINGW_LIBS=-lws2_32 -liconv -lreadline

ifeq ($(PLATFORM),osx)
# OSX
CC=gcc
STATIC_ANALYZE=-fsanitize=address -fsanitize=undefined
LIBS=-liconv -lreadline
MINGW_GCC_PREFIX=/usr/local/mingw
MINGW_GCC=$(MINGW_GCC_PREFIX)/bin/x86_64-w64-mingw32-gcc
else ifeq ($(PLATFORM),raspberry_pi)
# Raspberry Pi
CC=gcc
LIBS=-lreadline
else ifeq ($(PLATFORM),linux)
# Linux
CC=gcc-10
STATIC_ANALYZE=-fanalyzer -fsanitize=address -fsanitize=undefined
LIBS=-lreadline
MINGW_GCC_PREFIX=/usr/x86_64-w64-mingw32
MINGW_GCC=x86_64-w64-mingw32-gcc
else ifeq ($(PLATFORM),mingw64)
# Mingw64
CC=gcc
CLIENT_APPS:=$(addsuffix .exe, $(CLIENT_APPS))
LIBS=$(MINGW_LIBS)
STATIC_ANALYZE=
endif

SQUIRTD_SRCS=squirtd.c
SQUIRT_SRCS=squirt.c exec.c suck.c dir.c main.c cli.c cwd.c srl.c util.c argv.c backup.c restore.c exall.c protect.c
HEADERS=main.h squirt.h exec.h cwd.h dir.h srl.h cli.h backup.h argv.h common.h util.h main.h suck.h restore.h exall.h protect.h
COMMON_DEPS=Makefile platforms.mk mingw.mk

VBCC_CC=vc
AMIGA_GCC_PREFIX=/usr/local/amiga/bebbo
AMIGA_GCC=$(AMIGA_GCC_PREFIX)/bin/m68k-amigaos-gcc -I$(AMIGA_GCC_PREFIX)/m68k-amigaos/ndk-include/

DEBUG_CFLAGS=-g $(STATIC_ANALYZE)
WARNINGS=-Wno-error=format -Wno-format -Wall -Werror -Wall -Wpedantic -Wno-unknown-attributes -Wno-ignored-optimization-argument -Wno-unknown-pragmas  -Wmissing-field-initializers -Wfatal-errors -Wextra -Wshadow -Wuninitialized  -Wundef -Wbad-function-cast -Wparentheses -Wnull-dereference -pedantic-errors

CFLAGS=$(DEBUG_CFLAGS) $(WARNINGS) #-Os
AMIGA_GCC_CFLAGS=-fwhole-program -msmall-code -Os -fomit-frame-pointer -noixemul $(WARNINGS)
VBCC_CFLAGS=-O1 +aos68k -c99


SQUIRTD_AMIGA_OBJS=$(addprefix build/obj/amiga/, $(SQUIRTD_SRCS:.c=.o))
SQUIRTD_AMIGA_GCC_OBJS= $(addprefix build/obj/amiga.gcc/, $(SQUIRTD_SRCS:.c=.o))
SQUIRTD_OBJS=$(addprefix build/obj/, $(SQUIRTD_SRCS:.c=.o))
SQUIRT_OBJS=$(addprefix build/obj/, $(SQUIRT_SRCS:.c=.o))

HOST_CLIENT_APPS=$(addprefix build/, $(CLIENT_APPS))
SERVER_APPS=build/amiga/squirtd build/amiga/skill build/amiga/sps #build/amiga/squirtd.vbcc

all: $(HOST_CLIENT_APPS) $(SERVER_APPS)

client: $(HOST_CLIENT_APPS)


build/squirt: $(SQUIRT_OBJS)
	$(CC) $(CFLAGS) $(SQUIRT_OBJS) -o build/squirt $(LIBS)

build/squirt%: $(SQUIRT_OBJS)
	$(CC) $(CFLAGS) $(SQUIRT_OBJS) -o build/squirt$* $(LIBS)

build/obj/%.o: %.c $(HEADERS) $(COMMON_DEPS)
	@mkdir -p build/obj
	$(CC) -c $(CFLAGS) $*.c -o build/obj/$*.o

build/obj/amiga/%.o: %.c $(COMMON_DEPS)
	@mkdir -p build/obj/amiga
	vc -c $(VBCC_CFLAGS) $*.c -c -o build/obj/amiga/$*.o

build/obj/amiga.gcc/%.o: %.c $(COMMON_DEPS)
	@mkdir -p build/obj/amiga.gcc
	$(AMIGA_GCC) $(AMIGA_GCC_CFLAGS) $*.c -c -o build/obj/amiga.gcc/$*.o

build/amiga/squirtd.vbcc: $(SQUIRTD_AMIGA_OBJS)
	@mkdir -p build/amiga
	vc $(VBCC_CFLAGS) $(SQUIRTD_AMIGA_OBJS) -o build/amiga/squirtd.vbcc -lauto

build/amiga/squirtd: $(SQUIRTD_AMIGA_GCC_OBJS)
	@mkdir -p build/amiga
	$(AMIGA_GCC) $(AMIGA_GCC_CFLAGS) -s $(SQUIRTD_AMIGA_GCC_OBJS) -o build/amiga/squirtd -lamiga

build/amiga/skill: kill.c
	@mkdir -p build/amiga
	$(AMIGA_GCC) $(AMIGA_GCC_CFLAGS) -s kill.c -o build/amiga/skill -lamiga

build/amiga/sps: ps.c
	@mkdir -p build/amiga
	$(AMIGA_GCC) $(AMIGA_GCC_CFLAGS) -s ps.c -o build/amiga/sps -lamiga

install: all
	cp $(HOST_CLIENT_APPS) /usr/local/bin/

clean:
	rm -rf build

include mingw.mk
