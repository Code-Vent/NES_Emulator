package main

import "calc"
import "core:fmt"

//calc.write(Register::R0, 0x40);
//calc.write(Flag::CARRY, false);
//calc.aluOperation(Option::BIT, 0x01);
//calc.aluOperation(Option::SBC, 0x41);
//cout << hex << (int)calc.read(Register::R0) << endl;
//cout << calc.read(Flag::CARRY) << endl;
//cout << calc.read(Flag::ZERO) << endl;
//cout << calc.read(Flag::NEGATIVE) << endl;
//cout << calc.read(Flag::OVER_FLOW) << endl;

main ::proc() {
    c := calc.Calc8{};
    self := &c;
    calc.write_register(self, .R0, 0x40)
    calc.write_flag(self, .CARRY, true);
    //calc.aluOperation(self, .BIT, 0x01, .R0);
    calc.alu_operation(self, .SBC, 0x3F);
    fmt.printf("%2X\n", calc.read_register(self, .R0));
    fmt.println(calc.read_flag(self, .CARRY));
    fmt.println(calc.read_flag(self, .ZERO));
    fmt.println(calc.read_flag(self, .NEGATIVE));
    fmt.println(calc.read_flag(self, .OVERFLOW));
}