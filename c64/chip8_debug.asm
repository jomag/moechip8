#importonce

#import "registers.asm"

.var legend_str = "pc:.... op:.... i:...."

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
        sta ZP_ADR_HI
        lda #<chip8_debug_offset
        sta ZP_ADR_LO

        // Print PC
        ldy #3
        lda chip8_pc_hi
        jsr chip8_print_byte
        ldy #5
        lda chip8_pc_lo
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
        ldy #18
        lda chip8_index_hi
        jsr chip8_print_byte
        ldy #20
        lda chip8_index_lo
        jsr chip8_print_byte

        // Next line...
        lda #>chip8_debug_offset + 40
        sta ZP_ADR_HI
        lda #<chip8_debug_offset + 40
        sta ZP_ADR_LO

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
        sta ZP_ADR_HI
        lda #<chip8_debug_offset + 80
        sta ZP_ADR_LO

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
        sta (ZP_ADR), y
        iny
        rts