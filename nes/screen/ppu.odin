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

PPUSTATUS ::enum{
    HorizontalScrolling, //Unused on the NES
    VerticalScrolling, //Unused on the NES
    Unused2,
    Unused3,
    Unused4,
    SpriteOverflow,
    Sprite0Hit,
    VBlank
}

PPUStatus ::distinct bit_set[PPUSTATUS; u8];

PPUCTRL ::enum{
    NametableX,
    NametableY,
    VRAMIncrement,
    SpritePattern,
    BackgroundPattern,
    SpriteSize,
    MasterSlave,
    GenerateNMI,
}

PPUControl ::distinct bit_set[PPUCTRL; u8];

PPUMASK ::enum{
    GreyScale,
    LeftmostBackground,
    LeftmostSprite,
    BackgroundRendering,
    SpriteRendering,
    EmphasizeRed,
    EmphasizeGreen,
    EmphasizeBlue,
}

PPUMask ::distinct bit_set[PPUMASK; u8];

@(private)
PPURegisters :: struct {
    ctrl: PPUControl,
    mask: PPUMask,
    status: PPUStatus,
    oam_addr: u8,
    scroll: u16,
    addr: u16,
    read_buffer: u8,
    oam_dma: u8,
    write_toggle: u8
}

ppu_regs: PPURegisters = PPURegisters{
    write_toggle = 1
};

Ppu2C02 ::struct {
    mapper: ^cart.Mapper,
    events: bit_set[Ppu2C02_Events],
}

Ppu2C02_Events ::enum{
    HIT0_DETECTED,
    SCROLL_UPDATED,
    END_OF_TABLE0,
    END_OF_OAM,
}

Ppu2C02_Exception ::enum{
    DMA_PENDING,
    NMI_PENDING,
    NONE,
}

new_ppu ::proc(m: ^cart.Mapper) -> Ppu2C02 {    
    return Ppu2C02{
        mapper = m,
    };
}

ppu_reset ::proc(self: ^Ppu2C02) {
    if self.mapper.cartridge.meta.mirroring == .HORIZONTAL {
        ppu_regs.status = {.VerticalScrolling};
    }else if self.mapper.cartridge.meta.mirroring == .VERTICAL {
        ppu_regs.status = {.HorizontalScrolling};
    }else if self.mapper.cartridge.meta.mirroring == .FOUR_SCREEN {
        ppu_regs.status = {.HorizontalScrolling, .VerticalScrolling};
    }else{

    }
}

ppu_step ::proc(self: ^Ppu2C02) -> Ppu2C02_Exception{
    
    draw_name_table(self, name_tbl_base[0]);
    //draw_oam_sprites(self);
    //frame_render();
    ppu_regs.status += {.VBlank};

    //if sprite0hit_region.x0 < 256 && sprite0hit_region.y0 < 240 {
    //    self.events += {.HIT0_DETECTED};
    //    ppu_regs.status += {.Sprite0Hit};
    //}

    if .GenerateNMI in ppu_regs.ctrl {
        //self.events += {.END_OF_TABLE0};
        return Ppu2C02_Exception.NMI_PENDING;
    }

    return Ppu2C02_Exception{};
}

ppu_regs_read ::proc(self: ^Ppu2C02, address: u16) -> u8 {
    data:u8 = 0xCC;
    switch address {
        case 0x2002:
            ppu_regs.write_toggle = 1;
            data = transmute(u8)ppu_regs.status;
            //data &= 0xE0;
            ppu_regs.status -= {.VBlank};
        case 0x2004:
            data = ppu_oam[ppu_regs.oam_addr];
        case 0x2007:
            data = ppu_regs.read_buffer;
            ppu_regs.read_buffer = cart.mapper_vram_read(self.mapper, ppu_regs.addr);
            ppu_regs.addr += get_vram_address_inc();
        case:
            //assert(false);
    }  
    return data; 
}

ppu_regs_write ::proc(self: ^Ppu2C02, address: u16, data: u8) -> Ppu2C02_Exception{
    ex := Ppu2C02_Exception.NONE;

    switch address {
        case 0x2000://ppuctrl
            ppu_regs.ctrl = transmute(PPUControl)data;
        case 0x2001: //ppumask
            ppu_regs.mask = transmute(PPUMask)data;;
        case 0x2003: //oam addr
            ppu_regs.oam_addr = data;
        case 0x2004: //oam data
            ppu_oam[ppu_regs.oam_addr] = data;
            ppu_regs.oam_addr += 1;
        case 0x2005: //scroll
            ppu_regs.scroll |= u16(data) << (ppu_regs.write_toggle << 3);
            ppu_regs.write_toggle ~= 0x01;   
            if ppu_regs.write_toggle == 1 {
                self.events += {.SCROLL_UPDATED};
            }     
        case 0x2006: //vram address
            ppu_regs.addr |= u16(data) << (ppu_regs.write_toggle << 3);
            ppu_regs.write_toggle ~= 0x01;   
        case 0x2007: //vram data
            if cart.mapper_vram_write(self.mapper, ppu_regs.addr, data){
                self.events += {.END_OF_TABLE0};
                assert(false);
            } 
            ppu_regs.addr += get_vram_address_inc();
        case 0x4014:
            ppu_regs.oam_dma = data;
            ex = .DMA_PENDING;
        case:
            assert(false);
    }
    return ex;
}

draw_name_table ::proc(self: ^Ppu2C02, addr: u16) {    
    tbl_addr := get_bckgnd_pattern_tbl_address(self);
    src := cart.mapper_direct_access(self.mapper, addr, 1024);
    name_tbl := src[:attrib_tbl_offset];
    attrib_tbl := src[attrib_tbl_offset:];
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
    index := 0;
    sel := transmute(u8)ppu_regs.ctrl & 0x03; 
    decode_attrib(attrib_8x8[:][:], attrib_32x32[:][:]);
    for i in 0..<30 {
        for j in 0..<32 {
            palette_index := attrib_32x32[i][j];
            tile_no := name_tbl[index];
            frame_draw_pattern_tbl_tile(
                self, 
                tile_no, 
                u8(j), u8(i),
                0, 0,
                tbl_addr,  
                palette_ram[0][palette_index],
                background[sel][:][:],
                palette_index == 0
            );
            index += 1;
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
    coarse_x: u8,
    coarse_y: u8, 
    fine_x: u8,
    fine_y: u8, 
    attrib: u8,
    data: []u8,
};

draw_oam_sprites ::proc(self: ^Ppu2C02) {
    len := u16(get_sprite_size());
    offset:u16 = 0;
    s:Sprite;
    for i in 0..<16 {
        object := ppu_oam[offset:offset+len];
        s.coarse_y = object[0];
        index := object[1];
        s.attrib = object[2];
        s.coarse_x = object[3];
        addr := get_sprite_pattern_tbl_address(self, &index); 
        s.data = cart.mapper_direct_access(self.mapper, addr + u16(index), u16(len));
        draw_sprite(&s);
        if i == 0 {
            sprite0hit_region.x0 = s.coarse_x * 8;
            sprite0hit_region.y0 = (s.coarse_y * 8) + 1;
            sprite0hit_region.x1 = sprite0hit_region.x0 + 8;
            sprite0hit_region.y1 = sprite0hit_region.y0 + u8(len >> 1);
        }
        offset += len;
    }          
}

draw_sprite ::proc(sprite: ^Sprite) {
    tile:[8][8]u8;
    palette_index := 0x03 & sprite.attrib;
    behind_background := (sprite.attrib & 0x20) >> 5;
    plane0 := sprite.data[0:8];
    plane1 := sprite.data[8:16];
    frame_decode_tile_row(
        plane0, plane1,
        tile[:][:],
        palette_ram[1][palette_index],
        false,
        nil
    );
    apply_flip(tile[:][:], sprite.attrib);
    frame_draw_tile(
        sprite.coarse_x, sprite.coarse_y,
        0, 1,
        tile[:][:],
        foreground[:][:],
        behind_background == 1,
        nil
    );
    
    if len(sprite.data) == 32 {
            //bottom sprite
        plane0 := sprite.data[16:24];
        plane1 := sprite.data[24:32];
        frame_decode_tile_row(
            plane0, plane1,
            tile[:][:],
            palette_ram[1][palette_index],
            false,
            nil
        );
        apply_flip(tile[:][:], sprite.attrib);
        frame_draw_tile(
            sprite.coarse_x, sprite.coarse_y + 1,
            0, 1,
            tile[:][:],
            foreground[:][:],
            behind_background == 1,
            nil
        );
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
    if .VRAMIncrement in ppu_regs.ctrl {
        inc = 1;     
    }else{
        inc = 32;     
    }
    return u16(inc);
}


get_name_tbl_address ::proc(self: ^Ppu2C02) -> u16 {
    sel := transmute(u8)ppu_regs.ctrl & 0x03;
    return name_tbl_base[sel];
}

get_sprite_pattern_tbl_address ::proc(self: ^Ppu2C02, index: ^u8) -> u16 {
    sel:u8 = 0;
    if get_sprite_size() == 16 {
        sel = (transmute(u8)ppu_regs.ctrl & 0x08) >> 3;
    }else{
        sel = 0x0001 & index^;
        index^ &= 0xFE;
    }    
    return pattern_tbl_base[sel];
}

get_sprite_size ::proc() -> u8 {
    return (transmute(u8)ppu_regs.ctrl & 0x20 == 0)? 16: 32;
}

get_bckgnd_pattern_tbl_address ::proc(self: ^Ppu2C02) -> u16 {
    sel := u8(transmute(u8)ppu_regs.ctrl & 0x08) >> 3
    return pattern_tbl_base[sel];
}