package main

import "picture"
import "core:fmt"
import "../Cartridge/cart"


oam :[256]u8;

dma ::proc(addr: u16, nbytes: int) -> []u8 {
    for i in 0..<256 {
        oam[i] = u8(i);
    }
    fmt.printf("%4X\n", addr);
    return oam[:nbytes];
}

main ::proc() {
    cartridge := cart.Cartridge{};
    cartridge.meta.mapper_id = 0;
    cartridge.meta.mirroring = .VERTICAL;
    
    cart.nrom_mapper(&cartridge, 0, .TEST_INIT);
    cartridge.mapper = cart.nrom_mapper;

    ppu := picture.new_ppu(&cartridge);   
    defer picture.delete_ppu(&ppu);

    assert(len(ppu.nametables) == 2 * 1024);

    for i in 0..<0x400 {
        ppu.cartridge.mapper(ppu.cartridge, 0x2000 + u16(i), .VRAM_ADDR);
        a := cartridge.address;
        ppu.cartridge.mapper(ppu.cartridge, 0x2800 + u16(i), .VRAM_ADDR);
        b := cartridge.address;
        assert(a == i);
        assert(a == b);
    }

    for i in 0..<0x400 {
        ppu.cartridge.mapper(ppu.cartridge, 0x2400 + u16(i), .VRAM_ADDR);
        a := cartridge.address;
        ppu.cartridge.mapper(ppu.cartridge, 0x2C00 + u16(i), .VRAM_ADDR);
        b := cartridge.address;
        assert(a == (0x400 + i));
        assert(a == b);
    }

    ppu.dma_callback = dma;
    picture.write_ppu_regs(&ppu, 0x4014 & 0x2007, 0xEF);
    for i in 0..<len(oam[:]) {
        assert(oam[i] == ppu.oam_data[i]);
    }
    fmt.println(ppu.oam_data[:]);
}