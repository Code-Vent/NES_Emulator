package picture

import "../../PixelUnit/pixel"

//8-bit registers
VRAM_INC     ::pixel.Register.R0;
WRITE_TOGGLE ::pixel.Register.R1;
SPRITE_SIZE  ::pixel.Register.R2;
W0           ::pixel.Register.R3;
W1           ::pixel.Register.R4;

//16-bit registers
VRAM_ADDR                ::pixel.Register16.R0;
TEMP_VRAM_ADDR           ::pixel.Register16.R1;
NAMETABLE_ADDR           ::pixel.Register16.R2;
BCKGND_PATTERNTABLE_ADDR ::pixel.Register16.R3;
SPRITE_PATTERNTABLE_ADDR ::pixel.Register16.R4;


PPU ::struct{
    pixel_unit: pixel.Pixel8,
}

write_ppu ::proc(ppu: ^PPU, address: u16, data: u8) {
    switch address {
        case 0x2000:
            parse_control_bits(ppu, data);
        case 0x2001:
            ppu.pixel_unit.render_settings = data;
        case 0x2003:
        case 0x2004:
        case 0x2005:
        case 0x2006:
        case 0x2007:
        case 0x4014:    
        case:
    }
}

read_ppu ::proc(ppu: ^PPU, address: u16) -> []u8 {
    switch address {
        case 0x2002:
        case 0x2004:
        case 0x2007:
        case:    
    }
    return nil;
}

parse_control_bits ::proc(ppu: ^PPU, value: u8) {
    inc := [?]u8{1,32};
    nametables := [?]u16{0x2000,0x2400,0x2800,0x2C00};
    patterntables := [?]u16{0x0000,0x1000};
    
    index := (value >> 2) & 1;    
    pixel.write_register(&ppu.pixel_unit, VRAM_INC, inc[index]);
    sprite := ((value >> 5) & 1) + 1;
    pixel.write_register(&ppu.pixel_unit, SPRITE_SIZE, sprite);
    
    index = (value >> 3) & 1;    
    pixel.lu_operation(&ppu.pixel_unit, .LDR, patterntables[index], SPRITE_PATTERNTABLE_ADDR);
    index = (value >> 4) & 1;
    pixel.lu_operation(&ppu.pixel_unit, .LDR, patterntables[index], BCKGND_PATTERNTABLE_ADDR);
    index = (value >> 0) & 3;
    pixel.lu_operation(&ppu.pixel_unit, .LDR, nametables[index], NAMETABLE_ADDR);
    temp := (u16(value) & 0x03) << 10;
    pixel.lu_operation(&ppu.pixel_unit, .AND, 0xF3FF, TEMP_VRAM_ADDR);
    pixel.lu_operation(&ppu.pixel_unit, .OR, temp, TEMP_VRAM_ADDR);

    pixel.write_control(&ppu.pixel_unit, .VBLANK_NMI, (0x80 & value) != 0);
}