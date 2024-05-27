#include"cpu.h"
#include<memory.h>


void CpuCore::Init() const
{
	memset(registers, 0, sizeof(registers[0]) * no_of_cpu_regs);
	stk = registers + (sizeof(registers[0]) * no_of_cpu_regs) + (stack_size - 1);
	registers[STACK_POINTER].load(stack_size - 1);
	return;
}

void CpuCore::update() const
{
}

void CpuCore::load_register(Register r, uint8_t value)const
{
	registers[r].load(value);
	return;
}

Memory<RegType>* CpuCore::get_register(Register r)const
{
	return &registers[r];
}

void CpuCore::ADDC(Memory<MemType>* mem)const
{
	uint16_t m = (uint16_t)mem->read();
	addc(m);
}

void CpuCore::SUBC(Memory<MemType>* mem)const
{
	uint16_t m = (uint16_t)mem->read() ^ 0x00FF;
	addc(m);
}

void CpuCore::push(uint8_t c)const
{
	auto sp = registers[STACK_POINTER].read();
	if (sp) {
		stk[sp].load(c);
		registers[STACK_POINTER].load(sp - 1);
	}
}

uint8_t CpuCore::pop()const
{
	auto sp = registers[STACK_POINTER].read();
	assert(sp < stack_size - 1);
	uint8_t t = stk[sp].read();
	registers[STACK_POINTER].load(sp + 1);
	return t;
}

void CpuCore::set_flag(Flag f, bool value)const
{
	if (value)
		set(f);
	else
		clear(f);
}

void CpuCore::set(Flag f)const
{
	registers[STATUS].set_bit(f);
}

void CpuCore::clear(Flag f)const
{
	registers[STATUS].clear_bit(f);
}

uint8_t CpuCore::get_flag(Flag f)const
{
	return registers[STATUS].at(f);
}

void CpuCore::addc(uint16_t m)const
{
	uint16_t a = (uint16_t)registers[ACCUMULATOR].read();
	uint16_t f = (uint16_t)get_flag(Flag::C);
	uint16_t r = a + m + f;
	registers[ACCUMULATOR].load(0x00FF & r);
	set_flag(Flag::C, r & 0x0100);
	set_flag(Flag::Z, r == 0x0000);
	set_flag(Flag::N, r & 0x80);
	auto v = ((~((uint16_t)a ^ (uint16_t)m) & ((uint16_t)a ^ (uint16_t)r)) & 0x0080);
	set_flag(Flag::V, v);
}


