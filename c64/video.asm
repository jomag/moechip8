#importonce

#import "registers.asm"

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
        sta zp_w0_lo
        lda vram_row_hi, X
        sta zp_w0_hi
        pla
        sta (zp_w0), Y
        rts

vmem_get_char:
        lda vram_row_lo, X
        sta zp_w0_lo
        lda vram_row_hi, X
        sta zp_w0_hi
        lda (zp_w0), Y
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
        sta zp_w0_lo
        lda #$d0
        sta zp_w0_hi

        // Target
        lda #$00
        sta zp_w1_lo
        lda #$30
        sta zp_w1_hi

        ldx #0
        ldy #0

_vmem_copy_charset__loop:
        lda (zp_w0), y
        sta (zp_w1), y
        iny
        bne _vmem_copy_charset__loop

        inc zp_w0_hi
        inc zp_w1_hi
        inx
        cpx #8
        bne _vmem_copy_charset__loop

        rts
