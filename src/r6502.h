#pragma once
#include"cpu.h"
#include<array>
#include<functional>
#include<unordered_map>
#include"try.h"
using namespace std;

typedef enum Status {
	PC_HALT,
	PC_PLUS_ONE,
	PC_PLUS_TWO,
	PC_PLUS_THREE,
	PC_PLUS_FOUR,
	RESET,
	FATAL_ERROR
}status_t;

class ProgramCounter;

struct Instruction {
	virtual status_t execute(const CpuCore* cpu, Memory<MemType>* opr, ProgramCounter&) { return status_t::PC_PLUS_FOUR; }
};

struct AddressMode {
	virtual status_t operator()(const CpuCore* cpu,
		Instruction* op,
		Memory<MemType>* opr,
		ProgramCounter& pc) = 0;
	AddressMode(CpuCore::Register R = CpuCore::ACCUMULATOR);
	CpuCore::Register r;
};

class ProgramCounter {
	friend struct R6502InstructionSet;
public:
	ProgramCounter(MemoryMapped<MemType>* Ram, void* c);
	Memory<MemType>* operator*();
	void operator++();
	void operator+=(uint16_t offset);
	uint16_t from(Memory<MemType>*);
	Memory<MemType>* to(uint16_t);
	uint16_t get();
	void set(uint16_t);
private:
	MemoryMapped<MemType>* ram;
	uint16_t* counter;
};

using INSTRUCTION = pair<Instruction*, AddressMode*>;

struct R6502InstructionSet {
	R6502InstructionSet();
	status_t decode(const CpuCore* cpu, ProgramCounter& pc);
private:
	std::unordered_map<uint8_t, INSTRUCTION> instruction_set;
};

template<class PC>
class R6502 : public Tryable {
	friend class Clock;	
public:
	R6502(MemoryMapped<MemType>* Ram, MemoryMappedDevice<RegType>* Core);
	void Try() override;
private:
	MemoryMapped<MemType>* ram;
	MemoryMappedDevice<RegType>* core;
};

template<class PC>
inline R6502<PC>::R6502(MemoryMapped<MemType>* Ram, MemoryMappedDevice<RegType>* Core)
	:ram(Ram), core(Core)
{
}

template<class PC>
inline void R6502<PC>::Try()
{
	static R6502InstructionSet iset;
	auto cpu = reinterpret_cast<const CpuCore*>(core->get_device());
	//Initialize registers, setup handlers etc
	PC pc(ram, cpu->registers + cpu->PCL);
	cpu->Init();
	auto status = status_t::PC_HALT;
	while (status != status_t::PC_HALT) {
		status = iset.decode(cpu, pc);
		pc += status;
		
		cpu->update();
	}
}
