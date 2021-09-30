BasicUpstart2(start)

.const ZP = $00
.const VRAM = $0400

// Zero Page
.const ZP_PARAM1 = $73
.const ZP_PARAM2 = $74
.const ZP_PARAM3 = $75
.const ZP_PARAM4 = $76

.const ZP_ADR = $FB
.const ZP_ADR_LO = $FB
.const ZP_ADR_HI = $FC

.const ZP_ADR2 = $FD
.const ZP_ADR2_LO = $FD
.const ZP_ADR2_HI = $FE

.const ZP_TMP = $02

.const pixel_characters = 128
.const pixel_00_00 = 128
.const pixel_10_00 = 129
.const pixel_01_00 = 130
.const pixel_00_10 = 131
.const pixel_00_01 = 132

#import "video.asm"
#import "chip8.asm"


        * = $4000 "Main Program"
        
start:
        lda #' '
        jsr vmem_fill
        jsr chip8_init_charset


        lda #0
        sta px
        sta py
test_loop:
        lda px
        sta ZP_PARAM1
        lda py
        sta ZP_PARAM2
        jsr chip8_set_pixel

        inc px
        inc py

        lda px
        cmp #20
        bne test_loop

sleep:
        jmp sleep

main_loop:
        ldy #3
        ldx #5
        jsr vmem_get_char

        clc
        adc #1
        ldy #3
        ldx #5
        jsr vmem_set_char

        jmp main_loop

end_of_program:
        jmp end_of_program

px:     .byte 0
py:     .byte 0

