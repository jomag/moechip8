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

characters:
        .byte $00, $00, $00, $00, $00, $00, $00, $00 // 00 00
        .byte $F0, $F0, $F0, $F0, $00, $00, $00, $00 // 10 00
        .byte $0F, $0F, $0F, $0F, $00, $00, $00, $00 // 01 00
        .byte $FF, $FF, $FF, $FF, $00, $00, $00, $00 // 11 00
        .byte $00, $00, $00, $00, $F0, $F0, $F0, $F0 // 00 10
        .byte $F0, $F0, $F0, $F0, $F0, $F0, $F0, $F0 // 10 10
        .byte $0F, $0F, $0F, $0F, $F0, $F0, $F0, $F0 // 01 10
        .byte $FF, $FF, $FF, $FF, $F0, $F0, $F0, $F0 // 11 10
        .byte $00, $00, $00, $00, $0F, $0F, $0F, $0F // 00 01
        .byte $F0, $F0, $F0, $F0, $0F, $0F, $0F, $0F // 10 01
        .byte $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F // 01 01
        .byte $FF, $FF, $FF, $FF, $0F, $0F, $0F, $0F // 11 01
        .byte $00, $00, $00, $00, $FF, $FF, $FF, $FF // 00 11
        .byte $F0, $F0, $F0, $F0, $FF, $FF, $FF, $FF // 10 11
        .byte $0F, $0F, $0F, $0F, $FF, $FF, $FF, $FF // 01 11
        .byte $FF, $FF, $FF, $FF, $FF, $FF, $FF, $FF // 11 11

vram_row_lo:
        .byte <VRAM,     <VRAM+40,  <VRAM+80,  <VRAM+120, <VRAM+160
        .byte <VRAM+200, <VRAM+240, <VRAM+280, <VRAM+320, <VRAM+360
        .byte <VRAM+400, <VRAM+440, <VRAM+480, <VRAM+520, <VRAM+560
        .byte <VRAM+600, <VRAM+640, <VRAM+680, <VRAM+720, <VRAM+760
        .byte <VRAM+800, <VRAM+840, <VRAM+880, <VRAM+920, <VRAM+960

vram_row_hi:
        .byte >VRAM,     >VRAM+40,  >VRAM+80,  >VRAM+120, >VRAM+160
        .byte >VRAM+200, >VRAM+240, >VRAM+280, >VRAM+320, >VRAM+360
        .byte >VRAM+400, >VRAM+440, >VRAM+480, >VRAM+520, >VRAM+560
        .byte >VRAM+600, >VRAM+640, >VRAM+680, >VRAM+720, >VRAM+760
        .byte >VRAM+800, >VRAM+840, >VRAM+880, >VRAM+920, >VRAM+960

        * = $4000 "Main Program"
        
start:
        lda #'.'
        // jsr vmem_fill

        ldx #0
        ldy #0
        lda #128
        jsr vmem_set_char
        iny
        lda #129
        jsr vmem_set_char
        iny
        lda #128
        jsr vmem_set_char
        iny
        lda #130
        jsr vmem_set_char
        iny
        lda #128
        jsr vmem_set_char
        iny
        lda #131
        jsr vmem_set_char
        iny
        lda #128
        jsr vmem_set_char
        iny
        lda #132
        jsr vmem_set_char
        iny
        lda #128
        jsr vmem_set_char

        jsr chip8_init_charset

test_loop:
        lda #0
        sta ZP_PARAM1
        lda #0
        sta ZP_PARAM2
        jsr chip8_set_pixel
        jmp test_loop

main_loop:
        ldy #3
        ldx #5
        jsr vmem_get_char

        adc #1
        ldy #3
        ldx #5
        jsr vmem_set_char

        jmp main_loop

end_of_program:
        jmp end_of_program

// Set character at row X and column Y to value of A
vmem_set_char:
        pha
        lda vram_row_lo, X
        sta ZP_ADR_LO
        lda vram_row_hi, X
        sta ZP_ADR_HI
        pla
        sta (ZP_ADR), Y
        rts

vmem_get_char:
        lda vram_row_lo, X
        sta ZP_ADR_LO
        lda vram_row_hi, X
        sta ZP_ADR_HI
        lda (ZP_ADR), Y
        rts

vmem_fill:
        ldx #250
_loop:  dex
        sta VRAM, X
        sta VRAM + 250, x
        sta VRAM + 500, x
        sta VRAM + 750, x
        bne _loop
        rts

// X = 0, Y = 0 -> 1    0001
// X = 1, Y = 0 -> 2    0010
// X = 0, Y = 1 -> 4    0100
// X = 1, Y = 1 -> 10   1010

// 2 | X = 0, Y = 0 -> 1

// --- chip8_set_pixel_2 ------------------------------------
// chip8_set_pixel_2:
//         lda #

// --- chip8_set_pixel (old version) ------------------------------------
chip8_set_pixel:
        lda #1
        and ZP_PARAM1
        bne _chip8_set_pixel__right

_chip8_set_pixel__left:
        lda #1
        and ZP_PARAM2
        bne _chip8_set_pixel__left_bottom

_chip8_set_pixel__left_top:
        lda #'a'
        lda #0
        jsr vmem_set_char
        rts

_chip8_set_pixel__left_bottom:
        lda #'z'
        jsr vmem_set_char
        rts

_chip8_set_pixel__right:
        lda #1
        and ZP_PARAM2
        bne _chip8_set_pixel__right_bottom

_chip8_set_pixel__right_top:
        lda #'s'
        jsr vmem_set_char
        rts

_chip8_set_pixel__right_bottom:
        lda #'x'
        jsr vmem_set_char
        rts

// --- chip8_init_charset ---------------------------------
chip8_init_charset:
        // References:
        // https://www.georg-rottensteiner.de/c64/projectj/step2/step2.html
        // http://www.coding64.org/?p=164
        // https://codebase64.org/doku.php?id=base:vicii_memory_organizing
        sei

        // Store previous configuration
        lda $1
        sta ZP_PARAM1

        // Change memory mapping to make charset available for writes
        lda #$51
        sta $1

        // First copy the entire charset to RAM
        jsr vmem_copy_charset

        // Create the custom characters
        jsr chip8_create_characters

        // Restore previous memory bank configuration
        lda ZP_PARAM1
        sta $1
        cli

        lda #$1c
        sta $d018

        rts

chip8_create_characters:
        lda #<characters
        sta ZP_ADR_LO
        lda #>characters
        sta ZP_ADR_HI

        lda #<$3000 + pixel_characters * 8
        sta ZP_ADR2_LO
        lda #>$3000 + pixel_characters * 8
        sta ZP_ADR2_HI

        ldy #0
        ldx #0
chip8_create_characters__loop:
        lda (ZP_ADR), Y
        sta (ZP_ADR2), Y
        iny
        tya
        cpy 8 * 5
        bne chip8_create_characters__loop

        rts

vmem_copy_charset:
        // The complete charset is 256 characters. Each character is 8 byte.
        // The total number of bytes to copy is: 256 * 8 = 2048 (0x800)

        // Source
        lda #$00
        sta ZP_ADR_LO
        lda #$d0
        sta ZP_ADR_HI

        // Target
        lda #$00
        sta ZP_ADR2_LO
        lda #$30
        sta ZP_ADR2_HI

        ldx #0
        ldy #0

vmem_copy_charset__loop:
        lda (ZP_ADR), Y
        sta (ZP_ADR2), Y
        iny
        bne vmem_copy_charset__loop

        inc ZP_ADR_HI
        inc ZP_ADR2_HI
        inx
        cpx #8
        bne vmem_copy_charset__loop

        rts
