package micro

import "core:fmt"
import "core:math/rand"
import "core:time"
import "../../Calculator/calc"
import "../../Cartridge/cart"
import "../../PictureProcessor/picture"

A  ::calc.Register.R0;
X  ::calc.Register.R1;
Y  ::calc.Register.R2;
W0 ::calc.Register.R3;
W1 ::calc.Register.R4;

Flag ::enum(u8){
	DECIMAL   = (1<<3), 
	INTERRUPT = (1<<2), 
    BREAK     = (1<<4),
    HIGH      = (1<<5),
};

Operand::union {
    u8,
    u16,
    calc.Register,
}

get_R ::proc(alu: ^calc.Calc8, R: calc.Register) -> u8 {
    return calc.read_register(alu, R);
}

set_R ::proc(alu: ^calc.Calc8, R: calc.Register, val: u8) {
    calc.write_register(alu, R, val);
}

M6502 ::struct{
    pc :u16,
    sp :u8,
    alu :calc.Calc8,
    src: Operand,
    cycles: int,
    ram :[2048]u8, 
    cartridge :^cart.Cartridge,
    ppu :picture.PPU,
    log :string,
};

reset ::proc(mcu: ^M6502, cartridge: ^cart.Cartridge) {
    reset_handler := cart.read_rom(cartridge, 0xFFFC, 2);
    mcu.pc = u16(reset_handler[1]) << 8 | u16(reset_handler[0]);
    mcu.sp = 0xFF;
    write_flag(mcu, .HIGH, true);
    mcu.cartridge = cartridge;
    now := time.now();
    rand.reset(u64(now._nsec));
    mcu.cycles = 0;
    for i in 0..<len(mcu.ram) {
        mcu.ram[i] = u8(rand.uint64());
    }
}

decode ::proc(mcu: ^M6502) -> (debug_info:string) {
    pc := mcu.pc;
    mcu.log = "";
    instr := read_bus(mcu, pc, 3);
    row := (instr[0] & 0xF0) >> 4;
    col := (instr[0] & 0x0F);
    opcode := OPCODES[row][col];
    dest: Operand;
    instr_size := address_mode(mcu, opcode.al, instr[1:]);
    mcu.pc += u16(instr_size);
    decode_instruction(mcu, opcode.ol);
    mcu.cycles += int(opcode.cycles);
    debug_info = fmt.tprintf("%4X %2X %s %s", pc, instr[0], opcode.txt, mcu.log);
    return debug_info;
}

read_flag ::proc(mcu: ^M6502, f: Flag) -> bool {
    flag0 := calc.ref_flags(&mcu.alu)^;
    return (flag0 & transmute(u8)f) != 0;
}

write_flag ::proc(mcu: ^M6502, f: Flag, value: bool) {
    flag0 := calc.ref_flags(&mcu.alu)
    if value {
		flag0^ |= transmute(u8)f;
	}
	else {
		flag0^ &= ~transmute(u8)f;
	}
}

write_bus ::proc(mcu: ^M6502, address: u16, data: u8) {
    switch address {
        case 0x0000..=0x1FFF://RAM
            index := address & 0x07FF;
            mcu.ram[index] = data;
        case 0x2000..=0x3FFF, 0x4014://PPU
            picture.write_ppu(&mcu.ppu, address & 0x2007, data);
        case 0x4020..=0xFFFF: //Cartridge 
            cart.write_rom(mcu.cartridge, address, data);
        case:
    }
}

read_bus ::proc(mcu: ^M6502, address: u16, nbytes: int = 1) -> (data: []u8) {
    switch address {
        case 0x0000..=0x1FFF://RAM
            start := address & 0x07FF;
            end   := start + u16(nbytes);
            if end < len(mcu.ram) {
                data = mcu.ram[start:end];
            }else{
                data = mcu.ram[start:];
            }
        case 0x2000..=0x3FFF://PPU
            data = picture.read_ppu(&mcu.ppu, address & 0x2007);
        case 0x4020..=0xFFFF://Cartridge  
            data = cart.read_rom(mcu.cartridge, address, nbytes);
        case:
    }
    return data;
}