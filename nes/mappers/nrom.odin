package mappers

import "core:fmt"

nrom_init_banks_map ::proc(banks: ^BanksMap, segs: ^SegmentInfo) {
    nrom_map_prg_rom(banks, segs);
    nrom_map_chr_rom(banks, segs);
}

@(private)
nrom_read::proc (self: ^Mapper, address: u16) -> u8 {
    data:u8 = 0;
    loc:int = 0;
    switch address {
        case 0x0000..=0x1FFF:
            loc = int(address - 0x0000) + self.banks.chr_bnk[0];
        case 0x8000..=0xBFFF:
            loc = int(address - 0x8000) + self.banks.prg_bnk[0];
        case 0xC000..=0xFFFF:
            loc = int(address - 0xC000) + self.banks.prg_bnk[1];
    }
    data = self.cartridge.buffer[loc];
    return data;
}

@(private)
nrom_write::proc (self: ^Mapper, address: u16, data: u8) {
    loc:int = 0;
    switch address {
        case 0x0000..=0x1FFF:
            if self.cartridge.meta.chr_writeable {
                loc := int(address - 0x0000) + self.banks.chr_bnk[0];
                self.cartridge.buffer[loc] = data;
            }
        case:
            fmt.printfln("nrom_write received an unexpected address\n");
    }
    //self.cartridge.buffer[loc] = data;
}

@(private)
nrom_map_prg_rom ::proc(b: ^BanksMap, seg: ^SegmentInfo){
    if seg.prg_rom_banks > 1 {
        b.prg_bnk[0] = seg.prg_rom_offset;
        b.prg_bnk[1] = seg.prg_rom_offset + 16384;
    }else {
        b.prg_bnk[0] = seg.prg_rom_offset;
        b.prg_bnk[1] = seg.prg_rom_offset;
    }
}

@(private)
nrom_map_chr_rom ::proc(b: ^BanksMap, seg: ^SegmentInfo){
    b.chr_bnk[0] = seg.chr_rom_offset;
    //b.chr_bnk[1] = seg.chr_rom_offset;
}
