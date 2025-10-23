package micro

import "core:fmt"
import "../../Calculator/calc"
import "../../Cartridge/cart"


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
    /*80*/{{"NOP",.NOP,.IMM,2},{"STA",.STA,.IZX,6},{"NOP",.NOP,.IMM,2},{"SAX",.SAX,.IZX,6},{"STY",.STY,.ZP0,3},{"STA",.STA,.ZP0,3},{"STX",.STX,.ZP0,3},{"SAX",.SAX,.ZP0,3},{"DEY",.DEY,.IMP,2},{"NOP",.NOP,.IMM,2},{"TXA",.TXA,.IMP,2},{"XAA",.XAA,.IMM,2},{"STY",.STY,.ABS,4},{"STA",.STA,.ABS,4},{"STX",.STX,.ABS,4},{"SAX",.SAX,.ABS,4}},//8
    /*80*/{{"BCC",.BCC,.REL,2},{"STA",.STA,.IZY,6},{"UND",.UND,.IMP,2},{"AHX",.AHX,.IZY,6},{"STY",.STY,.ZPX,4},{"STA",.STA,.ZPX,4},{"STX",.STX,.ZPY,4},{"SAX",.SAX,.ZPY,4},{"TYA",.TYA,.IMP,2},{"STA",.STA,.ABY,5},{"TXS",.TXS,.IMP,2},{"TAS",.TAS,.ABY,5},{"NOP",.SHY,.ABX,5},{"STA",.STA,.ABX,5},{"SHX",.SHX,.ABY,5},{"AHX",.AHX,.ABY,5}},//9
    /*A0*/{{"LDY",.LDY,.IMM,2},{"LDA",.LDA,.IZX,6},{"LDX",.LDX,.IMM,2},{"LAX",.LAX,.IZX,6},{"LDY",.LDY,.ZP0,3},{"LDA",.LDA,.ZP0,3},{"LDX",.LDX,.ZP0,3},{"LAX",.LAX,.ZP0,3},{"TAY",.TAY,.IMP,2},{"LDA",.LDA,.IMM,2},{"TAX",.TAX,.IMP,2},{"LAX",.LAX,.IMM,2},{"LDY",.LDY,.ABS,4},{"LDA",.LDA,.ABS,4},{"LDX",.LDX,.ABS,4},{"LAX",.LAX,.ABS,4}},//A
    /*A0*/{{"BCS",.BCS,.REL,2},{"LDA",.LDA,.IZY,5},{"UND",.UND,.IMP,2},{"LAX",.LAX,.IZY,5},{"LDY",.LDY,.ZPX,4},{"LDA",.LDA,.ZPX,4},{"LDX",.LDX,.ZPY,4},{"LAX",.LAX,.ZPY,4},{"CLV",.CLV,.IMP,2},{"LDA",.LDA,.ABY,4},{"TSX",.TSX,.IMP,2},{"LAS",.LAS,.ABY,4},{"LDY",.LDY,.ABX,4},{"LDA",.LDA,.ABX,4},{"LDX",.LDX,.ABY,4},{"LAX",.LAX,.ABY,4}},//B
    /*C0*/{{"CPY",.CPY,.IMM,2},{"CMP",.CMP,.IZX,6},{"NOP",.NOP,.IMM,2},{"DCP",.DCP,.IZX,8},{"CPY",.CPY,.ZP0,3},{"CMP",.CMP,.ZP0,3},{"DEC",.DEC,.ZP0,5},{"DCP",.DCP,.ZP0,5},{"INY",.INY,.IMP,2},{"CMP",.CMP,.IMM,2},{"DEX",.DEX,.IMP,2},{"AXS",.AXS,.IMM,2},{"CPY",.CPY,.ABS,4},{"CMP",.CMP,.ABS,4},{"DEC",.DEC,.ABS,6},{"DCP",.DCP,.ABS,6}},//C
    /*C0*/{{"BNE",.BNE,.REL,2},{"CMP",.CMP,.IZY,5},{"UND",.UND,.IMP,2},{"DCP",.DCP,.IZY,8},{"NOP",.NOP,.ZPX,4},{"CMP",.CMP,.ZPX,4},{"DEC",.DEC,.ZPX,6},{"DCP",.DCP,.ZPX,6},{"CLD",.CLD,.IMP,2},{"CMP",.CMP,.ABY,4},{"NOP",.NOP,.IMP,2},{"DCP",.DCP,.ABY,7},{"NOP",.NOP,.ABX,4},{"CMP",.CMP,.ABX,4},{"DEC",.DEC,.ABX,7},{"DCP",.DCP,.ABX,7}},//D
    /*E0*/{{"CPX",.CPX,.IMM,2},{"SBC",.SBC,.IZX,6},{"NOP",.NOP,.IMM,2},{"ISC",.ISC,.IZX,8},{"CPX",.CPX,.ZP0,3},{"SBC",.SBC,.ZP0,3},{"INC",.INC,.ZP0,5},{"ISC",.ISC,.ZP0,5},{"INX",.INX,.IMP,2},{"SBC",.SBC,.IMM,2},{"NOP",.NOP,.IMP,2},{"SBC",.SBC,.IMM,2},{"CPX",.CPX,.ABS,4},{"SBC",.SBC,.ABS,4},{"INC",.INC,.ABS,6},{"ISC",.ISC,.ABS,6}},//E
    /*E0*/{{"BEQ",.BEQ,.REL,2},{"SBC",.SBC,.IZY,5},{"UND",.UND,.IMP,2},{"ISC",.ISC,.IZY,8},{"NOP",.NOP,.ZPX,4},{"SBC",.SBC,.ZPX,4},{"INC",.INC,.ZPX,6},{"ISC",.ISC,.ZPX,6},{"SED",.SED,.IMP,2},{"SBC",.SBC,.ABY,4},{"NOP",.NOP,.IMP,2},{"ISC",.ISC,.ABY,7},{"NOP",.NOP,.ABX,4},{"SBC",.SBC,.ABX,4},{"INC",.INC,.ABX,7},{"ISC",.ISC,.ABX,7}},//F
};

decode_instruction::proc (
    mcu: ^M6502, 
    op: OpcodeLabel
) {
    
    switch op {
        case .PHP:
            write_flag(mcu, .BREAK, true);
            flags := calc.ref_flags(&mcu.alu)^;
            push_stack(mcu, flags);
        case .PHA:
            a := get_R(&mcu.alu, A);
            push_stack(mcu, a);
        case .PLP:
            flags := pop_stack(mcu);
            calc.ref_flags(&mcu.alu)^ = flags;
        case .PLA:
            a := pop_stack(mcu);
            set_R(&mcu.alu, W0, a);
            calc.copy_register(&mcu.alu, W0, A);
        case .TAX:
            calc.copy_register(&mcu.alu, A, X);
        case .TXA:
            calc.copy_register(&mcu.alu, X, A);
        case .TAY:
            calc.copy_register(&mcu.alu, A, Y);
        case .TYA:
            calc.copy_register(&mcu.alu, Y, A);
        case .TXS:
            mcu.sp = get_R(&mcu.alu, X);
        case .TSX:
            set_R(&mcu.alu, W1, mcu.sp);
            calc.copy_register(&mcu.alu, W1, X);
        case .LDA:
            value := fetch_operand(mcu);
            set_R(&mcu.alu, W0, value);
            calc.copy_register(&mcu.alu, W0, A);
        case .STA:
            result := get_R(&mcu.alu, A);
            store_result(mcu, result);
        case .LDX:
            value := fetch_operand(mcu);
            set_R(&mcu.alu, W0, value);
            calc.copy_register(&mcu.alu, W0, X);
        case .STX:
            result := get_R(&mcu.alu, X);
            store_result(mcu, result);
        case .LDY:
            value := fetch_operand(mcu);
            set_R(&mcu.alu, W0, value);
            calc.copy_register(&mcu.alu, W0, Y);
        case .STY:
            result := get_R(&mcu.alu, Y);
            store_result(mcu, result);
        case .CMP:
            value := fetch_operand(mcu);
            calc.alu_operation(&mcu.alu, .CMP, value, A);
        case .CPX:
            value := fetch_operand(mcu);
            calc.alu_operation(&mcu.alu, .CMP, value, X);
        case .CPY:
            value := fetch_operand(mcu);
            calc.alu_operation(&mcu.alu, .CMP, value, Y);
        case .BCC:
            branch_if(mcu, 
                calc.read_flag(&mcu.alu, .CARRY) == false
            );
        case .BCS:
            branch_if(mcu, 
                calc.read_flag(&mcu.alu, .CARRY) == true
            );
        case .BEQ:
            branch_if(mcu, 
                calc.read_flag(&mcu.alu, .ZERO) == true
            );
        case .BNE:
            branch_if(mcu, 
                calc.read_flag(&mcu.alu, .ZERO) == false
            );
        case .BPL:
            branch_if(mcu, 
                calc.read_flag(&mcu.alu, .NEGATIVE) == false
            );
        case .BMI:
            branch_if(mcu, 
                calc.read_flag(&mcu.alu, .NEGATIVE) == true
            );
        case .BVC:
            branch_if(mcu, 
                calc.read_flag(&mcu.alu, .OVERFLOW) == false
            );
        case .BVS:
            branch_if(mcu, 
                calc.read_flag(&mcu.alu, .OVERFLOW) == true
            );
        case .CLC:
            calc.write_flag(&mcu.alu, .CARRY, false);
        case .SEC:
            calc.write_flag(&mcu.alu, .CARRY, true);
            //fmt.printf("Carry Flag is %v\n", calc.read_flag(&mcu.alu, .CARRY));
        case .CLI:
            write_flag(mcu, .INTERRUPT, false);
        case .SEI:
            write_flag(mcu, .INTERRUPT, true);
        case .CLD:
            write_flag(mcu, .DECIMAL, false);
        case .SED:
            write_flag(mcu, .DECIMAL, true);
        case .CLV:
            calc.write_flag(&mcu.alu, .OVERFLOW, false);
        case .NOP:
            //Do nothing
        case .JMP:
            branch_if(mcu, true);
        case .JSR:
            mcu.pc -= 1;
            push_pc_to_stack(mcu);
            branch_if(mcu, true);
        case .RTS:  
            pop_pc_from_stack(mcu);
            mcu.pc += 1;
        case .BRK:
            write_flag(mcu, .BREAK, true);
            write_flag(mcu, .INTERRUPT, true);
            flags := calc.ref_flags(&mcu.alu)^;
            push_stack(mcu, flags);            
            push_pc_to_stack(mcu);
            mcu.pc = 0xFFFE;
        case .RTI:
            flags := pop_stack(mcu);
            calc.ref_flags(&mcu.alu)^ = flags;
            pop_pc_from_stack(mcu);
        case .ADC:
            val := fetch_operand(mcu);
            debug_info := calc.alu_operation(&mcu.alu, .ADC, val, A);
            mcu.log = fmt.tprintf("%s %s", mcu.log, debug_info);
        case .SBC:
            val := fetch_operand(mcu);
            calc.alu_operation(&mcu.alu, .SBC, val, A);
        case .INC:
            val := fetch_operand(mcu);
            set_R(&mcu.alu, W1, val);
            calc.alu_operation(&mcu.alu, .INC, 0, W1);
            result := get_R(&mcu.alu, W1);
            store_result(mcu, result);
        case .INX:
            calc.alu_operation(&mcu.alu, .INC, 0, X);
        case .INY:
            calc.alu_operation(&mcu.alu, .INC, 0, Y);
        case .DEC:
            val := fetch_operand(mcu);
            set_R(&mcu.alu, W1, val);
            calc.alu_operation(&mcu.alu, .DEC, val, W1);
            result := get_R(&mcu.alu, W1);
            store_result(mcu, result);
        case .DEX:
            calc.alu_operation(&mcu.alu, .DEC, 0, X);
        case .DEY:
            calc.alu_operation(&mcu.alu, .DEC, 0, Y);
        case .ASL:
            val := fetch_operand(mcu);
            calc.alu_operation(&mcu.alu, .ASL, val, W1);
            result := get_R(&mcu.alu, W1);
            store_result(mcu, result);
        case .LSR:
            val := fetch_operand(mcu);
            calc.alu_operation(&mcu.alu, .LSR, val, W1);
            result := get_R(&mcu.alu, W1);
            store_result(mcu, result);
        case .ROL:
            val := fetch_operand(mcu);
            calc.alu_operation(&mcu.alu, .ROL, val, W1);
            result := get_R(&mcu.alu, W1);
            store_result(mcu, result);
        case .ROR:
            val := fetch_operand(mcu);
            calc.alu_operation(&mcu.alu, .ROR, val, W1);
            result := get_R(&mcu.alu, W1);
            store_result(mcu, result);
        case .AND:
            val := fetch_operand(mcu);
            calc.alu_operation(&mcu.alu, .AND, val, A);
        case .ORA:
            val := fetch_operand(mcu);
            calc.alu_operation(&mcu.alu, .OR, val, A);
        case .EOR:
            val := fetch_operand(mcu);
            calc.alu_operation(&mcu.alu, .XOR, val, A);
        case .BIT:
            val := fetch_operand(mcu);
            calc.alu_operation(&mcu.alu, .BIT, val, A);
        //uNDOCUMENTED CODES
        //UND, SLO, RLA, SRE, RRA, SAX, AHX, LAX, DCP, ISC,
        //ANC, ALR, XAA, TAS, LAS, AXS, SHX, ARR, SHY
        case .LAX:
            val := fetch_operand(mcu);
            set_R(&mcu.alu, A, val);
            calc.copy_register(&mcu.alu, A, X);
        case .AHX:
            addr, ok := mcu.src.(u16); assert(ok);
            hi := (addr & 0xFF00) >> 8;
            result := get_R(&mcu.alu, A) & get_R(&mcu.alu, X) & u8(hi + 1);
            store_result(mcu, result);
        case .ARR://Not sure implementation is correct
            val := fetch_operand(mcu);
            calc.alu_operation(&mcu.alu, .AND, val, W1);
            result := get_R(&mcu.alu, W1);
            calc.alu_operation(&mcu.alu, .ROR, result, A);
            //store_result(mcu, result);
        case .SAX:
            result := get_R(&mcu.alu, A) & get_R(&mcu.alu, X);
            store_result(mcu, result);
            //debug_info = fmt.tprintf("%s(A=%2X)(X=%2X)(AX=%2X)", debug_info, self.regs.A, self.regs.X, ax);
        case .RRA:
            val := fetch_operand(mcu);
            calc.alu_operation(&mcu.alu, .ROR, val, W1);
            result := get_R(&mcu.alu, W1);
            calc.alu_operation(&mcu.alu, .ADC, result, A);
            store_result(mcu, result);
        case .SLO:
            val := fetch_operand(mcu);
            calc.alu_operation(&mcu.alu, .ASL, val, W1);
            result := get_R(&mcu.alu, W1);
            calc.alu_operation(&mcu.alu, .OR, result, A);
            store_result(mcu, result);
        case .SRE:
            val := fetch_operand(mcu);
            calc.alu_operation(&mcu.alu, .LSR, val, W1);
            result := get_R(&mcu.alu, W1);
            calc.alu_operation(&mcu.alu, .XOR, result, A);
            store_result(mcu, result);
        case .RLA:
            val := fetch_operand(mcu);
            calc.alu_operation(&mcu.alu, .ROL, val, W1);
            result := get_R(&mcu.alu, W1);
            calc.alu_operation(&mcu.alu, .AND, result, A);
            store_result(mcu, result);
        case .DCP:
            result := fetch_operand(mcu) - 1;
            calc.alu_operation(&mcu.alu, .CMP, result, A);
            store_result(mcu, result);
        case .ISC:
            val := fetch_operand(mcu);
            result := val + 1;
            calc.alu_operation(&mcu.alu, .SBC, result, A);
            store_result(mcu, result);
        case .ALR:
            val := fetch_operand(mcu);
            calc.lock_flags(&mcu.alu);
            calc.alu_operation(&mcu.alu, .AND, val, A);
            calc.unlock_flags(&mcu.alu);
            result := get_R(&mcu.alu, A);
            calc.alu_operation(&mcu.alu, .LSR, result, A);
        case .ANC:
            val := fetch_operand(mcu);
            calc.alu_operation(&mcu.alu, .AND, val, A);
            f := calc.read_flag(&mcu.alu, .NEGATIVE);
            calc.write_flag(&mcu.alu, .CARRY, f);
        case .AXS:
            val1 := get_R(&mcu.alu, A) & get_R(&mcu.alu, X);
            val2 := fetch_operand(mcu);
            result := u8(i8(val1) - i8(val2));
            set_R(&mcu.alu, W1, result);
            calc.copy_register(&mcu.alu, W1, X);
            calc.write_flag(&mcu.alu, .CARRY, val1 >= val2);
        case .LAS:
            val := fetch_operand(mcu);
            set_R(&mcu.alu, A, mcu.sp);
            calc.lock_flags(&mcu.alu);
            calc.alu_operation(&mcu.alu, .AND, val, A);
            calc.copy_register(&mcu.alu, A, X);
            calc.unlock_flags(&mcu.alu);
            mcu.sp = get_R(&mcu.alu, A);
        case .TAS:
            mcu.sp = get_R(&mcu.alu, A) & get_R(&mcu.alu, X);
            addr, ok := mcu.src.(u16); assert(ok);
            hi := (addr & 0xFF00) >> 8;
            result := mcu.sp & u8(hi + 1);
            store_result(mcu, result);
        case .XAA:
        case .SHX:
            addr, ok := mcu.src.(u16); assert(ok);
            hi := (addr & 0xFF00) >> 8;
            result := get_R(&mcu.alu, X) & u8(hi + 1);
            store_result(mcu, result);
        case .SHY:
            addr, ok := mcu.src.(u16); assert(ok);
            hi := (addr & 0xFF00) >> 8;
            result := get_R(&mcu.alu, Y) & u8(hi + 1);
            store_result(mcu, result);
        case .UND:
            //assert(false);
    }
    //return debug_info;
}

fetch_operand ::proc(mcu: ^M6502) -> u8 {
    data: u8;
    switch choice in mcu.src {
        case u8:
            data = choice;
        case u16:
            data = read_bus(mcu, choice)[0];
        case calc.Register:
            data = calc.read_register(&mcu.alu, choice);
        case:
            data = 0xCC;
    }
    mcu.log = fmt.tprintf("%s fetched($%2X)", mcu.log, data);
    return data;
}

store_result ::proc(mcu: ^M6502, result: u8) {
    switch choice in mcu.src {
        case u8:
            assert(false);
        case u16:
            write_bus(mcu, choice, result);
            mcu.log = fmt.tprintf("%s stored($%2X at $%4X)", mcu.log, result, choice);
        case calc.Register:
            calc.write_register(&mcu.alu, choice, result);
            mcu.log = fmt.tprintf("%s stored($%2X in %v)", mcu.log, result, choice);
    }
}

branch_if ::proc(mcu: ^M6502, cond: bool) {
    if cond {

        goto, ok := mcu.src.(u16); assert(ok);
        mcu.pc = goto;
    }
}

pop_stack ::proc(mcu: ^M6502) -> u8{
    data := u8(0xCC);
    if mcu.sp < 0xff {
        mcu.sp += 1;
        stack_ptr := u16(0x100) + u16(mcu.sp);
        data = read_bus(mcu, stack_ptr)[0];
    }
    mcu.log = fmt.tprintf("%s pulled($%2X)", mcu.log, data);
    return data;
}

push_stack ::proc(mcu: ^M6502, data: u8) {
    if mcu.sp > 0x00 {
        stack_ptr := u16(0x100) + u16(mcu.sp);
        write_bus(mcu, stack_ptr, data);
        mcu.sp -= 1;
        mcu.log = fmt.tprintf("%s pushed($%2X)", mcu.log, data);
    }
}

push_pc_to_stack ::proc (mcu: ^M6502) {
    hi := u8((mcu.pc >> 8) & 0x00FF);
    lo := u8(mcu.pc & 0x00FF);
    push_stack(mcu, hi);
    push_stack(mcu, lo);
    //fmt.println(self.regs.PC);
}

pop_pc_from_stack ::proc (mcu: ^M6502) {
    lo := pop_stack(mcu);
    hi := pop_stack(mcu);
    mcu.pc = u16(hi) << 8 | u16(lo);
    //fmt.println(self.regs.PC);
}