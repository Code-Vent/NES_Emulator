package main

import "core:fmt"
import "nes"
import scrn "./nes/screen"
import cart "./nes/mappers"
import "core:mem"


main ::proc() {
    mapper, ok := cart.new_mapper("./mario.nes");
    assert(ok);
    defer cart.delete_mapper(&mapper);

    ppu := scrn.new_ppu(&mapper);
    fmt.println(mapper.cartridge.meta.mirroring);
    scrn.init();
    scrn.view_pattern_table(&ppu, scrn.background[0][:], true);
    //scrn.render_frame();
    //scrn.draw_name_table(&ppu);
}

