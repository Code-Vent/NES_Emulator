#include "r6502.h"
#include<assert.h>

struct Immediate : public AddressMode {
	status_t operator()(const CpuCore* cpu, Instruction* op, Memory<MemType>* opr, ProgramCounter& pc)override;
}IMM;

struct Absolute : public AddressMode {
	status_t operator()(const CpuCore* cpu, Instruction* op, Memory<MemType>* opr, ProgramCounter& pc)override;
}ABS;

struct ZeroPage : public AddressMode {
	status_t operator()(const CpuCore* cpu, Instruction* op, Memory<MemType>* opr, ProgramCounter& pc)override;
}ZP;

struct IndexedZeroPage : public AddressMode {
	IndexedZeroPage(CpuCore::Register r)
		:AddressMode(r)
	{
	}
	status_t operator()(const CpuCore* cpu, Instruction* op, Memory<MemType>* opr, ProgramCounter& pc)override;
}IND_ZPX{CpuCore::INDEX_X}, IND_ZPY{ CpuCore::INDEX_Y };

struct IndexedAbsolutePage : public AddressMode {
	IndexedAbsolutePage(CpuCore::Register r)
		:AddressMode(r)
	{
	}
	status_t operator()(const CpuCore* cpu, Instruction* op, Memory<MemType>* opr, ProgramCounter& pc)override;
}IND_ABSX{ CpuCore::INDEX_X }, IND_ABSY{ CpuCore::INDEX_Y };

struct ImpliedRegister : public AddressMode {
	ImpliedRegister(CpuCore::Register r)
		:AddressMode(r)
	{
	}
	status_t operator()(const CpuCore* cpu, Instruction* op, Memory<MemType>* opr, ProgramCounter& pc)override;
}IMP_STAT{ CpuCore::STATUS }, IMP_SP{ CpuCore::STACK_POINTER }, IMP_ACC{ CpuCore::ACCUMULATOR }, IMP_PC{ CpuCore::PCL };

struct ImpliedMemory : public AddressMode {
	status_t operator()(const CpuCore* cpu, Instruction* op, Memory<MemType>* opr, ProgramCounter& pc)override;
}IMP_LOC;

struct Relative : public AddressMode {
	status_t operator()(const CpuCore* cpu, Instruction* op, Memory<MemType>* opr, ProgramCounter& pc)override;
}REL;

struct IndexedIndirect : public AddressMode {
	status_t operator()(const CpuCore* cpu, Instruction* op, Memory<MemType>* opr, ProgramCounter& pc)override;
}IND_INDR;

struct IndirectIndexed : public AddressMode {
	status_t operator()(const CpuCore* cpu, Instruction* op, Memory<MemType>* opr, ProgramCounter& pc)override;
}INDR_IND;

struct AbsoluteIndirect : public AddressMode {
	status_t operator()(const CpuCore* cpu, Instruction* op, Memory<MemType>* opr, ProgramCounter& pc)override;
}ABS_INDR;

status_t Immediate::operator()(const CpuCore* cpu, Instruction* op, Memory<MemType>* opr, ProgramCounter& pc)
{
	auto s = op->execute(cpu, opr, pc);
	return min(status_t::PC_PLUS_ONE, s);
}

status_t Absolute::operator()(const CpuCore* cpu, Instruction* op, Memory<MemType>* opr, ProgramCounter& pc)
{
	auto lo = opr[0].read();
	auto hi = opr[1].read();
	uint16_t abs_addr = (hi << 8) | lo;
	auto s = op->execute(cpu, pc.to(abs_addr), pc);
	return min(s, status_t::PC_PLUS_TWO);
}

status_t ZeroPage::operator()(const CpuCore* cpu, Instruction* op, Memory<MemType>* opr, ProgramCounter& pc)
{
	auto abs_addr = opr->read();
	auto s = op->execute(cpu, pc.to(abs_addr), pc);
	return min(s, status_t::PC_PLUS_ONE);
}

status_t IndexedZeroPage::operator()(const CpuCore* cpu, Instruction* op, Memory<MemType>* opr, ProgramCounter& pc)
{
	assert(r == CpuCore::INDEX_X || r == CpuCore::INDEX_Y);
	uint16_t abs_addr = cpu->get_register(r)->read() + opr[0].read();
	auto s = op->execute(cpu, pc.to(abs_addr & 0x00FF), pc);
	return min(s, status_t::PC_PLUS_ONE);
}

AddressMode::AddressMode(CpuCore::Register R)
{
	r = R;
}

status_t IndexedAbsolutePage::operator()(const CpuCore* cpu, Instruction* op, Memory<MemType>* opr, ProgramCounter& pc)
{
	assert(r == CpuCore::INDEX_X || r == CpuCore::INDEX_Y);
	auto lo = opr[0].read();
	auto hi = opr[1].read();
	uint16_t abs_addr = (hi << 8) | lo;
	abs_addr += cpu->get_register(r)->read();
	auto s = op->execute(cpu, pc.to(abs_addr), pc);
	return min(s, status_t::PC_PLUS_TWO);
}

status_t ImpliedRegister::operator()(const CpuCore* cpu, Instruction* op, Memory<MemType>* opr, ProgramCounter& pc)
{
	auto s = op->execute(cpu, cpu->get_register(r), pc);
	return min(s, status_t::PC_PLUS_ONE);
}

status_t ImpliedMemory::operator()(const CpuCore* cpu, Instruction* op, Memory<MemType>* opr, ProgramCounter& pc)
{
	return status_t();
}

status_t Relative::operator()(const CpuCore* cpu, Instruction* op, Memory<MemType>* opr, ProgramCounter& pc)
{
	auto offset = opr->read();
	auto s = op->execute(cpu, &opr[offset], pc);
	return min(s, status_t::PC_PLUS_ONE);
}

status_t IndexedIndirect::operator()(const CpuCore* cpu, Instruction* op, Memory<MemType>* opr, ProgramCounter& pc)
{
	*cpu->get_register(CpuCore::INDEX_X) += opr[0];
	auto loc = cpu->get_register(CpuCore::INDEX_X)->read();
	auto lo = pc.to(loc)->read();
	auto hi = pc.to(loc + 1)->read();
	uint16_t abs_addr = (hi << 8) | lo;
	auto s = op->execute(cpu, pc.to(0x00ff & abs_addr), pc);
	return min(s, status_t::PC_PLUS_ONE);
}

status_t IndirectIndexed::operator()(const CpuCore* cpu, Instruction* op, Memory<MemType>* opr, ProgramCounter& pc)
{
	cpu->load_register(CpuCore::Register::ACCUMULATOR, opr->read());
	cpu->ADDC(cpu->get_register(CpuCore::INDEX_Y));
	auto lo = cpu->get_register(CpuCore::ACCUMULATOR)->read();
	uint16_t hi = opr[1].read() + cpu->get_flag(CpuCore::Flag::C);
	uint16_t abs_addr = (hi << 8) | lo;
	auto s = op->execute(cpu, pc.to(0x00ff & abs_addr), pc);
	return min(s, status_t::PC_PLUS_TWO);
}

status_t AbsoluteIndirect::operator()(const CpuCore* cpu, Instruction* op, Memory<MemType>* opr, ProgramCounter& pc)
{
	auto lo = opr[0].read();
	auto hi = opr[1].read();
	uint16_t abs_addr = (hi << 8) | lo;
	auto s = op->execute(cpu, pc.to(abs_addr), pc);
	return min(s, status_t::PC_PLUS_TWO);
}


ProgramCounter::ProgramCounter(MemoryMapped<MemType>* Ram, void* c)
{
	ram = Ram;
	counter = new(c)uint16_t;
	*counter = 0;
}

Memory<MemType>* ProgramCounter::operator*()
{
	return ram->at(*counter);
}

void ProgramCounter::operator+=(uint16_t o)
{
	assert(*counter + o < ram->size());
	*counter += o;
}

uint16_t ProgramCounter::from(Memory<MemType>* mem)
{
	assert(mem > ram->at(0));
	uint16_t diff = mem - ram->at(0);
	assert(diff < ram->size());
	return diff;
}

Memory<MemType>* ProgramCounter::to(uint16_t d)
{
	return ram->at(d);
}

uint16_t ProgramCounter::get()
{
	return *counter;
}

void ProgramCounter::set(uint16_t abs_addr)
{
	*counter = abs_addr;
}

void ProgramCounter::operator++()
{
	assert(*counter < ram->size());
	*counter += 1;
}

struct Nop : Instruction {

}NOP;

struct BRK : Instruction {
	status_t execute(const CpuCore* cpu, Memory<MemType>*, ProgramCounter& pc)override {
		cpu->set_flag(CpuCore::Flag::I, 1);
		cpu->set_flag(CpuCore::Flag::B, 1);
		uint8_t pch = pc.get() >> 8;
		cpu->push(pch);
		uint8_t pcl = pc.get() & 0x00ff;
		cpu->push(pcl);
		Memory<MemType>* s = cpu->get_register(CpuCore::Register::STATUS);
		cpu->push(s->read());
		cpu->set_flag(CpuCore::Flag::B, 0);

		pch = pc.to(0xFFFF)->read();
		pcl = pc.to(0xFFFE)->read();
		pc.set(pcl | (pch << 8));
		return status_t::PC_PLUS_FOUR;
	}
}BRK;

struct Ora : Instruction {
	status_t execute(const CpuCore* cpu, Memory<MemType>* opr, ProgramCounter& pc)override {
		cpu->get_register(CpuCore::ACCUMULATOR)->ORed(opr->read());
		auto r = cpu->get_register(CpuCore::ACCUMULATOR)->read();
		cpu->set_flag(CpuCore::Flag::Z, r == 0x00);
		cpu->set_flag(CpuCore::Flag::N, r & 0x80);
		return status_t::PC_PLUS_FOUR;
	}
}ORA;

struct Asl : Instruction {
	status_t execute(const CpuCore* cpu, Memory<MemType>* opr, ProgramCounter& pc)override {
		int16_t r = opr->read();
		r <<= 1;
		opr->load(0x00ff & r);
		cpu->set_flag(CpuCore::Flag::Z, r == 0x00);
		cpu->set_flag(CpuCore::Flag::N, r & 0x80);
		cpu->set_flag(CpuCore::Flag::C, r & 0x0100);
		return status_t::PC_PLUS_FOUR;
	}
}ASL;

struct Php : Instruction {
	status_t execute(const CpuCore* cpu, Memory<MemType>* opr, ProgramCounter& pc)override {
		cpu->set_flag(CpuCore::Flag::B, 1);
		cpu->push(opr->read());
		cpu->set_flag(CpuCore::Flag::B, 0);
		return status_t::PC_PLUS_FOUR;
	}
}PHP;

struct Clc : Instruction {
	status_t execute(const CpuCore* cpu, Memory<MemType>* opr, ProgramCounter& pc)override {
		cpu->set_flag(CpuCore::Flag::C, 0);
		return status_t::PC_PLUS_FOUR;
	}
}CLC;

struct Bpl : Instruction {
	status_t execute(const CpuCore* cpu, Memory<MemType>* opr, ProgramCounter& pc)override {
		if (cpu->get_flag(CpuCore::Flag::N) == 0) {
			uint16_t* pc = reinterpret_cast<uint16_t*>(cpu->get_register(CpuCore::Register::PCL));
			*pc += opr->read();
			return status_t::PC_HALT;
		}
		return status_t::PC_PLUS_FOUR;
	}
}BPL;

struct Jsr : Instruction {
	status_t execute(const CpuCore* cpu, Memory<MemType>* opr, ProgramCounter& pc)override {
		uint16_t d = pc.from(opr);
		pc.set(d);
		return status_t::PC_HALT;
	}
}JSR;

struct And : Instruction {
	status_t execute(const CpuCore* cpu, Memory<MemType>* opr, ProgramCounter& pc)override {
		cpu->get_register(CpuCore::Register::ACCUMULATOR)->ANDed(opr->read());
		auto r = cpu->get_register(CpuCore::Register::ACCUMULATOR)->read();
		cpu->set_flag(CpuCore::Flag::Z, r == 0x00);
		cpu->set_flag(CpuCore::Flag::N, r & 0x80);
		return status_t::PC_PLUS_FOUR;
	}
}AND;

struct Bit : Instruction {
	status_t execute(const CpuCore* cpu, Memory<MemType>* opr, ProgramCounter& pc)override {
		auto t = cpu->get_register(CpuCore::Register::ACCUMULATOR)->read();
		auto r = t & opr->read();
		cpu->set_flag(CpuCore::Flag::Z, r == 0x00);
		cpu->set_flag(CpuCore::Flag::N, t & UINT8_C(128));
		cpu->set_flag(CpuCore::Flag::V, t & UINT8_C(64));
		return status_t::PC_PLUS_FOUR;
	}
}BIT;

struct Rol : Instruction {
	status_t execute(const CpuCore* cpu, Memory<MemType>* opr, ProgramCounter& pc)override {
		Memory<MemType>* s = cpu->get_register(CpuCore::Register::STATUS);
		MemoryIterator<MemType> it1(s, CpuCore::Flag::C);
		auto it2 = opr->rbegin();
		Memory<MemType>::swap(it1, it2);

		opr->ROL(1);
		auto r = opr->read();
		cpu->set_flag(CpuCore::Flag::Z, r == 0x00);
		cpu->set_flag(CpuCore::Flag::N, r & 0x80);
		return status_t::PC_PLUS_FOUR;
	}
}ROL;

struct Ror : Instruction {
	status_t execute(const CpuCore* cpu, Memory<MemType>* opr, ProgramCounter& pc)override {
		Memory<MemType>* s = cpu->get_register(CpuCore::Register::STATUS);
		MemoryIterator<MemType> it1(s, CpuCore::Flag::C);
		auto it2 = opr->begin();
		Memory<MemType>::swap(it1, it2);

		opr->ROR(1);
		auto r = opr->read();
		cpu->set_flag(CpuCore::Flag::Z, r == 0x00);
		cpu->set_flag(CpuCore::Flag::N, r & 0x80);
		return status_t::PC_PLUS_FOUR;
	}
}ROR;

struct Plp : Instruction {
	status_t execute(const CpuCore* cpu, Memory<MemType>* opr, ProgramCounter& pc)override {
		auto s = cpu->pop();
		cpu->get_register(CpuCore::Register::STATUS)->load(s);
		cpu->set_flag(CpuCore::Flag::_, 1);
		return status_t::PC_PLUS_FOUR;
	}
}PLP;

struct Bmi : Instruction {
	status_t execute(const CpuCore* cpu, Memory<MemType>* opr, ProgramCounter& pc)override {
		if (cpu->get_flag(CpuCore::Flag::N) == 1) {
			auto abs_addr = pc.from(opr);
			pc.set(abs_addr);
			return status_t::PC_HALT;
		}
		return status_t::PC_PLUS_FOUR;
	}
}BMI;

struct Sec : Instruction {
	status_t execute(const CpuCore* cpu, Memory<MemType>* opr, ProgramCounter& pc)override {
		cpu->set_flag(CpuCore::Flag::C, 1);
		return status_t::PC_PLUS_FOUR;
	}
}SEC;

struct Rti : Instruction {
	status_t execute(const CpuCore* cpu, Memory<MemType>* opr, ProgramCounter& pc)override {
		auto status = cpu->pop();
		opr->load(status);
		cpu->set_flag(CpuCore::Flag::B, 0);
		cpu->set_flag(CpuCore::Flag::_, 0);

		auto pch = cpu->pop();
		auto pcl = cpu->pop();
		pc.set(pcl | (pch << 8));
		return status_t::PC_HALT;
	}
}RTI;

struct Eor : Instruction {
	status_t execute(const CpuCore* cpu, Memory<MemType>* opr, ProgramCounter& pc)override {
		cpu->get_register(CpuCore::Register::ACCUMULATOR)->XORed(opr->read());
		auto r = cpu->get_register(CpuCore::Register::ACCUMULATOR)->read();
		cpu->set_flag(CpuCore::Flag::Z, r == 0x00);
		cpu->set_flag(CpuCore::Flag::N, r & 0x80);
		return status_t::PC_PLUS_FOUR;
	}
}EOR;

struct Lsr : Instruction {
	status_t execute(const CpuCore* cpu, Memory<MemType>* opr, ProgramCounter& pc)override {
		cpu->set_flag(CpuCore::Flag::C, opr->at(0));
		opr->RSH(1);
		auto r = opr->read();
		cpu->set_flag(CpuCore::Flag::Z, r == 0x00);
		cpu->set_flag(CpuCore::Flag::N, r & 0x80);
		return status_t::PC_PLUS_FOUR;
	}
}LSR;

struct Lsl : Instruction {
	status_t execute(const CpuCore* cpu, Memory<MemType>* opr, ProgramCounter& pc)override {
		cpu->set_flag(CpuCore::Flag::C, opr->at(7));
		opr->LSH(1);
		auto r = opr->read();
		cpu->set_flag(CpuCore::Flag::Z, r == 0x00);
		cpu->set_flag(CpuCore::Flag::N, r & 0x80);
		return status_t::PC_PLUS_FOUR;
	}
}LSL;

struct Pha : Instruction {
	status_t execute(const CpuCore* cpu, Memory<MemType>* opr, ProgramCounter& pc)override {
		cpu->push(opr->read());
		return status_t::PC_PLUS_FOUR;
	}
}PHA;

struct Jmp : Instruction {
	status_t execute(const CpuCore* cpu, Memory<MemType>* opr, ProgramCounter& pc)override {
		auto j = pc.from(opr);
		pc.set(j);
		return status_t::PC_HALT;
	}
}JMP;

R6502InstructionSet::R6502InstructionSet()
{
	instruction_set.insert(make_pair(0x00, make_pair(&BRK, &IMP_PC)));
	instruction_set.insert(make_pair(0x01, make_pair(&ORA, &IND_ZPX)));
	instruction_set.insert(make_pair(0x05, make_pair(&ORA, &ZP)));
	instruction_set.insert(make_pair(0x06, make_pair(&ASL, &ZP)));
	instruction_set.insert(make_pair(0x08, make_pair(&PHP, &IMP_STAT)));
	instruction_set.insert(make_pair(0x09, make_pair(&ORA, &IMM)));
	instruction_set.insert(make_pair(0x0A, make_pair(&ORA, &IMP_ACC)));
	instruction_set.insert(make_pair(0x0D, make_pair(&ORA, &ABS)));
	instruction_set.insert(make_pair(0x0E, make_pair(&ASL, &IND_ZPX)));

	instruction_set.insert(make_pair(0x10, make_pair(&BPL, &REL)));
	instruction_set.insert(make_pair(0x11, make_pair(&ORA, &IND_ZPY)));
	instruction_set.insert(make_pair(0x15, make_pair(&ORA, &IND_ZPX)));
	instruction_set.insert(make_pair(0x16, make_pair(&ASL, &IND_ZPX)));
	instruction_set.insert(make_pair(0x18, make_pair(&CLC, &IMP_STAT)));
	instruction_set.insert(make_pair(0x19, make_pair(&ORA, &IND_ABSY)));
	instruction_set.insert(make_pair(0x1D, make_pair(&ORA, &IND_ABSX)));
	instruction_set.insert(make_pair(0x1E, make_pair(&ASL, &IND_ABSX)));

	instruction_set.insert(make_pair(0x20, make_pair(&JSR, &ABS)));
	instruction_set.insert(make_pair(0x21, make_pair(&AND, &IND_ZPX)));
	instruction_set.insert(make_pair(0x24, make_pair(&BIT, &ZP)));
	instruction_set.insert(make_pair(0x25, make_pair(&AND, &ZP)));
	instruction_set.insert(make_pair(0x26, make_pair(&ROL, &ZP)));
	instruction_set.insert(make_pair(0x28, make_pair(&PLP, &IMP_STAT)));
	instruction_set.insert(make_pair(0x29, make_pair(&AND, &IMM)));
	instruction_set.insert(make_pair(0x2A, make_pair(&ROL, &IMP_ACC)));
	instruction_set.insert(make_pair(0x2C, make_pair(&BIT, &ABS)));
	instruction_set.insert(make_pair(0x2D, make_pair(&AND, &ABS)));
	instruction_set.insert(make_pair(0x2E, make_pair(&ROL, &ABS)));

	instruction_set.insert(make_pair(0x30, make_pair(&BMI, &REL)));
	instruction_set.insert(make_pair(0x31, make_pair(&AND, &IND_ZPY)));
	instruction_set.insert(make_pair(0x35, make_pair(&AND, &IND_ZPX)));
	instruction_set.insert(make_pair(0x36, make_pair(&ROL, &IND_ZPX)));
	instruction_set.insert(make_pair(0x38, make_pair(&SEC, &IMP_STAT)));
	instruction_set.insert(make_pair(0x39, make_pair(&AND, &IND_ABSY)));
	instruction_set.insert(make_pair(0x3D, make_pair(&AND, &IND_ABSX)));
	instruction_set.insert(make_pair(0x3E, make_pair(&ROL, &IND_ABSX)));

	instruction_set.insert(make_pair(0x40, make_pair(&RTI, &IMP_STAT)));
	instruction_set.insert(make_pair(0x41, make_pair(&EOR, &IND_ZPX)));
	instruction_set.insert(make_pair(0x45, make_pair(&EOR, &ZP)));
	instruction_set.insert(make_pair(0x46, make_pair(&LSR, &ZP)));
	instruction_set.insert(make_pair(0x48, make_pair(&PHA, &IMP_ACC)));
	instruction_set.insert(make_pair(0x49, make_pair(&EOR, &IMM)));
	instruction_set.insert(make_pair(0x4A, make_pair(&LSR, &IMP_ACC)));
	instruction_set.insert(make_pair(0x4C, make_pair(&JMP, &ABS)));
	instruction_set.insert(make_pair(0x4D, make_pair(&EOR, &ABS)));
	instruction_set.insert(make_pair(0x4E, make_pair(&LSR, &ABS)));
}

status_t R6502InstructionSet::decode(const CpuCore* cpu, ProgramCounter& pc)
{
	Memory<MemType>* opcode = *pc;
	++pc;
	Memory<MemType>* opr = *pc;
	auto iter = instruction_set.find(opcode->read());
	if (iter != instruction_set.end()) {
		auto instruction = iter->second;
		return instruction.second->operator()(cpu, instruction.first, opr, pc);
	}
	return status_t::PC_HALT;
}
