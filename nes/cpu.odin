package nes


import addr "address"
import "core:fmt"


ProcessingUnit::union {
    ^Alu6502,
    ^Ppu2C02,
}

None::struct {}
Result::union {
    Alu6502_Result,
    Ppu2C02_Result,
    None,
}

CpuInterface::struct {
    pu: ProcessingUnit,
    bus: addr.Bus,
}

@(private)
CPUMemoryBlock::struct {
    ram: [0x0800]u8,
    apu_io_funcs: [0x0008]u8,
    cartridge: [0xBFE0]u8,
}
@(private)
CPU_MEMORY := CPUMemoryBlock{};

@(private)
cpu := CpuInterface{};

@(private)
cpu_mem_map: [7]addr.Addressable;

cpu_get::proc (alu: ^Alu6502) -> ^CpuInterface {
    cpu_mem_map[0] = addr.new_address_space(CPU_MEMORY.ram[:], 0x0000, 0x07FF,0x1FFF);
    cpu_mem_map[1] = addr.new_address_space(ppu_regs_io, 0x2000, 0x2007,0x3FFF);
    cpu_mem_map[2] = addr.new_address_space(apu_regs_io, 0x4000, 0xFFFF,0x4013);
    cpu_mem_map[3] = addr.new_address_space(ppu_regs_io, 0x4014, 0xFFFF,0x4014);
    cpu_mem_map[4] = addr.new_address_space(apu_regs_io, 0x4015, 0xFFFF,0x4017);
    cpu_mem_map[5] = addr.new_address_space(CPU_MEMORY.apu_io_funcs[:], 0x4018, 0x401F,0x401F);
    cpu_mem_map[6] = addr.new_address_space(CPU_MEMORY.cartridge[:], 0x4020, 0xFFFF,0xFFFF);

    cpu.bus = addr.new_bus(cpu_mem_map[:]);    
    alu.regs.SR = u8(1 << 5); 
    cpu.pu = alu;      
    return &cpu;
}

cpu_write::proc (self: ^CpuInterface, address: u16, data: u8) {
    addr.bus_write(&self.bus, address, data);
}

cpu_read::proc (self: ^CpuInterface, address: u16) -> u8 {
    return addr.bus_read_u8(&self.bus, address);
}

cpu_debug_print::proc (self: ^CpuInterface, address: u16) {
    addr.bus_print_u8(&self.bus, address);
}

cpu_reset::proc (self: ^CpuInterface) {
    alu, ok := self.pu.(^Alu6502); assert(ok);
    lo := u16(cpu_read(self, 0xFFFC));
    hi := u16(cpu_read(self, 0xFFFD));
    alu.regs.PC = (hi << 8) | lo;
    alu.regs.A = 0;
    alu.regs.X = 0;
    alu.regs.Y = 0;
    alu.regs.SP = 0xFF;
    alu.regs.SR = u8(1 << 5);
}

cpu_nmi::proc (self: ^CpuInterface) {
    alu, ok := self.pu.(^Alu6502); assert(ok);
    alu_push_pc(alu, &self.bus);
    alu_clear_flag(alu, .B);
    alu_push(alu, &self.bus, alu.regs.SR);
    alu_set_flag(alu, .I);
    
    lo := u16(cpu_read(self, 0xFFFA));
    hi := u16(cpu_read(self, 0xFFFB));

    isr: Operand = u16((hi << 8) | lo);
    alu_jump(&isr, alu, .JMP, &self.bus);
}

cpu_irq::proc (self: ^CpuInterface) {
    alu, ok := self.pu.(^Alu6502); assert(ok);
    if alu_is_flag_clear(alu, .I) {
        alu_push_pc(alu, &self.bus);
        alu_clear_flag(alu, .B);
        alu_push(alu, &self.bus, alu.regs.SR);
        alu_set_flag(alu, .I);
        
        lo := u16(cpu_read(self, 0xFFFE));
        hi := u16(cpu_read(self, 0xFFFF));

        isr: Operand = u16((hi << 8) | lo);

        alu_jump(&isr, alu, .JMP, &self.bus);
    }
}

cpu_step::proc (self: ^CpuInterface) -> Result {
    result: Result = None{};
    switch u in self.pu {
        case ^Alu6502:
            result = alu_step(u, &self.bus);
        case ^Ppu2C02:
            result = ppu_step(u, &self.bus);
    }
    return result;
}


