
AS=kickass
AS_FLAGS=-vicesymbols

EMU=~/c64/ViceGTK/bin/x64sc
EMU_FLAGS=-autostartprgmode 1 -initbreak 4000 --moncommands hello.vs

SRCS=hello.asm video.asm chip8.asm chip8_op.asm registers.asm

hello.prg: $(SRCS)
	$(AS) hello.asm $(AS_FLAGS)

run: hello.prg
	$(EMU) $(EMU_FLAGS) hello.prg

emu:
	$(EMU)

