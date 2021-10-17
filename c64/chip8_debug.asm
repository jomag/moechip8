// +----+----------------------+-------------------------------------------------------------------------------------------------------+
// |    |                      |                                Peek from $dc01 (code in paranthesis):                                 |
// |row:| $dc00:               +------------+------------+------------+------------+------------+------------+------------+------------+
// |    |                      |   BIT 7    |   BIT 6    |   BIT 5    |   BIT 4    |   BIT 3    |   BIT 2    |   BIT 1    |   BIT 0    |
// +----+----------------------+------------+------------+------------+------------+------------+------------+------------+------------+
// |1.  | #%11111110 (254/$fe) | DOWN  ($  )|   F5  ($  )|   F3  ($  )|   F1  ($  )|   F7  ($  )| RIGHT ($  )| RETURN($  )|DELETE ($  )|
// |2.  | #%11111101 (253/$fd) |LEFT-SH($  )|   e   ($05)|   s   ($13)|   z   ($1a)|   4   ($34)|   a   ($01)|   w   ($17)|   3   ($33)|
// |3.  | #%11111011 (251/$fb) |   x   ($18)|   t   ($14)|   f   ($06)|   c   ($03)|   6   ($36)|   d   ($04)|   r   ($12)|   5   ($35)|
// |4.  | #%11110111 (247/$f7) |   v   ($16)|   u   ($15)|   h   ($08)|   b   ($02)|   8   ($38)|   g   ($07)|   y   ($19)|   7   ($37)|
// |5.  | #%11101111 (239/$ef) |   n   ($0e)|   o   ($0f)|   k   ($0b)|   m   ($0d)|   0   ($30)|   j   ($0a)|   i   ($09)|   9   ($39)|
// |6.  | #%11011111 (223/$df) |   ,   ($2c)|   @   ($00)|   :   ($3a)|   .   ($2e)|   -   ($2d)|   l   ($0c)|   p   ($10)|   +   ($2b)|
// |7.  | #%10111111 (191/$bf) |   /   ($2f)|   ^   ($1e)|   =   ($3d)|RGHT-SH($  )|  HOME ($  )|   ;   ($3b)|   *   ($2a)|   £   ($1c)|
// |8.  | #%01111111 (127/$7f) | STOP  ($  )|   q   ($11)|COMMODR($  )| SPACE ($20)|   2   ($32)|CONTROL($  )|  <-   ($1f)|   1   ($31)|
// +----+----------------------+------------+------------+------------+------------+------------+------------+------------+------------+

#importonce

#import "registers.asm"

.var legend_str = "pc:.... op:.... i:.... sp:.."

.label chip8_debug_offset = VRAM + 40 * 22

legend: .text legend_str

wait_for_key:
        lda #$7F   // %01111111
        sta $DC00
        lda $DC01
        and #$10  // mask %00010000
        bne wait_for_key
wait_for_release:
        lda $DC01
        cmp #$FF
        bne wait_for_release
        rts

chip8_print_status:
        // Print legend
        ldx #legend_str.size()
!:      dex
        lda (legend), x
        sta (chip8_debug_offset), x
        txa
        cmp #0
        bne !-

chip8_update_status:
        // First line ...
        lda #>chip8_debug_offset
        sta zp_w0_hi
        lda #<chip8_debug_offset
        sta zp_w0_lo

        // Print PC, with CHIP8 memory offset subtracted
        sec
        lda chip8_pc_lo
        sbc #<chip8_mem
        sta ZP_PARAM1
        lda chip8_pc_hi
        sbc #>chip8_mem
        sta ZP_PARAM2

        ldy #3
        lda ZP_PARAM2
        jsr chip8_print_byte
        ldy #5
        lda ZP_PARAM1
        jsr chip8_print_byte

        // Print op
        ldy #0
        lda (chip8_pc), Y
        ldy #11
        jsr chip8_print_byte

        ldy #1
        lda (chip8_pc), Y
        ldy #13
        jsr chip8_print_byte

        // Print I register (index)
        sec
        lda chip8_index_lo
        sbc #<chip8_mem
        sta ZP_PARAM1
        lda chip8_index_hi
        sbc #>chip8_mem
        sta ZP_PARAM2

        ldy #18
        lda ZP_PARAM2
        jsr chip8_print_byte
        ldy #20
        lda ZP_PARAM1
        jsr chip8_print_byte

        // Print stack pointer
        ldy #26
        lda chip8_sp
        jsr chip8_print_byte

        // Next line...
        lda #>chip8_debug_offset + 40
        sta zp_w0_hi
        lda #<chip8_debug_offset + 40
        sta zp_w0_lo

        // Print all registers
        ldy #0
        lda chip8_registers, y
        ldy #0
        jsr chip8_print_byte

        ldy #1
        lda chip8_registers, y
        ldy #3
        jsr chip8_print_byte

        ldy #2
        lda chip8_registers, y
        ldy #6
        jsr chip8_print_byte

        ldy #3
        lda chip8_registers, y
        ldy #9
        jsr chip8_print_byte

        ldy #4
        lda chip8_registers, y
        ldy #12
        jsr chip8_print_byte

        ldy #5
        lda chip8_registers, y
        ldy #15
        jsr chip8_print_byte

        ldy #6
        lda chip8_registers, y
        ldy #18
        jsr chip8_print_byte

        ldy #7
        lda chip8_registers, y
        ldy #21
        jsr chip8_print_byte

        // Next line...
        lda #>chip8_debug_offset + 80
        sta zp_w0_hi
        lda #<chip8_debug_offset + 80
        sta zp_w0_lo

        // Print all registers
        ldy #8
        lda chip8_registers, y
        ldy #0
        jsr chip8_print_byte

        ldy #9
        lda chip8_registers, y
        ldy #3
        jsr chip8_print_byte

        ldy #10
        lda chip8_registers, y
        ldy #6
        jsr chip8_print_byte

        ldy #11
        lda chip8_registers, y
        ldy #9
        jsr chip8_print_byte

        ldy #12
        lda chip8_registers, y
        ldy #12
        jsr chip8_print_byte

        ldy #13
        lda chip8_registers, y
        ldy #15
        jsr chip8_print_byte

        ldy #14
        lda chip8_registers, y
        ldy #18
        jsr chip8_print_byte

        ldy #15
        lda chip8_registers, y
        ldy #21
        jsr chip8_print_byte

        rts

chip8_print_byte:
        pha
        lsr
        lsr
        lsr
        lsr
        jsr !nibble+
        pla
        and #$0f
!nibble:
        cmp #$0a
        bcs !letter+
!digit: 
        ora #$30        // $30 == "0" in PETSCII
        bne !print+
!letter:
        sbc #$09        // $A - $9 == $1 == "A" in PETSCII
!print:
        sta (zp_w0), y
        iny
        rts

// Sets carry flag if one key is set
// Input: key to test in acc.
// Returns: set/not set in carry flag
//
// Key layout:
//
// 1 2 3 4            1  2  3 12 
// Q W E R    ===>    4  5  6 13
// A S D F            7  8  9 14
// Z X C V           10  0 11 15
//
chip8_read_key:
        tax
        lda __chip8_key_mask, x
        sta $dc00
        lda $dc01
        and __chip8_key_bit, x
        beq !+
        clc
        rts
!:      sec
        rts

__chip8_key_mask:
        .byte $fb, $7f, $7f, $fd
        .byte $7f, $fd, $fd, $fd
        .byte $fd, $fb, $fd, $fb
        .byte $fd, $fb, $fb, $f7
__chip8_key_bit:
        .byte $80, $01, $08, $01
        .byte $40, $02, $40, $04
        .byte $20, $04, $10, $10
        .byte $08, $02, $20, $80


.const __offset = VRAM + 41
chip8_print_keys:
        lda #0
        jsr chip8_read_key
        lda #'x'
        bcc !+
        clc
        adc #128
!:      sta __offset + 122

        lda #1
        jsr chip8_read_key
        lda #'1'
        bcc !+
        clc
        adc #128
!:      sta __offset

        lda #2
        jsr chip8_read_key
        lda #'2'
        bcc !+
        clc
        adc #128
!:      sta __offset + 2

        lda #3
        jsr chip8_read_key
        lda #'3'
        bcc !+
        clc
        adc #128
!:      sta __offset + 4

        lda #4
        jsr chip8_read_key
        lda #'q'
        bcc !+
        clc
        adc #128
!:      sta __offset + 40

        lda #5
        jsr chip8_read_key
        lda #'w'
        bcc !+
        clc
        adc #128
!:      sta __offset + 42

        lda #6
        jsr chip8_read_key
        lda #'e'
        bcc !+
        clc
        adc #128
!:      sta __offset + 44

        lda #7
        jsr chip8_read_key
        lda #'a'
        bcc !+
        clc
        adc #128
!:      sta __offset + 80

        lda #8
        jsr chip8_read_key
        lda #'s'
        bcc !+
        clc
        adc #128
!:      sta __offset + 82

        lda #9
        jsr chip8_read_key
        lda #'d'
        bcc !+
        clc
        adc #128
!:      sta __offset + 84

        lda #10
        jsr chip8_read_key
        lda #'z'
        bcc !+
        clc
        adc #128
!:      sta __offset + 120

        lda #11
        jsr chip8_read_key
        lda #'c'
        bcc !+
        clc
        adc #128
!:      sta __offset + 124

        lda #12
        jsr chip8_read_key
        lda #'4'
        bcc !+
        clc
        adc #128
!:      sta __offset + 6

        lda #13
        jsr chip8_read_key
        lda #'r'
        bcc !+
        clc
        adc #128
!:      sta __offset + 46

        lda #14
        jsr chip8_read_key
        lda #'f'
        bcc !+
        clc
        adc #128
!:      sta __offset + 86

        lda #15
        jsr chip8_read_key
        lda #'v'
        bcc !+
        clc
        adc #128
!:      sta __offset + 126

        rts
