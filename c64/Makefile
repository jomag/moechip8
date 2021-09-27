
AS=kickass
EMU=/Applications/vice-sdl2-3.4-r37694/VICE.app/Contents/Resources/bin/x64sc
EMU_FLAGS=-autostartprgmode 1

hello.prg: hello.asm
	$(AS) hello.asm

run: hello.prg
	$(EMU) $(EMU_FLAGS) hello.prg

emu:
	$(EMU)

