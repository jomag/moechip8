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
