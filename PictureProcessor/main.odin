package main

import "picture"
import "core:fmt"

main ::proc() {
    p := picture.PPU{};
    picture.parse_control_bits(&p, 3);
    fmt.printf("%4X\n%4X\n",p.pixel_unit.rx16[picture.NAMETABLE_ADDR],
        p.pixel_unit.rx16[picture.TEMP_VRAM_ADDR]);
}