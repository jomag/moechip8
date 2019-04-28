
from collections import deque
from time import sleep, time_ns
from random import randint
import curses
import sys
from tkinter import Tk, Canvas, NORMAL, HIDDEN

__NAME__ = "MoeChip8"

MEMORY_SIZE = 4096
REGISTER_COUNT = 16

def format_opcode(op):
    t = (op & 0xF000) >> 12
    nnn = f"0x{op & 0xFFF:03X}"
    vx = f"V{(op & 0xF00) >> 8:X}"
    vy = f"V{(op & 0x0F0) >> 4:X}"
    kk = f"{op & 0xFF:d}"
    invalid = f"! invalid op code: 0x{op:04X} !"

    # Super Chip-48 instructions
    if op & 0xFFF0 == 0x00C0:
        return f"SCD  {op & 0xF}  ; Chip-48"
    if op == 0x00FB:
        return f"SCR              ; Chip-48"
    if op == 0x00FC:
        return f"SCL              ; Chip-48"
    if op == 0x00FD:
        return f"EXIT             ; Chip-48"
    if op == 0x00FE:
        return f"LOW              ; Chip-48"
    if op == 0x00FF:
        return f"HIGH             ; Chip-48"
    if op & 0xF0FF == 0xF030:
        return f"LD   HF, {vx}    ; Chip-48"
    if op & 0xF0FF == 0xF075:
        return f"LD   R, {vx}     ; Chip-48"
    if op & 0xF0FF == 0xF085:
        return f"LD   {vx}, R     ; Chip-48"

    # Chip-8 instructions
    if t == 0:
        if op == 0xE0:
            return f"CLS"
        if op == 0xEE:
            return f"RET"
        return f"SYS  {nnn}"

    if t == 1:
        return f"JP   {nnn}"

    if t == 2:
        return f"CALL {nnn}"

    if t == 3:
        return f"SE   {vx}, {kk}"

    if t == 4:
        return f"SNE  {vx}, {kk}"

    if t == 5:
        return f"SE   {vx}, {vy}"

    if t == 6:
        return f"LD   {vx}, {kk}"

    if t == 7:
        return f"ADD  {vx}, {kk}"

    if t == 8:
        q = op & 0xF
        if q == 0x0:
            return f"LD   {vx}, {vy}"
        if q == 0x1:
            return f"OR   {vx}, {vy}"
        if q == 0x2:
            return f"AND  {vx}, {vy}"
        if q == 0x3:
            return f"XOR  {vx}, {vy}"
        if q == 0x4:
            return f"ADD  {vx}, {vy}"
        if q == 0x5:
            return f"SUB  {vx}, {vy}"
        if q == 0x6:
            return f"SHR  {vx}"
        if q == 0x7:
            return f"SUBN {vx}, {vy}"
        if q == 0xE:
            return f"SHL  {vx}"
        return invalid

    if t == 9:
        q = op & 0xF
        if q == 0x0:
            return f"SNE  {vx}, {vy}"
        return invalid

    if t == 0xA:
        return f"LD   I, {nnn}"

    if t == 0xB:
        return f"JP   V0, {nnn}"

    if t == 0xC:
        return f"RND  {vx}, {kk}"

    if t == 0xD:
        q = op & 0xF
        return f"DRW  {vx}, {vy}, {q}"

    if t == 0xE:
        q = op & 0xFF
        if q == 0x9E:
            return f"SKP  {vx}"
        if q == 0xA1:
            return f"SKNP {vx}"
        return invalid

    if t == 0xF:
        q = op & 0xFF
        if q == 0x07:
            return f"LD   {vx}, DT"
        if q == 0x0A:
            return f"LD   {vx}, K"
        if q == 0x15:
            return f"LD   DT, {vx}"
        if q == 0x18:
            return f"LD   ST, {vx}"
        if q == 0x1E:
            return f"ADD  I, {vx}"
        if q == 0x29:
            return f"LD   F, {vx}"
        if q == 0x33:
            return f"LD   B, {vx}"
        if q == 0x55:
            return f"LD   [I], {vx}"
        if q == 0x65:
            return f"LD   {vx}, [I]"
        return invalid

    return invalid

import pygame

class PyGameDisplay:
    WIDTH = 64
    HEIGHT = 32
    SCALE = 6

    def __init__(self):
        self.buf = [bytearray(self.WIDTH) for n in range(self.HEIGHT)]
        self.window = None
        self.keys = [False] * 16

    def setup(self):
        pygame.init()
        resolution = (self.WIDTH * self.SCALE, self.HEIGHT * self.SCALE)
        pygame.display.set_mode(resolution)
        self.surface = pygame.Surface((self.WIDTH, self.HEIGHT))

    def update(self):
        key_map = [
            pygame.K_q, pygame.K_a, pygame.K_z, pygame.K_w,
            pygame.K_s, pygame.K_x, pygame.K_e, pygame.K_d,
            pygame.K_c, pygame.K_r, pygame.K_f, pygame.K_v,
            pygame.K_t, pygame.K_g, pygame.K_b, pygame.K_y
        ]

        event = pygame.event.poll()
        if event.type == pygame.QUIT:
            raise SystemExit
        if event.type == pygame.KEYDOWN:
            idx = key_map.index(event.key)
            self.keys[idx] = True
        if event.type == pygame.KEYUP:
            try:
                idx = key_map.index(event.key)
                self.keys[idx] = False
            except ValueError:
                pass

    def finalize(self):
        pass

    def reset_keypad(self):
        pass

    def read_keypad(self):
        pass

    def render(self):
        on = pygame.Color(255, 255, 255)
        off = pygame.Color(0, 0, 0)

        px = pygame.PixelArray(self.surface)

        y = 0
        for row in self.buf:
            x = 0
            for pixel in row:
                px[x, y] = on if pixel else off
                x = x + 1
            y = y + 1

        del px
        
        screen = pygame.display.get_surface()
        scaled = pygame.transform.scale(self.surface, screen.get_size())
        screen.blit(scaled, (0, 0))
        pygame.display.flip()

    def sprite(self, x, y, sprite):
        for bmp in sprite:
            y = y & (self.HEIGHT - 1)
            bx = x
            for bit in [128,64,32,16,8,4,2,1]:
                bx = bx & (self.WIDTH - 1)
                c = self.buf[y][bx]
                n = bmp & bit
                if (c and not n) or (n and not c):
                    self.buf[y][bx] = True
                else:
                    self.buf[y][bx] = False
                bx = bx + 1
            y = y + 1

class IllegalOp(Exception):
    def __init__(self, op, addr):
        super().__init__(f"Unsupported opcode: 0x{op:04X}, at 0x{addr:04X}")
        self.op = op
        self.addr = addr

class VM:
    digits = [
        [ 0xF0, 0x90, 0x90, 0x90, 0xF0 ],  # 0
        [ 0x20, 0x60, 0x20, 0x20, 0x70 ],  # 1
        [ 0xF0, 0x10, 0xF0, 0x80, 0xF0 ],  # 2
        [ 0xF0, 0x10, 0xF0, 0x10, 0xF0 ],  # 3
        [ 0x90, 0x90, 0xF0, 0x10, 0x10 ],  # 4
        [ 0xF0, 0x80, 0xF0, 0x10, 0xF0 ],  # 5
        [ 0xF0, 0x80, 0xF0, 0x90, 0xF0 ],  # 6
        [ 0xF0, 0x10, 0x20, 0x40, 0x40 ],  # 7
        [ 0xF0, 0x90, 0xF0, 0x90, 0xF0 ],  # 8
        [ 0xF0, 0x90, 0xF0, 0x10, 0xF0 ],  # 9
        [ 0xF0, 0x90, 0xF0, 0x90, 0x90 ],  # A
        [ 0xE0, 0x90, 0xE0, 0x90, 0xE0 ],  # B
        [ 0xF0, 0x80, 0x80, 0x80, 0xF0 ],  # C
        [ 0xE0, 0x90, 0x90, 0x90, 0xE0 ],  # D
        [ 0xF0, 0x80, 0xF0, 0x80, 0xF0 ],  # E 
        [ 0xF0, 0x80, 0xF0, 0x80, 0x80 ]   # F
    ]

    def __init__(self, display=None):
        self.ram = bytearray(MEMORY_SIZE)
        self.display = display
        self.stack = deque()
        self.reg = bytearray(REGISTER_COUNT)
        
        # Copy digits to interpreter area of the RAM
        idx = 0
        for digit in VM.digits:
            for b in digit:
                self.ram[idx] = b
                idx = idx + 1

        # The 16-bit program counter register
        self.pc = 0

        # The 16-bit address register
        self.i = 0

        # CHIP-8 has two timers. They both count down
        # at 60 Hz until they reach 0.

        # The delay timer is intended to be used for timing
        # the events of games.
        self.delay_timer = 0

        # Sound timer is used for sound effects. When
        # its value is non-zero, a beeping sound is made.
        self.sound_timer = 0

    def load(self, path, addr=0x200):
        with open(path, "rb") as f:
            data = f.read()
        self.ram[addr:addr+len(data)] = data
        return len(data)

    def disassemble(self, start, length):
        for i in range(0, length, 2):
            op = (self.ram[start + i] << 8) | self.ram[start + i + 1]
            print(f"{i:04X}: {op:04X} {format_opcode(op)}")

    def step(self):
        if self.display:
            self.display.read_keypad()
            self.display.update()

        op_addr = self.pc
        op = (self.ram[self.pc] << 8) | self.ram[self.pc + 1]
        self.pc = self.pc + 2

        prefix = (op & 0xF000) >> 12
        nnn = op & 0xFFF
        x = (op & 0xF00) >> 8
        y = (op & 0x0F0) >> 4
        kk = op & 0xFF

        if prefix == 0x00:
            if op == 0x00E0:  # CLS
                raise Exception("FIXME: CLS not implemented")
            if op == 0x00EE:  # RET
                self.pc = self.stack.pop()
            else:  # SYS addr
                # This instruction is only used on the old computers
                # on which Chip-8 was originally implemented. It is
                # ignored by modern interpreters.
                pass
        elif prefix == 0x1:  # JP addr
            self.pc = nnn
        elif prefix == 0x2:  # CALL addr
            self.stack.append(self.pc)
            self.pc = nnn
        elif prefix == 0x3:  # SE Vx, byte
            if self.reg[x] == kk:
                self.pc += 2
        elif prefix == 0x4:  # SNE Vx, byte
            if self.reg[x] != kk:
                self.pc += 2
        elif prefix == 0x6:  # LD Vx, byte
            self.reg[x] = kk
        elif prefix == 0x7:  # ADD Vx, byte
            self.reg[x] = (self.reg[x] + kk) & 0xFF
        elif 0x8000 == op & 0xF00F:  # LD Vx, Vy
            self.reg[x] = self.reg[y]
        elif 0x8002 == op & 0xF00F:  # AND Vx, Vy
            self.reg[x] = self.reg[x] & self.reg[y]
        elif 0x8004 == op & 0xF00F:  # ADD Vx, Vy
            r = self.reg[x] + self.reg[y]
            self.reg[x] = r & 0xFF
            self.reg[0xF] = 1 if r > 0xFF else 0
        elif 0x8005 == op & 0xF00F:  # SUB Vx, Vy
            r = self.reg[x] - self.reg[y]
            self.reg[x] = r & 0xFF
            self.reg[0xF] = 0 if r < 0 else 1
        elif prefix == 0xA:  # LD I, addr
            self.i = nnn
        elif prefix == 0xC:  # RND Vx, byte
            self.reg[x] = randint(0, 255) & kk
        elif prefix == 0xD:  # DRW Vx, Vy, nibble
            q = op & 0xF
            self.display.sprite(self.reg[x], self.reg[y], self.ram[self.i:self.i+q])
            # raise Exception("%d %s" % (q, str(self.ram[self.i:self.i + q])))
        elif op & 0xF0FF == 0xE0A1:  # SKNP Vx
            if self.display.keys[self.reg[x]]:
                self.pc += 2
        elif op & 0xF0FF == 0xF007:  # LD Vx, DT
            self.reg[x] = self.delay_timer
        elif op & 0xF0FF == 0xF015:  # LD DT, Vx
            self.delay_timer = self.reg[x]
        elif op & 0xF0FF == 0xF018:  # LD ST, Vx
            self.sound_timer = self.reg[x]
        elif op & 0xF0FF == 0xF033:  # LD B, Vx
            # Store BCD representation of Vx at I, I+1 and I+2
            v = self.reg[x]
            self.ram[self.i] = v // 100
            self.ram[self.i + 1] = (v % 100) // 10
            self.ram[self.i + 2] = (v % 10)
        elif op & 0xF0FF == 0xF065:  # LD, Vx, [I]
            # Read registers V0 through Vx from memory starting at I
            for n in range(0, x + 1):
                self.reg[n] = self.ram[self.i + n]
        elif op & 0xF0FF == 0xF029:  # LD F, Vx
            # The digits are stored at address 0x0000,
            # and each digit is 8x5 bits (5 bytes)
            self.i = self.reg[x] * 5
        else:
            raise IllegalOp(op, op_addr)

    def jump(self, pc):
        self.pc = pc
    
    def run(self):
        ts = time_ns()
        while True:
            vm.step()
            now = time_ns()
            if now - ts > 16_666_667:
                self.display.render()
                self.display.reset_keypad()
                if self.delay_timer > 0:
                    self.delay_timer -= 1
                if self.sound_timer > 0:
                    self.sound_timer -= 1
                ts = now
            sleep(0.0001)

display = PyGameDisplay()
vm = VM(display)
length = vm.load("../rom/pong", 0x200)
vm.jump(0x200)
vm.disassemble(0x200, length)
display.setup()

try:
    vm.run()
except IllegalOp as e:
    display.finalize()
    print(e)
    print("  Disassembled: ", format_opcode(e.op))
except Exception as e:
    display.finalize()
    raise e

