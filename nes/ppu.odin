package nes


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
ppu_memory := PPUMemoryBlock{};

@(private)
ppu_mem_map: [12]Addressable;

@(private)
ppu_oam: [256]u8;

@(private)
PPURegisters::struct {
    ctrl: u8,
    mask: u8,
    status: u8,
    oam_addr: u8,
    oam_data: u8,
    scroll: u16,
    addr: u16,
    data: u8,
    oam_dma: u8,
}
Ppu2C02::struct {
    bus: Bus,
    regs: PPURegisters,
}

Ppu2C02_Result::struct{

}

ppu_init::proc (self: ^Ppu2C02) {
    ppu_mem_map[0] = new_address_space(ppu_memory.pattern_tbl0[:], 0x0000, 0xFFFF,0x0FFF);
    ppu_mem_map[1] = new_address_space(ppu_memory.pattern_tbl1[:], 0x1000, 0xFFFF,0x1FFF);
    ppu_mem_map[2] = new_address_space(ppu_memory.name_tbl0[:], 0x2000, 0xFFFF,0x23BF);
    ppu_mem_map[3] = new_address_space(ppu_memory.attrib_tbl0[:], 0x23C0, 0xFFFF,0x23FF);
    ppu_mem_map[4] = new_address_space(ppu_memory.name_tbl1[:], 0x2400, 0xFFFF,0x27BF);
    ppu_mem_map[5] = new_address_space(ppu_memory.attrib_tbl1[:], 0x27C0, 0xFFFF,0x27FF);
    ppu_mem_map[6] = new_address_space(ppu_memory.name_tbl2[:], 0x2800, 0xFFFF,0x2BBF);
    ppu_mem_map[7] = new_address_space(ppu_memory.attrib_tbl2[:], 0x2BC0, 0xFFFF,0x2BFF);
    ppu_mem_map[8] = new_address_space(ppu_memory.name_tbl3[:], 0x2C00, 0xFFFF,0x2FBF);
    ppu_mem_map[9] = new_address_space(ppu_memory.attrib_tbl3[:], 0x2FC0, 0xFFFF,0x2FFF);
    ppu_mem_map[10] = new_address_space(ppu_memory.unused[:], 0x3000, 0xFFFF,0x3EFF);
    ppu_mem_map[11] = new_address_space(ppu_memory.palette_ram[:], 0x3F00, 0x3F1F,0x3FFF);

    self.bus = new_bus(ppu_mem_map[:]);
}

ppu_step::proc (self: ^Ppu2C02, bus: ^Bus) -> Ppu2C02_Result {
    return Ppu2C02_Result{};
}

ppu_regs_read::proc (self: ^Ppu2C02, address: u16) -> u8 {
    switch address {
        case 0x2000:
            return 0xFA;
        case 0x4014:
            return 0xFE;

        case:
            return 0xFD;
    }   
}

@(private)
byte_shift:u8 = 8;

ppu_regs_write::proc (self: ^Ppu2C02, address: u16, data: u8) {
    switch address {
        case 0x2000://ppuctrl
            self.regs.ctrl = data;
        case 0x2001: //ppumask
            self.regs.mask = data;
        case 0x2003: //oam addr
            self.regs.oam_addr = data;
        case 0x2004: //oam data
            self.regs.oam_addr = data;
        case 0x2005: //scroll
            self.regs.scroll |= u16(data) << byte_shift;
            byte_shift = (byte_shift + 8) & 0x8;        
        case 0x2006: //vram address
            self.regs.addr |= u16(data) << byte_shift;
            byte_shift = (byte_shift + 8) & 0x8; 
        case 0x2007: //vram data
            //self.regs.addr |= u16(data) << byte_shift;
            //byte_shift = (byte_shift + 8) & 0x8;       
        case 0x4014:
            self.regs.oam_dma = data;
    }
}