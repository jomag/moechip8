# TODO:
# - Validate the complex DRW op. Does it handle wrapping correctly, etc?

import argparse
from collections import deque
from time import sleep, time_ns
from random import randint
import pygame

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


class PyGameDisplay:
    width: int
    height: int
    zoom: int

    _key_map = [
        pygame.K_x,  # 0
        pygame.K_1,  # 1
        pygame.K_2,  # 2
        pygame.K_3,  # 3
        pygame.K_q,  # 4
        pygame.K_w,  # 5
        pygame.K_e,  # 6
        pygame.K_a,  # 7
        pygame.K_s,  # 8
        pygame.K_d,  # 9
        pygame.K_z,  # A
        pygame.K_c,  # B
        pygame.K_4,  # C
        pygame.K_r,  # D
        pygame.K_f,  # E
        pygame.K_v,  # F
    ]

    def __init__(self, width=64, height=32, zoom=5):
        self.zoom = zoom
        self.width = width
        self.height = height
        self.buf = [bytearray(self.width) for n in range(self.height)]
        # self.window = None
        self.keys = [False] * 16

    def clear(self):
        self.buf = [bytearray(self.width) for n in range(self.height)]

    def setup(self):
        pygame.init()
        resolution = (self.width * self.zoom, self.height * self.zoom)
        pygame.display.set_mode(resolution)
        self.surface = pygame.Surface((self.width, self.height))

    def _handle_event(self, evt):
        if evt.type == pygame.QUIT:
            raise SystemExit
        if evt.type == pygame.KEYDOWN:
            try:
                idx = self._key_map.index(evt.key)
                self.keys[idx] = True
            except ValueError:
                print("Illegal key down: ", evt.key)
        if evt.type == pygame.KEYUP:
            try:
                idx = self._key_map.index(evt.key)
                self.keys[idx] = False
            except ValueError:
                print("Illegal key up: ", evt.key)

    def update(self):
        event = pygame.event.poll()
        self._handle_event(event)

    def wait_for_key(self):
        self.render()
        while True:
            evt = pygame.event.wait()
            self._handle_event(evt)
            if evt.type == pygame.KEYDOWN:
                try:
                    return self._key_map.index(evt.key)
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

    def sprite(self, x: int, y: int, sprite: bytes, wrap: bool) -> int:
        collision = False

        if not wrap and y < 0:
            sprite = sprite[-y:]
            y = 0

        for bmp in sprite:
            if wrap:
                y = y % self.height
            elif y >= self.height:
                break

            bx = x
            for bit in [128, 64, 32, 16, 8, 4, 2, 1]:
                if wrap:
                    bx = bx % self.width
                elif bx >= self.width:
                    break

                if wrap or bx >= 0:
                    c = self.buf[y][bx]
                    n = bmp & bit
                    if c and n:
                        collision = True
                    if (c and not n) or (n and not c):
                        self.buf[y][bx] = True
                    else:
                        self.buf[y][bx] = False

                bx = bx + 1
            y = y + 1
        return collision


class IllegalOp(Exception):
    def __init__(self, op, addr):
        super().__init__(f"Unsupported opcode: 0x{op:04X}, at 0x{addr:04X}")
        self.op = op
        self.addr = addr


class VM:
    display: PyGameDisplay
    pc: int
    i: int
    delay_timer: int
    sound_timer: int
    wrap: bool

    digits = [
        [0xF0, 0x90, 0x90, 0x90, 0xF0],  # 0
        [0x20, 0x60, 0x20, 0x20, 0x70],  # 1
        [0xF0, 0x10, 0xF0, 0x80, 0xF0],  # 2
        [0xF0, 0x10, 0xF0, 0x10, 0xF0],  # 3
        [0x90, 0x90, 0xF0, 0x10, 0x10],  # 4
        [0xF0, 0x80, 0xF0, 0x10, 0xF0],  # 5
        [0xF0, 0x80, 0xF0, 0x90, 0xF0],  # 6
        [0xF0, 0x10, 0x20, 0x40, 0x40],  # 7
        [0xF0, 0x90, 0xF0, 0x90, 0xF0],  # 8
        [0xF0, 0x90, 0xF0, 0x10, 0xF0],  # 9
        [0xF0, 0x90, 0xF0, 0x90, 0x90],  # A
        [0xE0, 0x90, 0xE0, 0x90, 0xE0],  # B
        [0xF0, 0x80, 0x80, 0x80, 0xF0],  # C
        [0xE0, 0x90, 0x90, 0x90, 0xE0],  # D
        [0xF0, 0x80, 0xF0, 0x80, 0xF0],  # E
        [0xF0, 0x80, 0xF0, 0x80, 0x80],  # F
    ]

    def __init__(self, display: PyGameDisplay, frequency=700, wrap=False):
        self.ram = bytearray(MEMORY_SIZE)
        self.display = display
        self.stack = deque()
        self.reg = bytearray(REGISTER_COUNT)
        self.frequency = frequency
        self.timer_frequency = 60
        self.wrap = wrap

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
        self.ram[addr : addr + len(data)] = data
        return len(data)

    def disassemble(self, start, length):
        for i in range(0, length, 2):
            op = (self.ram[start + i] << 8) | self.ram[start + i + 1]
            adr = (i + start) & 0xFFFF
            print(f"{adr:04X}: {op:04X} {format_opcode(op)}")

    def step(self):
        if self.display:
            self.display.read_keypad()
            self.display.update()

        op_addr = self.pc
        op = (self.ram[self.pc] << 8) | self.ram[self.pc + 1]
        self.pc = self.pc + 2

        nnn = op & 0xFFF
        x = (op & 0xF00) >> 8
        y = (op & 0x0F0) >> 4
        kk = op & 0xFF

        if 0x0000 == op & 0xF000:
            if 0x00E0 == op:  # CLS
                self.display.clear()
            elif 0x00EE == op:  # RET
                self.pc = self.stack.pop()
            else:  # SYS addr
                # This instruction is only used on the old computers
                # on which Chip-8 was originally implemented. It is
                # ignored by modern interpreters.
                pass
        elif 0x1000 == op & 0xF000:  # JP addr
            self.pc = nnn
        elif 0x2000 == op & 0xF000:  # CALL addr
            self.stack.append(self.pc)
            self.pc = nnn
        elif 0x3000 == op & 0xF000:  # SE Vx, byte
            if self.reg[x] == kk:
                self.pc += 2
        elif 0x4000 == op & 0xF000:  # SNE Vx, byte
            if self.reg[x] != kk:
                self.pc += 2
        elif 0x5000 == op & 0xF00F:  # SE Vx, Vy
            if self.reg[x] == self.reg[y]:
                self.pc += 2
        elif 0x6000 == op & 0xF000:  # LD Vx, byte
            self.reg[x] = kk
        elif 0x7000 == op & 0xF000:  # ADD Vx, byte
            self.reg[x] = (self.reg[x] + kk) & 0xFF
        elif 0x8000 == op & 0xF00F:  # LD Vx, Vy
            self.reg[x] = self.reg[y]
        elif 0x8001 == op & 0xF00F:  # OR Vx, Vy
            self.reg[x] = self.reg[x] | self.reg[y]
        elif 0x8002 == op & 0xF00F:  # AND Vx, Vy
            self.reg[x] = self.reg[x] & self.reg[y]
        elif 0x8003 == op & 0xF00F:  # XOR Vx, Vy
            self.reg[x] = self.reg[x] ^ self.reg[y]
        elif 0x8004 == op & 0xF00F:  # ADD Vx, Vy
            r = self.reg[x] + self.reg[y]
            self.reg[x] = r & 0xFF
            self.reg[0xF] = 1 if r > 0xFF else 0
        elif 0x8005 == op & 0xF00F:  # SUB Vx, Vy
            self.reg[0xF] = 1 if self.reg[x] > self.reg[y] else 0
            self.reg[x] = (self.reg[x] - self.reg[y]) & 0xFF
        elif 0x8006 == op & 0xF00F:  # SHR Vx {, Vy}
            # Note that this op was originally undocumented and
            # the spec is a bit unclear regarding the Vy register.
            self.reg[0xF] = self.reg[x] & 1
            self.reg[x] = self.reg[x] >> 1
        elif 0x8007 == op & 0xF00F:  # SUBN Vx, Vy
            self.reg[0xF] = 1 if self.reg[y] > self.reg[x] else 0
            self.reg[x] = (self.reg[y] - self.reg[x]) & 0xFF
        elif 0x800E == op & 0xF00F:  # SHL Vx {, Vy}
            # Originaly undocumented. See 0x8006.
            self.reg[0xF] = self.reg[x] >> 7
            self.reg[x] = (self.reg[x] & 0x7F) << 1
        elif 0x9000 == op & 0xF00F:  # SNE Vx, Vy
            if self.reg[x] != self.reg[y]:
                self.pc += 2
        elif 0xA000 == op & 0xF000:  # LD I, addr
            self.i = nnn
        elif 0xC000 == op & 0xF000:  # RND Vx, byte
            self.reg[x] = randint(0, 255) & kk
        elif 0xD000 == op & 0xF000:  # DRW Vx, Vy, nibble
            q = op & 0xF
            self.reg[0xF] = self.display.sprite(
                self.reg[x],
                self.reg[y],
                self.ram[self.i : self.i + q],
                self.wrap,
            )
        elif 0xE09E == op & 0xF0FF:  # SKP Vx
            if self.display.keys[self.reg[x]]:
                self.pc += 2
        elif 0xE0A1 == op & 0xF0FF:  # SKNP Vx
            if not self.display.keys[self.reg[x]]:
                self.pc += 2
        elif 0xF007 == op & 0xF0FF:  # LD Vx, DT
            self.reg[x] = self.delay_timer
        elif 0xF00A == op & 0xF0FF:  # LD Vx, K
            self.reg[x] = self.display.wait_for_key()
        elif 0xF015 == op & 0xF0FF:  # LD DT, Vx
            self.delay_timer = self.reg[x]
        elif 0xF018 == op & 0xF0FF:  # LD ST, Vx
            self.sound_timer = self.reg[x]
        elif 0xF01E == op & 0xF0FF:  # ADD I, Vx
            self.i = (self.i + self.reg[x]) & 0xFFFF
        elif 0xF029 == op & 0xF0FF:  # LD F, Vx
            # The digits are stored at address 0x0000,
            # and each digit is 8x5 bits (5 bytes)
            self.i = self.reg[x] * 5
        elif 0xF033 == op & 0xF0FF:  # LD B, Vx
            # Store BCD representation of Vx at I, I+1 and I+2
            v = self.reg[x]
            self.ram[self.i] = v // 100
            self.ram[self.i + 1] = (v % 100) // 10
            self.ram[self.i + 2] = v % 10
        elif 0xF055 == op & 0xF0FF:  # LD [I], Vx
            # Store registers V0 through Vx in memory starting at I
            for n in range(0, x + 1):
                self.ram[self.i + n] = self.reg[n]
        elif 0xF065 == op & 0xF065:  # LD, Vx, [I]
            # Read registers V0 through Vx from memory starting at I
            for n in range(0, x + 1):
                self.reg[n] = self.ram[self.i + n]
        else:
            raise IllegalOp(op, op_addr)

    def run(self):
        timer_interval = 1_000_000_000 / self.timer_frequency
        print(f"Interval: {timer_interval}")
        ts = time_ns()
        while True:
            self.step()
            now = time_ns()
            if now - ts >= timer_interval:
                self.display.render()
                self.display.reset_keypad()
                if self.delay_timer > 0:
                    self.delay_timer -= 1
                if self.sound_timer > 0:
                    self.sound_timer -= 1
                ts = now

            # This is a terrible way to get correct timing.
            sleep(1.0 / self.frequency)


def start(args):
    display = PyGameDisplay(zoom=args.zoom)
    vm = VM(display, frequency=args.freq, wrap=args.wrap)
    length = vm.load(args.rom, args.start)
    vm.pc = args.start
    vm.disassemble(args.start, length)
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


autoint = lambda x: int(x, 0)
parser = argparse.ArgumentParser(
    description="Moe CHIP-8 emulator (Python version)",
    formatter_class=argparse.ArgumentDefaultsHelpFormatter,
)
parser.add_argument(
    "rom",
    help="ROM file to load",
)
parser.add_argument(
    "--start",
    "-s",
    help="Start address",
    default="0x200",
    type=autoint,
)
parser.add_argument(
    "--zoom",
    "-z",
    help="Zoom pixels",
    default="5",
    type=autoint,
)
parser.add_argument(
    "--freq",
    "-f",
    help="Frequency in Hz",
    default=700,
    type=autoint,
)
parser.add_argument(
    "--wrap", "-w", help="Wrap sprites (required by some games)", default=False
)

args = parser.parse_args()

start(args)
