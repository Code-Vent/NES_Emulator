package nes

import "core:fmt"
import cart "mappers"
import scrn "screen"


CpuInterface::struct {
    alu: ^Alu6502,
    bus: Bus,
    disasm: ^Disassembler,
}

@(private)
CPUMemoryBlock::struct {
    ram: [0x0800]u8,
    apu_io_funcs: [0x0008]u8,
}

@(private)
cpu_memory := CPUMemoryBlock{};

@(private)
cpu := CpuInterface{};

@(private)
cpu_mem_map: [7]Addressable;

cpu_get::proc (
    alu: ^Alu6502, 
    ppu: ^scrn.Ppu2C02, 
    apu: ^ApuRP2A03,
    mapper: ^cart.Mapper
) -> ^CpuInterface {
    cpu_mem_map[0] = new_address_space(cpu_memory.ram[:], 0x0000, 0x07FF,0x1FFF);
    cpu_mem_map[1] = new_address_space(ppu, 0x2000, 0x2007,0x3FFF);
    cpu_mem_map[2] = new_address_space(apu, 0x4000, 0xFFFF,0x4013);
    cpu_mem_map[3] = new_address_space(ppu, 0x4014, 0xFFFF,0x4014);
    cpu_mem_map[4] = new_address_space(apu, 0x4015, 0xFFFF,0x4017);
    cpu_mem_map[5] = new_address_space(cpu_memory.apu_io_funcs[:], 0x4018, 0x401F,0x401F);
    cpu_mem_map[6] = new_address_space(mapper, 0x4020, 0xFFFF,0xFFFF);

    cpu.bus = new_bus(cpu_mem_map[:]);    
    alu.regs.SR = u8(1 << 5); 
    cpu.alu = alu;  
    cpu_reset(&cpu);
    cpu.disasm = disasm_get();    
    return &cpu;
}

cpu_write::proc (self: ^CpuInterface, address: u16, data: u8) {
    bus_write(&self.bus, address, data);
}

cpu_read::proc (self: ^CpuInterface, address: u16) -> u8 {
    return bus_read_u8(&self.bus, address);
}

cpu_debug_print::proc (self: ^CpuInterface, address: u16) {
    bus_print_u8(&self.bus, address);
}

cpu_reset::proc (self: ^CpuInterface) {
    lo := u16(cpu_read(self, 0xFFFC));
    hi := u16(cpu_read(self, 0xFFFD));
    self.alu.regs.PC = (hi << 8) | lo;
    self.alu.regs.A = 0;
    self.alu.regs.X = 0;
    self.alu.regs.Y = 0;
    self.alu.regs.SP = 0xFF;
    self.alu.regs.SR = u8(1 << 5);
}

cpu_nmi::proc (self: ^CpuInterface) {
    alu_push_pc(self.alu, &self.bus);
    alu_clear_flag(self.alu, .B);
    alu_push(self.alu, &self.bus, self.alu.regs.SR);
    alu_set_flag(self.alu, .I);
    
    lo := u16(cpu_read(self, 0xFFFA));
    hi := u16(cpu_read(self, 0xFFFB));

    isr: Operand = u16((hi << 8) | lo);
    alu_jump(&isr, self.alu, .JMP, &self.bus);
}

cpu_irq::proc (self: ^CpuInterface) {
    if alu_is_flag_clear(self.alu, .I) {
        alu_push_pc(self.alu, &self.bus);
        alu_clear_flag(self.alu, .B);
        alu_push(self.alu, &self.bus, self.alu.regs.SR);
        alu_set_flag(self.alu, .I);
        
        lo := u16(cpu_read(self, 0xFFFE));
        hi := u16(cpu_read(self, 0xFFFF));

        isr: Operand = u16((hi << 8) | lo);

        alu_jump(&isr, self.alu, .JMP, &self.bus);
    }
}


