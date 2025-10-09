package nes

import "core:debug/pe"
import "core:strings"
import "core:strconv"
import "core:fmt"

Flags::enum {
    C = 0, Z , I , D, B, _, V, N
}

Registers::struct {
    A : u8,
    X: u8,
    Y: u8,
    PC: u16,
    SP: u8,
    SR: u8,
}

Operand::union {
    u8,
    u16,
    ^u8,
    u32
}

Alu6502::struct {
    regs: Registers,
}

Alu6502_Result::struct {
    opcode: u8,
    pc    : u16,
}

OpcodeLabel::enum(u8) {
    LDA, STA, LDX, STX, LDY, STY,//Implemented
    TAX, TXA, TAY, TYA, TXS, TSX,//Implemented
    ADC, SBC, INC, DEC, INX, DEX, INY, DEY,//Implemented
    ASL, LSR, ROL, ROR,//Implemented
    AND, ORA, EOR, BIT,//Implemented
    CMP, CPX, CPY,//Implemented
    BCC, BCS, BEQ, BNE, BPL, BMI, BVC, BVS,//Implemented
    JMP, JSR, RTS, BRK, RTI,//Implemented
    PHA, PLA, PHP, PLP,//Implemented
    CLC, SEC, CLI, SEI, CLD, SED, CLV,//Implemented
    NOP, //Implemented
    //Undocumented Opcodes
    UND, SLO, RLA, SRE, RRA, SAX, AHX, LAX, DCP, ISC,
    ANC, ALR, XAA, TAS, LAS, AXS, SHX, ARR, SHY
}

AddressingLabel::enum(u8) {
    IMP, IMM, ZP0, ZPX, ZPY, REL, ABS, ABX, ABY, IND, IZX, IZY, ACC,
}

Opcode::struct {
    txt: string,
    ol:OpcodeLabel,
    al:AddressingLabel,
    cycles: u8,
}


OPCODES:[16][16]Opcode = {
    //            0                       1                   2                   3                   4                   5                   6                   7                   8                   9                   A                   B                   C                   D                   E                   F
    /*00*/{{"BRK",.BRK,.IMM,7},{"ORA",.ORA,.IZX,6},{"UND",.UND,.IMP,2},{"SLO",.SLO,.IZX,8},{"NOP",.NOP,.ZP0,3},{"ORA",.ORA,.ZP0,3},{"ASL",.ASL,.ZP0,5},{"SLO",.SLO,.ZP0,5},{"PHP",.PHP,.IMP,3},{"ORA",.ORA,.IMM,2},{"ASL",.ASL,.ACC,2},{"ANC",.ANC,.IMM,2},{"NOP",.NOP,.ABS,4},{"ORA",.ORA,.ABS,4},{"ASL",.ASL,.ABS,6},{"SLO",.SLO,.ABS,6}},//0
    /*00*/{{"BPL",.BPL,.REL,2},{"ORA",.ORA,.IZY,5},{"UND",.UND,.IMP,2},{"SLO",.SLO,.IZY,8},{"NOP",.NOP,.ZPX,4},{"ORA",.ORA,.ZPX,4},{"ASL",.ASL,.ZPX,6},{"SLO",.SLO,.ZPX,6},{"CLC",.CLC,.IMP,2},{"ORA",.ORA,.ABY,4},{"NOP",.NOP,.IMP,2},{"SLO",.SLO,.ABY,7},{"NOP",.NOP,.ABX,4},{"ORA",.ORA,.ABX,4},{"ASL",.ASL,.ABX,7},{"SLO",.SLO,.ABX,7}},//1
    /*20*/{{"JSR",.JSR,.ABS,6},{"AND",.AND,.IZX,6},{"UND",.UND,.IMP,2},{"RLA",.RLA,.IZX,8},{"BIT",.BIT,.ZP0,3},{"AND",.AND,.ZP0,3}, {"ROL",.ROL,.ZP0,5},{"RLA",.RLA,.ZP0,5},{"PLP",.PLP,.IMP,4},{"AND",.AND,.IMM,2},{"ROL",.ROL,.IMP,2},{"ANC",.ANC,.IMM,2},{"BIT",.BIT,.ABS,4},{"AND",.AND,.ABS,4},{"ROL",.ROL,.ABS,6},{"RLA",.RLA,.ABS,6}},//2
    /*20*/{{"BMI",.BMI,.REL,2},{"AND",.AND,.IZY,5},{"UND",.UND,.IMP,2},{"RLA",.RLA,.IZY,8},{"NOP",.NOP,.ZPX,4},{"AND",.AND,.ZPX,4},{"ROL",.ROL,.ZPX,6},{"RLA",.RLA,.ZPX,6},{"SEC",.SEC,.IMP,2},{"AND",.AND,.ABY,4},{"NOP",.NOP,.IMP,2},{"RLA",.RLA,.ABY,7},{"NOP",.NOP,.ABX,4},{"AND",.AND,.ABX,4},{"ROL",.ROL,.ABX,7},{"RLA",.RLA,.ABX,7}},//3
    /*40*/{{"RTI",.RTI,.IMP,6},{"EOR",.EOR,.IZX,6},{"UND",.UND,.IMP,2},{"SRE",.SRE,.IZX,8},{"NOP",.NOP,.ZP0,3},{"EOR",.EOR,.ZP0,3},{"LSR",.LSR,.ZP0,5},{"SRE",.SRE,.ZP0,5},{"PHA",.PHA,.IMP,3},{"EOR",.EOR,.IMM,2},{"LSR",.LSR,.IMP,2},{"ALR",.ALR,.IMM,2},{"JMP",.JMP,.ABS,3},{"EOR",.EOR,.ABS,4},{"LSR",.LSR,.ABS,6},{"SRE",.SRE,.ABS,6}},//4
    /*40*/{{"BVC",.BVC,.REL,2},{"EOR",.EOR,.IZY,5},{"UND",.UND,.IMP,2},{"SRE",.SRE,.IZY,8},{"NOP",.NOP,.ZPX,4},{"EOR",.EOR,.ZPX,4},{"LSR",.LSR,.ZPX,6},{"SRE",.SRE,.ZPX,6},{"CLI",.CLI,.IMP,2},{"EOR",.EOR,.ABY,4},{"NOP",.NOP,.IMP,2},{"SRE",.SRE,.ABY,7},{"NOP",.NOP,.ABX,4},{"EOR",.EOR,.ABX,4},{"LSR",.LSR,.ABX,7},{"SRE",.SRE,.ABX,7}},//5
    /*60*/{{"RTS",.RTS,.IMP,6},{"ADC",.ADC,.IZX,6},{"UND",.UND,.IMP,2},{"RRA",.RRA,.IZX,8},{"NOP",.NOP,.ZP0,3},{"ADC",.ADC,.ZP0,3},{"ROR",.ROR,.ZP0,5},{"RRA",.RRA,.ZP0,5},{"PLA",.PLA,.IMP,4},{"ADC",.ADC,.IMM,2},{"ROR",.ROR,.IMP,2},{"ARR",.ARR,.IMM,2},{"JMP",.JMP,.IND,5},{"ADC",.ADC,.ABS,4},{"ROR",.ROR,.ABS,6},{"RRA",.RRA,.ABS,6}},//6
    /*60*/{{"BVS",.BVS,.REL,2},{"ADC",.ADC,.IZY,5},{"UND",.UND,.IMP,2},{"RRA",.RRA,.IZY,8},{"NOP",.NOP,.ZPX,4},{"ADC",.ADC,.ZPX,4},{"ROR",.ROR,.ZPX,6},{"RRA",.RRA,.ZPX,6},{"SEI",.SEI,.IMP,2},{"ADC",.ADC,.ABY,4},{"NOP",.NOP,.IMP,2},{"RRA",.RRA,.ABY,7},{"NOP",.NOP,.ABX,4},{"ADC",.ADC,.ABX,4},{"ROR",.ROR,.ABX,7},{"RRA",.RRA,.ABX,7}},//7
    /*80*/{{"NOP",.NOP,.IMM,2},{"STA",.STA,.IZX,6},{"NOP",.NOP,.IMM,2},{"SAX",.SAX,.IZX,8},{"STY",.STY,.ZP0,3},{"STA",.STA,.ZP0,3},{"STX",.STX,.ZP0,3},{"SAX",.SAX,.ZP0,3},{"DEY",.DEY,.IMP,2},{"NOP",.NOP,.IMM,2},{"TXA",.TXA,.IMP,2},{"XAA",.XAA,.IMM,2},{"STY",.STY,.ABS,4},{"STA",.STA,.ABS,4},{"STX",.STX,.ABS,4},{"SAX",.SAX,.ABS,4}},//8
    /*80*/{{"BCC",.BCC,.REL,2},{"STA",.STA,.IZY,6},{"UND",.UND,.IMP,2},{"AHX",.AHX,.IZY,6},{"STY",.STY,.ZPX,4},{"STA",.STA,.ZPX,4},{"STX",.STX,.ZPY,4},{"SAX",.SAX,.ZPY,4},{"TYA",.TYA,.IMP,2},{"STA",.STA,.ABY,5},{"TXS",.TXS,.IMP,2},{"TAS",.TAS,.ABY,5},{"NOP",.SHY,.ABX,5},{"STA",.STA,.ABX,5},{"SHY",.SHX,.ABY,5},{"AHX",.AHX,.ABY,5}},//9
    /*A0*/{{"LDY",.LDY,.IMM,2},{"LDA",.LDA,.IZX,6},{"LDX",.LDX,.IMM,2},{"LAX",.LAX,.IZX,6},{"LDY",.LDY,.ZP0,3},{"LDA",.LDA,.ZP0,3},{"LDX",.LDX,.ZP0,3},{"LAX",.LAX,.ZP0,3},{"TAY",.TAY,.IMP,2},{"LDA",.LDA,.IMM,2},{"TAX",.TAX,.IMP,2},{"LAX",.LAX,.IMM,2},{"LDY",.LDY,.ABS,4},{"LDA",.LDA,.ABS,4},{"LDX",.LDX,.ABS,4},{"LAX",.LAX,.ABS,4}},//A
    /*A0*/{{"BCS",.BCS,.REL,2},{"LDA",.LDA,.IZY,5},{"UND",.UND,.IMP,2},{"LAX",.LAX,.IZY,5},{"LDY",.LDY,.ZPX,4},{"LDA",.LDA,.ZPX,4},{"LDX",.LDX,.ZPY,4},{"LAX",.LAX,.ZPY,4},{"CLV",.CLV,.IMP,2},{"LDA",.LDA,.ABY,4},{"TSX",.TSX,.IMP,2},{"LAS",.LAS,.ABY,4},{"LDY",.LDY,.ABX,4},{"LDA",.LDA,.ABX,4},{"LDX",.LDX,.ABY,4},{"LAX",.LAX,.ABY,4}},//B
    /*C0*/{{"CPY",.CPY,.IMM,2},{"CMP",.CMP,.IZX,6},{"NOP",.NOP,.IMM,2},{"DCP",.DCP,.IZX,8},{"CPY",.CPY,.ZP0,3},{"CMP",.CMP,.ZP0,3},{"DEC",.DEC,.ZP0,5},{"DCP",.DCP,.ZP0,5},{"INY",.INY,.IMP,2},{"CMP",.CMP,.IMM,2},{"DEX",.DEX,.IMP,2},{"AXS",.AXS,.IMM,2},{"CPY",.CPY,.ABS,4},{"CMP",.CMP,.ABS,4},{"DEC",.DEC,.ABS,6},{"DCP",.DCP,.ABS,6}},//C
    /*C0*/{{"BNE",.BNE,.REL,2},{"CMP",.CMP,.IZY,5},{"UND",.UND,.IMP,2},{"DCP",.DCP,.IZY,8},{"NOP",.NOP,.ZPX,4},{"CMP",.CMP,.ZPX,4},{"DEC",.DEC,.ZPX,6},{"DCP",.DCP,.ZPX,6},{"CLD",.CLD,.IMP,2},{"CMP",.CMP,.ABY,4},{"NOP",.NOP,.IMP,2},{"DCP",.DCP,.ABY,7},{"NOP",.NOP,.ABX,4},{"CMP",.CMP,.ABX,4},{"DEC",.DEC,.ABX,7},{"DCP",.DCP,.ABX,7}},//D
    /*E0*/{{"CPX",.CPX,.IMM,2},{"SBC",.SBC,.IZX,6},{"NOP",.NOP,.IMM,2},{"ISC",.ISC,.IZX,8},{"CPX",.CPX,.ZP0,3},{"SBC",.SBC,.ZP0,3},{"INC",.INC,.ZP0,5},{"ISC",.ISC,.ZP0,5},{"INX",.INX,.IMP,2},{"SBC",.SBC,.IMM,2},{"NOP",.NOP,.IMP,2},{"SBC",.SBC,.IMM,2},{"CPX",.CPX,.ABS,4},{"SBC",.SBC,.ABS,4},{"INC",.INC,.ABS,6},{"ISC",.ISC,.ABS,6}},//E
    /*E0*/{{"BEQ",.BEQ,.REL,2},{"SBC",.SBC,.IZY,5},{"UND",.UND,.IMP,2},{"ISC",.ISC,.IZY,8},{"NOP",.NOP,.ZPX,4},{"SBC",.SBC,.ZPX,4},{"INC",.INC,.ZPX,6},{"ISC",.ISC,.ZPX,6},{"SED",.SED,.IMP,2},{"SBC",.SBC,.ABY,4},{"NOP",.NOP,.IMP,2},{"ISC",.ISC,.ABY,7},{"NOP",.NOP,.ABX,4},{"SBC",.SBC,.ABX,4},{"INC",.INC,.ABX,7},{"ISC",.ISC,.ABX,7}},//F
};


alu_read_u8_arg ::proc (
    self: ^Alu6502, 
    bus: ^Bus
) -> u8 {
    data := bus_read_u8(bus, self.regs.PC);
    self.regs.PC += 1;
    return data;
}

alu_read_u16_arg ::proc (
    self: ^Alu6502, 
    bus: ^Bus
) -> u16 {
    data := bus_read_u16(bus, self.regs.PC);
    self.regs.PC += 2;
    return data;
}

alu_pop ::proc (
    self: ^Alu6502, 
    bus: ^Bus
) -> u8{
    if self.regs.SP < 0xff {
        self.regs.SP += 1;
        stack_ptr:u16 = u16(0x100) + u16(self.regs.SP);
        return bus_read_u8(bus, stack_ptr);
    }
    return 0;
}

alu_push ::proc (
    self: ^Alu6502, 
    bus: ^Bus, 
    data: u8
){
    if self.regs.SP > 0x00 {
        stack_ptr:u16 = u16(0x100) + u16(self.regs.SP);
        bus_write(bus, stack_ptr, data);
        self.regs.SP -= 1;
        //fmt.printf("%X pushed %X\n", data, self.regs.SP);
    }
}

alu_push_pc ::proc (self: ^Alu6502, bus: ^Bus) {
    hi := u8((self.regs.PC >> 8) & 0x00FF);
    lo := u8(self.regs.PC & 0x00FF);
    alu_push(self, bus, hi);
    alu_push(self, bus, lo);
    //fmt.println(self.regs.PC);
}

alu_pop_pc ::proc (self: ^Alu6502, bus: ^Bus) {
    lo := alu_pop(self, bus);
    hi := alu_pop(self, bus);
    self.regs.PC = u16(hi) << 8 | u16(lo);
    //fmt.println(self.regs.PC);
}


alu_set_flag ::proc (self: ^Alu6502, flag: Flags) {
    self.regs.SR |= u8(1 << u8(flag));
}

alu_clear_flag ::proc (self: ^Alu6502, flag: Flags) {
    self.regs.SR &= ~u8(1 << u8(flag));
}

alu_is_flag_set ::proc (self: ^Alu6502, flag: Flags) -> bool {
    return (self.regs.SR & u8(1 << u8(flag))) != 0;
}

alu_is_flag_clear ::proc (self: ^Alu6502, flag: Flags) -> bool{
    return (self.regs.SR & u8(1 << u8(flag))) == 0;
}

alu_step ::proc (
    self: ^Alu6502, 
    bus: ^Bus
) -> (debug_info:string) {
    pc := self.regs.PC;
    value := alu_read_u8_arg(self, bus);
    row := (value & 0xF0) >> 4;
    col := (value & 0x0F);
    opcode := OPCODES[row][col];
    src, dest: Operand;
    decode_operand(self, opcode.al, bus, &src);
    debug_info = decode_operation(self, opcode.ol, bus, &src, &dest);
    debug_info = fmt.tprintf("%4X %s %s\n", pc, opcode.txt, debug_info);
    return debug_info;
}

//@(private)
decode_operand ::proc (
    self: ^Alu6502, 
    mode: AddressingLabel, 
    bus: ^Bus, 
    opr: ^Operand
) -> (size: u8){
    switch(mode){
        case .ABS:
            size = absolute(self, bus, opr)
        case .ABX:
            size = absolute_indexed_x(self, bus, opr)
        case .ABY:
            size = absolute_indexed_y(self, bus, opr)
        case .IMM:
            size = immediate(self, bus, opr);
        case .IMP,.ACC:
            size = implied(self, bus, opr);
        case .IND:
            size = indirect(self, bus, opr)
        case .IZX:
            size = indirect_indexed_x(self, bus, opr)
        case .IZY:
            size = indirect_indexed_y(self, bus, opr)
        case .REL:
            size = relative(self, bus, opr)
        case .ZP0:
            size = zero_page(self, bus, opr)
        case .ZPX:
            size = zero_page_indexed_x(self, bus, opr)
        case .ZPY:
            size = zero_page_indexed_y(self, bus, opr)
    }
    return size;
}

@(private)
implied ::proc (
    self: ^Alu6502, 
    bus: ^Bus, 
    opr: ^Operand
) -> (size:u8){
    opr^ = &self.regs.A;
    return 1;
}

@(private)
immediate ::proc (
    self: ^Alu6502, 
    bus: ^Bus, 
    opr: ^Operand
) -> (size:u8) {
    arg := alu_read_u8_arg(self, bus);
    opr^ = arg;
    return 2;
}

@(private)
relative ::proc (
    self: ^Alu6502, 
    bus: ^Bus, 
    opr: ^Operand
) -> (size:u8){
    arg := alu_read_u8_arg(self, bus);
    //val := (0x80 & arg != 0)? -1 * int(~(arg - 1)) : int(arg);
    eaddr:int = int(self.regs.PC) + int(i8(arg));
    opr^ = u16(eaddr);
    return 2;
}

@(private)
zero_page_indexed_x ::proc (
    self: ^Alu6502, 
    bus: ^Bus, 
    opr: ^Operand
) -> (size: u8){
    arg := alu_read_u8_arg(self, bus);
    eaddr := u16(arg + self.regs.X) & 0x00FF;
    opr^ = eaddr;
    return 2;
}

@(private)
zero_page_indexed_y ::proc (
    self: ^Alu6502, 
    bus: ^Bus, 
    opr: ^Operand
) -> (size:u8) {
    arg:u8 = alu_read_u8_arg(self, bus);
    eaddr:u16 = u16(arg + self.regs.Y) & 0x00FF;
    opr^ = eaddr;
    return 2;
}

@(private)
absolute ::proc (
    self: ^Alu6502, 
    bus: ^Bus, 
    opr: ^Operand
) -> (size: u8){
    arg := alu_read_u16_arg(self, bus);
    opr^ = arg;
    return 3;
}

@(private)
absolute_indexed_x ::proc (
    self: ^Alu6502, 
    bus: ^Bus, 
    opr: ^Operand
) -> (size: u8){
    arg := alu_read_u16_arg(self, bus);
    eaddr := u16(arg) + u16(self.regs.X);
    opr^ = eaddr;
    return 3;
}

@(private)
absolute_indexed_y ::proc (
    self: ^Alu6502, 
    bus: ^Bus, 
    opr: ^Operand
) -> (size: u8){
    arg := alu_read_u16_arg(self, bus);
    eaddr := u16(arg) + u16(self.regs.Y);
    opr^ = eaddr;
    return 3;
}

@(private)
indirect_indexed_x ::proc (
    self: ^Alu6502, 
    bus: ^Bus, 
    opr: ^Operand
) -> (size: u8){
    arg := alu_read_u8_arg(self, bus);
    temp := u16(arg + self.regs.X) & 0x00FF;
    eadrr_lo := bus_read_u8(bus, temp);
    temp = u16(arg + self.regs.X + 1) & 0x00FF;
    eadrr_hi := bus_read_u8(bus, temp);
    eaddr := u16(eadrr_hi) << 8 | u16(eadrr_lo);
    opr^ = eaddr;
    return 2;
}

@(private)
indirect_indexed_y::proc (
    self: ^Alu6502, 
    bus: ^Bus, 
    opr: ^Operand
) -> (size: u8){
    arg := alu_read_u8_arg(self, bus);
    eadrr_lo := bus_read_u8(bus, u16(arg));
    temp := u16(arg + 1) & 0x00FF;
    eadrr_hi := bus_read_u8(bus, temp);
    eaddr := (u16(eadrr_hi) << 8 | u16(eadrr_lo)) + u16(self.regs.Y);
    opr^ = eaddr;
    return 2;
}

@(private)
indirect::proc (
    self: ^Alu6502, 
    bus: ^Bus, 
    opr: ^Operand
) -> (size: u8){
    arg := u32(alu_read_u16_arg(self, bus));
    opr^ = arg;
    return 3;
}

@(private)
zero_page::proc (
    self: ^Alu6502, 
    bus: ^Bus, 
    opr: ^Operand
) -> (size: u8){
    arg := alu_read_u8_arg(self, bus);
    eaddr := u16(arg) & 0x00FF;
    opr^ = eaddr;
    return 2;
}

//@(private)
decode_operation::proc (
    self: ^Alu6502, 
    op: OpcodeLabel, 
    bus: ^Bus, 
    src: ^Operand, 
    dest: ^Operand
) -> (debug_info: string) {
    #partial switch op {
        case .PHP:
            alu_set_flag(self, .B);
            src^ = &self.regs.SR
            fallthrough
        case .PHA:
            debug_info = alu_stack(src, self, bus, .PUSH);
        case .PLP:
            src^ = &self.regs.SR
            debug_info = alu_stack(src, self, bus, .PULL);
        case .PLA:
            
            debug_info = alu_stack(src, self, bus, .PULL);//src has been set to A inside imp addressing mode
            //fmt.println(self.regs.A);
            
            if self.regs.A == 0 {
                alu_set_flag(self, .Z);
                //fmt.println(alu_is_flag_set(self, .Z));
            }else{
                alu_clear_flag(self, .Z);
            }

            if self.regs.A & 0x80 == 0 {
                alu_clear_flag(self, .N);
            }else{
                alu_set_flag(self, .N);
            }
        case .TAX:
            dest^ = &self.regs.X
            debug_info = alu_transfer(src, dest, self, false);
        case .TXA:
            src^ = &self.regs.X
            dest^ = &self.regs.A
            debug_info = alu_transfer(src, dest, self, false);
        case .TAY:
            dest^ = &self.regs.Y
            debug_info = alu_transfer(src, dest, self, false);
        case .TYA:
            src^ = &self.regs.Y;
            dest^ = &self.regs.A;
            debug_info = alu_transfer(src, dest, self, false);
        case .TXS:
            src^ = &self.regs.X;
            dest^ = &self.regs.SP;
            debug_info = alu_transfer(src, dest, self, true);
        case .TSX:
            src^ = &self.regs.SP;
            dest^ = &self.regs.X;
            debug_info = alu_transfer(src, dest, self, false);
        case .LDA:
            dest^ = &self.regs.A;
            debug_info = alu_load(src, dest, self, bus);
        case .STA:
            dest^ = &self.regs.A;
            debug_info = alu_store(dest, src, bus);
            //assert(false);
        case .LDX:
            dest^ = &self.regs.X;
            debug_info = alu_load(src, dest, self, bus);
        case .LAX:
            dest^ = &self.regs.A;
            debug_info = alu_load(src, dest, self, bus);
            self.regs.X = self.regs.A;
        case .STX:
            dest^ = &self.regs.X;
            debug_info = alu_store(dest, src, bus);
        case .SAX:
            ax := (self.regs.A) & (self.regs.X);
            dest^ = &ax;
            debug_info = alu_store(dest, src, bus);
            debug_info = fmt.tprintf("%s(A=%2X)(X=%2X)(AX=%2X)", debug_info, self.regs.A, self.regs.X, ax);
            //fmt.println("AX", ax);
        case .LDY:
            dest^ = &self.regs.Y;
            debug_info = alu_load(src, dest, self, bus);
        case .STY:
            dest^ = &self.regs.Y;
            debug_info = alu_store(dest, src, bus);
        case .CMP:
            dest^ = &self.regs.A;
            debug_info = alu_compare(src, dest, self, bus);
        case .CPX:
            dest^ = &self.regs.X;
            debug_info = alu_compare(src, dest, self, bus);
        case .CPY:
            dest^ = &self.regs.Y;
            debug_info = alu_compare(src, dest, self, bus);
        case .BCC:
            debug_info = alu_branch(src, self, .C, false);
        case .BCS:
            debug_info = alu_branch(src, self, .C, true);
        case .BEQ:
            debug_info = alu_branch(src, self, .Z, true);
        case .BNE:
            //fmt.println(alu_is_flag_clear(self, .Z));
            //fmt.println(alu_is_flag_set(self, .Z));
            debug_info = alu_branch(src, self, .Z, false);
        case .BPL:
            debug_info = alu_branch(src, self, .N, false);
        case .BMI:
            debug_info = alu_branch(src, self, .N, true);
        case .BVC:
            debug_info = alu_branch(src, self, .V, false);
        case .BVS:
            debug_info = alu_branch(src, self, .V, true);
        case .CLC:
            alu_clear_flag(self, .C);
        case .SEC:
            alu_set_flag(self, .C);
        case .CLI:
            alu_clear_flag(self, .I);
        case .SEI:
            alu_set_flag(self, .I);
        case .CLD:
            alu_clear_flag(self, .D);
        case .SED:
            alu_set_flag(self, .D);
        case .CLV:
            alu_clear_flag(self, .V);
        case .NOP:
            //Do nothing
        case .JMP:
            debug_info = alu_jump(src, self, .JMP, bus);
        case .JSR:
            debug_info = alu_jump(src, self, .JSR, bus);
        case .RTS:  
            debug_info = alu_jump(src, self, .RTS, bus);
        case .BRK:
            debug_info = alu_jump(src, self, .BRK, bus);
        case .RTI:
            debug_info = alu_jump(src, self, .RTI, bus);
        case .ADC:
            debug_info = alu_arithmetic(src, self, bus);
        case .SBC:
            debug_info = sbc(src, self, bus);
        case .INC:
            debug_info = alu_inc_or_dec(src, self, .INC, bus, false);
        case .INX:
            src^ = &self.regs.X;
            debug_info = alu_inc_or_dec(src, self, .INC, bus, false);
        case .INY:
            src^ = &self.regs.Y;
            debug_info = alu_inc_or_dec(src, self, .INC, bus, false);
        case .DEC:
            debug_info = alu_inc_or_dec(src, self, .DEC, bus, false);
        case .DEX:
            src^ = &self.regs.X;
            debug_info = alu_inc_or_dec(src, self, .DEC, bus, false);
        case .DEY:
            src^ = &self.regs.Y;
            debug_info = alu_inc_or_dec(src, self, .DEC, bus, false);
        case .ASL:
            debug_info = alu_shift(src, .LEFT, self, bus);
        case .LSR:
            debug_info = alu_shift(src, .RIGHT, self, bus);
        case .ROL:
            debug_info = alu_rotate(src, .LEFT, self, bus);
        case .ROR:
            debug_info = alu_rotate(src, .RIGHT, self, bus);
        case .AND:
            debug_info = alu_bitwise(src, self, .AND, bus);
        case .ORA:
            debug_info = alu_bitwise(src, self, .OR, bus);
        case .EOR:
            debug_info = alu_bitwise(src, self, .XOR, bus);
        case .BIT:
            debug_info = alu_bitwise(src, self, .BIT, bus);
        //uNDOCUMENTED CODES
        case .RRA:
            info1 := alu_rotate(src, .RIGHT, self, bus);
            info2 := alu_arithmetic(src, self, bus);
            debug_info = fmt.tprintf("%s%s", info1, info2);
        case .SLO:
            info1 := alu_shift(src, .LEFT, self, bus);
            carry_set := alu_is_flag_set(self, .C);
            info2 := alu_bitwise(src, self, .OR, bus);
            if carry_set {
                alu_set_flag(self, .C);
            }else{
                alu_clear_flag(self, .C);
            }
            debug_info = fmt.tprintf("%s%s", info1, info2);
        case .SRE:
            info1 := alu_shift(src, .RIGHT, self, bus);
            info2 := alu_bitwise(src, self, .XOR, bus);
            debug_info = fmt.tprintf("%s%s", info1, info2);
        case .RLA:
            info1 := alu_rotate(src, .LEFT, self, bus);
            info2 := alu_bitwise(src, self, .AND, bus);
            debug_info = fmt.tprintf("%s%s", info1, info2);
        case .DCP:
            info1 := alu_inc_or_dec(src, self, .DEC, bus, true);
            dest^ = &self.regs.A;
            info2 := alu_compare(src, dest, self, bus);
            debug_info = fmt.tprintf("%s%s", info1, info2);
        case .ISC:
            info1 := alu_inc_or_dec(src, self, .INC, bus, false);
            info2 := sbc(src, self, bus);
            debug_info = fmt.tprintf("%s%s", info1, info2);
        case:
            //assert(false);
    }
    return debug_info;
}


alu_load::proc (
    src: ^Operand, 
    dest: ^Operand, 
    alu: ^Alu6502, 
    bus: ^Bus
) -> (debug_info: string){
    result:u8;
    #partial switch choice in src {
        case u8:
            result = choice;
            debug_info = fmt.tprintf(" #%2X", choice);
        case u16:
            result = bus_read_u8(bus, choice);
            debug_info = fmt.tprintf(" [%4X](%2X)", choice, result);
        case:
            assert(false);
    }
    
    destaddrr, ok := dest.(^u8); assert(ok);
    destaddrr^ = result;

    if result == 0 {
        alu_set_flag(alu, .Z);
    }else{
        alu_clear_flag(alu, .Z);
    }
    
    if result & 0x80 == 0 {
        alu_clear_flag(alu, .N);
    }else{
        alu_set_flag(alu, .N);
    }
    return debug_info;
}

alu_store::proc (
    src: ^Operand, 
    dest: ^Operand, 
    bus: ^Bus
) -> (debug_info: string){
    srcaddr, ok1 := src.(^u8); assert(ok1);
    data := srcaddr^;
    destaddrr, ok2 := dest.(u16); assert(ok2);
    bus_write(bus, destaddrr, data);
    dummy := bus_read_u8(bus, destaddrr);
    debug_info = fmt.tprintf(" [%4X](%2X)", destaddrr, dummy);
    return debug_info;
}

alu_transfer::proc (
    src: ^Operand, 
    dest: ^Operand, 
    alu: ^Alu6502,
    dirty: bool
) ->(debug_info: string) {
    srcaddr, ok1 := src.(^u8); assert(ok1);
    destaddrr, ok2 := dest.(^u8); assert(ok2);
    result := srcaddr^;
    destaddrr^ = result;

    if !dirty {
        if result == 0 {
            alu_set_flag(alu, .Z);
        }else{
            alu_clear_flag(alu, .Z);
        }
    
        if result & 0x80 == 0 {
            alu_clear_flag(alu, .N);
        }else{
            alu_set_flag(alu, .N);
        }
    }
    debug_info = fmt.tprintf("(%2X);", result);    
    return debug_info;
}

@(private)
sbc ::proc (
    src: ^Operand, 
    alu: ^Alu6502, 
    bus: ^Bus
) -> (debug_info: string){
    #partial switch choice in src {
        case u8:
            data := choice;
            data = ~data;
            src^ = data;
        case u16:
            data := bus_read_u8(bus, choice);
            data = ~data;
            src^ = data;
        case ^u8:
            assert(false);
    }
    debug_info = alu_arithmetic(src, alu, bus);
    return debug_info;
}

alu_arithmetic ::proc (
    src: ^Operand, 
    alu: ^Alu6502, 
    bus: ^Bus
) -> (debug_info: string) {
    data:u8;
    #partial switch choice in src {
        case u8:
            debug_info = fmt.tprintf(" #%2X", choice);
            data = choice;
        case u16:
            data = bus_read_u8(bus, choice);
            debug_info = fmt.tprintf(" [%4X]", choice);
        case:
            assert(false);
    }
    carry_in := alu_is_flag_set(alu, .C)? 1 : 0;
    result:int = int(i8(alu.regs.A)) + int(i8(data)) + carry_in;
    carry_out := int(alu.regs.A) + int(data) + carry_in;

    if carry_out > 255 {
        alu_set_flag(alu, .C);
    }else{
        alu_clear_flag(alu, .C);
    }

    if result == 0 {
        alu_set_flag(alu, .Z);
    }else{
        alu_clear_flag(alu, .Z);
    }
    
    overflow := (result~int(alu.regs.A)) & (result~int(data));
    alu.regs.A = u8(result & 0x000000FF);
    debug_info = fmt.tprintf("%s (A = %X, carry=%v)", 
    debug_info, alu.regs.A, (carry_out > 255));

    if overflow & 0x80 != 0{
        alu_set_flag(alu, .V);
    }else{
        alu_clear_flag(alu, .V);
    }
    
    if(result & 0x80 == 0){
        alu_clear_flag(alu, .N)
    }
    else{
        alu_set_flag(alu,.N);
    }
    return debug_info;
}

alu_compare::proc (
    src: ^Operand, 
    dest: ^Operand, 
    alu: ^Alu6502, 
    bus: ^Bus
) -> (debug_info: string) {
    memory:u8;
    register, ok := dest.(^u8); assert(ok);
    #partial switch choice in src {
        case u8:
            memory = choice;
            debug_info = fmt.tprintf(" #%2X", choice);
        case u16:
            memory = bus_read_u8(bus, choice);
            debug_info = fmt.tprintf(" [%4X]", choice);
        case:
            assert(false);
    }
    
    result := int(register^) - int(memory);

    if result == 0 {
        alu_set_flag(alu, .Z);
    }else{
        alu_clear_flag(alu, .Z);
    }

    if result >= 0 {
        alu_set_flag(alu, .C);
    }else{
        alu_clear_flag(alu, .C);
    }

    if result & 0x80 == 0 {
        alu_clear_flag(alu, .N);
    }else{
        alu_set_flag(alu, .N);
    }
    return debug_info;
}

alu_branch::proc (
    src: ^Operand, 
    alu: ^Alu6502, 
    flag: Flags, 
    cond: bool
) -> (debug_info: string) {
    eaddr, ok := src.(u16); assert(ok);
    debug_info = fmt.tprintf(" [%4X]", eaddr);
    if (cond && alu_is_flag_set(alu, flag)) || 
    (!cond && alu_is_flag_clear(alu, flag)){
        alu.regs.PC = eaddr;
    }
    return debug_info;
}

alu_inc_or_dec::proc (
    src: ^Operand, 
    alu: ^Alu6502, 
    option: enum(int){INC=1,DEC=-1}, 
    bus: ^Bus,
    dirty: bool
) -> (debug_info: string) {
    result:u8;
    #partial switch eaddr in src {
        case u16:
            data := bus_read_u8(bus, eaddr);
            result = u8(int(data) + int(option));
            bus_write(bus, eaddr, result);
            debug_info = fmt.tprintf(" [%4X](%2X)", eaddr, result);
        case ^u8:
            result = u8(int(eaddr^) + int(option));
            eaddr^ = result;
            debug_info = fmt.tprintf("(%2X);", result);
        case:
            assert(false);
    }
    
    if !dirty {
        if result == 0 {
            alu_set_flag(alu, .Z);
        }else{
            alu_clear_flag(alu, .Z);
        }
    
        if result & 0x80 == 0 {
            alu_clear_flag(alu, .N);
        }else{
            alu_set_flag(alu, .N);
        }
    }
    return debug_info;
}

ShiftDirection::enum{
    RIGHT,
    LEFT,
}

alu_shift::proc (
    src: ^Operand, 
    dir: ShiftDirection, 
    alu: ^Alu6502, 
    bus: ^Bus
) -> (debug_info: string) {
    carry:bool;
    result:u8;
    data:u8;
    #partial switch eaddr in src {
        case ^u8:
            data = eaddr^;
        case u16:
            data = bus_read_u8(bus, eaddr);
        case:
            assert(false);
    }
    if dir == .LEFT {
        carry = (data & 0x80) == 0x80;
        result = data << 1;   
    }else{
        carry = (data & 0x01) == 0x01;
        result = data >> 1;      
    }

    eaddr, ok := src.(^u8);
    if ok {
        eaddr^ = result;
        //debug_info = fmt.tprintf(" r(%X) = (%X);", data, result);
    }else{
        eaddr := src.(u16);
        bus_write(bus, eaddr, result);
        debug_info = fmt.tprintf(" [%4X]", eaddr);
    }

    if carry {
        alu_set_flag(alu, .C);
    }else{
        alu_clear_flag(alu, .C);
    }

    if result == 0 {
        alu_set_flag(alu, .Z);
    }else{
        alu_clear_flag(alu, .Z);
    }
    
    if result & 0x80 == 0 {
        alu_clear_flag(alu, .N);
    }else{
        alu_set_flag(alu, .N);
    }
    
    return debug_info;
}

alu_rotate::proc (
    src: ^Operand, 
    dir: ShiftDirection, 
    alu: ^Alu6502, 
    bus: ^Bus
) -> (debug_info: string) {
    old_carry:bool = alu_is_flag_set(alu, .C);
    new_carry:bool;
    result:u8;
    data:u8;
    #partial switch eaddr in src {
        case ^u8:
            data = eaddr^;
        case u16:
            data = bus_read_u8(bus, eaddr);
        case:
            assert(false);
    }
    if dir == .LEFT {
        new_carry = (data & 0x80) == 0x80; 
        result = (old_carry)? (data << 1) | 1 : (data << 1);
    }else{
        new_carry = (data & 0x01) == 0x01;
        result = (old_carry)? (data >> 1) | 0x80 : (data >> 1);      
    }

    eaddr, ok := src.(^u8);
    if ok {
        eaddr^ = result;
        //debug_info = fmt.tprintf(" r(%X) = (%X);", data, result);
    }else{
        eaddr := src.(u16);
        bus_write(bus, eaddr, result);
        debug_info = fmt.tprintf(" [%4X]", eaddr);
    }

    if new_carry {
        alu_set_flag(alu, .C);
    }else{
        alu_clear_flag(alu, .C);
    }

    if result == 0 {
        alu_set_flag(alu, .Z);
    }else{
        alu_clear_flag(alu, .Z);
    }
    
    if result & 0x80 == 0 {
        alu_clear_flag(alu, .N);
    }else{
        alu_set_flag(alu, .N);
    }
    return debug_info;
}

BitwiseOp::enum{
    AND,
    OR,
    XOR,
    BIT,
}

alu_bitwise::proc (
    src: ^Operand, 
    alu: ^Alu6502, 
    op: BitwiseOp, 
    bus: ^Bus
) -> (debug_info: string) {
    data, result:u8;
    #partial switch eaddr in src {
        case u8:
            data = eaddr
            debug_info = fmt.tprintf(" #%2X", data);
        case u16:
            data = bus_read_u8(bus, eaddr);
            debug_info = fmt.tprintf(" [%4X](%2X)(%2X)", eaddr, data, alu.regs.A);
        case:
            assert(false);
    }

    switch op {
        case .AND:
            result = alu.regs.A & data;
            alu.regs.A = result;
        case .OR:
            result = alu.regs.A | data;
            alu.regs.A = result;
        case .BIT:
            result = alu.regs.A & data;
        case .XOR:
            result = alu.regs.A ~  data;
            alu.regs.A = result;
    }
    //debug_info = fmt.tprintf("%s %X;", debug_info, result);
    if result == 0 {
        alu_set_flag(alu, .Z);
    }else{
        alu_clear_flag(alu, .Z);
    }
    
    if op == .BIT {
        if data & 0x80 == 0 {
            alu_clear_flag(alu, .N);
        }else{
            alu_set_flag(alu, .N);
            debug_info = fmt.tprintf("%s N flag Set", debug_info);
        }

        if data & 0x40 == 0 {
            alu_clear_flag(alu, .V);
        }else{
            alu_set_flag(alu, .V);
        }
    }else{
        if result & 0x80 == 0 {
            alu_clear_flag(alu, .N);
        }else{
            alu_set_flag(alu, .N);
        }
    }
    return debug_info;
}

JumpOp::enum{
    JMP,
    JSR,
    RTS,
    BRK,
    RTI,
}

alu_jump::proc (
    src: ^Operand, 
    alu: ^Alu6502, 
    op: JumpOp, 
    bus: ^Bus
) -> (debug_info: string) {
    pc:u16;
    #partial switch eaddr in src {
        case u16:
            pc = eaddr;
            debug_info = fmt.tprintf(" [%4X](%X)", pc, alu.regs.PC);
        case u32:
            if eaddr & 0x000000FF == 0x000000FF {
                hi := bus_read_u8(bus, u16(eaddr & 0x0000FF00));
                lo := bus_read_u8(bus, u16(eaddr & 0x0000FFFF));
                pc = u16(hi) << 8 | u16(lo);
            }else{
                pc = bus_read_u16(bus, u16(eaddr & 0x0000FFFF));
            }
            debug_info = fmt.tprintf(" [[%4X]](%X)", u16(eaddr), pc);
        case:
    }

    switch op {
        case .BRK:
            alu_set_flag(alu, .B);
            //alu_push(alu, bus, alu.regs.SR);
            alu_set_flag(alu, .I);
            //alu_push_pc(alu, bus);
        case .JSR:
            //fmt.printf("%4X\n",alu.regs.PC);
            alu.regs.PC -= 1;
            alu_push_pc(alu, bus);
            alu.regs.PC = pc;
        case .JMP:
            alu.regs.PC = pc;
        case .RTI:
            alu.regs.SR = alu_pop(alu, bus);
            alu_pop_pc(alu, bus);
        case .RTS:
            alu_pop_pc(alu, bus);
            alu.regs.PC += 1;
            //fmt.printf("%4X\n",alu.regs.PC);
    }
    return debug_info;
}

alu_stack::proc (
    src: ^Operand, 
    alu: ^Alu6502, 
    bus: ^Bus, 
    op: enum{PUSH, PULL}
) -> (debug_info: string) {
    reg, ok := src.(^u8); assert(ok);
    switch op {
        case .PUSH:
            alu_push(alu, bus, reg^);
        case .PULL:
            reg^ = alu_pop(alu, bus);
            debug_info = fmt.tprintf("(%X)", reg^);
    }    
    return debug_info;
}





