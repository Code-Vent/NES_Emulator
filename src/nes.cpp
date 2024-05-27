#include"nes.h"

NES::NES(MemType* mem)
	:ram(mem, ram_size), cpu_core(), cpu(),isa(R6502<ProgramCounter>(&ram, &cpu))
{
	assert(mem != nullptr);
	cpu = MemoryMappedDevice<RegType>(mem + ram_size, CpuCore::no_of_cpu_regs, &cpu_core);
	isa.Try();
}

NES::~NES()
{
}
