
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

_vmem_copy_charset__loop:
        lda (ZP_ADR), Y
        sta (ZP_ADR2), Y
        iny
        bne _vmem_copy_charset__loop

        inc ZP_ADR_HI
        inc ZP_ADR2_HI
        inx
        cpx #8
        bne _vmem_copy_charset__loop

        rts
