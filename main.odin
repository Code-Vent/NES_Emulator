package main

import "Calculator/calc"
import "Cartridge/cart"
import "MicroProcessor/micro"
import "PictureProcessor/picture"
import "PixelUnit"

@(private)
mcu :micro.M6502;

nmi ::proc () {
    micro.nmi(&mcu);
}

irq ::proc () {
    micro.irq(&mcu);
}

dma ::proc(addr: u16, nbytes: int) -> []u8 {
    return micro.read_bus(&mcu, addr, nbytes);
}


main ::proc(){

}