package nes

Mapper::struct {
    cpu_bus: ^Bus,
    ppu_bus: ^Bus,
}

Mapper_Result::struct{

}

mapper_step::proc (self: ^Mapper) -> Mapper_Result {
    return Mapper_Result{};
}