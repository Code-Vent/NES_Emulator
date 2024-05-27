#pragma once
#include"cpu.h"
#include"r6502.h"
#include<stdint.h>


class NES {
public:
	NES(MemType* mem = nullptr);
	~NES();	
	static constexpr int mem_size() {
		return CpuCore::size() + ram_size;
	}
private:
	static constexpr int ram_size = 1024;	
	MemoryMapped<MemType> ram;
	MemoryMappedDevice<RegType> cpu;
	CpuCore cpu_core;
	R6502<ProgramCounter> isa;
};