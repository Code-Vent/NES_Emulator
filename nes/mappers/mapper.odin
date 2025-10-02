package mappers

import "core:fmt"

MapperType ::enum {
    NROM,
    UNKNOWN,
}

BanksMap ::struct {
    prg_bnk: [32]int,
    chr_bnk: [32]int,
}

VRam :: struct {
    name_tbl0_offset: u16,
    name_tbl1_offset: u16,
    name_tbl2_offset: u16,
    name_tbl3_offset: u16,
    buffer: []u8,
}

Mapper ::struct {
    cartridge: Cartridge,
    banks: BanksMap,
    type: MapperType,
    state: Mapper_State,
    vram: VRam,
}

Mapper_State ::enum{
}

new_mapper::proc ( 
    filename: string
) -> (mapper: Mapper, success: bool){
    cart, ok := new_cartridge(filename);
    ty := mapper_get_type(cart.meta.mapper_id);
    b := BanksMap{}
    switch ty {
        case .NROM:
            nrom_init_banks_map(&b, &cart.seg_info);
        case .UNKNOWN:
    }

    v := mapper_alloc_vram(&cart.meta)
    
    return Mapper{
        cartridge = cart,
        banks = b,
        type = ty,
        state = Mapper_State{},
        vram = v,
    }, ok;
}

@(private)
mapper_alloc_vram ::proc(meta: ^MetaData) -> VRam {
    buf:[]u8;
    vram := VRam{};
    switch meta.mirroring {
        case .HORIZONTAL:
            vram.name_tbl0_offset = 0;
            vram.name_tbl2_offset = 0;
            vram.name_tbl1_offset = 1024;
            vram.name_tbl3_offset = 1024;
            buf = make([]u8, 2 * 1024);//2KB
        case .VERTICAL:
            vram.name_tbl0_offset = 0;
            vram.name_tbl1_offset = 1024;
            vram.name_tbl2_offset = 0;
            vram.name_tbl3_offset = 1024;
            buf = make([]u8, 2 * 1024);//2KB
        case .FOUR_SCREEN:
            vram.name_tbl0_offset = 0;
            vram.name_tbl1_offset = 1024;
            vram.name_tbl2_offset = 2 * 1024;
            vram.name_tbl3_offset = 3 * 1024;
            buf = make([]u8, 4 * 1024);//4KB
        case .SINGLE_SCREEN:
            vram.name_tbl0_offset = 0;
            vram.name_tbl1_offset = 0;
            vram.name_tbl2_offset = 0;
            vram.name_tbl3_offset = 0;
            buf = make([]u8, 1024);//1KB
    }
    vram.buffer = buf[:];
    return vram;
}

@(private)
mapper_get_type ::proc(id: int) -> MapperType {
    type:MapperType = .UNKNOWN;
    switch id {
        case 0:
            type = .NROM;
        case:
    }
    return type;
}

mapper_step::proc (self: ^Mapper) {
}

mapper_read::proc (self: ^Mapper, address: u16) -> u8 {
    data:u8;
    switch self.type {
        case .NROM:
            data = nrom_read(self, address);
        case .UNKNOWN:
    }
    return data;
}

mapper_direct_access ::proc(self: ^Mapper, address: u16, len: u16) -> []u8 {
    loc:int = 0;
    data:[]u8;
    switch address {
        case 0x0000..=0x1FFF:
            loc = int(address - 0x0000) + self.banks.chr_bnk[0];
            data = self.cartridge.buffer[loc:];
        case 0x2000..=0x23BF:
            data = self.vram.buffer[self.vram.name_tbl0_offset:];
        case 0x2400..=0x27BF:
            data = self.vram.buffer[self.vram.name_tbl1_offset:];
        case 0x2800..=0x2BBF:
            data = self.vram.buffer[self.vram.name_tbl2_offset:];
        case 0x2C00..=0x2FBF:
            data = self.vram.buffer[self.vram.name_tbl3_offset:];
        case:
            fmt.printfln("Invalid Mapper address");
    }
    return data[:len];
}

mapper_write::proc (self: ^Mapper, address: u16, data: u8) {
    switch self.type {
        case .NROM:
            nrom_write(self, address, data);
        case .UNKNOWN:
    }
}

mapper_vram_read::proc (self: ^Mapper, address: u16) -> u8 {
    data:u8;
    loc:u16 = 0;
    switch address {
        case 0x2000..=0x23BF:
            loc = (address - 0x2000) + self.vram.name_tbl0_offset;
        case 0x2400..=0x27BF:
            loc = (address - 0x2400) + self.vram.name_tbl1_offset;
        case 0x2800..=0x2BBF:
            loc = (address - 0x2800) + self.vram.name_tbl2_offset;
        case 0x2C00..=0x2FBF:
            loc = (address - 0x2C00) + self.vram.name_tbl3_offset;
        case:
            fmt.printfln("Invalid Mapper address");
    }
    return self.vram.buffer[loc];
}

mapper_vram_write::proc (self: ^Mapper, address: u16, data: u8) {
    loc:u16 = 0;
    switch address {
        case 0x2000..=0x23BF:
            loc = (address - 0x2000) + self.vram.name_tbl0_offset;
        case 0x2400..=0x27BF:
            loc = (address - 0x2400) + self.vram.name_tbl1_offset;
        case 0x2800..=0x2BBF:
            loc = (address - 0x2800) + self.vram.name_tbl2_offset;
        case 0x2C00..=0x2FBF:
            loc = (address - 0x2C00) + self.vram.name_tbl3_offset;
        case:
            fmt.printfln("Invalid Mapper address");
    }
    self.vram.buffer[loc] = data;
}

delete_mapper ::proc(self: ^Mapper){
    delete(self.cartridge.buffer);
    delete(self.vram.buffer);
}