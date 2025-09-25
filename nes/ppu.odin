package nes

import cart "mappers"


pattern_tbl_base := [2]u16{
    0x0000,
    0x1000,
} 

name_tbl_base := [4]u16{
    0x2000,
    0x2400,
    0x2800,
    0x2C00,
}

attrib_tbl_offset::u16(0x03C0);

palette_address_mask ::u16(0x3F1F);

@(private)
palette_ram : [0x0020]u8;

@(private)
ppu_oam: [256]u8;

@(private)
PPURegisters :: struct {
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

@(private)
ppu_regs: PPURegisters = PPURegisters{};

Ppu2C02 ::struct {
    mapper: ^cart.Mapper,
    state: Ppu2C02_State,
}

Ppu2C02_State ::enum{
    DMA_PENDING,
    NMI_PENDING,
}

new_ppu ::proc(m: ^cart.Mapper) -> Ppu2C02 {    
    return Ppu2C02{
        mapper = m,
    };
}

ppu_step ::proc(self: ^Ppu2C02) {
}

ppu_regs_read ::proc(self: ^Ppu2C02, address: u16) -> u8 {
    data:u8 = 0xCC;
    switch address {
        case 0x2002:
            byte_shift = 8;
            data = ppu_regs.status & 0xE0;
            clear_vblank_flag();
        case 0x2004:
            data = ppu_oam[ppu_regs.oam_addr];
        case 0x2007:
            data = cart.mapper_vram_read(self.mapper, ppu_regs.addr);
        case:
            //assert(false);
    }  
    return data; 
}

@(private)
byte_shift:u8 = 8;

ppu_regs_write ::proc(self: ^Ppu2C02, address: u16, data: u8) {
    switch address {
        case 0x2000://ppuctrl
            ppu_regs.ctrl = data;
        case 0x2001: //ppumask
            ppu_regs.mask = data;
        case 0x2003: //oam addr
            ppu_regs.oam_addr = data;
        case 0x2004: //oam data
            ppu_oam[ppu_regs.oam_addr] = data;
            ppu_regs.oam_addr += 1;
        case 0x2005: //scroll
            ppu_regs.scroll |= u16(data) << byte_shift;
            byte_shift = (byte_shift + 8) & 0x8;        
        case 0x2006: //vram address
            ppu_regs.addr |= u16(data) << byte_shift;
            byte_shift = (byte_shift + 8) & 0x8; 
        case 0x2007: //vram data
            cart.mapper_vram_write(self.mapper, ppu_regs.addr, data); 
            ppu_regs.addr += get_vram_address_inc();
        case 0x4014:
            ppu_regs.oam_dma = data;
            self.state = .DMA_PENDING;
        case:
            assert(false);
    }
}

ppu_dma ::proc(self: ^Ppu2C02, bus: ^Bus){
    src := u16(ppu_regs.oam_dma) << 8;
    for i in 0..<256 {
        ppu_oam[i] = bus_read_u8(bus, src);
        src += 1;        
    }
}

get_vram_address_inc ::proc() -> u16{
    inc := 0;
    if ppu_regs.ctrl & 0x04 == 0{
        inc = 1;     
    }else{
        inc = 32;     
    }
    return u16(inc);
}

is_nmi_enabled ::proc() -> bool {
    return ppu_regs.ctrl & 0x80 != 0;
}

get_name_tbl_address ::proc(self: ^Ppu2C02) -> u16 {
    sel := ppu_regs.ctrl & 0x03;
    return name_tbl_base[sel];
}

get_sprite_pattern_tbl_address ::proc(self: ^Ppu2C02) -> u16 {
    sel:u8 = 0;
    if sprite_size() == 8 {
        sel = (ppu_regs.ctrl & 0x08) >> 3;
    }
    return pattern_tbl_base[sel];
}

sprite_size ::proc() -> u8 {
    return (ppu_regs.ctrl & 0x20 == 0)? 8: 16;
}

get_bckgnd_pattern_tbl_address ::proc(self: ^Ppu2C02) -> u16 {
    sel := u8(ppu_regs.ctrl & 0x08) >> 3
    return pattern_tbl_base[sel];
}

is_background_enabled ::proc() -> bool {
    return ppu_regs.mask & 0x08 != 0;
}

is_sprite_enabled ::proc() -> bool {
    return ppu_regs.mask & 0x10 != 0;
}

get_greyscale ::proc() -> u8 {
    return ppu_regs.mask & 0x01;
}

is_show_leftmost_bkgnd ::proc() -> bool {
    return ppu_regs.mask & 0x02 != 0;
}

is_show_leftmost_sprites ::proc() -> bool {
    return ppu_regs.mask & 0x04 != 0;
}

is_emphasize_red ::proc() -> bool {
    return ppu_regs.mask & 0x20 != 0;
}

is_emphasize_green ::proc() -> bool {
    return ppu_regs.mask & 0x40 != 0;
}

is_emphasize_blue ::proc() -> bool {
    return ppu_regs.mask & 0x80 != 0;
}

set_overfow_flag ::proc() {
    ppu_regs.status |= 0x20;
}

set_0_hit_flag::proc() {
    ppu_regs.status |= 0x40;
}

set_vblank_flag ::proc() {
    ppu_regs.status |= 0x80;
}

clear_overfow_flag ::proc() {
    ppu_regs.status &= ~u8(0x20);
}

clear_0_hit_flag ::proc() {
    ppu_regs.status &= ~u8(0x40);
}

clear_vblank_flag ::proc() {
    ppu_regs.status &= ~u8(0x80);
}