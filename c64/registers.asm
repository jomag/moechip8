#importonce

.label ZP = $00
.label VRAM = $0400

.label ZP_PARAM1 = $73
.label ZP_PARAM2 = $74
.label ZP_PARAM3 = $75
.label ZP_PARAM4 = $76

.label ZP_ADR = $FB
.label ZP_ADR_LO = $FB
.label ZP_ADR_HI = $FC

.label ZP_ADR2 = $FD
.label ZP_ADR2_LO = $FD
.label ZP_ADR2_HI = $FE

.label ZP_TMP = $02

.label chip8_pc = $f7
.label chip8_pc_lo = $f7
.label chip8_pc_hi = $f8

// The CHIP8 index register
.label chip8_index = $2e
.label chip8_index_lo = $2e
.label chip8_index_hi = $2f

.label chip8_registers = $30
.label chip8_regf = $3f
