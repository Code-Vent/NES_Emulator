package calc

import "core:fmt"

carryFlagMask :u8:(1<<0);
zeroFlagMask :u8:(1<<1);
overflowFlagMask :u8:(1<<6);
negativeFlagMask :u8:(1<<7);

Option ::enum{
	ADD, ADC, SUB, SBC,
	AND, OR, XOR, BIT,
	LSR, ASL, ROR, ROL,
	INC, DEC,
	CMP,
};

Register ::enum(u8){
	R0=0, R1=1, R2=2, R3=3, R4=4, R5=5,
};

Flag ::enum(u8){
	CARRY    = (1<<0), 
	ZERO     = (1<<1), 
	OVERFLOW = (1<<6), 
	NEGATIVE = (1<<7),
};

Calc8 ::struct{
    rx :[6]u8,
	flag0 :u8,
	flag1 :u8,
	flags_locked :bool,
};

alu_operation ::proc(
	calc: ^Calc8, 
	op: Option, 
	value: u8, 
	r := Register.R0
) -> (debug_info:string){
	save_flags(calc);
	switch (op)
	{
	case .ADD:
		add(calc, value, r);
	case .ADC:
		debug_info = adc(calc, value, r);
	case .SUB:
		add(calc, ~value, r);
	case .SBC:
		adc(calc, ~value, r);
	case .BIT:
		v := calc.rx[r] & value;
		write_flag(calc, .ZERO, v == 0);
		write_flag(calc, .NEGATIVE, (value & 0x80) != 0);
		write_flag(calc, .OVERFLOW, (value & 0x40) != 0);		
	case .AND:
		calc.rx[r] &= value;
		update_ZN_flags(calc, calc.rx[r]);
	case .OR:
		calc.rx[r] |= value;
		update_ZN_flags(calc, calc.rx[r]);
	case .XOR:
		calc.rx[r] ~= value;
		update_ZN_flags(calc, calc.rx[r]);
	case .LSR:
		write_flag(calc, .CARRY, (value & 0x01) != 0);
		calc.rx[r] = value >> 1;
		update_ZN_flags(calc, calc.rx[r]);
	case .ASL:
		write_flag(calc, .CARRY, (value & 0x80) != 0);
		calc.rx[r] = value << 1;
		update_ZN_flags(calc, calc.rx[r]);
	case .ROR:
		write_flag(calc, .CARRY, (value & 0x01) != 0);
		calc.rx[r] = value >> 1;
		calc.rx[r] |= ((calc.flag1 & transmute(u8)Flag.CARRY) != 0) ? 0x80 : 0;
		update_ZN_flags(calc, calc.rx[r]);
	case .ROL:
		write_flag(calc, .CARRY, (value & 0x80) != 0);
		calc.rx[r] = value << 1;
		calc.rx[r] |= ((calc.flag1 & transmute(u8)Flag.CARRY) != 0) ? 0x01 : 0;
		update_ZN_flags(calc, calc.rx[r]);
	case .INC:
		val := read_register(calc, r) + 1;
		write_register(calc, r, val);
		update_ZN_flags(calc, val);
	case .DEC:
		val := read_register(calc, r) - 1;
		write_register(calc, r, val);
		update_ZN_flags(calc, val);
	case .CMP:
		write_flag(calc, .CARRY, calc.rx[r] >= value);
		write_flag(calc, .ZERO, calc.rx[r] == value);
		result := calc.rx[r] - value;
		write_flag(calc, .NEGATIVE, (result & 0x80) != 0);
	}
	return debug_info;
}

read_register ::proc(calc: ^Calc8, r: Register) -> u8 {
    return calc.rx[r];
}

write_register ::proc(calc: ^Calc8, r: Register, value: u8) {
    calc.rx[r] = value;
}

read_flag ::proc(calc: ^Calc8, f: Flag) -> bool {
    return (calc.flag0 & transmute(u8)f) != 0;
}

ref_flags ::proc(calc: ^Calc8) -> ^u8 {
    return &calc.flag0;
}

write_flag ::proc(calc: ^Calc8, f: Flag, value: bool) {
	if calc.flags_locked {
		return;
	}
	mask := transmute(u8)f;
    if value {
		calc.flag0 |= mask;
	}
	else {
		calc.flag0 &= ~mask;
	}
}

copy_register ::proc(calc: ^Calc8, from: Register, to: Register) {
	val := calc.rx[from];
    calc.rx[to] = val;
	update_ZN_flags(calc, val);
}

save_flags ::proc(calc: ^Calc8) {
    calc.flag1 = calc.flag0;
}

restore_flags ::proc(calc: ^Calc8) {
    calc.flag0 = calc.flag1;
}

restore_flag ::proc(calc: ^Calc8, f: Flag) {
    calc.flag0 |= (calc.flag1 & transmute(u8)f);
}

add ::proc(calc: ^Calc8, value: u8, r: Register) {
	r9 := &calc.rx[r];
	result := int(i8(r9^)) + int(i8(value));
	carry_out := int(r9^) + int(value);

	write_flag(calc, .CARRY, carry_out > 255);
	write_flag(calc, .ZERO, result == 0);

	overflow := (result ~ int(r9^)) & (result ~ int(value));
	r9^ = u8(result & 0x000000FF);

	write_flag(calc, .OVERFLOW, overflow != 0);
	write_flag(calc, .NEGATIVE, (result & 0x80) != 0);
}

adc ::proc(
	calc: ^Calc8, 
	value: u8, 
	r: Register
) -> (debug_info:string){
	
	r9 := &calc.rx[r];
	carry_in := read_flag(calc, .CARRY) ? 1 : 0;
	sum := int(i8(r9^)) + int(i8(value)) + carry_in;
	carry_out := int(r9^) + int(value) + carry_in;
	result := u8(sum & 0x000000FF);
	
	write_flag(calc, .CARRY, carry_out > 255);
	write_flag(calc, .ZERO, result == 0);

	overflow := (result ~ (r9^)) & (result ~ value);
	r9^ = result;
	
	write_flag(calc, .OVERFLOW, (overflow & 0x80) != 0);
	write_flag(calc, .NEGATIVE, (result & 0x80) != 0);
	C := read_flag(calc, .CARRY);
	Z := read_flag(calc, .ZERO);
	N := read_flag(calc, .NEGATIVE);
	V := read_flag(calc, .OVERFLOW);
	debug_info = fmt.tprintf("($%2X) Flags(Z = %v, C = %v, N = %v, V = %v)",r9^,Z,C,N,overflow);
	return debug_info;
}

update_ZN_flags ::proc(calc: ^Calc8, result: u8) {
	write_flag(calc, .ZERO, result == 0);
	write_flag(calc, .NEGATIVE, (result & 0x80) != 0);
}

lock_flags ::proc(calc: ^Calc8) {
	calc.flags_locked = true;
}

unlock_flags ::proc(calc: ^Calc8) {
	calc.flags_locked = false;
}