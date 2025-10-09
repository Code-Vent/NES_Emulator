package main

import "core:strconv"
import "core:strings"
import "core:fmt"
import "nes"
import scrn "./nes/screen"
import cart "./nes/mappers"
import "core:mem"
import "core:os"


main ::proc() {
    alu_ := nes.Alu6502{};
    mapper_, ok := cart.new_mapper("./nestest.nes"); assert(ok);
    defer cart.delete_mapper(&mapper_);
    ppu_ := scrn.new_ppu(&mapper_);
    apu_ := nes.ApuRP2A03{};
    cpu_ := nes.cpu_get(&alu_, &ppu_, &apu_, &mapper_);
    pu := nes.ProcessingUnits{
        cpu = cpu_,
        ppu = &ppu_,
        apu = &apu_,
        mapper = &mapper_
    };

    
    //str := nes.disasm_all(cpu_.disasm);
    //fmt.println(str);
    log, ok1 := os.read_entire_file("nestest.log");assert(ok1);
    expected := strings.split(transmute(string)log, "\n");
    ok2, error := nes.disasm_run_test(cpu_.disasm, 0xC000, expected);
    
    if ok2 {
        fmt.println("Disassembly test passed.");
    } else {
        fmt.println("Disassembly test failed: %s", error);
    }

    a := u8(0x80);
    b := u8(0x7F);

    fmt.println(int(i8(a)), int(i8(b)));
    
    //nes.clock_add_units(&pu);
    //nes.clock_run();
    
    //fmt.println(mapper_.cartridge.meta.mirroring);
    //scrn.frame_init();
    //for{
    //    scrn.frame_view_pattern_table(&ppu_, scrn.background[0][:], true);
    //    msg: win.MSG;
    //    if win.GetMessageW(&msg, nil, 0, 0) > 0 {
    //        win.TranslateMessage(&msg);
    //        win.DispatchMessageW(&msg);
    //    }
    //}
    //scrn.render_frame();
    //scrn.draw_name_table(&ppu);
}

