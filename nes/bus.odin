package nes

import "core:fmt"

Bus::struct {
    devices: []Addressable,
    last_addr: u16,
}

new_bus::proc (devices: []Addressable) -> Bus {
    return Bus {
        devices = devices,
    };
}


bus_find::proc (self: ^Bus, address: u16) -> (^Addressable,bool) {
    for i in 0..<len(self.devices) {
        if space_contains_address(&self.devices[i], address) {
            return &self.devices[i], true;
        }
    }
    return nil, false;
}

bus_write::proc (self: ^Bus, address: u16, data: u8) {
    self.last_addr = address;
    device , ok := bus_find(self, address); assert(ok);
    space_write(device, address, data);
}

bus_read_u8::proc (self: ^Bus, address: u16) -> u8 {
    self.last_addr = address;
    device , ok := bus_find(self, address); assert(ok);
    return space_read(device, address);
}

bus_read_u16::proc (self: ^Bus, address: u16) -> u16 {
    self.last_addr = address;
    device , ok := bus_find(self, address); assert(ok);
    lo:= u16(space_read(device, address));
    hi:= u16(space_read(device, address + 1));
    data := (hi << 8) | lo;
    return lo;
}

bus_print_u8::proc (self: ^Bus, address: u16) {
    data := bus_read_u8(self, address);
    fmt.printf("Address: %x contains %x\n", address, data);
}

bus_print_u16::proc (self: ^Bus, address: u16) {
    bus_print_u8(self, address + 1);
    bus_print_u8(self, address);
}

bus_map::proc (self: ^Bus) {
    for i in 0..<len(self.devices) {
        fmt.printf("first addr: %x   last addr: %x\n", 
        self.devices[i].addr_space.lower_addr,self.devices[i].addr_space.upper_addr);
    }
}