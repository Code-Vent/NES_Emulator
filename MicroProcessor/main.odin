package main

import "micro"
import "core:fmt"
import "core:os"
import "core:strings"
import "../Cartridge/cart"
import "../Calculator/calc"
import "core:time"


main ::proc() {
     //mcu_test();  
     disassembler();      
}

disassembler ::proc() {
    cartridge, ok := cart.load_cartridge("./../Cartridge/games/mario.nes", false); assert(ok);
    defer cart.unload_cartridge(&cartridge);

    mcu := micro.new_mcu(&cartridge);
    micro.reset(&mcu);
    program := micro.disassemble(&mcu);
    os.write_entire_file("program.log", transmute([]u8)program); 
}

mcu_test ::proc() {
    cartridge, ok := cart.load_cartridge("./../Cartridge/games/nestest.nes", false); assert(ok);
    defer cart.unload_cartridge(&cartridge);

    mcu := micro.new_mcu(&cartridge);
    micro.reset(&mcu);
    log, ok1 := os.read_entire_file("./micro/nestest.log");assert(ok1);
    expected := strings.split(transmute(string)log, "\n");
    start := time.tick_now();
    ok2, error := micro.disasm_run_test(&mcu, 0xC000, expected); 
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