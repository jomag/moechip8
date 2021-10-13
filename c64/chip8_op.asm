#importonce

#import "chip8.asm"
#import "registers.asm"
#import "chip8_debug.asm"

// Note that 1 is subtracted from every label as RTS is used for
// the jump, and it adds 1 to the value it loads from the stack.
_first_nibble_jump_table:
        .word _op0-1, _op1-1, _op2-1, _op3-1
        .word _op4-1, _op5-1, _op6-1, _op7-1
        .word _op8-1, _op9-1, _opA-1, _opB-1
        .word _opC-1, _opD-1, _opE-1, _opF-1

_op8_jump_table:
        .word _op8XY0-1, _op8XY1-1, _op8XY2-1, _op8XY3-1
        .word _op8XY4-1, _op8XY5-1, _op8_todo-1, _op8_todo-1
        .word _op8_todo-1, _op8_todo-1, _op8_todo-1, _op8_todo-1
        .word _op8_todo-1, _op8_todo-1, _op8_todo-1, _op8_todo-1

!next:
        clc
        lda chip8_pc_lo
        adc #2
        sta chip8_pc_lo
        bcc chip8_run
        inc chip8_pc_hi

// This was my first approach. Check cycles to see which is faster!
//         inc chip8_pc_lo
//         bne !+
//         inc chip8_pc_hi
// !:      inc chip8_pc_lo
//         bne chip8_run
//         inc chip8_pc_hi

chip8_run:
        // Show debug info and use single instruction stepping
        // if the stepping flag is set
        lda chip8_vm_flags
        and CHIP8_STEPPING_FLAG
        beq !+
        jsr chip8_update_status
        jsr wait_for_key
!:

        // Load first nible into accumulator and use it
        // with the first-nibble jump table. Note that since
        // each record in the jump table is 2 bytes, the
        // byte is shifted right 3 times, and then the first
        // bit is cleared.
        ldy #0
        lda (chip8_pc), y
        lsr
        lsr
        lsr
        and #$1e
        tax

        lda _first_nibble_jump_table + 1, x
        pha
        lda _first_nibble_jump_table, x
        pha
        rts

_invalid_op:
        ldx #$de
        ldy #$ad
        .break
        jmp *

_unimplemented_op:
        ldx #$be
        ldy #$ef
        .break
        jmp *

_op0:
        // If first nibble is 0, the program would jump to the address
        // of the next three nibbles (0NNN) on the original hardware. This
        // was used to call native functions. In modern CHIP8 emulators,
        // the only two functions that are supported are 00E0 (clear screen)
        // and 00EE (return from subroutine)

        // First and second nibble must be 00
        ldy #0
        lda (chip8_pc), y
        cmp #0
        bne _invalid_op

        // 00E0: clear screen
        iny
        lda (chip8_pc), y
        cmp #$e0
        bne !+
        jsr chip8_clear_screen
        jmp !next-

        // 00EE: return from subroutine
!:      cmp #$ee
        bne !+

        dec chip8_sp
        dec chip8_sp
        lda chip8_sp
        tax
        lda chip8_stack, x
        sta chip8_pc_lo
        lda chip8_stack + 1, x
        sta chip8_pc_hi
        jmp !next-

!:      bne _invalid_op

_op2:   // 2NNN => call subroutine at NNN, pushing PC to stack

        // Push PC to stack
        lda chip8_sp
        tax
        lda chip8_pc_lo
        sta chip8_stack, x
        lda chip8_pc_hi
        sta chip8_stack + 1, x

        // Increment stafck point
        inc chip8_sp
        inc chip8_sp

        // Fall through to _op1, as they work the same, except
        // that 2NNN push PC first.

_op1:   // 1NNN => jump to NNN (set PC to NNN)
        ldy #1
        lda (chip8_pc), y
        clc
        adc #<chip8_mem
        tax

        dey
        lda (chip8_pc), y
        and #$0f
        adc #>chip8_mem
        sta chip8_pc_hi
        stx chip8_pc_lo

        // As this op has changed PC we go directly to
        // `chip8_run` instead of `!next-`.
        jmp chip8_run


_op3:   // 3XNN => skip next instruction if VX == NN

        // Load value of CHIP8 register X
        ldy #0
        lda (chip8_pc), y
        and #$0f
        tax
        lda chip8_registers, x
        
        // Compare with NN
        iny
        cmp (chip8_pc), y
        beq !+
        jmp !next-

        // Skip next instruction
!:      clc
        lda chip8_pc_lo
        adc #4
        sta chip8_pc_lo
        bcc !+
        inc chip8_pc_hi
!:      jmp chip8_run

_op4:   // 4XNN => skip next instruction if VX != NN

        // Load value of CHIP8 register X
        ldy #0
        lda (chip8_pc), y
        and #$0f
        tax
        lda chip8_registers, x
        
        // Compare with NN
        iny
        cmp (chip8_pc), y
        bne !+
        jmp !next-

        // Skip next instruction
!:      clc
        lda chip8_pc_lo
        adc #4
        sta chip8_pc_lo
        bcc !+
        inc chip8_pc_hi
!:      jmp chip8_run

_op5:   // 5XY0 => skip next instruction if VX == VY

        // Load value of CHIP8 register X into ZP_PARAM1
        ldy #0
        lda (chip8_pc), y
        and #$0f
        tax
        lda chip8_registers, x
        sta ZP_PARAM1
        
        // Compare with value of CHIP8 register Y
        iny
        lda (chip8_pc), y
        lsr
        lsr
        lsr
        lsr
        tax
        lda ZP_PARAM1
        cmp chip8_registers, x
        beq !+
        jmp !next-

        // Skip next instruction
!:      clc
        lda chip8_pc_lo
        adc #4
        sta chip8_pc_lo
        bcc !+
        inc chip8_pc_hi
!:      jmp chip8_run

_op6:   // 6XNN => set register X to NN
        ldy #0
        lda (chip8_pc), y
        and #$0f
        tax

        iny
        lda (chip8_pc), y
        sta chip8_registers, x

        jmp !next-

_op7:   // 7XNN => Add NN to register X

        // Load NN into ZP_TMP
        ldy #1
        lda (chip8_pc), y
        sta ZP_TMP

        // Set X to value of chip8-register X.
        dey
        lda (chip8_pc), y
        and #$0f
        tax

        // Add ZP_TMP to acc and write to register X.
        lda ZP_TMP
        clc
        adc chip8_registers, x
        sta chip8_registers, x

        jmp !next-

_op8:   // 8XYC => Logical/arithmetical instructions

        // Store value of CHIP8 register Y in ZP_TMP
        ldy #1
        lda (chip8_pc), y
        lsr
        lsr
        lsr
        lsr
        tax
        lda chip8_registers, x
        sta ZP_TMP

        // Jump to sub-op handler
        lda (chip8_pc), y
        and #$0f
        asl
        tax
        lda _op8_jump_table + 1, x
        pha
        lda _op8_jump_table, x
        pha
        rts

_op8XY0: // 8XY0 => Set VX to value of VY
        ldy #0
        lda (chip8_pc), y
        and #$0f
        tax
        lda ZP_TMP
        sta chip8_registers, x
        jmp !next-

_op8XY1: // 8XY1 => Set VX to VX | VY
        ldy #0
        lda (chip8_pc), y
        and #$0f
        tax
        lda chip8_registers, x
        ora ZP_TMP
        sta chip8_registers, x
        jmp !next-

_op8XY2: // 8XY1 => Set VX to VX & VY
        ldy #0
        lda (chip8_pc), y
        and #$0f
        tax
        lda chip8_registers, x
        and ZP_TMP
        sta chip8_registers, x
        jmp !next-

_op8XY3: // 8XY1 => Set VX to VX ^ VY
        ldy #0
        lda (chip8_pc), y
        and #$0f
        tax
        lda chip8_registers, x
        eor ZP_TMP
        sta chip8_registers, x
        jmp !next-

_op8XY4: // 8XY1 => Set VX to VX + VY
        ldy #0
        lda (chip8_pc), y
        and #$0f
        tax
        lda chip8_registers, x
        clc
        adc ZP_TMP
        sta chip8_registers, x

        // Set VF to 1 if carry flag set, 0 if not
        bcs !carry_set+
        lda #0
        sta chip8_regf
        jmp !next-

_op8XY5: // 8XY5 => Step VX to VX - VY
        jsr chip8_enable_stepping

        ldy #0
        lda (chip8_pc), y
        and #$0f
        tax
        lda chip8_registers, x

        sec
        sbc ZP_TMP
        sta chip8_registers, x

        // If VX > VY before the subtraction, set VF to 1.
        // Else, set VF to 0.
        bcc !+
        lda #1
        sta chip8_regf
        jmp !next-
!:      lda #0
        sta chip8_regf
        jmp !next-

!carry_set:
        lda #1
        sta chip8_regf
        jmp !next-

_op8_todo:
        .break
        lda #$b8
        jmp _unimplemented_op

_op9:   // 9XY0 => skip next instruction if VX != VY

        // Load value of CHIP8 register X into ZP_TMP
        ldy #0
        lda (chip8_pc), y
        and #$0f
        tax
        lda chip8_registers, x
        sta ZP_TMP
        
        // Compare with value of CHIP8 register Y
        iny
        lda (chip8_pc), y
        lsr
        lsr
        lsr
        lsr
        tax
        lda ZP_TMP
        cmp chip8_registers, x
        bne !+
        jmp !next-

        // Skip next instruction
!:      clc
        lda chip8_pc_lo
        adc #4
        sta chip8_pc_lo
        bcc !+
        inc chip8_pc_hi
!:      jmp chip8_run

_opA:   // ANNN => set index register to NNN
        ldy #0
        lda (chip8_pc), y
        and #$0f
        sta chip8_index_hi

        iny
        lda (chip8_pc), y
        sta chip8_index_lo

        jmp !next-

_opB:
        .break
        lda #$bb
        jmp _unimplemented_op
_opC:
        .break
        lda #$bc
        jmp _unimplemented_op

_opD:   // DXYN => Draw sprite
        // X is the index of the register that holds the horizontal position
        // Y is the index of the register that holds the vertical postion
        // N is the height of the sprit
        // I-register points at the sprite data

        // Load value of register X into ZP_PARAM1
        ldy #0
        lda (chip8_pc), y
        and #$0f
        tax
        lda chip8_registers, x
        sta ZP_PARAM1

        // Load value of register Y into ZP_PARAM2
        iny
        lda (chip8_pc), y
        lsr
        lsr
        lsr
        lsr
        tax
        lda chip8_registers, x
        sta ZP_PARAM2

        // Set ZP_PARAM3 to N
        lda (chip8_pc), y
        and #$0f
        sta ZP_PARAM3

        // Set `zp_w1` to CHIP8 memory offset + I
        clc
        lda #<chip8_mem
        adc chip8_index_lo
        sta zp_w1_lo
        lda #>chip8_mem
        adc chip8_index_hi
        sta zp_w1_hi

        jsr chip8_draw_sprite
        jmp !next-

_opE:
        lda #$be
        jmp _unimplemented_op

_opF:   // FXCC => subcommand CC
        ldy #1
        lda (chip8_pc), y

        cmp #$0a
        beq _opFx0A

        cmp #$29
        beq _opFx29

        lda #$bf
        jmp _unimplemented_op

_opFx0A:
        // FX0A => wait for key to be pressed and set register X
        //         to its value
        
        // FIXME: The current implementation only reads the space
        //        key and always set register X to 1.

        lda #$7f
        sta $DC00
        lda $DC01
        and #$10

        // Instead of blocking here, we execute the same operation
        // over and over until a key has been pressed.
        bne !+
        jmp chip8_run

        // Key press detected!
!:      ldy #0
        lda (chip8_pc), y
        and #$0f
        tax
        lda #1  // <--- should be the pressed key! FIXME
        sta chip8_registers, x

        jmp !next-

_opFx29:
        // FX29 => Set the I-register to point at the glyph data
        //         of the character in register X. Only the low
        //         nibble of register X is used.

        // Load value of register X
        ldy #0
        lda (chip8_pc), y
        and #$0f
        tax
        lda chip8_registers, x

        // Use only low nibble
        and #$0f

        // Load glyph offset from table
        tax
        lda glyph_offset_table, x
        sta chip8_index_lo
        lda glyph_offset_table + 1, x
        sta chip8_index_hi

        jmp !next-
