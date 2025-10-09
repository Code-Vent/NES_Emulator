package nes

import "core:fmt"
import "core:os"
import "core:strings"

Disassembler ::struct{
    alu: Alu6502,
    bus: Bus,
    origin: u16,
    left_ptr: u16,
}

@(private)
asm_str: [50]string;

@(private)
disasm := Disassembler{};

@(private)
disasm_mem_map: [1]Addressable;

@(private)
disasm_get ::proc() -> ^Disassembler{
    disasm.origin = cpu.alu.regs.PC;
    disasm.left_ptr = cpu.alu.regs.PC;

    disasm_mem_map[0] = new_address_space(&disasm, 0x0000, 0xFFFF,0xFFFF);
    disasm.bus = new_bus(disasm_mem_map[:]);  



    return &disasm;
}

@(private)
disasm_load ::proc(){

}

disasm_all ::proc(self: ^Disassembler) -> string {
    pc := self.origin;
    result: string;
    for pc < 0xFFFA  {
        self.alu.regs.PC = pc
        value := alu_read_u8_arg(&self.alu, &self.bus);
        row := (value & 0xF0) >> 4;
        col := (value & 0x0F);
        opcode := OPCODES[row][col];
        src, dest: Operand;
        size := decode_operand(&self.alu, opcode.al, &self.bus, &src);
        debug_info := decode_operation(&self.alu, opcode.ol, &self.bus, &src, &dest);
        debug_info = fmt.tprintf("%x %2x %s %s\r\n", pc, value, opcode.txt, debug_info);
        //fmt.println(debug_info);
        result = fmt.tprintf("%s %s", result, debug_info);
        pc += u16(size);
    }
    return result;
}

disasm_run_test ::proc(
    self: ^Disassembler, 
    start_from: u16, 
    expected: []string,
) -> (ok:bool, error_msg: string) {
    cpu.alu.regs.PC = start_from;
    result: string;
    
    if expected == nil {
        return false, "No expected results";
    }

    no_of_lines := len(expected) - 1;
    for i in 0..<no_of_lines  { 
        pc := cpu.alu.regs.PC;       
        value := alu_read_u8_arg(cpu.alu, &cpu.bus);
        row := (value & 0xF0) >> 4;
        col := (value & 0x0F);
        opcode := OPCODES[row][col];
        src, dest: Operand;
        size := decode_operand(cpu.alu, opcode.al, &cpu.bus, &src);
        debug_info := decode_operation(cpu.alu, opcode.ol, &cpu.bus, &src, &dest);
        debug_info = fmt.tprintf("%4X %2X %s %s\r\n", pc, value, opcode.txt, debug_info);
        result = fmt.tprintf("%s %s", result, debug_info);
    }
    os.write_entire_file("disasm_test.txt", transmute([]u8)result);
    lines := strings.split(result, "\n");    

    for i in 0..<no_of_lines {
        e := strings.trim(expected[i], " ");
        l := strings.trim(lines[i], " ");
        if e[:5] != l[:5] {
            return false, fmt.tprintf(
                "Mismatch at line %d: expected '%s' but got '%s'", 
                i+1, e, l
            );
        }
    }
    return true, "";
}


disasm_write ::proc(self: ^Disassembler, addr: u16, data: u8){

}

disasm_read ::proc(self: ^Disassembler, addr: u16) -> u8{
    return bus_read_u8(&cpu.bus, addr);
}

