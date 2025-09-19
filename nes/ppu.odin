package nes
import addr "address"

@(private)
PPUMemoryBlock::struct {
    pattern_tbl0: [0x1000]u8,
    pattern_tbl1: [0x1000]u8,
    name_tbl0   : [0x03C0]u8,
    attrib_tbl0 : [0x0040]u8,
    name_tbl1   : [0x03C0]u8,
    attrib_tbl1 : [0x0040]u8,
    name_tbl2   : [0x03C0]u8,
    attrib_tbl2 : [0x0040]u8,
    name_tbl3   : [0x03C0]u8,
    attrib_tbl3 : [0x0040]u8,
    unused      : [0x0F00]u8,
    palette_ram : [0x0020]u8,
}

@(private)
PPU_MEMORY := PPUMemoryBlock{};

@(private)
ppu_mem_map: [12]addr.Addressable;

@(private)
ppu_oam: [256]u8;
Ppu2C02::struct {
    bus: addr.Bus,
}

Ppu2C02_Result::struct{

}

ppu_init::proc (self: ^Ppu2C02) {
    ppu_mem_map[0] = addr.new_address_space(PPU_MEMORY.pattern_tbl0[:], 0x0000, 0x07FF,0);
    ppu_mem_map[1] = addr.new_address_space(PPU_MEMORY.pattern_tbl1[:], 0x2000, 0x2007,0);
    ppu_mem_map[2] = addr.new_address_space(PPU_MEMORY.name_tbl0[:], 0x4000, 0x4017,0);
    ppu_mem_map[3] = addr.new_address_space(PPU_MEMORY.attrib_tbl0[:], 0x4018, 0x401F,0);
    ppu_mem_map[4] = addr.new_address_space(PPU_MEMORY.name_tbl1[:], 0x4020, 0xFFFF,0);
    ppu_mem_map[5] = addr.new_address_space(PPU_MEMORY.attrib_tbl1[:], 0x4020, 0xFFFF,0);
    ppu_mem_map[6] = addr.new_address_space(PPU_MEMORY.name_tbl2[:], 0x4020, 0xFFFF,0);
    ppu_mem_map[7] = addr.new_address_space(PPU_MEMORY.attrib_tbl2[:], 0x4020, 0xFFFF,0);
    ppu_mem_map[8] = addr.new_address_space(PPU_MEMORY.name_tbl3[:], 0x4020, 0xFFFF,0);
    ppu_mem_map[9] = addr.new_address_space(PPU_MEMORY.attrib_tbl3[:], 0x4020, 0xFFFF,0);
    ppu_mem_map[10] = addr.new_address_space(PPU_MEMORY.unused[:], 0x4020, 0xFFFF,0);
    //ppu_mem_map[11] = addr.new_address_space(PPU_MEMORY.palette_ram[:], 0x4020, 0xFFFF,0);

    self.bus = addr.new_bus(ppu_mem_map[:]);
}

ppu_step::proc (self: ^Ppu2C02, bus: ^addr.Bus) -> Ppu2C02_Result {
    return Ppu2C02_Result{};
}

ppu_regs_io::proc (address: u16, data: u8) -> u8 {
    switch address {
        case 0x2000:
            return 0xFA;
        case 0x4014:
            return 0xFE;
        case:
            return 0xFD;
    }   
}