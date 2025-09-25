package main

import "core:fmt"
import "nes"
import screen "./nes/display"
import cart "./nes/mappers"
import "core:mem"


main ::proc() {
    mapper, ok := cart.new_mapper("./mario.nes");
    assert(ok);
    defer cart.delete_mapper(&mapper);

    cpu := nes.cpu_get(&nes.Alu6502{}, &nes.Ppu2C02{}, &nes.ApuRP2A03{}, &mapper);

    value := nes.bus_read_u16(&cpu.bus, 0xFFFC);
    fmt.printf("%x\n", value);
}

