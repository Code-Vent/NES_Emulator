package screen

import cart "./../mappers"

import "core:fmt"

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
palette_ram := [2][4][4]u8{
    //Background Palettes
    {
        {0x0F, 0x31, 0x32, 0x33,},
        {0x0F, 0x35, 0x36, 0x37,},
        {0x0F, 0x39, 0x3A, 0x3B,},
        {0x0F, 0x3D, 0x3E, 0x3F,},
    },
    //Sprite Palettes
    {
        {0x0F, 0x1C, 0x15, 0x14,},
        {0x0F, 0x02, 0x38, 0x3C,},
        {0x0F, 0x1C, 0x15, 0x14,},
        {0x0F, 0x02, 0x38, 0x3C,},
    },
};

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

draw_name_table ::proc(self: ^Ppu2C02) {    
    tbl_addr := get_bckgnd_pattern_tbl_address(self);
    addr := get_name_tbl_address(self);
    src := cart.mapper_direct_access(self.mapper, addr, 1024);
    name_tbl := src[:960];
    attrib_tbl := src[960:];
    attrib_8x8 := [][]u8{
        attrib_tbl[0:8],
        attrib_tbl[8:16],
        attrib_tbl[16:24],
        attrib_tbl[24:32],
        attrib_tbl[32:40],
        attrib_tbl[40:48],
        attrib_tbl[48:56],
        attrib_tbl[56:64],
    };
    attrib_32x32: [32][32]u8;
    k := 0;
    decode_attrib(attrib_8x8[:][:], attrib_32x32[:][:]);
    for i in 0..<30 {
        for j in 0..<32 {
            palette_index := attrib_32x32[i][j];
            tile_no := u16(name_tbl[k]);
            stride_x := u16(j * int(8));
            stride_y := u16(i * int(8));
            draw_pattern_tbl_tile(
                self, 
                tile_no, 
                tbl_addr,  
                stride_x,
                stride_y,
                palette_ram[0][palette_index],
                background[:][:],
                palette_index == 0
            );
            k += 1;
        }
    }
}

decode_attrib ::proc(attrib_8x8:[][]u8, attrib_32x32: [][32]u8) {
    for i in 0..<8 {
        for j in 0..<8 {            
            attrib := attrib_8x8[i][j];
            top_left := (attrib >> 0) & 0x03;
            top_right := (attrib >> 2) & 0x03;
            bottom_left := (attrib >> 4) & 0x03;
            bottom_right := (attrib >> 6) & 0x03;
            x := 4 * j;
            y := 4 * i;
            for m in 0..<4 {
                for n in 0..<4 {
                    if m < 2 && n < 2 {
                        //top left
                        attrib_32x32[y + m][x + n] = top_left;
                    }else if m < 2 && n > 1 {
                        //top right
                        attrib_32x32[y + m][x + n] = top_right;
                    }else if m > 1 && n < 2 {
                        //bottom left
                        attrib_32x32[y + m][x + n] = bottom_left;
                    }else{
                        //bottom right
                        attrib_32x32[y + m][x + n] = bottom_right;
                    }
                }
            }
        }
    }
}

Sprite ::struct {
    x_pos: u16,
    y_pos: u16, 
    attrib: u8,
    data: []u8,
};

draw_oam_sprites ::proc(self: ^Ppu2C02) {
    len := get_sprite_size();
    offset:u16 = 0;
    s:Sprite;
    for i in 0..<16 {
        object := ppu_oam[offset:offset+len];
        s.y_pos = u16(object[0]);
        index := object[1];
        s.attrib = object[2];
        s.x_pos = u16(object[3]);
        addr := get_sprite_pattern_tbl_address(self, &index); 
        s.data = cart.mapper_direct_access(self.mapper, addr + u16(index), len);
        draw_sprite(&s, i==0);
        offset += len;
    }          
}

draw_sprite ::proc(sprite: ^Sprite, check_hit_0: bool) {
    tile:[8][8]u8;
    palette_index := 0x03 & sprite.attrib;
    behind_background := (sprite.attrib & 0x20) >> 5;
    switch len(sprite.data) {
        case 32:
            //top sprite
            plane0 := sprite.data[0:8];
            plane1 := sprite.data[8:16];
            decode_tile_row(
                plane0, plane1,
                tile[:][:],
                palette_ram[1][palette_index],
                false,
                nil
            );
            apply_flip(tile[:][:], sprite.attrib);
            draw_tile(
                sprite.x_pos, sprite.y_pos,
                tile[:][:],
                0,0,
                foreground[:][:],
                behind_background == 1,
                nil
            );
            fallthrough;
        case 16:
            //bottom sprite
            plane0 := sprite.data[16:24];
            plane1 := sprite.data[24:32];
            decode_tile_row(
                plane0, plane1,
                tile[:][:],
                palette_ram[1][palette_index],
                false,
                nil
            );
            apply_flip(tile[:][:], sprite.attrib);
            draw_tile(
                sprite.x_pos, sprite.y_pos,
                tile[:][:],
                0,8,
                foreground[:][:],
                behind_background == 1,
                nil
            );
        case:
            fmt.printf("Invalid sprite size!\n");
    }
}

apply_flip ::proc(tile: [][8]u8, attrib: u8) {
    flip_hor := attrib & 0x40 != 0;
    flip_vert := attrib & 0x80 != 0;
        
    if flip_hor {
        flip_horizontal(tile[:][:]);
    }

    if flip_vert {
        flip_vertical(tile[:][:]);
    }
}

flip_horizontal ::proc(tile: [][8]u8){

}

flip_vertical ::proc(tile: [][8]u8){

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

get_sprite_pattern_tbl_address ::proc(self: ^Ppu2C02, index: ^u8) -> u16 {
    sel:u8 = 0;
    if get_sprite_size() == 16 {
        sel = (ppu_regs.ctrl & 0x08) >> 3;
    }else{
        sel = 0x0001 & index^;
        index^ &= 0xFE;
    }    
    return pattern_tbl_base[sel];
}

get_sprite_size ::proc() -> u16 {
    return (ppu_regs.ctrl & 0x20 == 0)? 16: 32;
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