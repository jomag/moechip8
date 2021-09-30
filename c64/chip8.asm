
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

// --- chip8_set_pixel ------------------------------------
chip8_set_pixel:
        


        lda ZP_PARAM1
        lsr
        tax
        lda ZP_PARAM2
        lsr
        tay

        lda #1
        and ZP_PARAM1
        bne _chip8_set_pixel__right

_chip8_set_pixel__left:
        and ZP_PARAM2
        bne _chip8_set_pixel__left_bottom

_chip8_set_pixel__left_top:
        lda #pixel_characters + 1
        jsr vmem_set_char
        rts

_chip8_set_pixel__left_bottom:
        lda #pixel_characters + 3
        jsr vmem_set_char
        rts

_chip8_set_pixel__right:
        lda #1
        and ZP_PARAM2
        bne _chip8_set_pixel__right_bottom

_chip8_set_pixel__right_top:
        lda #pixel_characters + 2
        jsr vmem_set_char
        rts

_chip8_set_pixel__right_bottom:
        lda #pixel_characters + 4
        jsr vmem_set_char
        rts
