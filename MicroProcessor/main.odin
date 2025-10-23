package main

import "micro"
import "core:fmt"
import "core:os"
import "core:strings"
import "../Cartridge/cart"
import "core:time"


main ::proc() {
    mcu := micro.M6502{};
    cartridge, ok := cart.load_cartridge("./../Cartridge/games/nestest.nes", false); assert(ok);
    defer cart.unload_cartridge(&cartridge);

    self := &mcu;
    micro.reset(self, &cartridge);
    log, ok1 := os.read_entire_file("./micro/nestest.log");assert(ok1);
    expected := strings.split(transmute(string)log, "\n");
    start := time.tick_now();
    ok2, error := micro.disasm_run_test(self, 0xC000, expected); 
    end := time.tick_now();   
    if ok2 {
        fmt.println("Disassembly test passed.");
    } else {
        fmt.println("Disassembly test failed: %s", error);
    }
    duration := time.tick_diff(start, end);
    fmt.printf("%v\n", duration);
    fmt.println(mcu.cycles);
}