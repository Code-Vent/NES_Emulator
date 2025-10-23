package micro

import "../../Cartridge/cart"
import "core:fmt"
import "core:os"
import "core:strings"


disasm_run_test ::proc(
    mcu: ^M6502, 
    start_from: u16, 
    expected: []string,
) -> (ok:bool, error_msg: string) {
    
    mcu.pc = start_from;
    result: string;
    
    if expected == nil {
        return false, "No expected results";
    }

    no_of_lines := len(expected) - 1;
    for i in 0..<no_of_lines  { 
        debug_info := decode(mcu);
        //fmt.printfln("%d %s", i+1, debug_info);
        e := strings.trim(expected[i], " ");
        l := strings.trim(debug_info, " ");
        if e[:5] != l[:5] {
            return false, fmt.tprintf(
                "Mismatch at line %d: expected '%s' but got '%s'", 
                i+1, e, l
            );
        }
        result = fmt.tprintf("%s %s", result, debug_info);
        
    }
    os.write_entire_file("disasm_test.txt", transmute([]u8)result);
    return true, "";
}