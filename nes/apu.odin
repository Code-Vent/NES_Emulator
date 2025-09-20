package nes

ApuRP2A03::struct {
}

ApuRP2A03_Result::struct {

}



apu_regs_read::proc (self: ^ApuRP2A03, address: u16) -> u8 {
    return 0;
}


apu_regs_write::proc (self: ^ApuRP2A03, address: u16, data: u8) {
    
}

apu_step::proc (self: ^ApuRP2A03) -> ApuRP2A03_Result {
    return ApuRP2A03_Result{};
}