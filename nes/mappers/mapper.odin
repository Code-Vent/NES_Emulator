package mappers

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
            vram.name_tbl1_offset = 0;
            vram.name_tbl2_offset = 1024;
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

mapper_write::proc (self: ^Mapper, address: u16, data: u8) {
    switch self.type {
        case .NROM:
            nrom_write(self, address, data);
        case .UNKNOWN:
    }
}

mapper_vram_read::proc (self: ^Mapper, address: u16) -> u8 {
    data:u8;
    
    return data;
}

mapper_vram_write::proc (self: ^Mapper, address: u16, data: u8) {
    
}

delete_mapper ::proc(self: ^Mapper){
    delete(self.cartridge.buffer);
    delete(self.vram.buffer);
}