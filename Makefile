# Advanced Makefile for mixed ASM and C compilation with NASM, Clang, and LLD-Link
# Supports debug, dev, and release builds

# Compiler and linker settings
ASM = nasm
CC = clang
LINK = lld-link

# Build configuration (can be overridden via command line)
# Options: release, debug, dev
CONFIG ?= dev
APP_ENTRY ?= main
FILE_NAME ?= "stories/game.bin"
SKIP_ANIMATIONS ?= 0

# Output directory structure
BUILD_DIR = build
OBJ_DIR = $(BUILD_DIR)/obj/$(CONFIG)
BIN_DIR = $(BUILD_DIR)/bin/$(CONFIG)

# Primary target name
TARGET = game

# File extensions
ASM_EXT = .asm
C_EXT = .c
INC_EXT = .inc
H_EXT = .h
OBJ_EXT = .obj
EXE_EXT = .exe
LST_EXT = .lst
PDB_EXT = .pdb
MAP_EXT = .map

# Final executable path
EXE_FILE = $(BIN_DIR)/$(TARGET)$(EXE_EXT)

# Source directories
SRC_DIR = src
ASM_DIR = $(SRC_DIR)/asm
C_DIR = $(SRC_DIR)/c
INCLUDE_DIR = $(SRC_DIR)/include

# Find all source files
ASM_SRCS = $(wildcard $(ASM_DIR)/*$(ASM_EXT))
C_SRCS = $(wildcard $(C_DIR)/*$(C_EXT))
INC_SRCS = $(wildcard $(INCLUDE_DIR)/*$(INC_EXT))

# Generate object file paths
ASM_OBJS = $(patsubst $(ASM_DIR)/%$(ASM_EXT),$(OBJ_DIR)/asm/%$(OBJ_EXT),$(ASM_SRCS))
C_OBJS = $(patsubst $(C_DIR)/%$(C_EXT),$(OBJ_DIR)/c/%$(OBJ_EXT),$(C_SRCS))
ALL_OBJS = $(ASM_OBJS) $(C_OBJS)
# Make all assembly objects depend on all include files
$(ASM_OBJS): $(INC_SRCS)

# Common linker settings
COMMON_LINKFLAGS = -entry:$(APP_ENTRY) -subsystem:console /defaultlib:kernel32.lib /defaultlib:msvcrt.lib /defaultlib:vcruntime.lib /defaultlib:ucrt.lib

# Configuration-specific flags
ifeq ($(CONFIG),dev)
    # Development configuration (faster iteration, skips animations)
    ASMFLAGS = -f win64 -g -DDEV_BUILD=1 -DDEBUG_LOG=1 -DFILE_NAME="\"$(FILE_NAME)\"" -DSKIP_ANIMATIONS=$(SKIP_ANIMATIONS) -I$(INCLUDE_DIR)
    CFLAGS = -c -O1 -DDEV_BUILD=1 -I$(INCLUDE_DIR)
    LINKFLAGS = /debug /map:$(BIN_DIR)/$(TARGET)$(MAP_EXT) /pdb:$(BIN_DIR)/$(TARGET)$(PDB_EXT) $(COMMON_LINKFLAGS)
else
    # Release configuration
    ASMFLAGS = -f win64 -I$(INCLUDE_DIR) -DSKIP_ANIMATIONS=$(SKIP_ANIMATIONS) -DFILE_NAME="\"$(FILE_NAME)\""
    CFLAGS = -c -O2 -I$(INCLUDE_DIR)
    LINKFLAGS = /release $(COMMON_LINKFLAGS)
endif

# Default rule
all: prepare $(EXE_FILE)

# Create necessary directories
prepare:
	-@md $(subst /,\,$(BIN_DIR)) 2>NUL || echo.
	-@md $(subst /,\,$(OBJ_DIR)\asm) 2>NUL || echo.
	-@md $(subst /,\,$(OBJ_DIR)\c) 2>NUL || echo.

# Link all object files into the final executable
$(EXE_FILE): $(ALL_OBJS)
	$(LINK) $(LINKFLAGS) $^ /out:$@
	@echo Build complete for $(CONFIG) configuration: $@

# Compile ASM files
$(OBJ_DIR)/asm/%$(OBJ_EXT): $(ASM_DIR)/%$(ASM_EXT)
	$(ASM) $(ASMFLAGS) -o $@ $<

# Compile C files
$(OBJ_DIR)/c/%$(OBJ_EXT): $(C_DIR)/%$(C_EXT)
	$(CC) $(CFLAGS) -o $@ $<

# Clean build artifacts
clean:
	-@rd /s /q $(subst /,\,$(BUILD_DIR)) 2>NUL || echo.

# Clean and rebuild
rebuild: clean all

# Phony targets
.PHONY: all prepare clean rebuild run debug help release

# Build-specific targets for convenience
build: all

run: build
	$(BIN_DIR)/$(TARGET)$(EXE_EXT)

debug: build
	x64dbg $(CURDIR)/$(BIN_DIR)/$(TARGET)$(EXE_EXT) "" "$(CURDIR)"

# Help information
help:
	@echo ------ Directory Structure ------
	@echo src/asm/          - Assembly source files (.asm)
	@echo src/c/            - C source files (.c)
	@echo src/include/      - Header files for both C (.h) and Assembly (.inc)
	@echo build/            - Build outputs (organized by configuration)
	@echo.
	@echo ------ Build Options ------
	@echo make               - Builds with default configuration ($(CONFIG))
	@echo make CONFIG=XXXX   - Builds with specified configuration
	@echo make release       - Builds release configuration
	@echo make dev           - Builds development configuration (skips animations)
	@echo make debug-build   - Builds debug configuration
	@echo.
	@echo ------ Run/Debug Commands ------
	@echo make run           - Builds and runs with current configuration
	@echo make run-release   - Builds and runs release configuration
	@echo make run-dev       - Builds and runs development configuration
	@echo make run-debug     - Builds and runs debug configuration
	@echo make debug         - Builds and starts x64dbg with current configuration
	@echo make debug-release - Builds and debugs release configuration
	@echo make debug-dev     - Builds and debugs development configuration
	@echo make debug-debug   - Builds and debugs debug configuration
	@echo.
	@echo ------ Other Commands ------
	@echo make clean         - Removes all build artifacts
	@echo make rebuild       - Clean and rebuild
	@echo make help          - Shows this help message