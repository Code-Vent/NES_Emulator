package nes

import cart "mappers"
import scrn "screen"
import "core:fmt"
import win "core:sys/windows"

ProcessingUnits::struct {
    cpu: ^CpuInterface,
    ppu: ^scrn.Ppu2C02,
    apu: ^ApuRP2A03,
    mapper: ^cart.Mapper,
}

@(private)
units: ^ProcessingUnits = nil;
//Do not forget to handle all pending states i.e DMA Pending: before 
//Moving to the next step


clock_add_units ::proc(pu: ^ProcessingUnits) {    
    units = pu;
}

clock_run ::proc() {
    cpu_reset(units.cpu);
    scrn.ppu_reset(units.ppu);
    apu_reset(units.apu);
    scrn.frame_init();
    for {
        debug_info := alu_step(units.cpu.alu, &units.cpu.bus);
        ppu_except := scrn.ppu_step(units.ppu);
        clock_ppu_exception_handler(ppu_except);
        msg: win.MSG;
        if win.GetMessageW(&msg, nil, 0, 0) > 0 {
            win.TranslateMessage(&msg);
            win.DispatchMessageW(&msg);
        }
        
        fmt.eprintln(debug_info);        
    }
}

clock_ppu_exception_handler ::proc(ex: scrn.Ppu2C02_Exception){
    #partial switch ex {
        case .DMA_PENDING:
            clock_ppu_dma();
        case .NMI_PENDING:
            cpu_nmi(units.cpu);
        case .NONE:
    }
}

clock_ppu_dma ::proc(){
    src := u16(scrn.ppu_regs.oam_dma) << 8;
    for i in 0..<256 {
        scrn.ppu_oam[i] = bus_read_u8(&units.cpu.bus, src);
        src += 1;        
    }
    units.ppu.events += {.END_OF_OAM};
}