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
        
        jsr chip8_clear_screen

        // // Load the IBM ROM
        // lda #<rom_ibm
        // sta ZP_ADR_LO
        // lda #>rom_ibm
        // sta ZP_ADR_HI
        // lda rom_ibm_size
        // sta ZP_PARAM1
        // jsr chip8_load_rom

        // Load the first test rom
        // lda #<rom_test1
        // sta ZP_ADR_LO
        // lda #>rom_test1
        // sta ZP_ADR_HI
        // lda rom_test1_size
        // sta ZP_PARAM1
        // jsr chip8_load_rom

        // Load the second test rom
        lda #<rom_test2
        sta ZP_ADR_LO
        lda #>rom_test2
        sta ZP_ADR_HI
        lda rom_test2_size
        sta ZP_PARAM1
        jsr chip8_load_rom

        jsr chip8_run
        jmp *
