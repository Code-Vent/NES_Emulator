package address

import "core:fmt"

Range::struct {
    lower_addr:u16,
    upper_addr:u16,
}

Target::union {
    []u8,
    proc(memory_mapped_addr:u16, data:u8)->u8,
}

Addressable::struct {
    addr_space: Range,
    mask: u16,
    target: Target,
}

new_address_space::proc (target: Target, first_addr: u16, addr_mask: u16, rightmost_addr:u16) -> Addressable{
    last_addr: u16;
    if mem, ok := target.([]u8); ok {
        last_addr = first_addr + u16(len(mem) - 1);
    }else{
        last_addr = rightmost_addr;
    }
    
    return {
        addr_space = Range{
            upper_addr = last_addr , 
            lower_addr = first_addr,
        },
        mask = addr_mask,
        target = target,
    };
}


space_write::proc (self: ^Addressable, address: u16, data: u8) {
    addr := self.mask & address;
    ok := space_contains_address(self, addr); assert(ok);
    i := index(self, addr);
    if bytes, ok := self.target.([]u8); ok {
        bytes[i] = data;
    }else{
        callback := self.target.(proc(memory_mapped_addr: u16,data: u8) -> u8);
        callback(address, data);
    }
    
}



space_read::proc (self: ^Addressable, address: u16) -> u8{ 
    addr := self.mask & address;
    ok := space_contains_address(self, addr); assert(ok);
    i := index(self, addr);
    if bytes, ok := self.target.([]u8); ok {
        bytes = self.target.([]u8);
        return bytes[i];
    }else{
        callback := self.target.(proc(memory_mapped_addr: u16,data: u8) -> u8);
        return callback(address, 0);
    }    
}

space_contains_address::proc (self: ^Addressable, address: u16) -> bool{
    return (address >= self.addr_space.lower_addr && 
        address <= self.addr_space.upper_addr);
}


@(private)
index::proc (self: ^Addressable, address: u16) -> int {
    return int(address - self.addr_space.lower_addr);
}



