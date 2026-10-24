
PREFIX  ?= riscv64-unknown-elf-
CC      := $(PREFIX)gcc
OBJDUMP := $(PREFIX)objdump
NM      := $(PREFIX)nm
GDB     ?= $(PREFIX)gdb          # override: make gdb GDB=riscv64-elf-gdb
QEMU    ?= qemu-system-riscv32

BUILD   := build
ELF     := $(BUILD)/kernel.elf
LDSCRIPT:= link.ld

SRCS    := $(wildcard src/*.S)
OBJS    := $(patsubst src/%.S,$(BUILD)/%.o,$(SRCS))
DEPS    := $(OBJS:.o=.d)

ARCH    := -march=rv32ima_zicsr -mabi=ilp32
ASFLAGS := $(ARCH) -g -Iinc -MMD -MP
LDFLAGS := $(ARCH) -nostdlib -nostartfiles -T $(LDSCRIPT) \
           -Wl,--no-warn-rwx-segments -Wl,-Map=$(BUILD)/kernel.map

QFLAGS  := -machine virt -nographic -bios none -kernel $(ELF)

.PHONY: all run debug gdb dis syms dtb clean

all: $(ELF)

$(ELF): $(OBJS) $(LDSCRIPT)
	$(CC) $(LDFLAGS) -o $@ $(OBJS)

$(BUILD)/%.o: src/%.S | $(BUILD)
	$(CC) $(ASFLAGS) -c $< -o $@

$(BUILD):
	mkdir -p $(BUILD)

run: $(ELF)              # exit QEMU with Ctrl-A then X
	$(QEMU) $(QFLAGS)

debug: $(ELF)            # terminal 1: QEMU frozen, waiting for gdb on :1234
	$(QEMU) $(QFLAGS) -s -S

gdb: $(ELF)              # terminal 2
	$(GDB) -ex 'set architecture riscv:rv32' -ex 'target remote :1234' $(ELF)

dis: $(ELF)
	$(OBJDUMP) -d -M no-aliases $(ELF) | less

syms: $(ELF)
	$(NM) -n $(ELF)

dtb:                     # regenerate the device tree dump
	$(QEMU) -machine virt,dumpdtb=$(BUILD)/virt.dtb
	dtc -I dtb -O dts $(BUILD)/virt.dtb -o $(BUILD)/virt.dts

clean:
	rm -rf $(BUILD)

-include $(DEPS)
