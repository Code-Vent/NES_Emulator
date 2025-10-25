package main

import "cart"
import "core:fmt"
import "core:sys/windows"

main ::proc() {
    cartridge, ok := cart.load_cartridge("./mario.nes");
    defer cart.unload_cartridge(&cartridge);
    data := cart.read_rom(&cartridge, 0xFFFD);
    fmt.printf("%2X", data);
}