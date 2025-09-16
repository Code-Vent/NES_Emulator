package address

import "core:fmt"

Range::struct {
    lower_addr:u16,
    upper_addr:u16,
}

Addressable::struct {
    addr_space: Range,
    mask: u16,
    bytes: []u8,
}

new_address_space::proc (mem: []u8, first_addr: u16, addr_mask: u16) -> Addressable{
    last_addr: u16 = first_addr + u16(len(mem) - 1);
    return {
        addr_space = Range{
            upper_addr = last_addr , 
            lower_addr = first_addr,
        },
        mask = addr_mask,
        bytes = mem,
    };
}


space_write::proc (self: ^Addressable, address: u16, data: u8) {
    addr := self.mask & address;
    ok := space_contains_address(self, addr); assert(ok);
    i := index(self, addr);
    self.bytes[i] = data;
}



space_read::proc (self: ^Addressable, address: u16) -> u8{ 
    addr := self.mask & address;
    ok := space_contains_address(self, addr); assert(ok);
    i := index(self, addr);
    return self.bytes[i];
}

space_contains_address::proc (self: ^Addressable, address: u16) -> bool{
    return (address >= self.addr_space.lower_addr && 
        address <= self.addr_space.upper_addr);
}


@(private)
index::proc (self: ^Addressable, address: u16) -> int {
    return int(address - self.addr_space.lower_addr);
}



