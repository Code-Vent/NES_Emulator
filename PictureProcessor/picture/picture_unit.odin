package picture

import "core:fmt"
import "core:mem"
import "../../PixelUnit/pixel"
import "../../Cartridge/cart"

spriteOverflowMask :u8:(1<<5); 
sprite0HitMask     :u8:(1<<6);
vBlankMask         :u8:(1<<7);
PPU ::struct{
    pixel_unit          :pixel.Pixel8,
    oam_data            :[256]u8, 
    nametables          :[]u8,
    //patterntable        :[1024]u8,
    palette             :[32]u8,
    read_buffer         :[2]u8,
    status              :[1]u8,
    oam_addr            :u8,
    vram_inc            :u8,
    sprite_size         :u8,
    x                   :u8,
    v                   :u16,
    t                   :u16,
    w                   :u8,
    nametable_addr      :u16,
    bckgnd_pattern_addr :u16,
    sprite_pattern_addr :u16,   
    cartridge           :^cart.Cartridge,
    nmi_enabled         :bool,
    dma_callback        :proc(addr: u16, nbytes: int)->[]u8,
    nmi_callback        :proc(),
}

new_ppu ::proc(c: ^cart.Cartridge) -> PPU {
    ppu := PPU{};
    c.mapper(c, 0x2C00, .VRAM_ADDR);
    if c.address == 0x0C00 {
        //fmt.println("FOUR SCREEN");
        ppu.nametables = make([]u8, 4 * 1024);
    }else if c.address == 0x0400 {
        //fmt.println("HORIZONTAL OR VERTICAL MIRRORING");
        ppu.nametables = make([]u8, 2 * 1024);
    }else{
        //fmt.println("SINGLE SCREEN");
        ppu.nametables = make([]u8, 1 * 1024);
    }
    ppu.cartridge = c;
    return ppu;
}

delete_ppu ::proc(ppu: ^PPU) {
    if ppu.nametables != nil {
        delete(ppu.nametables);
    }
}

write_ppu_regs ::proc(ppu: ^PPU, address: u16, data: u8) {
    switch address {
        case 0x2000:
            parse_control_bits(ppu, data);
        case 0x2001:
            ppu.pixel_unit.render_settings = transmute(pixel.RenderSettings)data;
        case 0x2003:
            ppu.oam_addr = data;
        case 0x2004:
            ppu.oam_data[ppu.oam_addr] = data;
            ppu.oam_addr += 1;
        case 0x2005:
            parse_scroll_bits(ppu, data);
        case 0x2006:
            parse_address_bits(ppu, data);
        case 0x2007:
            write_ppu(ppu, data);
        case 0x4014 & 0x2007: 
            addr := u16(data) << 8;
            oam := ppu.dma_callback(addr, 256);
            assert(len(oam) == 256);
            mem.copy(raw_data(ppu.oam_data[:]), raw_data(oam), len(oam));
            //ppu.oam_addr = 0;
        case:
    }
}

read_ppu_regs ::proc(ppu: ^PPU, address: u16) -> []u8 {
    switch address {
        case 0x2002:
            poll_status_bits(ppu);
            return ppu.status[:];
        case 0x2004:
            i := ppu.oam_addr;
            return ppu.oam_data[i:i+1];
        case 0x2007:
            ppu.read_buffer[0] = ppu.read_buffer[1];
            read_ppu(ppu);
            return ppu.read_buffer[:1];
        case:    
            assert(false);
    }
    return nil;
}

write_ppu ::proc(ppu: ^PPU, value: u8) {
    switch ppu.v {
        case 0x0000..=0x1FFF:
            cart.write_cart(ppu.cartridge, ppu.v, value);
        case 0x2000..=0x2FFF:
            ppu.cartridge.mapper(ppu.cartridge, ppu.v, .VRAM_ADDR);
            ppu.nametables[ppu.cartridge.address] = value;
        case 0x3F00..=0x3FFF:
            //Palette RAM
            index := (ppu.v & 0x3F1F) - 0x3F00;
            ppu.palette[index] = value;

    }
    ppu.v += u16(ppu.vram_inc);
}

read_ppu ::proc(ppu: ^PPU) {
    switch ppu.v {
        case 0x0000..=0x1FFF:
            ppu.read_buffer[1] = cart.read_cart(ppu.cartridge, ppu.v)[0];
        case 0x2000..=0x2FFF:
            ppu.cartridge.mapper(ppu.cartridge, ppu.v, .VRAM_ADDR);
            ppu.read_buffer[1] = ppu.nametables[ppu.cartridge.address];
        case 0x3F00..=0x3FFF:
            //Palette RAM
            index := (ppu.v & 0x3F1F) - 0x3F00;
            ppu.read_buffer[0] = ppu.palette[index];
    }
    ppu.v += u16(ppu.vram_inc);
}

parse_control_bits ::proc(ppu: ^PPU, value: u8) {
    inc := [?]u8{1,32};
    nametables := [?]u16{0x2000,0x2400,0x2800,0x2C00};
    patterntables := [?]u16{0x0000,0x1000};
    
    index := (value >> 2) & 1;    
    ppu.vram_inc = inc[index];
    sprite := ((value >> 5) & 1) + 1;
    ppu.sprite_size = sprite;
    
    index = (value >> 3) & 1;    
    ppu.sprite_pattern_addr = patterntables[index];
    index = (value >> 4) & 1;
    ppu.bckgnd_pattern_addr = patterntables[index];
    index = (value >> 0) & 3;
    ppu.nametable_addr = nametables[index];
    temp := (u16(value) & 0x03) << 10;
    ppu.t = (ppu.t & 0xF3FF) | temp;

    ppu.nmi_enabled = (0x80 & value) != 0;
}

parse_scroll_bits ::proc(ppu: ^PPU, value: u8) {
    if ppu.w == 0 {
        temp := (u16(value) & 0xF8) >> 3;
        ppu.t = (ppu.t & 0xFFE0) | temp;
        temp = (u16(value) & 0x07);
        ppu.x = u8(temp);
        ppu.w = 1;
    }else{
        fgh := (u16(value) & 0x07) << 12;
        abcde := (u16(value) & 0xF8) << 2;
        ppu.t = (ppu.t & 0x8C1F) | (abcde | fgh);
        ppu.w = 0;
    }
}

parse_address_bits ::proc(ppu: ^PPU, value: u8) {
    if ppu.w == 0 {
        temp := (u16(value) & 0x3F) << 8;
        ppu.t = (ppu.t & 0x00FF) | temp;
        ppu.w = 1;
    }else{
        ppu.t = (ppu.t & 0xFF00) | u16(value);
        ppu.w = 0;
        ppu.v = ppu.t;
    }
}

poll_status_bits ::proc(ppu: ^PPU) {
    mask:u8 = 0;
    if .VBLANK in ppu.pixel_unit.status {
        mask |= vBlankMask;
        ppu.pixel_unit.status -= {.VBLANK};
    }
    if .SPRITE0HIT in ppu.pixel_unit.status {
        mask |= sprite0HitMask;
        ppu.pixel_unit.status -= {.SPRITE0HIT};
    }
    if .SPRITE_OVERFLOW in ppu.pixel_unit.status {
        mask |= spriteOverflowMask;
        ppu.pixel_unit.status -= {.SPRITE_OVERFLOW};
    }
    ppu.status[0] |= mask;
}