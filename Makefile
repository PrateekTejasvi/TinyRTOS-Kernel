# TinyRTOS Makefile

PREFIX  ?= riscv64-unknown-elf-
CC      := $(PREFIX)gcc
OBJDUMP := $(PREFIX)objdump
NM      := $(PREFIX)nm
GDB     ?= riscv64-elf-gdb
QEMU    ?= qemu-system-riscv32

BUILD   := build
ELF     := $(BUILD)/kernel.elf
LDSCRIPT := link.ld

# Automatically find all assembly source files
SRC     := $(wildcard src/*.s src/*.S)
OBJ     := $(patsubst src/%.s,$(BUILD)/%.o,$(filter %.s,$(SRC))) \
           $(patsubst src/%.S,$(BUILD)/%.o,$(filter %.S,$(SRC)))

ARCH    := -march=rv32ima_zicsr -mabi=ilp32
ASFLAGS := $(ARCH) -g -Iinclude -MMD -MP
LDFLAGS := $(ARCH) -nostdlib -nostartfiles -T $(LDSCRIPT) \
           -Wl,--no-warn-rwx-segments \
           -Wl,-Map=$(BUILD)/kernel.map

QFLAGS  := -machine virt -nographic -bios none -kernel $(ELF)

.PHONY: all run debug gdb dis syms check clean

all: $(ELF)

# Create build directory
$(BUILD):
	mkdir -p $(BUILD)

# Compile lowercase .s files
$(BUILD)/%.o: src/%.s | $(BUILD)
	$(CC) $(ASFLAGS) -c $< -o $@

# Compile uppercase .S files
$(BUILD)/%.o: src/%.S | $(BUILD)
	$(CC) $(ASFLAGS) -c $< -o $@

# Link all object files
$(ELF): $(OBJ) $(LDSCRIPT) | $(BUILD)
	$(CC) $(LDFLAGS) -o $@ $(OBJ)

# Utilities
check: $(ELF)
	$(NM) $(ELF) | grep -E '_start|__stack_top'

syms: $(ELF)
	$(NM) -n $(ELF)

dis: $(ELF)
	$(OBJDUMP) -d -M no-aliases $(ELF) | less

run: $(ELF)
	$(QEMU) $(QFLAGS)

debug: $(ELF)
	$(QEMU) $(QFLAGS) -s -S

gdb: $(ELF)
	$(GDB) -ex 'set architecture riscv:rv32' \
	       -ex 'target remote :1234' $(ELF)

clean:
	rm -rf $(BUILD)

-include $(OBJ:.o=.d)
