#importonce

.var ibm_data = LoadBinary("ibm.ch8")
rom_ibm: .fill ibm_data.getSize(), ibm_data.get(i)
rom_ibm_size: .word ibm_data.getSize()

.var rom_test1_data = LoadBinary("../rom/chip8-test-rom.ch8")
rom_test1: .fill rom_test1_data.getSize(), rom_test1_data.get(i)
rom_test1_size: .word rom_test1_data.getSize()

.var rom_test2_data = LoadBinary("../rom/test_opcode.ch8")
rom_test2: .fill rom_test2_data.getSize(), rom_test2_data.get(i)
rom_test2_size: .word rom_test2_data.getSize()

.var invaders_data = LoadBinary("../rom/CHIP8/GAMES/INVADERS")
rom_invaders: .fill invaders_data.getSize(), invaders_data.get(i)
rom_invaders_size: .word invaders_data.getSize()

.var blitz_data = LoadBinary("../rom/CHIP8/GAMES/BLITZ")
rom_blitz: .fill blitz_data.getSize(), blitz_data.get(i)
rom_blitz_size: .word blitz_data.getSize()
