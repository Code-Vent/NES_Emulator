package micro

import "core:fmt"
import "../../Calculator/calc"
import "../../Cartridge/cart"

AddressingLabel::enum(u8) {
    IMP, IMM, ZP0, ZPX, ZPY, REL, ABS, ABX, ABY, IND, IZX, IZY, ACC,
}

address_mode ::proc(
    mcu: ^M6502, 
    mode: AddressingLabel,
    arg: []u8
) -> (size: u8){
    switch(mode){
        case .ABS:
            size = absolute(mcu, arg);
        case .ABX:
            size = absolute_indexed_x(mcu, arg);
        case .ABY:
            size = absolute_indexed_y(mcu, arg);
        case .IMM:
            size = immediate(mcu, arg);
        case .IMP,.ACC:
            size = implied(mcu, arg);
        case .IND:
            size = indirect(mcu, arg);
        case .IZX:
            size = indirect_indexed_x(mcu, arg);
        case .IZY:
            size = indirect_indexed_y(mcu, arg);
        case .REL:
            size = relative(mcu, arg);
        case .ZP0:
            size = zero_page(mcu, arg);
        case .ZPX:
            size = zero_page_indexed_x(mcu, arg);
        case .ZPY:
            size = zero_page_indexed_y(mcu, arg);
    }
    return size;
}

@(private)
implied ::proc(mcu: ^M6502, arg: []u8) -> (size:u8){
    mcu.src = A;
    return 1;
}

@(private)
immediate ::proc (mcu: ^M6502, arg: []u8) -> (size:u8) {
    mcu.src = arg[0];
    mcu.log = fmt.tprintf("#$%2X", arg[0]);
    return 2;
}

@(private)
relative ::proc (mcu: ^M6502, arg: []u8) -> (size:u8){
    eaddr:int = int(mcu.pc + 2) + int(i8(arg[0]));
    mcu.src = u16(eaddr);
    mcu.log = fmt.tprintf("$%4X", eaddr);
    return 2;
}

@(private)
zero_page_indexed_x ::proc (mcu: ^M6502, arg: []u8) -> (size: u8){    
    eaddr := (u16(arg[0]) + u16(get_R(&mcu.alu, X))) & 0x00FF;
    mcu.src = eaddr;
    mcu.log = fmt.tprintf("(X=$%2X, $%2X) = $%4X", get_R(&mcu.alu, X), arg[0], eaddr);
    return 2;
}

@(private)
zero_page_indexed_y ::proc (mcu: ^M6502, arg: []u8) -> (size:u8) {
    eaddr := (u16(arg[0]) + u16(get_R(&mcu.alu, Y))) & 0x00FF;
    mcu.src = eaddr;
    mcu.log = fmt.tprintf("(Y=$%2X, $%2X) = $%4X", get_R(&mcu.alu, Y), arg[0], eaddr);
    return 2;
}

@(private)
absolute ::proc (mcu: ^M6502, arg: []u8) -> (size: u8){
    eaddr := u16(arg[1]) << 8 | u16(arg[0]);
    mcu.src = eaddr;
    mcu.log = fmt.tprintf("$%4X", eaddr);
    return 3;
}

@(private)
absolute_indexed_x ::proc (mcu: ^M6502, arg: []u8) -> (size: u8){
    addr := u16(arg[1]) << 8 | u16(arg[0]);
    eaddr := u16(addr) + u16(get_R(&mcu.alu, X));
    mcu.src = eaddr;
    if (eaddr & 0xFF00) != (addr & 0xFF00) {
        mcu.cycles += 1;
    }
     mcu.log = fmt.tprintf("($%4X, X=$%2X) = $%4X", addr, get_R(&mcu.alu, X), eaddr);
    return 3;
}

@(private)
absolute_indexed_y ::proc (mcu: ^M6502, arg: []u8) -> (size: u8){
    addr := u16(arg[1]) << 8 | u16(arg[0]);
    eaddr := u16(addr) + u16(get_R(&mcu.alu, Y));
    mcu.src = eaddr;
    if (eaddr & 0xFF00) != (addr & 0xFF00) {
        mcu.cycles += 1;
    }
    mcu.log = fmt.tprintf("($%4X, Y=$%2X) = $%4X", addr, get_R(&mcu.alu, Y), eaddr);
    return 3;
}
//($FF,X)
@(private)
indirect_indexed_x ::proc (mcu: ^M6502, arg: []u8) -> (size: u8){
    temp := (u16(arg[0]) + u16(get_R(&mcu.alu, X))) & 0x00FF;
    lo_addr := read_bus(mcu, temp)[0];
    temp = (temp + 1) & 0x00FF;
    hi_addr := read_bus(mcu, temp)[0];
    eaddr := u16(hi_addr) << 8 | u16(lo_addr);
    mcu.src = eaddr;
    mcu.log = fmt.tprintf("($%2X, X=$%2X) = $%4X", arg[0], get_R(&mcu.alu, X), eaddr);
    return 2;
}

@(private)
indirect_indexed_y::proc (mcu: ^M6502, arg: []u8) -> (size: u8){
    lo_addr := read_bus(mcu, u16(arg[0]))[0];
    hi_addr := read_bus(mcu, u16(arg[0] + 1) & 0x00FF)[0];
    eaddr := (u16(hi_addr) << 8 | u16(lo_addr)) + u16(get_R(&mcu.alu, Y));
    mcu.src = eaddr;
    if (eaddr & 0xFF00) != (u16(hi_addr) << 8) {
        mcu.cycles += 1;
    }
    mcu.log = fmt.tprintf("($%2X, X=$%2X) = $%4X", arg[0], get_R(&mcu.alu, Y), eaddr);
    return 2;
}

@(private)
indirect::proc (mcu: ^M6502, arg: []u8) -> (size: u8){
    hi_addr := u16(arg[1]) << 8;
    addr    := u16(arg[1]) << 8 | u16(arg[0]);
    eaddr   := u16(0);
    if arg[0] == 0xFF {
        hi := read_bus(mcu, hi_addr);
        lo := read_bus(mcu, addr);
        eaddr = u16(hi[0]) << 8 | u16(lo[0]);
    }else{
        hi_lo := read_bus(mcu, addr, 2);
        eaddr = u16(hi_lo[1]) << 8 | u16(hi_lo[0]);
    }
    mcu.src = eaddr;
    mcu.log = fmt.tprintf("$%4X", eaddr);
    return 3;
}

@(private)
zero_page::proc (mcu: ^M6502, arg: []u8) -> (size: u8){
    eaddr := u16(arg[0]) & 0x00FF;
    mcu.src = eaddr;
    mcu.log = fmt.tprintf("$%2X", eaddr);
    return 2;
}
