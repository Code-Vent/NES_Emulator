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

new_address_space::proc (target: Target, first_addr: u16, addr_mask: u16, last_addr:u16) -> Addressable{    
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
    if bytes, ok := self.target.([]u8); ok {
        i := index(self, addr); assert(i < len(bytes));
        bytes[i] = data;
    }else{
        callback := self.target.(proc(memory_mapped_addr: u16,data: u8) -> u8);
        callback(addr, data);
    }
    
}



space_read::proc (self: ^Addressable, address: u16) -> u8{ 
    addr := self.mask & address;
    ok := space_contains_address(self, addr); assert(ok);
    if bytes, ok := self.target.([]u8); ok {
        bytes = self.target.([]u8);
        i := index(self, addr); assert(i < len(bytes));
        return bytes[i];
    }else{
        callback := self.target.(proc(memory_mapped_addr: u16,data: u8) -> u8);
        return callback(addr, 0);
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



