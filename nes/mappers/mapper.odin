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
    buf := make([]u8, 4 * 1024);//4KB
    vram := VRam{};
    switch meta.mirroring {
        case .HORIZONTAL:
        case .VERTICAL:
        case .FOUR_SCREEN:
        case .SINGLE_SCREEN:

    }
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
    delete_cartridge(&self.cartridge)
}