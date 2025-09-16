package main

import "core:mem"
import "core:fmt"
import sdl "vendor:sdl3"
import addr "./nes/address"
import "nes"

Operandi::union {
    u8,
    u16,
    ^u8,
}

main::proc () {
    alu := nes.Alu6502{};
    cpu := nes.cpu_get(&alu);
    nes.cpu_write(cpu, 0xFFFC, 0xFC);
    nes.cpu_write(cpu, 0xFFFD, 0xFD);
    nes.cpu_reset(cpu);
    addr.bus_map(&cpu.bus);

    fmt.printfln("%x\n", alu.regs.PC);
    fmt.printfln("%x\n", alu.regs.SP);
    fmt.printfln("%x\n", alu.regs.SR);
}