package main

import "core:mem"
import "core:fmt"
import sdl "vendor:sdl3"
import "nes"


main::proc () {
    alu := nes.Alu6502{};
    ppu := nes.Ppu2C02{};
    apu := nes.ApuRP2A03{};
    cpu := nes.cpu_get(&alu, &ppu, &apu);
    nes.cpu_write(cpu, 0xFFFC, 0xFC);
    nes.cpu_write(cpu, 0xFFFD, 0xFD);

    nes.cpu_write(cpu, 0xFFFE, 0xFE);
    nes.cpu_write(cpu, 0xFFFF, 0xFF);

    nes.cpu_write(cpu, 0xFFFA, 0xFA);
    nes.cpu_write(cpu, 0xFFFB, 0xFB);

    nes.cpu_reset(cpu);
    nes.bus_map(&cpu.bus);

    //fmt.printfln("\n%x\n", alu.regs.PC);
    //fmt.printfln("%x\n", alu.regs.SR);
    //nes.cpu_nmi(cpu);

    fmt.printfln("%x\n", alu.regs.PC);
    fmt.printfln("sr = %x\n", alu.regs.SR);

    for i in 0..=1000 {
        nes.alu_push(&alu, &cpu.bus, 0xBB);
        fmt.printfln("sp = %x\n", alu.regs.SP);
        src, dest: nes.Operand;
        nes.decode_operand(&alu, .IMP, &cpu.bus, &src);
        nes.decode_operation(&alu, .PLA, &cpu.bus, &src, &dest);
        fmt.printfln("A = %x\n", alu.regs.A);
        fmt.printfln("sp = %x\n", alu.regs.SP);
    }
    
    oam_reg := nes.bus_read_u8(&cpu.bus, 0x4014);
    fmt.printfln("oam reg = %x\n", oam_reg);
}