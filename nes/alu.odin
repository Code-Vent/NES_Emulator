package nes

import addr "address"

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
    cycles: u8,
}

OpcodeLabel::enum(u8) {
    LDA, STA, LDX, STX, LDY, STY,
    TAX, TXA, TAY, TYA, TXS, TSX,
    ADC, SBC, INC, DEC, INX, DEX, INY, DEY,
    ASL, LSR, ROL, ROR,
    AND, ORA, EOR, BIT,
    CMP, CPX, CPY,
    BCC, BCS, BEQ, BNE, BPL, BMI, BVC, BVS,
    JMP, JSR, RTS, BRK, RTI,
    PHA, PLA, PHP, PLP,//Done
    CLC, SEC, CLI, SEI, CLD, SED, CLV,
    NOP, UND,
}

AddressingLabel::enum(u8) {
    IMP, IMM, ZP0, ZPX, ZPY, REL, ABS, ABX, ABY, IND, IZX, IZY, ACC,
}

Opcode::struct {
    ol:OpcodeLabel,
    al:AddressingLabel,
    cycles: u8,
}


OPCODES:[16][16]Opcode = {
    //    0              1             2             3             4             5             6             7             8             9             A             B             C             D             E             F
    {{.BRK,.IMM,7},{.ORA,.IZX,6},{.UND,.IMP,2},{.UND,.IMP,8},{.NOP,.IMP,3},{.ORA,.ZP0,3},{.ASL,.ZP0,5},{.UND,.IMP,5},{.PHP,.IMP,3},{.ORA,.IMM,2},{.ASL,.ACC,2},{.UND,.IMP,2},{.NOP,.IMP,4},{.ORA,.ABS,4},{.ASL,.ABS,6},{.UND,.IMP,6}},//0
    {{.BPL,.REL,2},{.ORA,.IZY,5},{.UND,.IMP,2},{.UND,.IMP,8},{.NOP,.IMP,4},{.ORA,.ZPX,4},{.ASL,.ZPX,6},{.UND,.IMP,6},{.CLC,.IMP,2},{.ORA,.ABY,4},{.NOP,.IMP,2},{.UND,.IMP,7},{.NOP,.IMP,4},{.ORA,.ABX,4},{.ASL,.ABX,7},{.UND,.IMP,7}},//1
    {{.JSR,.ABS,6},{.AND,.IZX,6},{.UND,.IMP,2},{.UND,.IMP,8},{.BIT,.ZP0,3},{.AND,.ZP0,3},{.ROL,.ZP0,5},{.UND,.IMP,5},{.PLP,.IMP,4},{.AND,.IMM,2},{.ROL,.IMP,2},{.UND,.IMP,2},{.BIT,.ABS,4},{.AND,.ABS,4},{.ROL,.ABS,6},{.UND,.IMP,6}},//2
    {{.BMI,.REL,2},{.AND,.IZY,5},{.UND,.IMP,2},{.UND,.IMP,8},{.NOP,.IMP,4},{.AND,.ZPX,4},{.ROL,.ZPX,6},{.UND,.IMP,6},{.SEC,.IMP,2},{.AND,.ABY,4},{.NOP,.IMP,2},{.UND,.IMP,7},{.NOP,.IMP,4},{.AND,.ABX,4},{.ROL,.ABX,7},{.UND,.IMP,7}},//3
    {{.RTI,.IMP,6},{.EOR,.IZX,6},{.UND,.IMP,2},{.UND,.IMP,8},{.NOP,.IMP,3},{.EOR,.ZP0,3},{.LSR,.ZP0,5},{.UND,.IMP,5},{.PHA,.IMP,3},{.EOR,.IMM,2},{.LSR,.IMP,2},{.UND,.IMP,2},{.JMP,.ABS,3},{.EOR,.ABS,4},{.LSR,.ABS,6},{.UND,.IMP,6}},//4
    {{.BVC,.REL,2},{.EOR,.IZY,5},{.UND,.IMP,2},{.UND,.IMP,8},{.NOP,.IMP,4},{.EOR,.ZPX,4},{.LSR,.ZPX,6},{.UND,.IMP,6},{.CLI,.IMP,2},{.EOR,.ABY,4},{.NOP,.IMP,2},{.UND,.IMP,7},{.NOP,.IMP,4},{.EOR,.ABX,4},{.LSR,.ABX,7},{.UND,.IMP,7}},//5
    {{.RTS,.IMP,6},{.ADC,.IZX,6},{.UND,.IMP,2},{.UND,.IMP,8},{.NOP,.IMP,3},{.ADC,.ZP0,3},{.ROR,.ZP0,5},{.UND,.IMP,5},{.PLA,.IMP,4},{.ADC,.IMM,2},{.ROR,.IMP,2},{.UND,.IMP,2},{.JMP,.IND,5},{.ADC,.ABS,4},{.ROR,.ABS,6},{.UND,.IMP,6}},//6
    {{.BVS,.REL,2},{.ADC,.IZY,5},{.UND,.IMP,2},{.UND,.IMP,8},{.NOP,.IMP,4},{.ADC,.ZPX,4},{.ROR,.ZPX,6},{.UND,.IMP,6},{.SEI,.IMP,2},{.ADC,.ABY,4},{.NOP,.IMP,2},{.UND,.IMP,7},{.NOP,.IMP,4},{.ADC,.ABX,4},{.ROR,.ABX,7},{.UND,.IMP,7}},//7
    {{.NOP,.IMP,2},{.STA,.IZX,6},{.NOP,.IMP,2},{.UND,.IMP,8},{.STY,.ZP0,3},{.STA,.ZP0,3},{.STX,.ZP0,3},{.UND,.IMP,3},{.DEY,.IMP,2},{.NOP,.IMP,2},{.TXA,.IMP,2},{.UND,.IMP,2},{.STY,.ABS,4},{.STA,.ABS,4},{.STX,.ABS,4},{.UND,.IMP,4}},//8
    {{.BCC,.REL,2},{.STA,.IZY,6},{.UND,.IMP,2},{.UND,.IMP,6},{.STY,.ZPX,4},{.STA,.ZPX,4},{.STX,.ZPY,4},{.UND,.IMP,4},{.TYA,.IMP,2},{.STA,.ABY,5},{.TXS,.IMP,2},{.UND,.IMP,5},{.NOP,.IMP,5},{.STA,.ABX,5},{.UND,.IMP,5},{.UND,.IMP,5}},//9
    {{.LDY,.IMM,2},{.LDA,.IZX,6},{.LDX,.IMP,2},{.UND,.IMP,6},{.LDY,.ZP0,3},{.LDA,.ZP0,3},{.LDX,.ZP0,3},{.UND,.IMP,3},{.TAY,.IMP,2},{.LDA,.IMM,2},{.TAX,.IMP,2},{.UND,.IMP,2},{.LDY,.ABS,4},{.LDA,.ABS,4},{.LDX,.ABS,4},{.UND,.IMP,4}},//A
    {{.BCS,.REL,2},{.LDA,.IZY,5},{.UND,.IMP,2},{.UND,.IMP,5},{.LDY,.ZPX,4},{.LDA,.ZPX,4},{.LDX,.ZPY,4},{.UND,.IMP,4},{.CLV,.IMP,2},{.LDA,.ABY,4},{.TSX,.IMP,2},{.UND,.IMP,4},{.LDY,.ABX,4},{.LDA,.ABX,4},{.LDX,.ABY,4},{.UND,.IMP,4}},//B
    {{.CPY,.IMM,2},{.CMP,.IZX,6},{.NOP,.IMP,2},{.UND,.IMP,8},{.CPY,.ZP0,3},{.CMP,.ZP0,3},{.DEC,.ZP0,5},{.UND,.IMP,5},{.INY,.IMP,2},{.CMP,.IMM,2},{.DEX,.IMP,2},{.UND,.IMP,2},{.CPY,.ABS,4},{.CMP,.ABS,4},{.DEC,.ABS,6},{.UND,.IMP,6}},//C
    {{.BNE,.REL,2},{.CMP,.IZY,5},{.UND,.IMP,2},{.UND,.IMP,8},{.NOP,.IMP,4},{.CMP,.ZPX,4},{.DEC,.ZPX,6},{.UND,.IMP,6},{.CLD,.IMP,2},{.CMP,.ABY,4},{.NOP,.IMP,2},{.UND,.IMP,7},{.NOP,.IMP,4},{.CMP,.ABX,4},{.DEC,.ABX,7},{.UND,.IMP,7}},//D
    {{.CPX,.IMM,2},{.SBC,.IZX,6},{.NOP,.IMP,2},{.UND,.IMP,8},{.CPX,.ZP0,3},{.SBC,.ZP0,3},{.INC,.ZP0,5},{.UND,.IMP,5},{.INX,.IMP,2},{.SBC,.IMM,2},{.NOP,.IMP,2},{.SBC,.IMP,2},{.CPX,.ABS,4},{.SBC,.ABS,4},{.INC,.ABS,6},{.UND,.IMP,6}},//E
    {{.BEQ,.REL,2},{.SBC,.IZY,5},{.UND,.IMP,2},{.UND,.IMP,8},{.NOP,.IMP,4},{.SBC,.ZPX,4},{.INC,.ZPX,6},{.UND,.IMP,6},{.SED,.IMP,2},{.SBC,.ABY,4},{.NOP,.IMP,2},{.UND,.IMP,7},{.NOP,.IMP,4},{.SBC,.ABX,4},{.INC,.ABX,7},{.UND,.IMP,7}},//F
};


alu_read_u8_arg::proc (
    self: ^Alu6502, 
    bus: ^addr.Bus, 
    address: u16
) -> u8 {
    data := addr.bus_read_u8(bus, address);
    self.regs.PC = address + 1;
    return data;
}

alu_read_u16_arg::proc (
    self: ^Alu6502, 
    bus: ^addr.Bus, 
    address: u16
) -> u16 {
    data := addr.bus_read_u16(bus, address);
    self.regs.PC = address + 2;
    return data;
}

alu_pop::proc (
    self: ^Alu6502, 
    bus: ^addr.Bus
) -> u8{
    assert(self.regs.SP < 0xff);
    self.regs.SP += 1;
    stack_ptr:u16 = u16(0x100) + u16(self.regs.SP);
    return addr.bus_read_u8(bus, stack_ptr);
}

alu_push::proc (
    self: ^Alu6502, 
    bus: ^addr.Bus, 
    data: u8
){
    assert(self.regs.SP > 0x00);
    stack_ptr:u16 = u16(0x100) + u16(self.regs.SP);
    addr.bus_write(bus, stack_ptr, data);
    self.regs.SP -= 1;
}

alu_push_pc::proc (self: ^Alu6502, bus: ^addr.Bus) {
    lo:u8 = u8((self.regs.PC >> 8) & 0x00FF);
    hi:u8 = u8(self.regs.PC & 0x00FF);
    alu_push(self, bus, lo);
    alu_push(self, bus, hi);
}

alu_pop_pc::proc (self: ^Alu6502, bus: ^addr.Bus) {
    lo := alu_pop(self, bus);
    hi := alu_pop(self, bus);
    self.regs.PC = u16((hi << 8) | lo);
}


alu_set_flag::proc (self: ^Alu6502, flag: Flags) {
    self.regs.SR |= u8(1 << u8(flag));
}

alu_clear_flag::proc (self: ^Alu6502, flag: Flags) {
    self.regs.SR &= ~u8(1 << u8(flag));
}

alu_is_flag_set::proc (self: ^Alu6502, flag: Flags) -> bool {
    return (self.regs.SR & u8(1 << u8(flag))) != 0;
}

alu_is_flag_clear::proc (self: ^Alu6502, flag: Flags) -> bool{
    return (self.regs.SR & u8(1 << u8(flag))) == 0;
}

alu_step::proc (
    self: ^Alu6502, 
    bus: ^addr.Bus
) -> Alu6502_Result {
    byte := alu_read_u8_arg(self, bus, self.regs.PC);
    row := (byte & 0xF0) >> 4;
    col := (byte & 0x0F);
    opcode := OPCODES[row][col];
    src, dest: Operand;
    decode_operand(self, opcode.al, bus, &src);
    decode_operation(self, opcode.ol, bus, &src, &dest);
    return Alu6502_Result{cycles = opcode.cycles};
}

//@(private)
decode_operand::proc (
    self: ^Alu6502, 
    mode: AddressingLabel, 
    bus: ^addr.Bus, 
    opr: ^Operand
) {
    switch(mode){
        case .ABS:
            absolute(self, bus, opr)
        case .ABX:
            absolute_indexed_x(self, bus, opr)
        case .ABY:
            absolute_indexed_y(self, bus, opr)
        case .IMM:
            immediate(self, bus, opr);
        case .IMP,.ACC:
            implied(self, bus, opr);
        case .IND:
            indirect(self, bus, opr)
        case .IZX:
            indirect_indexed_x(self, bus, opr)
        case .IZY:
            indirect_indexed_y(self, bus, opr)
        case .REL:
            relative(self, bus, opr)
        case .ZP0:
            zero_page(self, bus, opr)
        case .ZPX:
            zero_page_indexed_x(self, bus, opr)
        case .ZPY:
            zero_page_indexed_y(self, bus, opr)
    }
}

@(private)
implied::proc (self: ^Alu6502, bus: ^addr.Bus, opr: ^Operand) {
    opr^ = &self.regs.A;
}

@(private)
immediate::proc (self: ^Alu6502, bus: ^addr.Bus, opr: ^Operand) {
    arg:u8 = alu_read_u8_arg(self, bus, self.regs.PC);
    opr^ = arg;
}

@(private)
relative::proc (self: ^Alu6502, bus: ^addr.Bus, opr: ^Operand) {
    arg := alu_read_u8_arg(self, bus, self.regs.PC);
    val := (0x80 & arg != 0)? -1 * int(~(arg - 1)) : int(arg);
    eaddr:int = int(self.regs.PC) + val;
    opr^ = u16(eaddr);
}

@(private)
zero_page_indexed_x::proc (self: ^Alu6502, bus: ^addr.Bus, opr: ^Operand) {
    arg:u8 = alu_read_u8_arg(self, bus, self.regs.PC);
    eaddr:u16 = u16(arg + self.regs.X) & 0x00FF;
    opr^ = eaddr;
}

@(private)
zero_page_indexed_y::proc (self: ^Alu6502, bus: ^addr.Bus, opr: ^Operand) {
    arg:u8 = alu_read_u8_arg(self, bus, self.regs.PC);
    eaddr:u16 = u16(arg + self.regs.Y) & 0x00FF;
    opr^ = eaddr;
}

@(private)
absolute::proc (self: ^Alu6502, bus: ^addr.Bus, opr: ^Operand) {
    arg:u16 = alu_read_u16_arg(self, bus, self.regs.PC);
    opr^ = arg;
}

@(private)
absolute_indexed_x::proc (self: ^Alu6502, bus: ^addr.Bus, opr: ^Operand) {
    arg:u16 = alu_read_u16_arg(self, bus, self.regs.PC);
    eaddr:u16 = u16(arg) + u16(self.regs.X);
    opr^ = eaddr;
}

@(private)
absolute_indexed_y::proc (self: ^Alu6502, bus: ^addr.Bus, opr: ^Operand) {
    arg:u16 = alu_read_u16_arg(self, bus, self.regs.PC);
    eaddr:u16 = u16(arg) + u16(self.regs.Y);
    opr^ = eaddr;
}

@(private)
indirect_indexed_x::proc (self: ^Alu6502, bus: ^addr.Bus, opr: ^Operand) {
    arg:u8 = alu_read_u8_arg(self, bus, self.regs.PC);
    temp:u16 = (u16(arg) + u16(self.regs.X)) & 0x00FF;
    eadrr_lo:u8 = addr.bus_read_u8(bus, temp);
    temp = (u16(arg) + u16(self.regs.X + 1)) & 0x00FF;
    eadrr_hi:u8 = addr.bus_read_u8(bus, temp);
    eaddr := u16(eadrr_hi) << 8 | u16(eadrr_lo);
    opr^ = eaddr;
}

@(private)
indirect_indexed_y::proc (self: ^Alu6502, bus: ^addr.Bus, opr: ^Operand) {
    arg:u8 = alu_read_u8_arg(self, bus, self.regs.PC);
    eadrr_lo:u8 = addr.bus_read_u8(bus, u16(arg));
    temp := u16(arg + 1) & 0x00FF;
    eadrr_hi:u8 = addr.bus_read_u8(bus, temp);
    eaddr := (u16(eadrr_hi) << 8 | u16(eadrr_lo)) + u16(self.regs.Y);
    opr^ = eaddr;
}

@(private)
indirect::proc (self: ^Alu6502, bus: ^addr.Bus, opr: ^Operand) {
    arg:u32 = u32(alu_read_u16_arg(self, bus, self.regs.PC));
    opr^ = arg;
}

@(private)
zero_page::proc (self: ^Alu6502, bus: ^addr.Bus, opr: ^Operand) {
    arg:u8 = alu_read_u8_arg(self, bus, self.regs.PC);
    eaddr:u16 = u16(arg) & 0x00FF;
    opr^ = eaddr;
}

//@(private)
decode_operation::proc (
    self: ^Alu6502, 
    op: OpcodeLabel, 
    bus: ^addr.Bus, 
    src: ^Operand, 
    dest: ^Operand
) {
    #partial switch op {
        case .PHP:
            src^ = &self.regs.SR
            fallthrough
        case .PHA:
            alu_stack(src, self, bus, .PUSH);
        case .PLP:
            src^ = &self.regs.SR
            fallthrough
        case .PLA:
            alu_stack(src, self, bus, .PULL);
        //case TAX, TXA, TAY, TYA, TXS, TSX
        case:
            assert(false);
    }
}


alu_load::proc (
    src: ^Operand, 
    dest: ^Operand, 
    alu: ^Alu6502, 
    bus: ^addr.Bus
) {
    srcaddr, ok1 := src.(u16); assert(ok1);
    result := addr.bus_read_u8(bus, srcaddr);
    destaddrr, ok2 := dest.(^u8); assert(ok2);
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
}

alu_store::proc (src: ^Operand, dest: ^Operand, bus: ^addr.Bus) {
    srcaddr, ok1 := src.(^u8); assert(ok1);
    data := srcaddr^;
    destaddrr, ok2 := dest.(u16); assert(ok2);
    addr.bus_write(bus, destaddrr, data);
}

alu_transfer::proc (src: ^Operand, dest: ^Operand, alu: ^Alu6502) {
    srcaddr, ok1 := src.(^u8); assert(ok1);
    destaddrr, ok2 := dest.(^u8); assert(ok2);
    result := srcaddr^;
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
}

alu_arithmetic::proc (src: ^Operand, alu: ^Alu6502, bus: ^addr.Bus) {
    data:u8;
    #partial switch choice in src {
        case u8:
            data = choice;
        case u16:
            data = addr.bus_read_u8(bus, choice);
        case:
            assert(false);
    }
    carry := alu_is_flag_set(alu, .C)? 1 : 0;
    result:int = int(alu.regs.A) + int(data) + carry;
    alu.regs.A = u8(result & 0x000000FF);
    if result & 0x100 != 0 {
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
    if overflow & 0x80 != 0 {
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
}

alu_compare::proc (src: ^Operand, dest: ^Operand, alu: ^Alu6502, bus: ^addr.Bus) {
    memory:u8;
    #partial switch choice in src {
        case u8:
            memory = choice;
        case u16:
            memory = addr.bus_read_u8(bus, choice);
        case:
            assert(false);
    }
    register, ok := dest.(^u8); assert(ok);
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
}

alu_branch::proc (src: ^Operand, alu: ^Alu6502, flag: Flags, cond: bool) {
    if cond && alu_is_flag_set(alu, flag) || 
    !cond && alu_is_flag_clear(alu, flag){
        eaddr, ok := src.(u16); assert(ok);
        alu.regs.PC = eaddr;
    }
}

alu_inc_or_dec::proc (src: ^Operand, alu: ^Alu6502, option: enum(int){INC=1,DEC=-1}, bus: ^addr.Bus) {
    result:int;
    #partial switch eaddr in src {
        case u16:
            data := addr.bus_read_u8(bus, eaddr);
            result = int(data) + int(option);
            addr.bus_write(bus, eaddr, u8(result));
        case ^u8:
            result = int(eaddr^) + int(option);
            eaddr^ = u8(result);
        case:
            assert(false);
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
}

ShiftDirection::enum{
    RIGHT,
    LEFT,
}

alu_shift::proc (src: ^Operand, dir: ShiftDirection, alu: ^Alu6502, bus: ^addr.Bus) {
    carry:bool;
    result:u8;
    data:u8;
    #partial switch eaddr in src {
        case ^u8:
            data = eaddr^;
        case u16:
            data = addr.bus_read_u8(bus, eaddr);
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
    }else{
        eaddr := src.(u16);
        addr.bus_write(bus, eaddr, result);
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
}

alu_rotate::proc (src: ^Operand, dir: ShiftDirection, alu: ^Alu6502, bus: ^addr.Bus) {
    old_carry:bool = alu_is_flag_set(alu, .C);
    new_carry:bool;
    result:u8;
    data:u8;
    #partial switch eaddr in src {
        case ^u8:
            data = eaddr^;
        case u16:
            data = addr.bus_read_u8(bus, eaddr);
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
    }else{
        eaddr := src.(u16);
        addr.bus_write(bus, eaddr, result);
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
}

BitwiseOp::enum{
    AND,
    OR,
    XOR,
    BIT,
}

alu_bitwise::proc (src: ^Operand, alu: ^Alu6502, op: BitwiseOp, bus: ^addr.Bus) {
    data, result:u8;
    #partial switch eaddr in src {
        case u8:
            data = eaddr
        case u16:
            data = addr.bus_read_u8(bus, eaddr);
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
}

JumpOp::enum{
    JMP,
    JSR,
    RTS,
    BRK,
    RTI,
}

alu_jump::proc (src: ^Operand, alu: ^Alu6502, op: JumpOp, bus: ^addr.Bus) {
    pc:u16;
    #partial switch eaddr in src {
        case u16:
            pc = eaddr;
        case u32:
            pc = addr.bus_read_u16(bus, u16(eaddr));
        case:
            assert(false);
    }

    switch op {
        case .BRK:
            alu_set_flag(alu, .B);
            alu_push(alu, bus, alu.regs.SR);
            alu_set_flag(alu, .I);
            fallthrough;
        case .JSR:
            alu_push_pc(alu, bus);
            fallthrough;
        case .JMP:
            alu.regs.PC = pc;
        case .RTI:
            alu.regs.SR = alu_pop(alu, bus);
            fallthrough;
        case .RTS:
            alu_pop_pc(alu, bus);
    }
}

alu_stack::proc (src: ^Operand, alu: ^Alu6502, bus: ^addr.Bus, op: enum{PUSH, PULL}) {
    reg, ok := src.(^u8); assert(ok);
    switch op {
        case .PUSH:
            alu_push(alu, bus, reg^);
        case .PULL:
            reg^ = alu_pop(alu, bus);
    }
}





