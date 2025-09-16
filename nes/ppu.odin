package nes
import addr "address"

Ppu2C02::struct {

}

Ppu2C02_Result::struct{

}

ppu_step::proc (self: ^Ppu2C02, bus: ^addr.Bus) -> Ppu2C02_Result {
    return Ppu2C02_Result{};
}