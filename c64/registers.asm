#importonce

// Controls if the VM should run in debug mode and step through instructions
.const CHIP8_STEPPING_FLAG = 1

// 0: Compatibility with original CHIP-8 machine, the COSMAC
// 1: Compatibility with CHIP-48, SUPER-CHIP, etc
.const CHIP8_MODERN_FLAG = 2

// Refactoring in progress:
// This is same as ZP_ADR2.
// But there's nothing special about this that
// makes it an address, so let's call it a w0
// instead and treat it as a generic 16 bit register.
.label zp_w0 = $FD
.label zp_w0_lo = $FD
.label zp_w0_hi = $FE

// As above, this is same as ZP_ADR
.label zp_w1 = $FB
.label zp_w1_lo = $FB
.label zp_w1_hi = $FC

// As above, this is the same as ZP_PARAM1-2
.label zp_w2 = $73
.label zp_w2_lo = $73
.label zp_w2_hi = $74

.label ZP = $00
.label VRAM = $0400

.label ZP_PARAM1 = $73
.label ZP_PARAM2 = $74
.label ZP_PARAM3 = $75

.label ZP_TMP = $02

.label chip8_pc = $f7
.label chip8_pc_lo = $f7
.label chip8_pc_hi = $f8

// The CHIP8 index register
.label chip8_index = $2e
.label chip8_index_lo = $2e
.label chip8_index_hi = $2f

.label chip8_sp = $2d
.label chip8_vm_flags = $76

.label chip8_registers = $30
.label chip8_regf = $3f
