package cart


MapperOp ::enum{
    INIT,
    VRAM_ADDR,
    WRITE,
    READ,
    DEINIT,
}

MapperBanks ::struct{
    chr :[]int,
    prg :[]int,
    mirroring :Mirroring,
}

@(private)
nrom_banks := MapperBanks{};

get_mapper ::proc(c: ^Cartridge) -> Mapper{
    switch c.meta.mapper_id {
        case 0:
            nrom_mapper(c, 0, .INIT);
            return nrom_mapper;
        case:
    }
    return nil;
}

vertical_mirroring ::proc(address: u16) -> u16 {
    return address & 0x07FF;
}

horizontal_mirroring ::proc(address: u16) -> u16 {
    if (address >= 0x2000 && address <=0x23FF) || 
       (address >= 0x2400 && address <=0x27FF) {
        return (address & 0x03FF);
    }
    
    if (address >= 0x2800 && address <=0x2BFF) {
        return 0x400 + (address & 0x07FF);
    } 
    
    if (address >= 0x2C00 && address <=0x2FFF) {
        return (address & 0x07FF);
    }
    return 0xCCCC;
}

single_screen ::proc(address: u16) -> u16 {
    return address & 0x03FF;
}

four_screen ::proc(address: u16) -> u16 {
    if (address >= 0x2000 && address <=0x23FF) {
        return 0x0000;
    }

    if (address >= 0x2400 && address <=0x27FF) {
        return 0x0400;
    }
    
    if (address >= 0x2800 && address <=0x2BFF) {
        return 0x0800;
    }

    if (address >= 0x2C00 && address <=0x2FFF) {
        return 0x0C00;
    }
    return 0xCCCC;
}

nrom_mapper ::proc(c: ^Cartridge, address: u16, op: MapperOp) -> (ok:bool){
    switch op {
        case .INIT:
            nrom_banks.chr = make([]int, c.seg_info.chr_rom_banks);
            nrom_banks.prg = make([]int, 2);
            base0 := c.seg_info.prg_rom_offset;
            base1 := c.seg_info.prg_rom_offset + 16384;
            nrom_banks.chr[0] = c.seg_info.chr_rom_offset;
            nrom_banks.prg[0] = base0;
            if c.seg_info.prg_rom_banks > 1 {
                nrom_banks.prg[1] = base1;
            }else {
                nrom_banks.prg[1] = base0;
            }  
            nrom_banks.mirroring = c.meta.mirroring;         
        case .DEINIT:
            if nrom_banks.chr != nil {
                delete(nrom_banks.chr);
            }
            if nrom_banks.prg != nil {
                delete(nrom_banks.prg);
            }
        case .READ:
            ok = true;
            fallthrough;
        case .WRITE:
            if address >= 0x0000 && address <=0x1FFF {
                //CHR Space
                c.address = nrom_banks.chr[0] + int(address);
                ok = c.meta.chr_writeable;
                break;
            }else if address >= 0x8000 && address <=0xBFFF {
                //CHR Space
                c.address = nrom_banks.prg[0] + int(address - 0x8000);
            }else if address >= 0xC000 && address <=0xFFFF {
                //PRG Space
                c.address = nrom_banks.prg[1] + int(address - 0xC000);
            }
        case .VRAM_ADDR:
            switch nrom_banks.mirroring {
                case .HORIZONTAL:
                    c.address = int(horizontal_mirroring(address));
                case .VERTICAL:
                    c.address = int(vertical_mirroring(address));
                case .FOUR_SCREEN:
                    c.address = int(four_screen(address));
                case .SINGLE_SCREEN:
                    c.address = int(single_screen(address));
            }
            ok = true;
    }
    return ok;
}