BasicUpstart2(start)

#import "registers.asm"
#import "video.asm"
#import "chip8.asm"
#import "games.asm"

        * = $4000 "Main Program"
        
start:
        .break
        lda #5
        eor #4

        lda #5
        eor #2

//  Test key reading:
//         lda #' '
//         jsr vmem_fill
// !:      jsr chip8_print_keys
//         jmp !-

        jsr chip8_init_charset

        lda #pixel_00_00
        jsr vmem_fill
        
        jsr chip8_clear_screen

        // Load the IBM ROM
        lda #<rom_ibm
        sta zp_w0_lo
        lda #>rom_ibm
        sta zp_w0_hi
        lda rom_ibm_size
        sta zp_w2_lo
        lda rom_ibm_size + 1
        sta zp_w2_hi
        jsr chip8_load_rom

        // Load the first test rom
        // lda #<rom_test1
        // sta zp_w0_lo
        // lda #>rom_test1
        // sta zp_w0_hi
        // lda rom_test1_size
        // sta zp_w2_lo
        // lda rom_test1_size + 1
        // sta zp_w2_hi
        // jsr chip8_load_rom

        // Load the second test rom
        // lda #<rom_test2
        // sta zp_w0_lo
        // lda #>rom_test2
        // sta zp_w0_hi
        // lda rom_test2_size
        // sta zp_w2_lo
        // lda rom_test2_size + 1
        // sta zp_w2_hi
        // jsr chip8_load_rom

        // Load Invaders
        // lda #<rom_invaders
        // sta zp_w0_lo
        // lda #>rom_invaders
        // sta zp_w0_hi
        // lda rom_invaders_size
        // sta zp_w2_lo
        // lda rom_invaders_size + 1
        // sta zp_w2_hi
        // jsr chip8_load_rom

        lda #<rom_blitz
        sta zp_w0_lo
        lda #>rom_blitz
        sta zp_w0_hi
        lda rom_blitz_size
        sta zp_w2_lo
        lda rom_blitz_size + 1
        sta zp_w2_hi
        jsr chip8_load_rom

        jsr chip8_run
        jmp *
