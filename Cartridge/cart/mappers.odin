package cart

MapperOp ::enum{
    INIT,
    WRITE,
    READ,
    DEINIT,
}

MapperBanks ::struct{
    chr: []int,
    prg: []int,
}

SupportedMappers ::struct{
    nrom :MapperBanks,
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
        case .DEINIT:
            delete(nrom_banks.chr);
            delete(nrom_banks.prg);
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

    }
    return ok;
}