# TinyRTOS Makefile

PREFIX  ?= riscv64-unknown-elf-
CC      := $(PREFIX)gcc
OBJDUMP := $(PREFIX)objdump
NM      := $(PREFIX)nm
GDB     ?= riscv64-elf-gdb
QEMU    ?= qemu-system-riscv32

BUILD   := build
ELF     := $(BUILD)/kernel.elf
SRC     := src/boot.S
OBJ     := $(BUILD)/boot.o
LDSCRIPT := link.ld

ARCH    := -march=rv32ima_zicsr -mabi=ilp32
ASFLAGS := $(ARCH) -g -Iinclude -MMD -MP
LDFLAGS := $(ARCH) -nostdlib -nostartfiles -T $(LDSCRIPT) \
           -Wl,--no-warn-rwx-segments \
           -Wl,-Map=$(BUILD)/kernel.map

QFLAGS  := -machine virt -nographic -bios none -kernel $(ELF)

.PHONY: all run debug gdb dis syms check clean

all: $(ELF)

# Step 2: Link the object file into the final ELF
$(ELF): $(OBJ) $(LDSCRIPT) | $(BUILD)
	$(CC) $(LDFLAGS) -o $@ $(OBJ)

# Step 1: Compile boot.S into an object file
$(OBJ): $(SRC) | $(BUILD)
	$(CC) $(ASFLAGS) -c $< -o $@

# Create build directory if needed
$(BUILD):
	mkdir -p $(BUILD)

# Check entry point and stack symbol addresses
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
