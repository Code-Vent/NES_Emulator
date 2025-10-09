package nes

import "core:fmt"
import cart "mappers"
import scrn "screen"

Range ::struct {
    lower_addr:u16,
    upper_addr:u16,
}

Target ::union {
    []u8,
    ^scrn.Ppu2C02,
    ^ApuRP2A03,
    ^cart.Mapper,
    ^Disassembler,
}

Addressable ::struct {
    addr_space: Range,
    mask: u16,
    target: Target,
}

new_address_space ::proc(target: Target, first_addr: u16, addr_mask: u16, last_addr:u16) -> Addressable{    
    return {
        addr_space = Range{
            upper_addr = last_addr , 
            lower_addr = first_addr,
        },
        mask = addr_mask,
        target = target,
    };
}


space_write ::proc(self: ^Addressable, address: u16, data: u8) {
    addr := self.mask & address;
    ok := space_contains_address(self, addr); assert(ok);

    switch opt in self.target {
        case []u8:
            i := index(self, addr); assert(i < len(opt));
            opt[i] = data;
        case ^scrn.Ppu2C02:
            ex := scrn.ppu_regs_write(opt, addr, data);
            clock_ppu_exception_handler(ex);
        case ^ApuRP2A03:
            apu_regs_write(opt, addr, data);
        case ^cart.Mapper:
            cart.mapper_write(opt, addr, data);
        case ^Disassembler:
            disasm_write(opt, addr, data);
    }
}



space_read ::proc(self: ^Addressable, address: u16) -> u8{ 
    addr := self.mask & address;
    ok := space_contains_address(self, addr); assert(ok);
    data: u8;
    switch opt in self.target {
        case []u8:
            i := index(self, addr); assert(i < len(opt));
            data = opt[i];
        case ^scrn.Ppu2C02:
            data = scrn.ppu_regs_read(opt, addr);
        case ^ApuRP2A03:
            data = apu_regs_read(opt, addr);
        case ^cart.Mapper:
            data = cart.mapper_read(opt, addr);
        case ^Disassembler:
            data = disasm_read(opt, addr);
    } 
    return data;  
}

space_contains_address ::proc(self: ^Addressable, address: u16) -> bool{
    return (address >= self.addr_space.lower_addr && 
        address <= self.addr_space.upper_addr);
}


@(private)
index ::proc(self: ^Addressable, address: u16) -> int {
    return int(address - self.addr_space.lower_addr);
}



