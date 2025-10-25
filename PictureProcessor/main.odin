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
    cartridge, ok := cart.load_cartridge("./../Cartridge/games/mario.nes", false);assert(ok);
    defer cart.unload_cartridge(&cartridge);

    mapper := cart.get_mapper(&cartridge);
    ppu := picture.new_ppu(&mapper);
    defer picture.delete_ppu(&ppu);

    assert(len(ppu.nametables) == 2 * 1024);

    for i in 0..<0x400 {
        ppu.mapper^(&cartridge, 0x2000 + u16(i), .VRAM_ADDR);
        a := cartridge.address;
        ppu.mapper^(&cartridge, 0x2800 + u16(i), .VRAM_ADDR);
        b := cartridge.address;
        assert(a == i);
        assert(a == b);
    }

    for i in 0..<0x400 {
        ppu.mapper^(&cartridge, 0x2400 + u16(i), .VRAM_ADDR);
        a := cartridge.address;
        ppu.mapper^(&cartridge, 0x2C00 + u16(i), .VRAM_ADDR);
        b := cartridge.address;
        assert(a == (0x400 + i));
        assert(a == b);
    }

    ppu.dma_callback = dma;
    picture.write_ppu_regs(&ppu, 0x4014, 0xEF);
    for i in 0..<len(oam[:]) {
        assert(oam[i] == ppu.oam_data[i]);
    }
    fmt.println(ppu.oam_data[:]);
}