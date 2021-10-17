#importonce
#import "registers.asm"

// Copy n bytes from one part of memory to another.
// Does not handle overlapping memory.
// Args:
// - zp_w0: source address
// - zp_w1: destinsation address
// - zp_w2: byte count
copy_mem:
        // If hi byte is zero, go directly to the last page
        ldx zp_w2_hi
        cpx #0
        beq !prepare_last_page+
        ldy #0

!full_page_loop:
        dey
        lda (zp_w0), y
        sta (zp_w1), y
        cpy #0
        bne !full_page_loop-

        inc zp_w0_hi
        inc zp_w1_hi
        
        dex
        bne !full_page_loop-

!prepare_last_page:
        ldy zp_w2_lo
        cpy #0
        bne !last_page_loop+
        rts
        
!last_page_loop:
        dey
        lda (zp_w0), y
        sta (zp_w1), y
        cpy #0
        bne !last_page_loop-

        rts

// Translates the value in the accumulator to BCD.
// Result is stored in zp_w0.
// During the conversion, interrupts are disabled.
// Before returning, interrupts are enabled, even
// if they were not enabled before.
//
// Destroys: a, x, ZP_TMP
//
// This is *heavily* inspired by Garth Wilsons algorithm:
// http://6502.org/source/integers/hex2dec.htm
// See also the double dabble algorithm:
// https://en.wikipedia.org/wiki/Double_dabble
__hex2dec_table:
        .word $1, $2, $4, $8, $16, $32, $64, $128

hex2dec:
        sta ZP_TMP
        sei     // Disable interrupts when in decimal mode
        sed     // Decimal mode

        lda #0
        sta zp_w0_lo
        sta zp_w0_hi

        ldx #14         // X points at last word in hex2dec_table
!:      asl ZP_TMP      // Shift high bit into carry
        bcc !htd1+      // If high bit was clear, don't add anything to output
        
        lda zp_w0_lo
        clc
        adc __hex2dec_table, x
        sta zp_w0_lo

        lda zp_w0_hi
        adc __hex2dec_table + 1, x
        sta zp_w0_hi

!htd1:  dex
        dex
        bpl !-

        cld     // Leave decimal mode
        cli     // Enable interrupts again
        rts
