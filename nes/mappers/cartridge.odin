package mappers

import "core:os"
import "core:mem"
import "core:fmt"

iNESHeader ::struct{
    name:[4]u8,
    prg_rom_banks:u8,
    chr_rom_banks:u8,
    mapper1:u8,
    mapper2:u8,
    prg_ram_size:u8,
    tv_system1:u8,
    tv_system2:u8,
    unused:[5]u8
}

Mirroring ::enum{
    HORIZONTAL,
    VERTICAL,
    FOUR_SCREEN,
    SINGLE_SCREEN,
}

SegmentInfo ::struct {
    prg_rom_offset:int,
    chr_rom_offset:int,
    prg_rom_banks:u8,
    chr_rom_banks:u8,
}

MetaData ::struct {
    mapper_id: int,
    mirroring: Mirroring,
    has_battery: bool,
    has_trainer: bool,
    chr_writeable: bool,
}

Cartridge ::struct {
    seg_info: SegmentInfo,
    meta: MetaData,
    buffer: []u8,
}

iNES_MAGIC ::[4]u8{'N','E','S',0x1A};


@(private)
new_cartridge ::proc(filename: string) -> (cart: Cartridge, success: bool) {
    
    content, ok := os.read_entire_file(filename); assert(ok);
    defer delete(content);
    assert(len(content) > 16);

    header := (^iNESHeader)(raw_data(content))^;
    assert(header.name == iNES_MAGIC);
    extract_meta_data(&header, &cart.meta);
    required_len, data_len := validate(&header, content[16:], 
        cart.meta.has_trainer, &cart.seg_info);
    assert(required_len == data_len);
    if header.chr_rom_banks == 0 {
        required_len += 8192;
    }

    buffer := make([]u8, required_len);
    copy(buffer[:], content[16:]);

    if header.chr_rom_banks == 0 {
        a := cart.seg_info.chr_rom_offset;
        mem.set(raw_data(buffer[a:]), 0, 8192);
    }
    
    cart.buffer = buffer[:];
    return cart, true;
}

validate ::proc(
    header: ^iNESHeader, 
    data: []byte, 
    has_trainer: bool, 
    seg: ^SegmentInfo
) -> (int, int) {
    required_len := 0;
    if has_trainer {
        required_len += 512;
    }
    seg.prg_rom_offset = required_len;
    required_len += int(header.prg_rom_banks) * 16384;
    seg.prg_rom_banks = header.prg_rom_banks;
    if header.chr_rom_banks != 0 {
        seg.chr_rom_offset = required_len;
        required_len += int(header.chr_rom_banks) * 8192;
        seg.chr_rom_banks = header.chr_rom_banks;
    }else{
        seg.chr_rom_offset = required_len;
    }
    return required_len, len(data);
}

extract_meta_data ::proc(
    header: ^iNESHeader,
    meta: ^MetaData
){
    meta.mapper_id = int((header.mapper2 & 0xF0) | (header.mapper1 >> 4));
    meta.has_battery = (header.mapper1 & 0x02) != 0;
    meta.has_trainer = (header.mapper1 & 0x04) != 0;
    meta.chr_writeable = header.chr_rom_banks == 0;
    mirroring := (header.mapper1 & 0x01) | ((header.mapper1 & 0x08) >> 2);
    switch mirroring {
        case 0:
            meta.mirroring = .HORIZONTAL;
        case 1:
            meta.mirroring = .VERTICAL;
        case 2,3:
            meta.mirroring = .FOUR_SCREEN;
    }
}

@(private)
delete_cartridge ::proc(self: ^Cartridge){
    delete(self.buffer);
}

