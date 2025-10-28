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
    pc        :u16,
    sp        :u8,
    alu       :calc.Calc8,
    src       :Operand,
    cycles    :int,
    ram       :[2048]u8, 
    cartridge :^cart.Cartridge,
    ppu       :picture.PPU,
    log       :string,
    dummy     :[1]u8,
};

new_mcu ::proc(cartridge: ^cart.Cartridge) -> M6502 {
    mcu := M6502{};
    mcu.cartridge = cartridge;
    mcu.ppu = picture.new_ppu(cartridge);
    reset(&mcu);
    return mcu;
}

reset ::proc(mcu: ^M6502) {
    reset_handler := cart.read_cart(mcu.cartridge, 0xFFFC, 2);
    mcu.pc = u16(reset_handler[1]) << 8 | u16(reset_handler[0]);
    mcu.sp = 0xFF;
    write_flag(mcu, .HIGH, true);
    now := time.now();
    rand.reset(u64(now._nsec));
    mcu.cycles = 0;
}

nmi ::proc(mcu: ^M6502) {
    push_pc_to_stack(mcu);//alu_push_pc(self.alu, &self.bus);
    write_flag(mcu, .BREAK, false);//alu_clear_flag(self.alu, .B);
    flags := calc.ref_flags(&mcu.alu)^;
    push_stack(mcu, flags);
    write_flag(mcu, .INTERRUPT, true);//alu_set_flag(self.alu, .I);    
    addr := read_bus(mcu, 0xFFFA, 2);
    mcu.pc = u16(addr[1]) << 8 | u16(addr[0]);
}

irq ::proc(mcu: ^M6502) {
    if !read_flag(mcu, .INTERRUPT) {//alu_is_flag_clear(self.alu, .I) {
        push_pc_to_stack(mcu);
        write_flag(mcu, .BREAK, false);//alu_clear_flag(self.alu, .B);
        flags := calc.ref_flags(&mcu.alu)^;
        push_stack(mcu, flags);
        write_flag(mcu, .INTERRUPT, true);        
        addr := read_bus(mcu, 0xFFFE, 2);
        mcu.pc = u16(addr[1]) << 8 | u16(addr[0]);
    }
}

dma ::proc(mcu: ^M6502, addr: u16, nbytes: int) -> []u8 {
    return read_bus(mcu, addr, nbytes);
}

decode ::proc(mcu: ^M6502) -> (debug_info:string) {
    pc := mcu.pc;
    mcu.log = "";
    instr := read_bus(mcu, pc, 3);
    row := (instr[0] & 0xF0) >> 4;
    col := (instr[0] & 0x0F);
    opcode := OPCODES[row][col];
    instr_size := address_mode(mcu, opcode.al, instr[1:]);
    mcu.pc += u16(instr_size);
    decode_instruction(mcu, opcode.ol);
    mcu.cycles += int(opcode.cycles);
    debug_info = fmt.tprintf("%4X %2X %s %s", pc, instr[0], opcode.txt, mcu.log);
    return debug_info;
}

disassemble ::proc(mcu: ^M6502) -> (program:string) {
    curr_pc := mcu.pc;
    for mcu.pc < 0xFFFA {        
        mcu.log = "";
        instr := read_bus(mcu, curr_pc, 3);
        row := (instr[0] & 0xF0) >> 4;
        col := (instr[0] & 0x0F);
        opcode := OPCODES[row][col];
        instr_size := address_mode(mcu, opcode.al, instr[1:]);
        decode_instruction(mcu, opcode.ol);
        mcu.cycles += int(opcode.cycles);
        loc := fmt.tprintf("%4X %2X %s %s", curr_pc, instr[0], opcode.txt, mcu.log);
        program = fmt.tprintf("%s%s\n", program, loc);
        curr_pc += u16(instr_size);
        mcu.pc = curr_pc;
        //fmt.println(loc);
    }
    addr := cart.read_cart(mcu.cartridge, 0xFFFC, 2);
    reset_handler := u16(addr[1]) << 8 | u16(addr[0]);
    program = fmt.tprintf("%sReset: $%4X\n", program, reset_handler);
    addr = cart.read_cart(mcu.cartridge, 0xFFFA, 2);
    nmi_handler := u16(addr[1]) << 8 | u16(addr[0]);
    program = fmt.tprintf("%sNMI  : $%4X\n", program, nmi_handler);
    addr = cart.read_cart(mcu.cartridge, 0xFFFE, 2);
    irq_handler := u16(addr[1]) << 8 | u16(addr[0]);
    program = fmt.tprintf("%sIRQ  : $%4X\n", program, irq_handler);
    return program;
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
        case 0x2000..=0x3FFF://PPU
            picture.write_ppu_regs(&mcu.ppu, address & 0x2007, data);
        case 0x4014:
            //assert(false);
            picture.write_ppu_regs(&mcu.ppu, address, data);
        case 0x4020..=0xFFFF: //Cartridge 
            cart.write_cart(mcu.cartridge, address, data);
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
            //assert(false);
            data = picture.read_ppu_regs(&mcu.ppu, address & 0x2007);
        case 0x4020..=0xFFFF://Cartridge  
            data = cart.read_cart(mcu.cartridge, address, nbytes);
        case:
            return mcu.dummy[:];
    }
    return data;
}