package main

import "core:mem"
import "core:fmt"
import sdl "vendor:sdl3"
import addr "./nes/address"
import "nes"


main::proc () {
    alu := nes.Alu6502{};
    cpu := nes.cpu_get(&alu);
    nes.cpu_write(cpu, 0xFFFC, 0xFC);
    nes.cpu_write(cpu, 0xFFFD, 0xFD);

    nes.cpu_write(cpu, 0xFFFE, 0xFE);
    nes.cpu_write(cpu, 0xFFFF, 0xFF);

    nes.cpu_write(cpu, 0xFFFA, 0xFA);
    nes.cpu_write(cpu, 0xFFFB, 0xFB);

    nes.cpu_reset(cpu);
    addr.bus_map(&cpu.bus);

    fmt.printfln("\n%x\n", alu.regs.PC);
    fmt.printfln("%x\n", alu.regs.SR);
    nes.cpu_nmi(cpu);

    fmt.printfln("%x\n", alu.regs.PC);
    fmt.printfln("%x\n", alu.regs.SR);
}