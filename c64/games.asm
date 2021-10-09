#importonce

.var ibm_data = LoadBinary("ibm.ch8")
rom_ibm: .fill ibm_data.getSize(), ibm_data.get(i)
rom_ibm_size: .word ibm_data.getSize()
