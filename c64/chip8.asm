#importonce

#import "registers.asm"
#import "video.asm"
#import "chip8_op.asm"
#import "chip8_debug.asm"

.const pixel_00_00 = 128
.const pixel_10_00 = 129
.const pixel_01_00 = 130
.const pixel_00_10 = 131
.const pixel_00_01 = 132

// Offset to font sprites
.const font_offset = $50
.const font_glyph_count = 16
.const font_glyph_size = 5

// Where games will be loaded into RAM, as an
// offset from the CHIP8 memory buffer
.const chip8_game_offset = $200

// The font sprites
font:
        .byte $F0, $90, $90, $90, $F0  // 0
        .byte $20, $60, $20, $20, $70  // 1
        .byte $F0, $10, $F0, $80, $F0  // 2
        .byte $F0, $10, $F0, $10, $F0  // 3
        .byte $90, $90, $F0, $10, $10  // 4
        .byte $F0, $80, $F0, $10, $F0  // 5
        .byte $F0, $80, $F0, $90, $F0  // 6
        .byte $F0, $10, $20, $40, $40  // 7
        .byte $F0, $90, $F0, $90, $F0  // 8
        .byte $F0, $90, $F0, $10, $F0  // 9
        .byte $F0, $90, $F0, $90, $90  // A
        .byte $E0, $90, $E0, $90, $E0  // B
        .byte $F0, $80, $80, $80, $F0  // C
        .byte $E0, $90, $90, $90, $E0  // D
        .byte $F0, $80, $F0, $80, $F0  // E
        .byte $F0, $80, $F0, $80, $80  // F

glyph_offset_table:
        .fillword 16, font_offset + i * 5

pixel_characters:
        .byte $00, $00, $00, $00, $00, $00, $00, $00 // 00 00 
        // .byte $00, $42, $00, $00, $00, $00, $42, $00 // 00 00 (alternate)
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

// The CHIP8 memory
chip8_mem:
        .fill 4096, 0

.print "CHIP8 memory: $" + toHexString(chip8_mem, 4)

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
        lda #<pixel_characters
        sta ZP_ADR_LO
        lda #>pixel_characters
        sta ZP_ADR_HI

        lda #<$3000 + pixel_00_00 * 8
        sta ZP_ADR2_LO
        lda #>$3000 + pixel_00_00 * 8
        sta ZP_ADR2_HI

        ldy #0
        ldx #0
!loop:
        lda (ZP_ADR), Y
        sta (ZP_ADR2), Y
        iny
        tya
        cpy 8 * 5
        bne !loop-

        rts

// --- chip8_set_pixel ------------------------------------
// ZP_PARAM1: X coordinate
// ZP_PARAM2: Y coordinate
chip8_set_pixel:
        // Reg Y = X-coord / 2
        lda ZP_PARAM1
        lsr
        tay

        // Reg X = Y-coord / 2
        lda ZP_PARAM2
        lsr
        tax

        // Point ZP_ADR at table of video RAM rows, indexed by Y-coordinate / 2
        lda vram_row_lo, X
        sta ZP_ADR_LO
        lda vram_row_hi, X
        sta ZP_ADR_HI

        // If first bit of X-coordinate is set ...
        lda ZP_PARAM1
        and #1
        bne chip8_set_pixel__x1

chip8_set_pixel__x0:
        // X-coordinate & 1 == 0
        lda ZP_PARAM2
        and #1
        bne chip8_set_pixel__x0_y1
chip8_set_pixel__x0_y0:
        lda #1
        jmp chip8_set_pixel__set
chip8_set_pixel__x0_y1:
        lda #4
        jmp chip8_set_pixel__set

chip8_set_pixel__x1:
        // X-coordinate & 1 == 1
        lda ZP_PARAM2
        and #1
        bne chip8_set_pixel__x1_y1
chip8_set_pixel__x1_y0:
        lda #2
        jmp chip8_set_pixel__set
chip8_set_pixel__x1_y1:
        lda #8

chip8_set_pixel__set:
        // Replace the character with same character, bitwise OR-ed with A 
        ora (ZP_ADR), Y
        sta (ZP_ADR), Y
        rts

// Draw sprite on screen
// ZP_ADR2 (ZP_ADR2_HI + ZP_ADR2_LO): pointer to the sprite
// ZP_PARAM1: X position
// ZP_PARAM2: Y position
// ZP_PARAM3: height of the sprite
chip8_draw_sprite:
        lda ZP_PARAM3
        bne !next_row+
        rts

!next_row:
        ldy #0
        lda (ZP_ADR2), Y
        sta ZP_TMP

        and #128
        beq !bit7+
        jsr chip8_set_pixel

!bit7:
        inc ZP_PARAM1
        lda ZP_TMP
        and #64
        beq !bit6+
        jsr chip8_set_pixel

!bit6:
        inc ZP_PARAM1
        lda ZP_TMP
        and #32
        beq !bit5+
        jsr chip8_set_pixel

!bit5:
        inc ZP_PARAM1
        lda ZP_TMP
        and #16
        beq !bit4+
        jsr chip8_set_pixel

!bit4:
        inc ZP_PARAM1
        lda ZP_TMP
        and #8
        beq !bit3+
        jsr chip8_set_pixel

!bit3:
        inc ZP_PARAM1
        lda ZP_TMP
        and #4
        beq !bit2+
        jsr chip8_set_pixel

!bit2:
        inc ZP_PARAM1
        lda ZP_TMP
        and #2
        beq !bit1+
        jsr chip8_set_pixel

!bit1:
        inc ZP_PARAM1
        lda ZP_TMP
        and #1
        beq !bit0+
        jsr chip8_set_pixel

!bit0:
        // Move cursor back 8 pixels on the row
        lda ZP_PARAM1
        sec
        sbc #7
        sta ZP_PARAM1

        // Jump to next row
        inc ZP_PARAM2

        inc ZP_ADR2_LO
        bne !+
        inc ZP_ADR2_HI
!:
 
        // Decrement the row count and draw the next row if not finished
        dec ZP_PARAM3
        bne !next_row-
        rts

// Initialize memory by filling it with zeros and copying the font
// to its fixed position at offset $50
chip8_initialize_memory:
        // Fill memory with zeros
        ldx #$ff
        lda #0
!fill_loop:
        dex
        sta chip8_mem, X
        sta chip8_mem + $100, x
        sta chip8_mem + $200, x
        sta chip8_mem + $300, x
        sta chip8_mem + $400, x
        sta chip8_mem + $500, x
        sta chip8_mem + $600, x
        sta chip8_mem + $700, x
        sta chip8_mem + $800, x
        sta chip8_mem + $900, x
        bne !fill_loop-

        // Copy font data
        ldx #(font_glyph_count * font_glyph_size)
!copy_font_loop:
        dex
        lda font, x
        sta chip8_mem + font_offset, x
        bne !copy_font_loop-

        rts

chip8_reset:
        jsr chip8_initialize_memory
        lda #0
        sta chip8_registers + $0
        sta chip8_registers + $1
        sta chip8_registers + $2
        sta chip8_registers + $3
        sta chip8_registers + $4
        sta chip8_registers + $5
        sta chip8_registers + $6
        sta chip8_registers + $7
        sta chip8_registers + $8
        sta chip8_registers + $9
        sta chip8_registers + $a
        sta chip8_registers + $b
        sta chip8_registers + $c
        sta chip8_registers + $d
        sta chip8_registers + $e
        sta chip8_registers + $f
        sta chip8_index_lo
        sta chip8_index_hi

        lda #<chip8_mem + chip8_game_offset
        sta chip8_pc_lo
        lda #>chip8_mem + chip8_game_offset
        sta chip8_pc_hi
        rts

// Load ROM into CHIP-8 memory
// Parameters:
// ZP_ADR: point to ROM data
// ZP_PARAM1: length of ROM data
//
// FIXME: Handles only ROM sizes up to 255 bytes.
// FIXME: Probably super inefficient!
chip8_load_rom:
        jsr chip8_reset

        lda ZP_PARAM1
        tay
        tax
!loop:
        dex
        dey
        lda (ZP_ADR), y
        sta (chip8_mem + chip8_game_offset), x

        tya
        cmp #0
        bne !loop-
 
        rts

// Clear the CHIP8 screen
chip8_clear_screen:
        lda #pixel_00_00
        jsr vmem_fill
        rts

