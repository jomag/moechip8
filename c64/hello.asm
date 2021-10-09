BasicUpstart2(start)

#import "registers.asm"
#import "video.asm"
#import "chip8.asm"
#import "games.asm"

        * = $4000 "Main Program"
        
start:
        jsr chip8_init_charset

        lda #pixel_00_00
        jsr vmem_fill

        // Draw some digits
        lda #<font
        sta ZP_ADR2_LO
        lda #>font
        sta ZP_ADR2_HI
        lda #0
        sta ZP_PARAM1
        lda #0
        sta ZP_PARAM2
        lda #5
        sta ZP_PARAM3
        jsr chip8_draw_sprite

        lda #<font+5
        sta ZP_ADR2_LO
        lda #>font+5
        sta ZP_ADR2_HI
        lda #5
        sta ZP_PARAM1
        lda #0
        sta ZP_PARAM2
        lda #5
        sta ZP_PARAM3
        jsr chip8_draw_sprite

        lda #<font+10
        sta ZP_ADR2_LO
        lda #>font+10
        sta ZP_ADR2_HI
        lda #10
        sta ZP_PARAM1
        lda #0
        sta ZP_PARAM2
        lda #5
        sta ZP_PARAM3
        jsr chip8_draw_sprite

        lda #<font+15
        sta ZP_ADR2_LO
        lda #>font+15
        sta ZP_ADR2_HI
        lda #15
        sta ZP_PARAM1
        lda #0
        sta ZP_PARAM2
        lda #5
        sta ZP_PARAM3
        jsr chip8_draw_sprite

        lda #<font+20
        sta ZP_ADR2_LO
        lda #>font+20
        sta ZP_ADR2_HI
        lda #20
        sta ZP_PARAM1
        lda #0
        sta ZP_PARAM2
        lda #5
        sta ZP_PARAM3
        jsr chip8_draw_sprite

        // Load the IBM ROM
        lda #<rom_ibm
        sta ZP_ADR_LO
        lda #>rom_ibm
        sta ZP_ADR_HI
        lda rom_ibm_size
        sta ZP_PARAM1
        jsr chip8_load_rom

        jsr chip8_run
        jmp *
